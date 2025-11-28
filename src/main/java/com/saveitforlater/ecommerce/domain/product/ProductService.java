package com.saveitforlater.ecommerce.domain.product;

import com.saveitforlater.ecommerce.api.product.dto.CreateProductRequest;
import com.saveitforlater.ecommerce.api.product.dto.ProductAttributeDto;
import com.saveitforlater.ecommerce.api.product.dto.ProductResponse;
import com.saveitforlater.ecommerce.api.product.dto.UpdateProductRequest;
import com.saveitforlater.ecommerce.api.product.mapper.ProductMapper;
import com.saveitforlater.ecommerce.domain.category.exception.CategoryNotFoundException;
import com.saveitforlater.ecommerce.domain.product.exception.ProductNotFoundException;
import com.saveitforlater.ecommerce.domain.product.exception.ProductSkuAlreadyExistsException;
import com.saveitforlater.ecommerce.persistence.entity.category.Category;
import com.saveitforlater.ecommerce.persistence.entity.product.*;
import com.saveitforlater.ecommerce.persistence.repository.category.CategoryRepository;
import com.saveitforlater.ecommerce.persistence.repository.product.ProductRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ProductService {

    private final ProductRepository productRepository;
    private final CategoryRepository categoryRepository;
    private final ProductMapper productMapper;
    private final AttributeService attributeService;
    private final AttributeOptionService attributeOptionService;
    private final ProductAttributeValueService productAttributeValueService;

    /**
     * Get all products (accessible to everyone)
     */
    public List<ProductResponse> getAllProducts() {
        log.debug("Fetching all products");
        return productRepository.findAll()
                .stream()
                .map(productMapper::toProductResponse)
                .collect(Collectors.toList());
    }

    /**
     * Get paginated products (accessible to everyone)
     */
    public Page<ProductResponse> getProducts(Pageable pageable) {
        log.debug("Fetching products with pagination: {}", pageable);
        return productRepository.findAll(pageable)
                .map(productMapper::toProductResponse);
    }

    /**
     * Get product by public ID (accessible to everyone)
     */
    public ProductResponse getProductById(String publicId) {
        log.debug("Fetching product by ID: {}", publicId);
        Product product = productRepository.findByPublicId(publicId)
                .orElseThrow(() -> ProductNotFoundException.byPublicId(publicId));

        return productMapper.toProductResponse(product);
    }

    /**
     * Get product by SKU (accessible to everyone)
     */
    public ProductResponse getProductBySku(String sku) {
        log.debug("Fetching product by SKU: {}", sku);
        Product product = productRepository.findBySku(sku)
                .orElseThrow(() -> ProductNotFoundException.bySku(sku));

        return productMapper.toProductResponse(product);
    }

    /**
     * Create a new product (ADMIN ONLY)
     */
    @Transactional
    public ProductResponse createProduct(CreateProductRequest request) {
        log.info("Creating new product with SKU: {}", request.sku());

        // Check if product SKU already exists
        if (productRepository.findBySku(request.sku()).isPresent()) {
            throw ProductSkuAlreadyExistsException.withSku(request.sku());
        }

        // Map basic fields
        Product product = productMapper.toProduct(request);

        // Set categories if provided
        if (request.categoryIds() != null && !request.categoryIds().isEmpty()) {
            Set<Category> categories = new HashSet<>();
            for (String categoryId : request.categoryIds()) {
                Category category = categoryRepository.findByPublicId(categoryId)
                        .orElseThrow(() -> CategoryNotFoundException.byPublicId(categoryId));
                categories.add(category);
            }
            product.setCategories(categories);
            log.debug("Set {} categories for new product: {}", categories.size(), request.name());
        }

        // Set attributes if provided
        if (request.attributes() != null && !request.attributes().isEmpty()) {
            for (ProductAttributeDto attrDto : request.attributes()) {
                processProductAttribute(product, attrDto);
            }
            log.debug("Set {} attributes for new product: {}", request.attributes().size(), request.name());
        }

        // Save product with duplicate SKU handling
        try {
            Product savedProduct = productRepository.save(product);
            log.info("Successfully created product with ID: {} and SKU: {}",
                    savedProduct.getPublicId(), savedProduct.getSku());
            return productMapper.toProductResponse(savedProduct);
        } catch (org.springframework.dao.DataIntegrityViolationException ex) {
            // Handle race condition where SKU was checked but inserted by another transaction
            if (ex.getMessage() != null && ex.getMessage().contains("sku")) {
                log.warn("Race condition detected: SKU {} was inserted by another transaction", request.sku());
                throw ProductSkuAlreadyExistsException.withSku(request.sku());
            }
            throw ex; // Re-throw other integrity violations
        }
    }

    /**
     * Update an existing product (ADMIN ONLY)
     */
    @Transactional
    public ProductResponse updateProduct(String publicId, UpdateProductRequest request) {
        log.info("Updating product with ID: {}", publicId);

        // Find existing product
        Product existingProduct = productRepository.findByPublicId(publicId)
                .orElseThrow(() -> ProductNotFoundException.byPublicId(publicId));

        // Check if new SKU conflicts with existing products (excluding current product)
        productRepository.findBySku(request.sku())
                .filter(product -> !product.getPublicId().equals(publicId))
                .ifPresent(product -> {
                    throw ProductSkuAlreadyExistsException.withSku(request.sku());
                });

        // Update basic fields
        productMapper.updateProductFromRequest(request, existingProduct);

        // Update categories if provided
        if (request.categoryIds() != null) {
            Set<Category> categories = new HashSet<>();
            for (String categoryId : request.categoryIds()) {
                Category category = categoryRepository.findByPublicId(categoryId)
                        .orElseThrow(() -> CategoryNotFoundException.byPublicId(categoryId));
                categories.add(category);
            }
            // Clear existing categories and set new ones
            existingProduct.getCategories().clear();
            existingProduct.setCategories(categories);
            log.debug("Updated categories for product: {}", existingProduct.getName());
        }

        // Update attributes if provided
        if (request.attributes() != null) {
            // Clear existing attribute values
            productAttributeValueService.clearAllAttributeValuesForProduct(existingProduct);

            // Add new attributes
            for (ProductAttributeDto attrDto : request.attributes()) {
                processProductAttribute(existingProduct, attrDto);
            }
            log.debug("Updated attributes for product: {}", existingProduct.getName());
        }

        // Save updated product
        Product updatedProduct = productRepository.save(existingProduct);
        log.info("Successfully updated product with ID: {}", updatedProduct.getPublicId());

        return productMapper.toProductResponse(updatedProduct);
    }

    /**
     * Delete a product (ADMIN ONLY)
     */
    @Transactional
    public void deleteProduct(String publicId) {
        log.info("Deleting product with ID: {}", publicId);

        Product product = productRepository.findByPublicId(publicId)
                .orElseThrow(() -> ProductNotFoundException.byPublicId(publicId));

        // TODO: Check if product has orders associated with it
        // This would require checking the Order entity relationships
        // For now, we'll rely on database constraints

        productRepository.delete(product);
        log.info("Successfully deleted product with ID: {}", publicId);
    }

    /**
     * Helper method to process product attributes using the new reusable system
     */
    private void processProductAttribute(Product product, ProductAttributeDto attrDto) {
        Attribute attribute;
        
        // Get or create attribute
        if (attrDto.attributeId() != null) {
            // Use existing attribute
            attribute = attributeService.findByPublicId(attrDto.attributeId())
                    .orElseThrow(() -> new IllegalArgumentException(
                            "Attribute not found with ID: " + attrDto.attributeId()));
        } else if (StringUtils.hasText(attrDto.attributeName())) {
            // Create or get attribute by name
            attribute = attributeService.createOrGetAttribute(
                    attrDto.attributeName(), attrDto.attributeDescription());
        } else {
            throw new IllegalArgumentException(
                    "Either attributeId or attributeName must be provided");
        }

        // Process attribute options
        if (attrDto.options() != null && !attrDto.options().isEmpty()) {
            for (ProductAttributeDto.ProductAttributeOptionDto optionDto : attrDto.options()) {
                AttributeOption option;
                
                if (optionDto.optionId() != null) {
                    // Use existing option
                    option = attributeOptionService.findByPublicId(optionDto.optionId())
                            .orElseThrow(() -> new IllegalArgumentException(
                                    "Attribute option not found with ID: " + optionDto.optionId()));
                    
                    // Verify the option belongs to the correct attribute
                    if (!option.getAttribute().equals(attribute)) {
                        throw new IllegalArgumentException(
                                "Option " + optionDto.optionId() + " does not belong to attribute " 
                                + attribute.getPublicId());
                    }
                } else if (StringUtils.hasText(optionDto.optionName())) {
                    // Create or get option by name
                    option = attributeOptionService.createOrGetOption(
                            attribute, optionDto.optionName(), optionDto.optionDescription());
                } else {
                    throw new IllegalArgumentException(
                            "Either optionId or optionName must be provided");
                }

                // Add the attribute value to the product directly (don't save yet - let cascade handle it)
                ProductAttributeValue attributeValue = new ProductAttributeValue(product, attribute, option);
                product.addAttributeValue(attributeValue);
            }
        }
    }
}


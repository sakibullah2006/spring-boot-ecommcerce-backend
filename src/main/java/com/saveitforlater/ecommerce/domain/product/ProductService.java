package com.saveitforlater.ecommerce.domain.product;

import com.saveitforlater.ecommerce.api.product.dto.CreateProductRequest;
import com.saveitforlater.ecommerce.api.product.dto.ProductResponse;
import com.saveitforlater.ecommerce.api.product.dto.UpdateProductRequest;
import com.saveitforlater.ecommerce.api.product.mapper.ProductMapper;
import com.saveitforlater.ecommerce.domain.category.exception.CategoryNotFoundException;
import com.saveitforlater.ecommerce.domain.product.exception.ProductNotFoundException;
import com.saveitforlater.ecommerce.domain.product.exception.ProductSkuAlreadyExistsException;
import com.saveitforlater.ecommerce.persistence.entity.category.Category;
import com.saveitforlater.ecommerce.persistence.entity.product.Product;
import com.saveitforlater.ecommerce.persistence.repository.category.CategoryRepository;
import com.saveitforlater.ecommerce.persistence.repository.product.ProductRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ProductService {

    private final ProductRepository productRepository;
    private final CategoryRepository categoryRepository;
    private final ProductMapper productMapper;

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
    public ProductResponse getProductById(UUID publicId) {
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
            for (UUID categoryId : request.categoryIds()) {
                Category category = categoryRepository.findByPublicId(categoryId)
                        .orElseThrow(() -> CategoryNotFoundException.byPublicId(categoryId));
                categories.add(category);
            }
            product.setCategories(categories);
            log.debug("Set {} categories for new product: {}", categories.size(), request.name());
        }

        // Save product
        Product savedProduct = productRepository.save(product);
        log.info("Successfully created product with ID: {} and SKU: {}",
                savedProduct.getPublicId(), savedProduct.getSku());

        return productMapper.toProductResponse(savedProduct);
    }

    /**
     * Update an existing product (ADMIN ONLY)
     */
    @Transactional
    public ProductResponse updateProduct(UUID publicId, UpdateProductRequest request) {
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
            for (UUID categoryId : request.categoryIds()) {
                Category category = categoryRepository.findByPublicId(categoryId)
                        .orElseThrow(() -> CategoryNotFoundException.byPublicId(categoryId));
                categories.add(category);
            }
            // Clear existing categories and set new ones
            existingProduct.getCategories().clear();
            existingProduct.setCategories(categories);
            log.debug("Updated categories for product: {}", existingProduct.getName());
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
    public void deleteProduct(UUID publicId) {
        log.info("Deleting product with ID: {}", publicId);

        Product product = productRepository.findByPublicId(publicId)
                .orElseThrow(() -> ProductNotFoundException.byPublicId(publicId));

        // TODO: Check if product has orders associated with it
        // This would require checking the Order entity relationships
        // For now, we'll rely on database constraints

        productRepository.delete(product);
        log.info("Successfully deleted product with ID: {}", publicId);
    }
}


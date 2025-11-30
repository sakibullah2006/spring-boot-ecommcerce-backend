package com.saveitforlater.ecommerce.api.product;

import com.saveitforlater.ecommerce.api.product.dto.ProductAttributeValueDto;
import com.saveitforlater.ecommerce.api.product.mapper.ProductMapper;
import com.saveitforlater.ecommerce.domain.product.AttributeOptionService;
import com.saveitforlater.ecommerce.domain.product.AttributeService;
import com.saveitforlater.ecommerce.domain.product.ProductAttributeValueService;
import com.saveitforlater.ecommerce.domain.product.exception.ProductNotFoundException;
import com.saveitforlater.ecommerce.persistence.entity.product.Attribute;
import com.saveitforlater.ecommerce.persistence.entity.product.AttributeOption;
import com.saveitforlater.ecommerce.persistence.entity.product.Product;
import com.saveitforlater.ecommerce.persistence.entity.product.ProductAttributeValue;
import com.saveitforlater.ecommerce.persistence.repository.product.ProductRepository;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Controller for managing product-attribute assignments.
 * Provides endpoints to add, retrieve, update, and remove attribute-option pairs for products.
 */
@Slf4j
@RestController
@RequestMapping("/api/products/{productId}/attributes")
@RequiredArgsConstructor
public class ProductAttributeController {

    private final ProductRepository productRepository;
    private final ProductAttributeValueService productAttributeValueService;
    private final AttributeService attributeService;
    private final AttributeOptionService attributeOptionService;
    private final ProductMapper productMapper;

    /**
     * Get all attribute assignments for a product - accessible to everyone
     */
    @GetMapping
    public ResponseEntity<List<ProductAttributeValueDto>> getProductAttributes(@PathVariable String productId) {
        log.debug("GET /api/products/{}/attributes - Fetching product attributes", productId);
        
        List<ProductAttributeValue> attributeValues = productAttributeValueService
                .getActiveAttributeValuesByProductId(productId);
        
        List<ProductAttributeValueDto> response = attributeValues.stream()
                .map(productMapper::toProductAttributeValueDto)
                .collect(Collectors.toList());
        
        return ResponseEntity.ok(response);
    }

    /**
     * Add attribute assignments to a product - ADMIN ONLY
     * Adds one or more attribute-option pairs to the product.
     */
    @PostMapping
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<List<ProductAttributeValueDto>> addProductAttributes(
            @PathVariable String productId,
            @Valid @RequestBody AddProductAttributesRequest request) {
        
        log.info("POST /api/products/{}/attributes - Adding {} attribute(s)", 
                productId, request.attributes().size());
        
        // Fetch product
        Product product = productRepository.findByPublicId(productId)
                .orElseThrow(() -> ProductNotFoundException.byPublicId(productId));
        
        // Add each attribute-option pair
        List<ProductAttributeValue> createdValues = request.attributes().stream()
                .map(attr -> {
                    Attribute attribute = attributeService.findByPublicId(attr.attributeId())
                            .orElseThrow(() -> new IllegalArgumentException(
                                    "Attribute not found: " + attr.attributeId()));
                    
                    AttributeOption option = attributeOptionService.findByPublicId(attr.optionId())
                            .orElseThrow(() -> new IllegalArgumentException(
                                    "Attribute option not found: " + attr.optionId()));
                    
                    // Verify option belongs to attribute
                    if (!option.getAttribute().getId().equals(attribute.getId())) {
                        throw new IllegalArgumentException(
                                "Option " + attr.optionId() + " does not belong to attribute " + attr.attributeId());
                    }
                    
                    return productAttributeValueService.addAttributeValueToProduct(product, attribute, option);
                })
                .collect(Collectors.toList());
        
        List<ProductAttributeValueDto> response = createdValues.stream()
                .map(productMapper::toProductAttributeValueDto)
                .collect(Collectors.toList());
        
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * Replace all attribute assignments for a product - ADMIN ONLY
     * Removes existing attributes and sets the provided ones.
     */
    @PutMapping
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<List<ProductAttributeValueDto>> replaceProductAttributes(
            @PathVariable String productId,
            @Valid @RequestBody ReplaceProductAttributesRequest request) {
        
        log.info("PUT /api/products/{}/attributes - Replacing attributes with {} new assignment(s)", 
                productId, request.attributes().size());
        
        // Fetch product
        Product product = productRepository.findByPublicId(productId)
                .orElseThrow(() -> ProductNotFoundException.byPublicId(productId));
        
        // Clear all existing attributes
        productAttributeValueService.clearAllAttributeValuesForProduct(product);
        
        // Add new attributes
        List<ProductAttributeValue> newValues = request.attributes().stream()
                .map(attr -> {
                    Attribute attribute = attributeService.findByPublicId(attr.attributeId())
                            .orElseThrow(() -> new IllegalArgumentException(
                                    "Attribute not found: " + attr.attributeId()));
                    
                    AttributeOption option = attributeOptionService.findByPublicId(attr.optionId())
                            .orElseThrow(() -> new IllegalArgumentException(
                                    "Attribute option not found: " + attr.optionId()));
                    
                    // Verify option belongs to attribute
                    if (!option.getAttribute().getId().equals(attribute.getId())) {
                        throw new IllegalArgumentException(
                                "Option " + attr.optionId() + " does not belong to attribute " + attr.attributeId());
                    }
                    
                    return productAttributeValueService.addAttributeValueToProduct(product, attribute, option);
                })
                .collect(Collectors.toList());
        
        List<ProductAttributeValueDto> response = newValues.stream()
                .map(productMapper::toProductAttributeValueDto)
                .collect(Collectors.toList());
        
        return ResponseEntity.ok(response);
    }

    /**
     * Remove a specific attribute from a product - ADMIN ONLY
     */
    @DeleteMapping("/{attributeId}")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<Void> removeProductAttribute(
            @PathVariable String productId,
            @PathVariable String attributeId) {
        
        log.info("DELETE /api/products/{}/attributes/{} - Removing attribute", productId, attributeId);
        
        Product product = productRepository.findByPublicId(productId)
                .orElseThrow(() -> ProductNotFoundException.byPublicId(productId));
        Attribute attribute = attributeService.findByPublicId(attributeId)
                .orElseThrow(() -> new IllegalArgumentException("Attribute not found: " + attributeId));
        
        productAttributeValueService.removeAllAttributeValuesFromProduct(product, attribute);
        
        return ResponseEntity.noContent().build();
    }

    /**
     * Remove a specific attribute-option pair from a product - ADMIN ONLY
     */
    @DeleteMapping("/{attributeId}/options/{optionId}")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<Void> removeProductAttributeOption(
            @PathVariable String productId,
            @PathVariable String attributeId,
            @PathVariable String optionId) {
        
        log.info("DELETE /api/products/{}/attributes/{}/options/{} - Removing attribute option", 
                productId, attributeId, optionId);
        
        Product product = productRepository.findByPublicId(productId)
                .orElseThrow(() -> ProductNotFoundException.byPublicId(productId));
        Attribute attribute = attributeService.findByPublicId(attributeId)
                .orElseThrow(() -> new IllegalArgumentException("Attribute not found: " + attributeId));
        AttributeOption option = attributeOptionService.findByPublicId(optionId)
                .orElseThrow(() -> new IllegalArgumentException("Attribute option not found: " + optionId));
        
        productAttributeValueService.removeAttributeValueFromProduct(product, attribute, option);
        
        return ResponseEntity.noContent().build();
    }

    // Request DTOs
    public record AddProductAttributesRequest(
            @NotEmpty(message = "At least one attribute must be provided")
            List<AttributeAssignment> attributes
    ) {}

    public record ReplaceProductAttributesRequest(
            List<AttributeAssignment> attributes // Can be empty to clear all
    ) {}

    public record AttributeAssignment(
            String attributeId,
            String optionId
    ) {}
}

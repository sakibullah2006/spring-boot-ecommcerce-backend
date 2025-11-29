package com.saveitforlater.ecommerce.api.product.dto;

import com.saveitforlater.ecommerce.domain.file.dto.ProductImageResponse;

import java.math.BigDecimal;
import java.util.List;
import java.util.Set;

// Response DTO
public record ProductResponse(
        String id,
        String sku,
        String name,
        String slug,
        String shortDescription,
        String description,
        BigDecimal price,
        BigDecimal salePrice,
        int stockQuantity,
        Set<CategorySummary> categories,
        List<ProductAttributeValueDto> attributes,
        List<ProductImageResponse> images
) {
    // Nested DTO
    public record CategorySummary(String id, String name, String slug, String parentId) {}
}


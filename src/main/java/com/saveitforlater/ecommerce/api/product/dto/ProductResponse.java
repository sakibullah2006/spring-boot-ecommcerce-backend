package com.saveitforlater.ecommerce.api.product.dto;

import java.math.BigDecimal;
import java.util.List;
import java.util.Set;

// Response DTO
public record ProductResponse(
        String id,
        String sku,
        String name,
        String description,
        BigDecimal price,
        BigDecimal salePrice,
        int stockQuantity,
        Set<CategorySummary> categories,
        List<ProductAttributeValueDto> attributes
) {
    // Nested DTO
    public record CategorySummary(String id, String name, String parentId) {}
}


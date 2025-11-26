package com.saveitforlater.ecommerce.api.product.dto;

import java.math.BigDecimal;
import java.util.Set;
import java.util.UUID;

// Response DTO
public record ProductResponse(
        UUID id,
        String sku,
        String name,
        String description,
        BigDecimal price,
        BigDecimal salePrice,
        int stockQuantity,
        Set<CategorySummary> categories
) {
    // Nested DTO
    public record CategorySummary(UUID id, String name, UUID parentId) {}
}


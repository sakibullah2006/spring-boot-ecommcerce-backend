package com.saveitforlater.ecommerce.api.product.dto;

import jakarta.validation.constraints.*;
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
        Set<CategorySummary> categories
) {
    // Nested DTO
    public record CategorySummary(UUID id, String name) {}
}


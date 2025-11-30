package com.saveitforlater.ecommerce.api.cart.dto;

import java.math.BigDecimal;
import java.time.Instant;

public record CartItemResponse(
        String id,
        ProductSummary product,
        Integer quantity,
        BigDecimal priceAtAddition,
        BigDecimal currentPrice,
        BigDecimal subtotal,
        Instant createdAt,
        Instant updatedAt
) {
    public record ProductSummary(
            String id,
            String sku,
            String name,
            String slug,
            BigDecimal price,
            BigDecimal salePrice,
            Integer stockQuantity
    ) {}
}

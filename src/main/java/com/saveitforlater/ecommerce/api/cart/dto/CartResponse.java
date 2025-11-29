package com.saveitforlater.ecommerce.api.cart.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

public record CartResponse(
        String id,
        String userId,
        List<CartItemResponse> items,
        BigDecimal totalPrice,
        Integer totalItems,
        Instant createdAt,
        Instant updatedAt
) {}

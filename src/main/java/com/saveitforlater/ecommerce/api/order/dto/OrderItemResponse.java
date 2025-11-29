package com.saveitforlater.ecommerce.api.order.dto;

import java.math.BigDecimal;

public record OrderItemResponse(
        String id,
        String productId,
        String productName,
        String productSku,
        Integer quantity,
        BigDecimal price,
        BigDecimal subtotal
) {}

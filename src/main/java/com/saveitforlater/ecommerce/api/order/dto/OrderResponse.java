package com.saveitforlater.ecommerce.api.order.dto;

import com.saveitforlater.ecommerce.persistence.entity.order.OrderStatus;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

public record OrderResponse(
        String id,
        String orderNumber,
        String userId,
        OrderStatus status,
        BigDecimal totalAmount,
        AddressResponse shippingAddress,
        AddressResponse billingAddress,
        String customerEmail,
        String customerPhone,
        String notes,
        List<OrderItemResponse> items,
        PaymentResponse payment,
        Instant createdAt,
        Instant updatedAt
) {}

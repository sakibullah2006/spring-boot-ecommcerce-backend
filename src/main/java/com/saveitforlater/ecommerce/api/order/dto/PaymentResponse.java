package com.saveitforlater.ecommerce.api.order.dto;

import com.saveitforlater.ecommerce.persistence.entity.order.PaymentMethod;
import com.saveitforlater.ecommerce.persistence.entity.order.PaymentStatus;

import java.math.BigDecimal;
import java.time.Instant;

public record PaymentResponse(
        String id,
        PaymentMethod paymentMethod,
        PaymentStatus paymentStatus,
        BigDecimal amount,
        String transactionId,
        String cardLastFour,
        String cardBrand,
        String paymentGateway,
        Instant paymentDate,
        Instant createdAt
) {}

package com.saveitforlater.ecommerce.api.order.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;

public record ProcessPaymentRequest(
        @Valid
        @NotNull(message = "Payment details are required")
        PaymentDetailsRequest paymentDetails
) {}

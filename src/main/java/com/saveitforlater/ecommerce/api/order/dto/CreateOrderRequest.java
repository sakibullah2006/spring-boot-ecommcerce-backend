package com.saveitforlater.ecommerce.api.order.dto;

import com.saveitforlater.ecommerce.persistence.entity.order.PaymentMethod;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record CreateOrderRequest(
        @Valid
        @NotNull(message = "Shipping address is required")
        AddressRequest shippingAddress,
        
        @Valid
        @NotNull(message = "Billing address is required")
        AddressRequest billingAddress,
        
        @Email(message = "Invalid email format")
        @NotBlank(message = "Email is required")
        String customerEmail,
        
        String customerPhone,
        
        String notes,
        
        @NotNull(message = "Payment method is required")
        PaymentMethod paymentMethod
) {}

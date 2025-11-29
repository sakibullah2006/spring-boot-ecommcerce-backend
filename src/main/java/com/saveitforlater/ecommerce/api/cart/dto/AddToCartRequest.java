package com.saveitforlater.ecommerce.api.cart.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;

public record AddToCartRequest(
        @NotBlank(message = "Product ID is required")
        String productId,

        @Positive(message = "Quantity must be positive")
        Integer quantity
) {}

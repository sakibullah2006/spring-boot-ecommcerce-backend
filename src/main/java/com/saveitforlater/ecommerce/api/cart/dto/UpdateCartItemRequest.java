package com.saveitforlater.ecommerce.api.cart.dto;

import jakarta.validation.constraints.Positive;

public record UpdateCartItemRequest(
        @Positive(message = "Quantity must be positive")
        Integer quantity
) {}

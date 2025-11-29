package com.saveitforlater.ecommerce.domain.cart.exception;

public class CartNotFoundException extends RuntimeException {
    
    public CartNotFoundException(String message) {
        super(message);
    }

    public static CartNotFoundException byPublicId(String publicId) {
        return new CartNotFoundException(String.format("Cart not found with ID: %s", publicId));
    }

    public static CartNotFoundException byUserId(String userId) {
        return new CartNotFoundException(String.format("Cart not found for user ID: %s", userId));
    }
}

package com.saveitforlater.ecommerce.domain.cart.exception;

public class CartItemNotFoundException extends RuntimeException {
    
    public CartItemNotFoundException(String message) {
        super(message);
    }

    public static CartItemNotFoundException byPublicId(String publicId) {
        return new CartItemNotFoundException(String.format("Cart item not found with ID: %s", publicId));
    }

    public static CartItemNotFoundException byProductId(String productId) {
        return new CartItemNotFoundException(String.format("Cart item not found for product ID: %s", productId));
    }
}

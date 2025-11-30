package com.saveitforlater.ecommerce.domain.cart.exception;

public class InsufficientStockException extends RuntimeException {
    
    public InsufficientStockException(String message) {
        super(message);
    }

    public static InsufficientStockException forProduct(String productName, int requested, int available) {
        return new InsufficientStockException(
            String.format("Insufficient stock for product '%s'. Requested: %d, Available: %d", 
                productName, requested, available));
    }
}

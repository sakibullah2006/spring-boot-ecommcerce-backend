package com.saveitforlater.ecommerce.domain.order.exception;

public class InsufficientStockException extends RuntimeException {
    
    public InsufficientStockException(String message) {
        super(message);
    }

    public static InsufficientStockException forProduct(String productName, int requested, int available) {
        return new InsufficientStockException(
                String.format("Insufficient stock for product '%s': requested %d, available %d", 
                        productName, requested, available)
        );
    }
}

package com.saveitforlater.ecommerce.domain.order.exception;

public class EmptyCartException extends RuntimeException {
    
    public EmptyCartException(String message) {
        super(message);
    }

    public static EmptyCartException create() {
        return new EmptyCartException("Cannot create order: cart is empty");
    }
}

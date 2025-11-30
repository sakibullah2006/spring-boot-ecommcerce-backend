package com.saveitforlater.ecommerce.domain.order.exception;

public class PaymentProcessingException extends RuntimeException {
    
    public PaymentProcessingException(String message) {
        super(message);
    }

    public PaymentProcessingException(String message, Throwable cause) {
        super(message, cause);
    }

    public static PaymentProcessingException failed(String reason) {
        return new PaymentProcessingException("Payment processing failed: " + reason);
    }
}

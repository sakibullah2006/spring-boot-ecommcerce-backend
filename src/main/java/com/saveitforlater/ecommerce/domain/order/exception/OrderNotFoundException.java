package com.saveitforlater.ecommerce.domain.order.exception;

public class OrderNotFoundException extends RuntimeException {
    
    public OrderNotFoundException(String message) {
        super(message);
    }

    public static OrderNotFoundException byId(String orderId) {
        return new OrderNotFoundException("Order not found with ID: " + orderId);
    }

    public static OrderNotFoundException byOrderNumber(String orderNumber) {
        return new OrderNotFoundException("Order not found with order number: " + orderNumber);
    }
}

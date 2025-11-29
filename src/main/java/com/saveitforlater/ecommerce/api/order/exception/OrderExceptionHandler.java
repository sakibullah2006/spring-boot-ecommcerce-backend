package com.saveitforlater.ecommerce.api.order.exception;

import com.saveitforlater.ecommerce.domain.order.exception.EmptyCartException;
import com.saveitforlater.ecommerce.domain.order.exception.InsufficientStockException;
import com.saveitforlater.ecommerce.domain.order.exception.OrderNotFoundException;
import com.saveitforlater.ecommerce.domain.order.exception.PaymentProcessingException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.net.URI;
import java.time.Instant;

@Slf4j
@RestControllerAdvice
public class OrderExceptionHandler {

    @ExceptionHandler(OrderNotFoundException.class)
    public ProblemDetail handleOrderNotFoundException(OrderNotFoundException ex) {
        log.error("Order not found: {}", ex.getMessage());
        
        ProblemDetail problemDetail = ProblemDetail.forStatusAndDetail(
                HttpStatus.NOT_FOUND,
                ex.getMessage()
        );
        problemDetail.setTitle("Order Not Found");
        problemDetail.setType(URI.create("https://api.ecommerce.com/errors/order-not-found"));
        problemDetail.setProperty("timestamp", Instant.now());
        
        return problemDetail;
    }

    @ExceptionHandler(EmptyCartException.class)
    public ProblemDetail handleEmptyCartException(EmptyCartException ex) {
        log.error("Empty cart error: {}", ex.getMessage());
        
        ProblemDetail problemDetail = ProblemDetail.forStatusAndDetail(
                HttpStatus.BAD_REQUEST,
                ex.getMessage()
        );
        problemDetail.setTitle("Empty Cart");
        problemDetail.setType(URI.create("https://api.ecommerce.com/errors/empty-cart"));
        problemDetail.setProperty("timestamp", Instant.now());
        
        return problemDetail;
    }

    @ExceptionHandler(InsufficientStockException.class)
    public ProblemDetail handleInsufficientStockException(InsufficientStockException ex) {
        log.error("Insufficient stock: {}", ex.getMessage());
        
        ProblemDetail problemDetail = ProblemDetail.forStatusAndDetail(
                HttpStatus.CONFLICT,
                ex.getMessage()
        );
        problemDetail.setTitle("Insufficient Stock");
        problemDetail.setType(URI.create("https://api.ecommerce.com/errors/insufficient-stock"));
        problemDetail.setProperty("timestamp", Instant.now());
        
        return problemDetail;
    }

    @ExceptionHandler(PaymentProcessingException.class)
    public ProblemDetail handlePaymentProcessingException(PaymentProcessingException ex) {
        log.error("Payment processing error: {}", ex.getMessage());
        
        ProblemDetail problemDetail = ProblemDetail.forStatusAndDetail(
                HttpStatus.PAYMENT_REQUIRED,
                ex.getMessage()
        );
        problemDetail.setTitle("Payment Processing Failed");
        problemDetail.setType(URI.create("https://api.ecommerce.com/errors/payment-failed"));
        problemDetail.setProperty("timestamp", Instant.now());
        
        return problemDetail;
    }
}

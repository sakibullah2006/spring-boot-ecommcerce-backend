package com.saveitforlater.ecommerce.api.cart.exception;

import com.saveitforlater.ecommerce.api.auth.exception.ErrorResponse;
import com.saveitforlater.ecommerce.domain.cart.exception.CartItemNotFoundException;
import com.saveitforlater.ecommerce.domain.cart.exception.CartNotFoundException;
import com.saveitforlater.ecommerce.domain.cart.exception.InsufficientStockException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Slf4j
@RestControllerAdvice
public class CartExceptionHandler {

    @ExceptionHandler(CartNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleCartNotFound(CartNotFoundException ex) {
        log.warn("Cart not found: {}", ex.getMessage());

        ErrorResponse errorResponse = new ErrorResponse(
                "CART_NOT_FOUND",
                ex.getMessage(),
                HttpStatus.NOT_FOUND.value(),
                "/api/cart"
        );

        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
    }

    @ExceptionHandler(CartItemNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleCartItemNotFound(CartItemNotFoundException ex) {
        log.warn("Cart item not found: {}", ex.getMessage());

        ErrorResponse errorResponse = new ErrorResponse(
                "CART_ITEM_NOT_FOUND",
                ex.getMessage(),
                HttpStatus.NOT_FOUND.value(),
                "/api/cart"
        );

        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
    }

    @ExceptionHandler(InsufficientStockException.class)
    public ResponseEntity<ErrorResponse> handleInsufficientStock(InsufficientStockException ex) {
        log.warn("Insufficient stock: {}", ex.getMessage());

        ErrorResponse errorResponse = new ErrorResponse(
                "INSUFFICIENT_STOCK",
                ex.getMessage(),
                HttpStatus.BAD_REQUEST.value(),
                "/api/cart"
        );

        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
    }
}

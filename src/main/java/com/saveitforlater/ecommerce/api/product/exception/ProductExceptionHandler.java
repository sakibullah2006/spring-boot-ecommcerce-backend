package com.saveitforlater.ecommerce.api.product.exception;

import com.saveitforlater.ecommerce.api.auth.exception.ErrorResponse;
import com.saveitforlater.ecommerce.domain.product.exception.ProductNotFoundException;
import com.saveitforlater.ecommerce.domain.product.exception.ProductSkuAlreadyExistsException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Slf4j
@RestControllerAdvice
public class ProductExceptionHandler {

    @ExceptionHandler(ProductNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleProductNotFound(ProductNotFoundException ex) {
        log.warn("Product not found: {}", ex.getMessage());

        ErrorResponse errorResponse = new ErrorResponse(
                "PRODUCT_NOT_FOUND",
                ex.getMessage(),
                HttpStatus.NOT_FOUND.value(),
                "/api/products"
        );

        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
    }

    @ExceptionHandler(ProductSkuAlreadyExistsException.class)
    public ResponseEntity<ErrorResponse> handleProductSkuAlreadyExists(ProductSkuAlreadyExistsException ex) {
        log.warn("Product SKU already exists: {}", ex.getMessage());

        ErrorResponse errorResponse = new ErrorResponse(
                "PRODUCT_SKU_ALREADY_EXISTS",
                ex.getMessage(),
                HttpStatus.CONFLICT.value(),
                "/api/products"
        );

        return ResponseEntity.status(HttpStatus.CONFLICT).body(errorResponse);
    }
}


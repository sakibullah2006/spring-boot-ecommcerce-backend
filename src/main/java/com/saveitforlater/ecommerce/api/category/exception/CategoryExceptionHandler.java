package com.saveitforlater.ecommerce.api.category.exception;

import com.saveitforlater.ecommerce.api.auth.exception.ErrorResponse;
import com.saveitforlater.ecommerce.domain.category.exception.CategoryHasChildrenException;
import com.saveitforlater.ecommerce.domain.category.exception.CategoryNameAlreadyExistsException;
import com.saveitforlater.ecommerce.domain.category.exception.CategoryNotFoundException;
import com.saveitforlater.ecommerce.domain.category.exception.CategorySlugAlreadyExistsException;
import com.saveitforlater.ecommerce.domain.category.exception.IllegalCategoryArgumentException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Slf4j
@RestControllerAdvice
public class CategoryExceptionHandler {

    @ExceptionHandler(CategoryNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleCategoryNotFound(CategoryNotFoundException ex) {
        log.warn("Category not found: {}", ex.getMessage());

        ErrorResponse errorResponse = new ErrorResponse(
                "CATEGORY_NOT_FOUND",
                ex.getMessage(),
                HttpStatus.NOT_FOUND.value(),
                "/api/categories"
        );

        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
    }

    @ExceptionHandler(CategoryNameAlreadyExistsException.class)
    public ResponseEntity<ErrorResponse> handleCategoryNameAlreadyExists(CategoryNameAlreadyExistsException ex) {
        log.warn("Category name already exists: {}", ex.getMessage());

        ErrorResponse errorResponse = new ErrorResponse(
                "CATEGORY_NAME_ALREADY_EXISTS",
                ex.getMessage(),
                HttpStatus.CONFLICT.value(),
                "/api/categories"
        );

        return ResponseEntity.status(HttpStatus.CONFLICT).body(errorResponse);
    }

    @ExceptionHandler(CategorySlugAlreadyExistsException.class)
    public ResponseEntity<ErrorResponse> handleCategorySlugAlreadyExists(CategorySlugAlreadyExistsException ex) {
        log.warn("Category slug already exists: {}", ex.getMessage());

        ErrorResponse errorResponse = new ErrorResponse(
                "CATEGORY_SLUG_ALREADY_EXISTS",
                ex.getMessage(),
                HttpStatus.CONFLICT.value(),
                "/api/categories"
        );

        return ResponseEntity.status(HttpStatus.CONFLICT).body(errorResponse);
    }

    @ExceptionHandler(CategoryHasChildrenException.class)
    public ResponseEntity<ErrorResponse> handleCategoryHasChildren(CategoryHasChildrenException ex) {
        log.warn("Category has children: {}", ex.getMessage());

        ErrorResponse errorResponse = new ErrorResponse(
                "CATEGORY_HAS_CHILDREN",
                ex.getMessage(),
                HttpStatus.CONFLICT.value(),
                "/api/categories"
        );

        return ResponseEntity.status(HttpStatus.CONFLICT).body(errorResponse);
    }

    @ExceptionHandler(IllegalCategoryArgumentException.class)
    public ResponseEntity<ErrorResponse> handleIllegalArgument(IllegalCategoryArgumentException ex) {
        log.warn("Illegal argument in category operation: {}", ex.getMessage());

        ErrorResponse errorResponse = new ErrorResponse(
                ex.getErrorCode(),
                ex.getMessage(),
                HttpStatus.BAD_REQUEST.value(),
                "/api/categories"
        );

        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
    }
}


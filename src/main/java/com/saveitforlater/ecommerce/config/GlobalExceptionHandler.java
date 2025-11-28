package com.saveitforlater.ecommerce.config;

import com.saveitforlater.ecommerce.api.auth.exception.ErrorResponse;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.HashMap;
import java.util.Map;

/**
 * Global exception handler for cross-cutting concerns
 * Handles validation, security, database constraints, and fallback exceptions
 * Module-specific handlers (ProductExceptionHandler, AuthExceptionHandler) take precedence
 */
@Slf4j
@Order(Ordered.LOWEST_PRECEDENCE)
@RestControllerAdvice
public class GlobalExceptionHandler {

    // ============================================
    // VALIDATION ERRORS
    // ============================================
    
    /**
     * Handle validation errors (e.g., @Valid, @NotNull, @NotBlank)
     * Applies globally to all controllers
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidationException(
            MethodArgumentNotValidException ex,
            HttpServletRequest request) {
        
        Map<String, String> fieldErrors = new HashMap<>();
        ex.getBindingResult().getAllErrors().forEach(error -> {
            String fieldName = ((FieldError) error).getField();
            String errorMessage = error.getDefaultMessage();
            fieldErrors.put(fieldName, errorMessage);
        });

        String message = fieldErrors.isEmpty() ? "Validation failed" :
            "Validation failed: " + fieldErrors.toString();

        ErrorResponse errorResponse = new ErrorResponse(
            "VALIDATION_FAILED",
            message,
            HttpStatus.BAD_REQUEST.value(),
            request.getRequestURI()
        );

        log.warn("Validation error on {}: {}", request.getRequestURI(), fieldErrors);
        return ResponseEntity.badRequest().body(errorResponse);
    }

    // ============================================
    // SECURITY & AUTHORIZATION
    // ============================================
    
    /**
     * Handle Spring Security authentication failures
     */
    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<ErrorResponse> handleAuthenticationException(
            AuthenticationException ex,
            HttpServletRequest request) {
        
        ErrorResponse errorResponse = new ErrorResponse(
            "AUTHENTICATION_REQUIRED",
            "Authentication is required to access this resource",
            HttpStatus.UNAUTHORIZED.value(),
            request.getRequestURI()
        );

        log.warn("Authentication error on {}: {}", request.getRequestURI(), ex.getMessage());
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(errorResponse);
    }

    /**
     * Handle access denied (missing permissions)
     */
    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ErrorResponse> handleAccessDeniedException(
            AccessDeniedException ex,
            HttpServletRequest request) {
        
        ErrorResponse errorResponse = new ErrorResponse(
            "ACCESS_DENIED",
            "You don't have permission to access this resource",
            HttpStatus.FORBIDDEN.value(),
            request.getRequestURI()
        );

        log.warn("Access denied on {}: {}", request.getRequestURI(), ex.getMessage());
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(errorResponse);
    }

    // ============================================
    // ILLEGAL ARGUMENT EXCEPTIONS
    // ============================================
    
    /**
     * Handle IllegalArgumentException - typically from invalid IDs or parameters
     */
    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ErrorResponse> handleIllegalArgumentException(
            IllegalArgumentException ex,
            HttpServletRequest request) {
        
        ErrorResponse errorResponse = new ErrorResponse(
            "INVALID_ARGUMENT",
            ex.getMessage(),
            HttpStatus.BAD_REQUEST.value(),
            request.getRequestURI()
        );

        log.warn("Illegal argument on {}: {}", request.getRequestURI(), ex.getMessage());
        return ResponseEntity.badRequest().body(errorResponse);
    }

    // ============================================
    // DATABASE CONSTRAINT VIOLATIONS
    // ============================================
    
    /**
     * Handle database constraint violations
     * Catches race conditions and other DB-level errors not handled by module handlers
     */
    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ErrorResponse> handleDataIntegrityViolationException(
            DataIntegrityViolationException ex,
            HttpServletRequest request) {
        
        String detail = "Database constraint violation";
        String errorCode = "DATA_INTEGRITY_VIOLATION";
        
        // Extract meaningful error message from the root cause
        String rootMessage = ex.getMostSpecificCause().getMessage();
        
        if (rootMessage != null) {
            if (rootMessage.contains("Duplicate entry") && rootMessage.contains("'sku'")) {
                String sku = extractValueFromDuplicateError(rootMessage);
                detail = String.format("Product with SKU '%s' already exists", sku);
                errorCode = "DUPLICATE_SKU";
            } else if (rootMessage.contains("Duplicate entry") && rootMessage.contains("'email'")) {
                String email = extractValueFromDuplicateError(rootMessage);
                detail = String.format("User with email '%s' already exists", email);
                errorCode = "DUPLICATE_EMAIL";
            } else if (rootMessage.contains("Duplicate entry") && rootMessage.contains("'public_id'")) {
                detail = "A record with this ID already exists";
                errorCode = "DUPLICATE_ID";
            } else if (rootMessage.contains("Duplicate entry")) {
                String value = extractValueFromDuplicateError(rootMessage);
                detail = String.format("A record with value '%s' already exists", value);
                errorCode = "DUPLICATE_ENTRY";
            } else if (rootMessage.contains("foreign key constraint")) {
                detail = "Cannot delete or update due to related records";
                errorCode = "FOREIGN_KEY_CONSTRAINT";
            } else if (rootMessage.contains("cannot be null")) {
                detail = "Required field is missing";
                errorCode = "NULL_CONSTRAINT";
            }
        }

        ErrorResponse errorResponse = new ErrorResponse(
            errorCode,
            detail,
            HttpStatus.CONFLICT.value(),
            request.getRequestURI()
        );

        log.error("Data integrity violation on {}: {}", request.getRequestURI(), rootMessage);
        return ResponseEntity.status(HttpStatus.CONFLICT).body(errorResponse);
    }

    // ============================================
    // FALLBACK HANDLER
    // ============================================
    
    /**
     * Catch-all handler for any unhandled exceptions
     * Should be last resort - most exceptions should be caught by module handlers
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGenericException(
            Exception ex,
            HttpServletRequest request) {
        
        ErrorResponse errorResponse = new ErrorResponse(
            "INTERNAL_SERVER_ERROR",
            "An unexpected error occurred. Please try again later.",
            HttpStatus.INTERNAL_SERVER_ERROR.value(),
            request.getRequestURI()
        );

        log.error("Unhandled exception on {}: {}", request.getRequestURI(), ex.getMessage(), ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
    }

    // ============================================
    // HELPER METHODS
    // ============================================
    
    /**
     * Extract value from MySQL duplicate entry error message
     * Format: "Duplicate entry 'value' for key 'field'"
     */
    private String extractValueFromDuplicateError(String errorMessage) {
        try {
            int startIdx = errorMessage.indexOf("'") + 1;
            int endIdx = errorMessage.indexOf("'", startIdx);
            if (startIdx > 0 && endIdx > startIdx) {
                return errorMessage.substring(startIdx, endIdx);
            }
        } catch (Exception e) {
            log.debug("Could not extract value from error message: {}", errorMessage);
        }
        return "unknown";
    }
}

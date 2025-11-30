package com.saveitforlater.ecommerce.api.auth.exception;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.saveitforlater.ecommerce.domain.auth.exception.InvalidCredentialsException;
import com.saveitforlater.ecommerce.domain.auth.exception.UserAlreadyExistsException;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.validation.BindException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.HashMap;
import java.util.Map;

/**
 * Global exception handler for authentication-related controllers
 */
@Slf4j
@RestControllerAdvice(basePackages = "com.saveitforlater.ecommerce.api.auth")
@RequiredArgsConstructor
public class AuthExceptionHandler {

    private final ObjectMapper objectMapper;

    /**
     * Handle user already exists exception
     */
    @ExceptionHandler(UserAlreadyExistsException.class)
    public ResponseEntity<ErrorResponse> handleUserAlreadyExists(
            UserAlreadyExistsException ex, HttpServletRequest request) {

        log.warn("User registration failed - email already exists: {}", ex.getMessage());

        ErrorResponse errorResponse = new ErrorResponse(
            "USER_ALREADY_EXISTS",
            ex.getMessage(),
            HttpStatus.CONFLICT.value(),
            request.getRequestURI()
        );

        return ResponseEntity.status(HttpStatus.CONFLICT).body(errorResponse);
    }

    /**
     * Handle authentication exceptions (bad credentials, etc.)
     */
    @ExceptionHandler({
        BadCredentialsException.class,
        InvalidCredentialsException.class,
        AuthenticationException.class
    })
    public ResponseEntity<ErrorResponse> handleAuthenticationException(
            Exception ex, HttpServletRequest request) {

        log.warn("Authentication failed: {}", ex.getMessage());

        ErrorResponse errorResponse = new ErrorResponse(
            "AUTHENTICATION_FAILED",
            "Invalid email or password",
            HttpStatus.UNAUTHORIZED.value(),
            request.getRequestURI()
        );

        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(errorResponse);
    }

    /**
     * Handle validation errors
     */
    @ExceptionHandler({MethodArgumentNotValidException.class, BindException.class})
    public ResponseEntity<ErrorResponse> handleValidationException(
            Exception ex, HttpServletRequest request) {

        log.warn("Validation failed: {}", ex.getMessage());

        Map<String, String> fieldErrors = new HashMap<>();

        if (ex instanceof MethodArgumentNotValidException methodEx) {
            for (FieldError error : methodEx.getBindingResult().getFieldErrors()) {
                fieldErrors.put(error.getField(), error.getDefaultMessage());
            }
        } else if (ex instanceof BindException bindEx) {
            for (FieldError error : bindEx.getBindingResult().getFieldErrors()) {
                fieldErrors.put(error.getField(), error.getDefaultMessage());
            }
        }

        String message = fieldErrors.isEmpty() ? "Validation failed" :
            "Validation failed: " + fieldErrors.toString();

        ErrorResponse errorResponse = new ErrorResponse(
            "VALIDATION_FAILED",
            message,
            HttpStatus.BAD_REQUEST.value(),
            request.getRequestURI()
        );

        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
    }

    /**
     * Handle general exceptions
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGeneralException(
            Exception ex, HttpServletRequest request) {

        log.error("Unexpected error occurred: ", ex);

        ErrorResponse errorResponse = new ErrorResponse(
            "INTERNAL_SERVER_ERROR",
            "An unexpected error occurred",
            HttpStatus.INTERNAL_SERVER_ERROR.value(),
            request.getRequestURI()
        );

        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
    }
}

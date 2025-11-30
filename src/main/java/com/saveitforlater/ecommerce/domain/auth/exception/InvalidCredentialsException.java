package com.saveitforlater.ecommerce.domain.auth.exception;

/**
 * Exception thrown when invalid credentials are provided
 */
public class InvalidCredentialsException extends RuntimeException {

    public InvalidCredentialsException() {
        super("Invalid email or password");
    }

    public InvalidCredentialsException(String message) {
        super(message);
    }
}

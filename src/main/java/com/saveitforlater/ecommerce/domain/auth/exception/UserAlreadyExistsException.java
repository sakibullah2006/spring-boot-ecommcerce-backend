package com.saveitforlater.ecommerce.domain.auth.exception;

/**
 * Exception thrown when a user tries to register with an email that already exists
 */
public class UserAlreadyExistsException extends RuntimeException {

    public UserAlreadyExistsException(String email) {
        super("User with email '" + email + "' already exists");
    }
}

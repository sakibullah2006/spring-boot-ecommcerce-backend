package com.saveitforlater.ecommerce.domain.category.exception;

public class CategoryNameAlreadyExistsException extends RuntimeException {
    public CategoryNameAlreadyExistsException(String message) {
        super(message);
    }

    public static CategoryNameAlreadyExistsException withName(String name) {
        return new CategoryNameAlreadyExistsException("Category with name '" + name + "' already exists");
    }
}

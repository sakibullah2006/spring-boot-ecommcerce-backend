package com.saveitforlater.ecommerce.domain.category.exception;

public class CategoryNotFoundException extends RuntimeException {
    public CategoryNotFoundException(String message) {
        super(message);
    }

    public static CategoryNotFoundException byPublicId(String publicId) {
        return new CategoryNotFoundException("Category not found with ID: " + publicId);
    }

    public static CategoryNotFoundException byName(String name) {
        return new CategoryNotFoundException("Category not found with name: " + name);
    }
}

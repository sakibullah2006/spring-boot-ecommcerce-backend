package com.saveitforlater.ecommerce.domain.category.exception;

public class CategorySlugAlreadyExistsException extends RuntimeException {
    public CategorySlugAlreadyExistsException(String message) {
        super(message);
    }

    public static CategorySlugAlreadyExistsException withSlug(String slug) {
        return new CategorySlugAlreadyExistsException("Category with slug '" + slug + "' already exists");
    }
}

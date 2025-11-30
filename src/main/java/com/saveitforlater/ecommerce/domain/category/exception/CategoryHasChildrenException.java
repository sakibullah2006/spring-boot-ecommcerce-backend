package com.saveitforlater.ecommerce.domain.category.exception;

public class CategoryHasChildrenException extends RuntimeException {
    public CategoryHasChildrenException(String message) {
        super(message);
    }

    public static CategoryHasChildrenException withId(String publicId) {
        return new CategoryHasChildrenException("Cannot delete category " + publicId + " because it has child categories");
    }
}

package com.saveitforlater.ecommerce.domain.product.exception;

public class ProductSlugAlreadyExistsException extends RuntimeException {
    public ProductSlugAlreadyExistsException(String message) {
        super(message);
    }

    public static ProductSlugAlreadyExistsException withSlug(String slug) {
        return new ProductSlugAlreadyExistsException("Product with slug '" + slug + "' already exists");
    }
}

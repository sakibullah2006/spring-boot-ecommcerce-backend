package com.saveitforlater.ecommerce.domain.product.exception;

public class ProductNotFoundException extends RuntimeException {
    public ProductNotFoundException(String message) {
        super(message);
    }

    public static ProductNotFoundException byPublicId(String publicId) {
        return new ProductNotFoundException("Product not found with ID: " + publicId);
    }

    public static ProductNotFoundException bySku(String sku) {
        return new ProductNotFoundException("Product not found with SKU: " + sku);
    }
}


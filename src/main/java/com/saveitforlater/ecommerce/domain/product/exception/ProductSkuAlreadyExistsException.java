package com.saveitforlater.ecommerce.domain.product.exception;

public class ProductSkuAlreadyExistsException extends RuntimeException {
    public ProductSkuAlreadyExistsException(String message) {
        super(message);
    }

    public static ProductSkuAlreadyExistsException withSku(String sku) {
        return new ProductSkuAlreadyExistsException("Product with SKU '" + sku + "' already exists");
    }
}


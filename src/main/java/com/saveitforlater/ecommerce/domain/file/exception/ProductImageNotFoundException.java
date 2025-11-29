package com.saveitforlater.ecommerce.domain.file.exception;

public class ProductImageNotFoundException extends RuntimeException {
    
    public ProductImageNotFoundException(String message) {
        super(message);
    }
    
    public static ProductImageNotFoundException byPublicId(String publicId) {
        return new ProductImageNotFoundException("Product image not found with public ID: " + publicId);
    }
    
    public static ProductImageNotFoundException forProduct(String productPublicId) {
        return new ProductImageNotFoundException("No images found for product: " + productPublicId);
    }
}

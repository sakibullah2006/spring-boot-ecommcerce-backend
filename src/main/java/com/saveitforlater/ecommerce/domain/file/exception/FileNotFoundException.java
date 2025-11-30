package com.saveitforlater.ecommerce.domain.file.exception;

public class FileNotFoundException extends RuntimeException {
    
    public FileNotFoundException(String message) {
        super(message);
    }
    
    public static FileNotFoundException byPublicId(String publicId) {
        return new FileNotFoundException("File not found with public ID: " + publicId);
    }
    
    public static FileNotFoundException byFileName(String fileName) {
        return new FileNotFoundException("File not found with name: " + fileName);
    }
}

package com.saveitforlater.ecommerce.domain.file.exception;

public class InvalidFileTypeException extends RuntimeException {
    
    public InvalidFileTypeException(String message) {
        super(message);
    }
    
    public static InvalidFileTypeException notAnImage(String contentType) {
        return new InvalidFileTypeException("Invalid file type. Expected image but got: " + contentType);
    }
    
    public static InvalidFileTypeException unsupportedType(String contentType) {
        return new InvalidFileTypeException("Unsupported file type: " + contentType);
    }
}

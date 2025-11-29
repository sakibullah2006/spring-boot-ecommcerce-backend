package com.saveitforlater.ecommerce.domain.file.exception;

public class FileStorageException extends RuntimeException {
    
    public FileStorageException(String message) {
        super(message);
    }
    
    public FileStorageException(String message, Throwable cause) {
        super(message, cause);
    }
    
    public static FileStorageException failedToStore(String fileName) {
        return new FileStorageException("Failed to store file: " + fileName);
    }
    
    public static FileStorageException failedToStore(String fileName, Throwable cause) {
        return new FileStorageException("Failed to store file: " + fileName, cause);
    }
    
    public static FileStorageException invalidPath() {
        return new FileStorageException("Invalid file path detected");
    }
}

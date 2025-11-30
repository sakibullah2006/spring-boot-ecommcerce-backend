package com.saveitforlater.ecommerce.api.file.exception;

import com.saveitforlater.ecommerce.domain.file.exception.FileNotFoundException;
import com.saveitforlater.ecommerce.domain.file.exception.FileStorageException;
import com.saveitforlater.ecommerce.domain.file.exception.InvalidFileTypeException;
import com.saveitforlater.ecommerce.domain.file.exception.ProductImageNotFoundException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.net.URI;
import java.time.Instant;

@Slf4j
@RestControllerAdvice
public class FileExceptionHandler {

    @ExceptionHandler(FileStorageException.class)
    public ProblemDetail handleFileStorageException(FileStorageException ex) {
        log.error("File storage error: {}", ex.getMessage());
        
        ProblemDetail problemDetail = ProblemDetail.forStatusAndDetail(
                HttpStatus.INTERNAL_SERVER_ERROR,
                ex.getMessage()
        );
        problemDetail.setTitle("File Storage Error");
        problemDetail.setType(URI.create("https://api.ecommerce.com/errors/file-storage-error"));
        problemDetail.setProperty("timestamp", Instant.now());
        
        return problemDetail;
    }

    @ExceptionHandler(FileNotFoundException.class)
    public ProblemDetail handleFileNotFoundException(FileNotFoundException ex) {
        log.error("File not found: {}", ex.getMessage());
        
        ProblemDetail problemDetail = ProblemDetail.forStatusAndDetail(
                HttpStatus.NOT_FOUND,
                ex.getMessage()
        );
        problemDetail.setTitle("File Not Found");
        problemDetail.setType(URI.create("https://api.ecommerce.com/errors/file-not-found"));
        problemDetail.setProperty("timestamp", Instant.now());
        
        return problemDetail;
    }

    @ExceptionHandler(InvalidFileTypeException.class)
    public ProblemDetail handleInvalidFileTypeException(InvalidFileTypeException ex) {
        log.error("Invalid file type: {}", ex.getMessage());
        
        ProblemDetail problemDetail = ProblemDetail.forStatusAndDetail(
                HttpStatus.BAD_REQUEST,
                ex.getMessage()
        );
        problemDetail.setTitle("Invalid File Type");
        problemDetail.setType(URI.create("https://api.ecommerce.com/errors/invalid-file-type"));
        problemDetail.setProperty("timestamp", Instant.now());
        
        return problemDetail;
    }

    @ExceptionHandler(ProductImageNotFoundException.class)
    public ProblemDetail handleProductImageNotFoundException(ProductImageNotFoundException ex) {
        log.error("Product image not found: {}", ex.getMessage());
        
        ProblemDetail problemDetail = ProblemDetail.forStatusAndDetail(
                HttpStatus.NOT_FOUND,
                ex.getMessage()
        );
        problemDetail.setTitle("Product Image Not Found");
        problemDetail.setType(URI.create("https://api.ecommerce.com/errors/product-image-not-found"));
        problemDetail.setProperty("timestamp", Instant.now());
        
        return problemDetail;
    }
}

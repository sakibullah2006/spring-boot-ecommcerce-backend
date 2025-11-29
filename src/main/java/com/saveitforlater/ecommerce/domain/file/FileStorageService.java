package com.saveitforlater.ecommerce.domain.file;

import com.saveitforlater.ecommerce.domain.file.exception.FileNotFoundException;
import com.saveitforlater.ecommerce.domain.file.exception.FileStorageException;
import com.saveitforlater.ecommerce.domain.file.exception.InvalidFileTypeException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Set;
import java.util.UUID;

/**
 * Reusable service for handling file storage operations on the local file system.
 * This service can be used for storing any type of files (images, documents, etc.)
 * and is designed to be reusable across different entities.
 */
@Slf4j
@Service
public class FileStorageService {

    private final Path fileStorageLocation;
    private final Set<String> allowedImageTypes;
    private final long maxFileSize;

    public FileStorageService(
            @Value("${app.file.upload-dir:uploads}") String uploadDir,
            @Value("${app.file.max-size:10485760}") long maxFileSize) {
        
        this.maxFileSize = maxFileSize;
        this.allowedImageTypes = Set.of(
            "image/jpeg",
            "image/jpg", 
            "image/png",
            "image/gif",
            "image/webp"
        );
        
        this.fileStorageLocation = Paths.get(uploadDir).toAbsolutePath().normalize();
        
        try {
            Files.createDirectories(this.fileStorageLocation);
            log.info("File storage location initialized at: {}", this.fileStorageLocation);
        } catch (IOException ex) {
            throw new FileStorageException("Could not create upload directory", ex);
        }
    }

    /**
     * Store a file and return the generated file name
     */
    public String storeFile(MultipartFile file) {
        return storeFile(file, null);
    }

    /**
     * Store a file in a subdirectory and return the generated file name
     */
    public String storeFile(MultipartFile file, String subdirectory) {
        // Validate file
        validateFile(file);
        
        String originalFileName = StringUtils.cleanPath(file.getOriginalFilename());
        
        try {
            // Check for invalid path sequences
            if (originalFileName.contains("..")) {
                throw FileStorageException.invalidPath();
            }

            // Generate unique file name
            String fileExtension = getFileExtension(originalFileName);
            String uniqueFileName = UUID.randomUUID().toString() + fileExtension;

            // Determine target location
            Path targetLocation;
            if (subdirectory != null && !subdirectory.isBlank()) {
                Path subDirPath = this.fileStorageLocation.resolve(subdirectory);
                Files.createDirectories(subDirPath);
                targetLocation = subDirPath.resolve(uniqueFileName);
            } else {
                targetLocation = this.fileStorageLocation.resolve(uniqueFileName);
            }

            // Copy file to target location
            try (InputStream inputStream = file.getInputStream()) {
                Files.copy(inputStream, targetLocation, StandardCopyOption.REPLACE_EXISTING);
            }

            log.info("File stored successfully: {}", uniqueFileName);
            
            // Return relative path from storage root
            if (subdirectory != null && !subdirectory.isBlank()) {
                return subdirectory + "/" + uniqueFileName;
            }
            return uniqueFileName;
            
        } catch (IOException ex) {
            throw FileStorageException.failedToStore(originalFileName, ex);
        }
    }

    /**
     * Load a file as a Resource
     */
    public Resource loadFileAsResource(String fileName) {
        try {
            Path filePath = this.fileStorageLocation.resolve(fileName).normalize();
            Resource resource = new UrlResource(filePath.toUri());
            
            if (resource.exists() && resource.isReadable()) {
                return resource;
            } else {
                throw FileNotFoundException.byFileName(fileName);
            }
        } catch (MalformedURLException ex) {
            throw FileNotFoundException.byFileName(fileName);
        }
    }

    /**
     * Delete a file
     */
    public void deleteFile(String fileName) {
        try {
            Path filePath = this.fileStorageLocation.resolve(fileName).normalize();
            Files.deleteIfExists(filePath);
            log.info("File deleted successfully: {}", fileName);
        } catch (IOException ex) {
            log.error("Failed to delete file: {}", fileName, ex);
            throw new FileStorageException("Failed to delete file: " + fileName, ex);
        }
    }

    /**
     * Validate image file type and size
     */
    public void validateImageFile(MultipartFile file) {
        validateFile(file);
        
        String contentType = file.getContentType();
        if (contentType == null || !allowedImageTypes.contains(contentType.toLowerCase())) {
            throw InvalidFileTypeException.notAnImage(contentType);
        }
    }

    /**
     * Validate file is not empty and within size limit
     */
    private void validateFile(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new FileStorageException("Cannot store empty file");
        }

        if (file.getSize() > maxFileSize) {
            throw new FileStorageException(
                String.format("File size exceeds maximum allowed size of %d bytes", maxFileSize)
            );
        }
    }

    /**
     * Get file extension from filename
     */
    private String getFileExtension(String fileName) {
        int dotIndex = fileName.lastIndexOf('.');
        if (dotIndex > 0 && dotIndex < fileName.length() - 1) {
            return fileName.substring(dotIndex);
        }
        return "";
    }

    /**
     * Check if content type is an image
     */
    public boolean isImageContentType(String contentType) {
        return contentType != null && allowedImageTypes.contains(contentType.toLowerCase());
    }
    
    /**
     * Get the file storage root path
     */
    public Path getFileStorageLocation() {
        return fileStorageLocation;
    }
}

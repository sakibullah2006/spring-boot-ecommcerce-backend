package com.saveitforlater.ecommerce.api.file;

import com.saveitforlater.ecommerce.domain.file.FileStorageService;
import com.saveitforlater.ecommerce.domain.file.ProductImageService;
import com.saveitforlater.ecommerce.domain.file.dto.ProductImageResponse;
import com.saveitforlater.ecommerce.domain.file.dto.UpdateProductImageRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/files")
@RequiredArgsConstructor
public class FileController {

    private final FileStorageService fileStorageService;
    private final ProductImageService productImageService;

    /**
     * Upload image for a product - ADMIN ONLY
     */
    @PostMapping("/products/{productPublicId}/images")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<ProductImageResponse> uploadProductImage(
            @PathVariable String productPublicId,
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "isPrimary", defaultValue = "false") boolean isPrimary,
            @RequestParam(value = "displayOrder", required = false) Integer displayOrder,
            @RequestParam(value = "altText", required = false) String altText) {
        
        log.info("POST /api/files/products/{}/images - Uploading product image", productPublicId);
        
        ProductImageResponse response = productImageService.uploadProductImage(
                productPublicId, file, isPrimary, displayOrder, altText);
        
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * Get all images for a product - PUBLIC
     */
    @GetMapping("/products/{productPublicId}/images")
    public ResponseEntity<List<ProductImageResponse>> getProductImages(
            @PathVariable String productPublicId) {
        
        log.debug("GET /api/files/products/{}/images - Fetching product images", productPublicId);
        
        List<ProductImageResponse> images = productImageService.getProductImages(productPublicId);
        return ResponseEntity.ok(images);
    }

    /**
     * Get primary image for a product - PUBLIC
     */
    @GetMapping("/products/{productPublicId}/images/primary")
    public ResponseEntity<ProductImageResponse> getPrimaryProductImage(
            @PathVariable String productPublicId) {
        
        log.debug("GET /api/files/products/{}/images/primary - Fetching primary image", productPublicId);
        
        ProductImageResponse image = productImageService.getPrimaryProductImage(productPublicId);
        return ResponseEntity.ok(image);
    }

    /**
     * Get a specific product image by ID - PUBLIC
     */
    @GetMapping("/images/{imagePublicId}")
    public ResponseEntity<Resource> getProductImage(@PathVariable String imagePublicId) {
        log.debug("GET /api/files/images/{} - Serving image", imagePublicId);
        
        ProductImageResponse imageData = productImageService.getProductImage(imagePublicId);
        Resource resource = fileStorageService.loadFileAsResource(imageData.fileMetadata().fileName());

        String contentType = imageData.fileMetadata().contentType();
        
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(contentType))
                .header(HttpHeaders.CONTENT_DISPOSITION, 
                        "inline; filename=\"" + imageData.fileMetadata().originalFileName() + "\"")
                .body(resource);
    }

    /**
     * Download a file by metadata public ID - PUBLIC
     */
    @GetMapping("/download/{filePublicId}")
    public ResponseEntity<Resource> downloadFile(@PathVariable String filePublicId) {
        log.debug("GET /api/files/download/{} - Downloading file", filePublicId);
        
        // This would require a FileMetadataService, but for now we'll keep it simple
        // You can extend this later
        return ResponseEntity.status(HttpStatus.NOT_IMPLEMENTED).build();
    }

    /**
     * Update product image metadata - ADMIN ONLY
     */
    @PatchMapping("/images/{imagePublicId}")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<ProductImageResponse> updateProductImage(
            @PathVariable String imagePublicId,
            @Valid @RequestBody UpdateProductImageRequest request) {
        
        log.info("PATCH /api/files/images/{} - Updating product image", imagePublicId);
        
        ProductImageResponse response = productImageService.updateProductImage(imagePublicId, request);
        return ResponseEntity.ok(response);
    }

    /**
     * Delete a product image - ADMIN ONLY
     */
    @DeleteMapping("/images/{imagePublicId}")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<Void> deleteProductImage(@PathVariable String imagePublicId) {
        log.info("DELETE /api/files/images/{} - Deleting product image", imagePublicId);
        
        productImageService.deleteProductImage(imagePublicId);
        return ResponseEntity.noContent().build();
    }

    /**
     * Delete all images for a product - ADMIN ONLY
     */
    @DeleteMapping("/products/{productPublicId}/images")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<Void> deleteAllProductImages(@PathVariable String productPublicId) {
        log.info("DELETE /api/files/products/{}/images - Deleting all product images", productPublicId);
        
        productImageService.deleteAllProductImages(productPublicId);
        return ResponseEntity.noContent().build();
    }
}

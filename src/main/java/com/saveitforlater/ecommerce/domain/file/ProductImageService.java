package com.saveitforlater.ecommerce.domain.file;

import com.saveitforlater.ecommerce.domain.file.dto.FileMetadataResponse;
import com.saveitforlater.ecommerce.domain.file.dto.ProductImageResponse;
import com.saveitforlater.ecommerce.domain.file.dto.UpdateProductImageRequest;
import com.saveitforlater.ecommerce.domain.file.exception.ProductImageNotFoundException;
import com.saveitforlater.ecommerce.domain.product.exception.ProductNotFoundException;
import com.saveitforlater.ecommerce.persistence.entity.file.FileMetadata;
import com.saveitforlater.ecommerce.persistence.entity.file.ProductImage;
import com.saveitforlater.ecommerce.persistence.entity.product.Product;
import com.saveitforlater.ecommerce.persistence.repository.file.FileMetadataRepository;
import com.saveitforlater.ecommerce.persistence.repository.file.ProductImageRepository;
import com.saveitforlater.ecommerce.persistence.repository.product.ProductRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Service for managing product images.
 * Uses FileStorageService for actual file operations.
 */
@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ProductImageService {

    private final ProductImageRepository productImageRepository;
    private final ProductRepository productRepository;
    private final FileMetadataRepository fileMetadataRepository;
    private final FileStorageService fileStorageService;

    /**
     * Upload and attach an image to a product
     */
    @Transactional
    public ProductImageResponse uploadProductImage(
            String productPublicId, 
            MultipartFile file, 
            boolean isPrimary,
            Integer displayOrder,
            String altText) {
        
        log.info("Uploading image for product: {}", productPublicId);
        
        // Validate image file
        fileStorageService.validateImageFile(file);
        
        // Find product
        Product product = productRepository.findByPublicId(productPublicId)
                .orElseThrow(() -> ProductNotFoundException.byPublicId(productPublicId));

        // Store file in subdirectory for products
        String fileName = fileStorageService.storeFile(file, "products");
        
        // Create file metadata
        FileMetadata fileMetadata = new FileMetadata();
        fileMetadata.setFileName(fileName);
        fileMetadata.setOriginalFileName(file.getOriginalFilename());
        fileMetadata.setFilePath(fileName);
        fileMetadata.setFileSize(file.getSize());
        fileMetadata.setContentType(file.getContentType());
        fileMetadata.setFileType(FileMetadata.FileType.IMAGE);
        
        // Create product image
        ProductImage productImage = new ProductImage();
        productImage.setProduct(product);
        productImage.setFileMetadata(fileMetadata);
        productImage.setPrimary(isPrimary);
        productImage.setDisplayOrder(displayOrder != null ? displayOrder : 0);
        productImage.setAltText(altText);

        // If this is set as primary, clear other primary images
        if (isPrimary) {
            productImageRepository.clearPrimaryForProduct(product.getId());
            log.debug("Cleared existing primary image for product: {}", productPublicId);
        }

        ProductImage savedImage = productImageRepository.save(productImage);
        log.info("Successfully uploaded image for product: {}", productPublicId);
        
        return toProductImageResponse(savedImage);
    }

    /**
     * Get all images for a product
     */
    public List<ProductImageResponse> getProductImages(String productPublicId) {
        log.debug("Fetching images for product: {}", productPublicId);
        
        List<ProductImage> images = productImageRepository
                .findByProductPublicIdOrderByDisplayOrderAsc(productPublicId);
        
        return images.stream()
                .map(this::toProductImageResponse)
                .collect(Collectors.toList());
    }

    /**
     * Get primary image for a product
     */
    public ProductImageResponse getPrimaryProductImage(String productPublicId) {
        log.debug("Fetching primary image for product: {}", productPublicId);
        
        return productImageRepository
                .findByProductPublicIdAndIsPrimaryTrue(productPublicId)
                .map(this::toProductImageResponse)
                .orElseThrow(() -> ProductImageNotFoundException.forProduct(productPublicId));
    }

    /**
     * Get a specific product image by ID
     */
    public ProductImageResponse getProductImage(String imagePublicId) {
        log.debug("Fetching product image: {}", imagePublicId);
        
        ProductImage productImage = productImageRepository.findByPublicId(imagePublicId)
                .orElseThrow(() -> ProductImageNotFoundException.byPublicId(imagePublicId));
        
        return toProductImageResponse(productImage);
    }

    /**
     * Update product image metadata
     */
    @Transactional
    public ProductImageResponse updateProductImage(String imagePublicId, UpdateProductImageRequest request) {
        log.info("Updating product image: {}", imagePublicId);
        
        ProductImage productImage = productImageRepository.findByPublicId(imagePublicId)
                .orElseThrow(() -> ProductImageNotFoundException.byPublicId(imagePublicId));

        // Update fields if provided
        if (request.isPrimary() != null) {
            if (request.isPrimary()) {
                productImageRepository.clearPrimaryForProduct(productImage.getProduct().getId());
                log.debug("Set image as primary for product: {}", productImage.getProduct().getPublicId());
            }
            productImage.setPrimary(request.isPrimary());
        }

        if (request.displayOrder() != null) {
            productImage.setDisplayOrder(request.displayOrder());
        }

        if (request.altText() != null) {
            productImage.setAltText(request.altText());
        }

        ProductImage updatedImage = productImageRepository.save(productImage);
        log.info("Successfully updated product image: {}", imagePublicId);
        
        return toProductImageResponse(updatedImage);
    }

    /**
     * Delete a product image
     */
    @Transactional
    public void deleteProductImage(String imagePublicId) {
        log.info("Deleting product image: {}", imagePublicId);
        
        ProductImage productImage = productImageRepository.findByPublicId(imagePublicId)
                .orElseThrow(() -> ProductImageNotFoundException.byPublicId(imagePublicId));

        // Delete physical file
        String fileName = productImage.getFileMetadata().getFileName();
        fileStorageService.deleteFile(fileName);

        // Delete from database (cascade will handle file_metadata)
        productImageRepository.delete(productImage);
        
        log.info("Successfully deleted product image: {}", imagePublicId);
    }

    /**
     * Delete all images for a product
     */
    @Transactional
    public void deleteAllProductImages(String productPublicId) {
        log.info("Deleting all images for product: {}", productPublicId);
        
        Product product = productRepository.findByPublicId(productPublicId)
                .orElseThrow(() -> ProductNotFoundException.byPublicId(productPublicId));

        List<ProductImage> images = productImageRepository.findByProductIdOrderByDisplayOrderAsc(product.getId());
        
        // Delete each physical file
        for (ProductImage image : images) {
            fileStorageService.deleteFile(image.getFileMetadata().getFileName());
        }

        // Delete from database
        productImageRepository.deleteByProductId(product.getId());
        
        log.info("Successfully deleted {} images for product: {}", images.size(), productPublicId);
    }

    /**
     * Convert ProductImage entity to response DTO
     */
    private ProductImageResponse toProductImageResponse(ProductImage productImage) {
        FileMetadata metadata = productImage.getFileMetadata();
        
        String imageUrl = ServletUriComponentsBuilder.fromCurrentContextPath()
                .path("/api/files/images/")
                .path(productImage.getPublicId())
                .toUriString();
        
        String downloadUrl = ServletUriComponentsBuilder.fromCurrentContextPath()
                .path("/api/files/download/")
                .path(metadata.getPublicId())
                .toUriString();

        FileMetadataResponse fileMetadataResponse = new FileMetadataResponse(
                metadata.getPublicId(),
                metadata.getFileName(),
                metadata.getOriginalFileName(),
                metadata.getFilePath(),
                metadata.getFileSize(),
                metadata.getContentType(),
                metadata.getFileType().name(),
                metadata.getCreatedAt().toString(),
                downloadUrl
        );

        return new ProductImageResponse(
                productImage.getPublicId(),
                productImage.getProduct().getPublicId(),
                fileMetadataResponse,
                productImage.isPrimary(),
                productImage.getDisplayOrder(),
                productImage.getAltText(),
                imageUrl
        );
    }
}

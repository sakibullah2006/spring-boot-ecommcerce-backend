package com.saveitforlater.ecommerce.domain.file.dto;

public record ProductImageResponse(
    String publicId,
    String productPublicId,
    FileMetadataResponse fileMetadata,
    boolean isPrimary,
    int displayOrder,
    String altText,
    String imageUrl
) {
}

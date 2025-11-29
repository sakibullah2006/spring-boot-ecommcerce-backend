package com.saveitforlater.ecommerce.domain.file.dto;

public record FileMetadataResponse(
    String publicId,
    String fileName,
    String originalFileName,
    String filePath,
    Long fileSize,
    String contentType,
    String fileType,
    String createdAt,
    String downloadUrl
) {
}

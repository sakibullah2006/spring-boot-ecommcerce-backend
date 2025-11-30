package com.saveitforlater.ecommerce.domain.file.dto;

public record UploadProductImageRequest(
    String productPublicId,
    boolean isPrimary,
    Integer displayOrder,
    String altText
) {
    public UploadProductImageRequest {
        if (displayOrder == null) {
            displayOrder = 0;
        }
    }
}

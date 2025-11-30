package com.saveitforlater.ecommerce.domain.file.dto;

public record UpdateProductImageRequest(
    Boolean isPrimary,
    Integer displayOrder,
    String altText
) {
}

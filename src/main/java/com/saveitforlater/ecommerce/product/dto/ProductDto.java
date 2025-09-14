package com.saveitforlater.ecommerce.product.dto;

import java.util.UUID;

public record ProductDto(
    UUID id,
    String name,
    String description,
    String category,
    String imageUrl,
    Double price,
    Integer stockQuantity,
    String sku
) {

}

package com.saveitforlater.ecommerce.api.product.dto;

import java.util.List;

public record ProductAttributeDto(
        String name,
        String slug,
        List<AttributeOptionDto> options
) {
    public record AttributeOptionDto(
            String name,
            String slug
    ) {}
}


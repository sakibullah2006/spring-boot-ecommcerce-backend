package com.saveitforlater.ecommerce.api.product.dto;

import java.util.List;

public record AttributeDto(
        String id,
        String name,
        String slug,
        String description,
        List<AttributeOptionDto> options
) {}
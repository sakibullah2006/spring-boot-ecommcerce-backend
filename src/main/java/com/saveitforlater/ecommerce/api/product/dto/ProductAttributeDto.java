package com.saveitforlater.ecommerce.api.product.dto;

import java.util.List;

/**
 * DTO for creating/updating product attributes.
 * Can reference existing attributes by ID or create new ones.
 */
public record ProductAttributeDto(
        String attributeId, // Optional: ID of existing attribute to use
        String attributeName, // Required if attributeId is null
        String attributeSlug, // Required if attributeId is null  
        String attributeDescription, // Optional
        List<ProductAttributeOptionDto> options
) {
    public record ProductAttributeOptionDto(
            String optionId, // Optional: ID of existing option to use
            String optionName, // Required if optionId is null
            String optionSlug, // Required if optionId is null
            String optionDescription // Optional
    ) {}
}


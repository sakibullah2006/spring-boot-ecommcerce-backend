package com.saveitforlater.ecommerce.api.product.dto;

public record ProductAttributeValueDto(
        String attributeId,
        String attributeName,
        String attributeSlug,
        String optionId,
        String optionName,
        String optionSlug
) {}
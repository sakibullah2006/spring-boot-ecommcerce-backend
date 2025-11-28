package com.saveitforlater.ecommerce.api.product.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.util.List;
import java.util.Set;

// Request DTO for updating a product (partial update - all fields optional except SKU)
public record UpdateProductRequest(
        @NotBlank(message = "SKU is required")
        @Size(max = 100)
        String sku,

        @Size(max = 255)
        String name,

        @Size(max = 255)
        String slug,

        String description,

        @PositiveOrZero(message = "Price must be zero or positive")
        BigDecimal price,

        @PositiveOrZero(message = "Sale price must be zero or positive")
        BigDecimal salePrice,

        @PositiveOrZero(message = "Stock quantity must be zero or positive")
        Integer stockQuantity,

        Set<String> categoryIds,

        List<ProductAttributeDto> attributes
) {}


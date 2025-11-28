package com.saveitforlater.ecommerce.api.product.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.util.List;
import java.util.Set;

// Request DTO
public record CreateProductRequest(
        @NotBlank
        @Size(max = 100)
        String sku,

        @NotBlank
        @Size(max = 255)
        String name,

        String description,

        @NotNull
        @PositiveOrZero(message = "Price must be zero or positive")
        BigDecimal price,

        @PositiveOrZero(message = "Sale price must be zero or positive")
        BigDecimal salePrice,

        @NotNull
        @PositiveOrZero(message = "Stock quantity must be zero or positive")
        Integer stockQuantity,

        @NotNull
        Set<String> categoryIds,

        List<ProductAttributeDto> attributes
) {}
package com.saveitforlater.ecommerce.api.product.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.util.Set;
import java.util.UUID;

// Request DTO
public record CreateProductRequest(
        @NotBlank
        @Size(max = 100)
        String sku,

        @NotBlank @Size(max = 255)
        String name,

        @NotNull
        String description,

        @Positive(message = "Price must be positive") BigDecimal price,
        @NotNull
        Set<UUID> categoryIds
) {}
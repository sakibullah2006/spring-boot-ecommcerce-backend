package com.saveitforlater.ecommerce.api.category.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.UUID;

// Request DTO
public record CreateCategoryRequest(
        @NotBlank @Size(max = 255) String name,
        String description,
        UUID parentId // Public ID of the parent (can be null)
) {}
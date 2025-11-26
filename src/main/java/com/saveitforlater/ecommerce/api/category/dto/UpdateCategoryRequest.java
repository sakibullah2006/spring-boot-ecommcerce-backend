package com.saveitforlater.ecommerce.api.category.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.UUID;

// Request DTO for updating a category
public record UpdateCategoryRequest(
        @NotBlank
        @Size(max = 255)
        String name,

        String description,

        UUID parentId // Public ID of the parent (can be null)
) {}


package com.saveitforlater.ecommerce.api.category.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.UUID;

// Response DTO
public record CategoryResponse(
        UUID id,
        String name,
        String description,
        UUID parentId // Public ID of the parent (can be null)
) {}

package com.saveitforlater.ecommerce.api.category.dto;

import java.util.Set;
import java.util.UUID;

// Response DTO
public record CategoryResponse(
        // id represents the publicId in the entity
        UUID id,
        String name,
        String slug,
        String description,
        CategorySummary parent, // Parent category (can be null)
        Set<CategorySummary> children // Child categories
) {
    // Nested DTO for parent and children
    public record CategorySummary(UUID id, String name, String slug) {}
}

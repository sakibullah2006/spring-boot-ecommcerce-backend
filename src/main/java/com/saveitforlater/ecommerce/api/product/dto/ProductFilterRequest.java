package com.saveitforlater.ecommerce.api.product.dto;

import java.math.BigDecimal;
import java.util.List;

public record ProductFilterRequest(
        String searchTerm,              // Search in name, description, SKU
        List<String> categoryIds,        // Filter by category public IDs
        BigDecimal minPrice,             // Minimum price
        BigDecimal maxPrice,             // Maximum price
        Boolean inStock,                 // true = only in stock, false = only out of stock, null = all
        List<AttributeFilter> attributes // Filter by attribute values
) {
    public record AttributeFilter(
            String attributeName,         // Attribute name (e.g., "Color")
            List<String> optionNames      // Option names (e.g., ["Red", "Blue"])
    ) {}
}

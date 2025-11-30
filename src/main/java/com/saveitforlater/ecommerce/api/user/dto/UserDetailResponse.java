package com.saveitforlater.ecommerce.api.user.dto;

import java.time.Instant;

/**
 * Extended user response with additional fields for admin/detailed views
 */
public record UserDetailResponse(
        String id,
        String firstName,
        String lastName,
        String email,
        String role,
        Instant createdAt,
        Instant updatedAt
) {}

package com.saveitforlater.ecommerce.api.auth.dto;

import java.util.UUID;

// This is a "safe" DTO to return to the client (no password)
public record UserResponse(
        UUID id,

        String firstName,

        String lastName,

        String email,

        String role
) {}
package com.saveitforlater.ecommerce.api.auth.dto;

// This is a "safe" DTO to return to the client (no password)
public record UserResponse(
        String id,

        String firstName,

        String lastName,

        String email,

        String role
) {}
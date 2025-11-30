package com.saveitforlater.ecommerce.api.order.dto;

public record AddressResponse(
        String addressLine1,
        String addressLine2,
        String city,
        String state,
        String postalCode,
        String country
) {}

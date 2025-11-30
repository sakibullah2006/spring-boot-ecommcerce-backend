package com.saveitforlater.ecommerce.api.order.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record PaymentDetailsRequest(
        @NotBlank(message = "Card number is required")
        @Pattern(regexp = "\\d{16}", message = "Card number must be 16 digits")
        String cardNumber,
        
        @NotBlank(message = "Card holder name is required")
        String cardHolderName,
        
        @NotBlank(message = "Expiry date is required")
        @Pattern(regexp = "(0[1-9]|1[0-2])/\\d{2}", message = "Expiry date must be in MM/YY format")
        String expiryDate,
        
        @NotBlank(message = "CVV is required")
        @Size(min = 3, max = 4, message = "CVV must be 3 or 4 digits")
        @Pattern(regexp = "\\d{3,4}", message = "CVV must contain only digits")
        String cvv,
        
        String cardBrand
) {}

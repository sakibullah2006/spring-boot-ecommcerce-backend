package com.saveitforlater.ecommerce.domain.category.exception;

import lombok.Getter;

@Getter
public class IllegalCategoryArgumentException extends IllegalArgumentException {
    private final String errorCode = "INVALID_CATEGORY_OPERATION";

    public IllegalCategoryArgumentException(String message) {
        super(message);
    }
}
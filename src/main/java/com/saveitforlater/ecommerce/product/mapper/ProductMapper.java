package com.saveitforlater.ecommerce.product.mapper;

import java.math.BigDecimal;

import org.springframework.stereotype.Component;

import com.saveitforlater.ecommerce.product.dto.ProductDto;
import com.saveitforlater.ecommerce.product.entities.Product;

@Component
public class ProductMapper {

    public ProductDto toDto(Product product) {
        if (product == null) {
            return null;
        }
        return new ProductDto(
            product.getId(),
            product.getName(),
            product.getDescription(),
            product.getCategory(),
            product.getImageUrl(),
            product.getPrice() != null ? product.getPrice().doubleValue() : null,
            product.getStockQuantity(),
            product.getSku()
        );
    }

    public Product toProduct(ProductDto dto) {
        if (dto == null) {
            return null;
        }
        Product product = new Product();
        product.setId(dto.id());
        product.setName(dto.name());
        product.setDescription(dto.description());
        product.setCategory(dto.category());
        product.setImageUrl(dto.imageUrl());
        product.setPrice(dto.price() != null ? BigDecimal.valueOf(dto.price()) : null);
        product.setStockQuantity(dto.stockQuantity());
        product.setSku(dto.sku());
        return product;
    }
}
package com.saveitforlater.ecommerce.api.product.mapper;

import com.saveitforlater.ecommerce.api.product.dto.ProductResponse;
import com.saveitforlater.ecommerce.persistence.entity.category.Category;
import com.saveitforlater.ecommerce.persistence.entity.product.Product;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper // componentModel="spring" is set globally in your pom.xml
public interface ProductMapper {

    @Mapping(source = "publicId", target = "id")
    ProductResponse toProductResponse(Product product);

    @Mapping(source = "publicId", target = "id")
    @Mapping(source = "parent.publicId", target = "parentId")
    ProductResponse.CategorySummary toCategorySummary(Category category);
}
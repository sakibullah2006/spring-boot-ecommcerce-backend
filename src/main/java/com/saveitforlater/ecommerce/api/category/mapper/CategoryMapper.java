package com.saveitforlater.ecommerce.api.category.mapper;

import com.saveitforlater.ecommerce.api.category.dto.CategoryResponse;
import com.saveitforlater.ecommerce.persistence.entity.category.Category;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper // componentModel="spring" is set globally in your pom.xml
public interface CategoryMapper {

    // MapStruct automatically maps 'parent.publicId' to 'parentId'
    @Mapping(source = "publicId", target = "id")
    @Mapping(source = "parent.publicId", target = "parentId")
    CategoryResponse toCategoryResponse(Category category);
}
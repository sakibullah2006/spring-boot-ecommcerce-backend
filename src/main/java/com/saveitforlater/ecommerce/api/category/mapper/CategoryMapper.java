package com.saveitforlater.ecommerce.api.category.mapper;

import com.saveitforlater.ecommerce.api.category.dto.CategoryResponse;
import com.saveitforlater.ecommerce.api.category.dto.CreateCategoryRequest;
import com.saveitforlater.ecommerce.api.category.dto.UpdateCategoryRequest;
import com.saveitforlater.ecommerce.persistence.entity.category.Category;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;

@Mapper(componentModel = "spring")
public interface CategoryMapper {

    @Mapping(source = "publicId", target = "id")
    CategoryResponse toCategoryResponse(Category category);

    @Mapping(source = "publicId", target = "id")
    CategoryResponse.CategorySummary toCategorySummary(Category category);

    @Mapping(target = "id", ignore = true)            // Database ID - auto-generated
    @Mapping(target = "publicId", ignore = true)      // Public UUID - auto-generated on create
    @Mapping(target = "parent", ignore = true)        // Set manually in service using parentId (public UUID)
    @Mapping(target = "children", ignore = true)      // Managed by JPA relationship
    @Mapping(target = "products", ignore = true)      // Managed by JPA relationship
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    Category toCategory(CreateCategoryRequest request);

    @Mapping(target = "id", ignore = true)            // Database ID - preserves existing value
    @Mapping(target = "publicId", ignore = true)      // Public UUID - preserves existing value
    @Mapping(target = "parent", ignore = true)        // Set manually in service using parentId (public UUID)
    @Mapping(target = "children", ignore = true)      // Managed by JPA relationship
    @Mapping(target = "products", ignore = true)      // Managed by JPA relationship
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    void updateCategoryFromRequest(UpdateCategoryRequest request, @MappingTarget Category category);
}
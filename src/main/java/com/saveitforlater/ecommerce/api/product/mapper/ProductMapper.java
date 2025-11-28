package com.saveitforlater.ecommerce.api.product.mapper;

import com.saveitforlater.ecommerce.api.product.dto.*;
import com.saveitforlater.ecommerce.persistence.entity.category.Category;
import com.saveitforlater.ecommerce.persistence.entity.product.*;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;

@Mapper // componentModel="spring" is set globally in your pom.xml
public interface ProductMapper {

    @Mapping(source = "publicId", target = "id")
    @Mapping(source = "attributeValues", target = "attributes")
    ProductResponse toProductResponse(Product product);

    @Mapping(source = "publicId", target = "id")
    @Mapping(source = "parent.publicId", target = "parentId")
    ProductResponse.CategorySummary toCategorySummary(Category category);

    // New mappers for the reusable attribute system
    @Mapping(source = "publicId", target = "id")
    AttributeDto toAttributeDto(Attribute attribute);

    @Mapping(source = "publicId", target = "id") 
    AttributeOptionDto toAttributeOptionDto(AttributeOption option);

    @Mapping(source = "attribute.publicId", target = "attributeId")
    @Mapping(source = "attribute.name", target = "attributeName")
    @Mapping(source = "attribute.slug", target = "attributeSlug")
    @Mapping(source = "attributeOption.publicId", target = "optionId")
    @Mapping(source = "attributeOption.name", target = "optionName")
    @Mapping(source = "attributeOption.slug", target = "optionSlug")
    ProductAttributeValueDto toProductAttributeValueDto(ProductAttributeValue value);

    @Mapping(target = "id", ignore = true)           // Internal DB ID - never mapped from external requests
    @Mapping(target = "publicId", ignore = true)      // Public UUID - auto-generated on create
    @Mapping(target = "categories", ignore = true)    // Set manually in service using categoryIds (public IDs)
    @Mapping(target = "attributeValues", ignore = true)    // Set manually in service using new attribute system
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    Product toProduct(CreateProductRequest request);

    @Mapping(target = "id", ignore = true)           // Internal DB ID - never mapped from external requests
    @Mapping(target = "publicId", ignore = true)      // Public UUID - preserves existing value
    @Mapping(target = "categories", ignore = true)    // Set manually in service using categoryIds (public IDs)
    @Mapping(target = "attributeValues", ignore = true)    // Set manually in service using new attribute system
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    void updateProductFromRequest(UpdateProductRequest request, @MappingTarget Product product);
}
package com.saveitforlater.ecommerce.api.product.mapper;

import com.saveitforlater.ecommerce.api.product.dto.CreateProductRequest;
import com.saveitforlater.ecommerce.api.product.dto.ProductAttributeDto;
import com.saveitforlater.ecommerce.api.product.dto.ProductResponse;
import com.saveitforlater.ecommerce.api.product.dto.UpdateProductRequest;
import com.saveitforlater.ecommerce.persistence.entity.category.Category;
import com.saveitforlater.ecommerce.persistence.entity.product.AttributeOption;
import com.saveitforlater.ecommerce.persistence.entity.product.Product;
import com.saveitforlater.ecommerce.persistence.entity.product.ProductAttribute;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;

@Mapper // componentModel="spring" is set globally in your pom.xml
public interface ProductMapper {

    @Mapping(source = "publicId", target = "id")
    ProductResponse toProductResponse(Product product);

    @Mapping(source = "publicId", target = "id")
    @Mapping(source = "parent.publicId", target = "parentId")
    ProductResponse.CategorySummary toCategorySummary(Category category);

    ProductAttributeDto toProductAttributeDto(ProductAttribute attribute);

    ProductAttributeDto.AttributeOptionDto toAttributeOptionDto(AttributeOption option);

    @Mapping(target = "id", ignore = true)           // Internal DB ID - never mapped from external requests
    @Mapping(target = "publicId", ignore = true)      // Public UUID - auto-generated on create
    @Mapping(target = "categories", ignore = true)    // Set manually in service using categoryIds (public IDs)
    @Mapping(target = "attributes", ignore = true)    // Set manually in service
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    Product toProduct(CreateProductRequest request);

    @Mapping(target = "id", ignore = true)           // Internal DB ID - never mapped from external requests
    @Mapping(target = "publicId", ignore = true)      // Public UUID - preserves existing value
    @Mapping(target = "categories", ignore = true)    // Set manually in service using categoryIds (public IDs)
    @Mapping(target = "attributes", ignore = true)    // Set manually in service
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    void updateProductFromRequest(UpdateProductRequest request, @MappingTarget Product product);
}
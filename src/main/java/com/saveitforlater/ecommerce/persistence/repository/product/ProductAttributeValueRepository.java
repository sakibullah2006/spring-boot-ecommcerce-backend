package com.saveitforlater.ecommerce.persistence.repository.product;

import com.saveitforlater.ecommerce.persistence.entity.product.Attribute;
import com.saveitforlater.ecommerce.persistence.entity.product.Product;
import com.saveitforlater.ecommerce.persistence.entity.product.ProductAttributeValue;
import com.saveitforlater.ecommerce.persistence.entity.product.AttributeOption;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ProductAttributeValueRepository extends JpaRepository<ProductAttributeValue, Long> {

    List<ProductAttributeValue> findByProduct(Product product);
    
    List<ProductAttributeValue> findByProductAndIsActiveTrue(Product product);
    
    List<ProductAttributeValue> findByAttribute(Attribute attribute);
    
    List<ProductAttributeValue> findByAttributeOption(AttributeOption attributeOption);
    
    Optional<ProductAttributeValue> findByProductAndAttribute(Product product, Attribute attribute);
    
    Optional<ProductAttributeValue> findByProductAndAttributeAndIsActiveTrue(Product product, Attribute attribute);
    
    @Query("SELECT pav FROM ProductAttributeValue pav WHERE pav.product.publicId = :productPublicId AND pav.isActive = true")
    List<ProductAttributeValue> findActiveAttributeValuesByProductPublicId(@Param("productPublicId") String productPublicId);
    
    @Query("SELECT pav FROM ProductAttributeValue pav WHERE pav.product = :product AND pav.attribute = :attribute AND pav.attributeOption = :option")
    Optional<ProductAttributeValue> findByProductAndAttributeAndOption(@Param("product") Product product, 
                                                                       @Param("attribute") Attribute attribute, 
                                                                       @Param("option") AttributeOption option);
    
    @Query("SELECT DISTINCT pav.attribute FROM ProductAttributeValue pav WHERE pav.product = :product AND pav.isActive = true")
    List<Attribute> findDistinctAttributesByProduct(@Param("product") Product product);
    
    void deleteByProductAndAttribute(Product product, Attribute attribute);
    
    void deleteByProductAndAttributeAndAttributeOption(Product product, Attribute attribute, AttributeOption attributeOption);
}
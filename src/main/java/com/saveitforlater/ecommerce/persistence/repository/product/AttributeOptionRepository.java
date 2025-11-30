package com.saveitforlater.ecommerce.persistence.repository.product;

import com.saveitforlater.ecommerce.persistence.entity.product.Attribute;
import com.saveitforlater.ecommerce.persistence.entity.product.AttributeOption;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AttributeOptionRepository extends JpaRepository<AttributeOption, Long> {

    Optional<AttributeOption> findByPublicId(String publicId);
    
    List<AttributeOption> findByAttribute(Attribute attribute);
    
    List<AttributeOption> findByAttributeAndIsActiveTrue(Attribute attribute);
    
    Optional<AttributeOption> findByAttributeAndName(Attribute attribute, String name);
    
    Optional<AttributeOption> findByAttributeAndSlug(Attribute attribute, String slug);
    
    Optional<AttributeOption> findByAttributeAndNameIgnoreCase(Attribute attribute, String name);
    
    Optional<AttributeOption> findByAttributeAndSlugIgnoreCase(Attribute attribute, String slug);
    
    @Query("SELECT ao FROM AttributeOption ao WHERE ao.attribute.publicId = :attributePublicId AND ao.isActive = true")
    List<AttributeOption> findActiveOptionsByAttributePublicId(@Param("attributePublicId") String attributePublicId);
    
    @Query("SELECT COUNT(ao) > 0 FROM AttributeOption ao WHERE ao.attribute = :attribute AND ao.name = :name AND ao.id != :id")
    boolean existsByAttributeAndNameAndIdNot(@Param("attribute") Attribute attribute, @Param("name") String name, @Param("id") Long id);
    
    @Query("SELECT COUNT(ao) > 0 FROM AttributeOption ao WHERE ao.attribute = :attribute AND ao.slug = :slug AND ao.id != :id")
    boolean existsByAttributeAndSlugAndIdNot(@Param("attribute") Attribute attribute, @Param("slug") String slug, @Param("id") Long id);
}
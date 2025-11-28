package com.saveitforlater.ecommerce.persistence.repository.product;

import com.saveitforlater.ecommerce.persistence.entity.product.Attribute;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface AttributeRepository extends JpaRepository<Attribute, Long> {

    Optional<Attribute> findByPublicId(String publicId);
    
    Optional<Attribute> findByName(String name);
    
    Optional<Attribute> findBySlug(String slug);
    
    Optional<Attribute> findByNameIgnoreCase(String name);
    
    Optional<Attribute> findBySlugIgnoreCase(String slug);
    
    List<Attribute> findByIsActiveTrue();
    
    @Query("SELECT a FROM Attribute a WHERE a.isActive = true ORDER BY a.name")
    List<Attribute> findAllActiveOrderByName();
    
    @Query("SELECT COUNT(a) > 0 FROM Attribute a WHERE a.name = :name AND a.id != :id")
    boolean existsByNameAndIdNot(@Param("name") String name, @Param("id") Long id);
    
    @Query("SELECT COUNT(a) > 0 FROM Attribute a WHERE a.slug = :slug AND a.id != :id")
    boolean existsBySlugAndIdNot(@Param("slug") String slug, @Param("id") Long id);
}
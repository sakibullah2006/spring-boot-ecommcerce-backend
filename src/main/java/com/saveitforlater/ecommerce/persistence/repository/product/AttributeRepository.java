package com.saveitforlater.ecommerce.persistence.repository.product;

import com.saveitforlater.ecommerce.persistence.entity.product.Attribute;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AttributeRepository extends JpaRepository<Attribute, Long> {

    @EntityGraph(attributePaths = {"options"})
    Optional<Attribute> findByPublicId(String publicId);
    
    Optional<Attribute> findByName(String name);
    
    Optional<Attribute> findBySlug(String slug);
    
    Optional<Attribute> findByNameIgnoreCase(String name);
    
    Optional<Attribute> findBySlugIgnoreCase(String slug);
    
    @EntityGraph(attributePaths = {"options"})
    List<Attribute> findByIsActiveTrue();
    
    @EntityGraph(attributePaths = {"options"})
    @Query("SELECT a FROM Attribute a WHERE a.isActive = true ORDER BY a.name")
    List<Attribute> findAllActiveOrderByName();
    
    @EntityGraph(attributePaths = {"options"})
    @Query("SELECT a FROM Attribute a ORDER BY a.name")
    List<Attribute> findAllWithOptions();
    
    @Query("SELECT COUNT(a) > 0 FROM Attribute a WHERE a.name = :name AND a.id != :id")
    boolean existsByNameAndIdNot(@Param("name") String name, @Param("id") Long id);
    
    @Query("SELECT COUNT(a) > 0 FROM Attribute a WHERE a.slug = :slug AND a.id != :id")
    boolean existsBySlugAndIdNot(@Param("slug") String slug, @Param("id") Long id);
    
    @Modifying
    @Query("DELETE FROM Attribute a WHERE a.publicId = :publicId")
    void deleteByPublicId(@Param("publicId") String publicId);
    
    @Query("SELECT COUNT(pav) FROM ProductAttributeValue pav WHERE pav.attribute.publicId = :publicId")
    long countProductUsages(@Param("publicId") String publicId);
}
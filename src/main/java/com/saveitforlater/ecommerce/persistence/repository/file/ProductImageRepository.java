package com.saveitforlater.ecommerce.persistence.repository.file;

import com.saveitforlater.ecommerce.persistence.entity.file.ProductImage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ProductImageRepository extends JpaRepository<ProductImage, Long> {
    
    Optional<ProductImage> findByPublicId(String publicId);
    
    List<ProductImage> findByProductIdOrderByDisplayOrderAsc(Long productId);
    
    List<ProductImage> findByProductPublicIdOrderByDisplayOrderAsc(String productPublicId);
    
    Optional<ProductImage> findByProductIdAndIsPrimaryTrue(Long productId);
    
    Optional<ProductImage> findByProductPublicIdAndIsPrimaryTrue(String productPublicId);
    
    @Modifying
    @Query("UPDATE ProductImage pi SET pi.isPrimary = false WHERE pi.product.id = :productId")
    void clearPrimaryForProduct(@Param("productId") Long productId);
    
    void deleteByPublicId(String publicId);
    
    void deleteByProductId(Long productId);
}

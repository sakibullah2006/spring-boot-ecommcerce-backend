package com.saveitforlater.ecommerce.persistence.repository.product;

import com.saveitforlater.ecommerce.persistence.entity.product.Product;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface ProductRepository extends JpaRepository<Product, Long> {

    Optional<Product> findByPublicId(String publicId);
    Optional<Product> findBySku(String sku);
}
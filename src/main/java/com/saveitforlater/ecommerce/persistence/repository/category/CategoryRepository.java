package com.saveitforlater.ecommerce.persistence.repository.category;

import com.saveitforlater.ecommerce.persistence.entity.category.Category;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.Set;
import java.util.UUID;

@Repository
public interface CategoryRepository extends JpaRepository<Category, Long> {

    Optional<Category> findByPublicId(UUID publicId);

    Optional<Category> findByName(String name);

    // Finds all top-level categories
    Set<Category> findByParentIsNull();
}
package com.saveitforlater.ecommerce.domain.category;

import com.saveitforlater.ecommerce.api.category.dto.CategoryResponse;
import com.saveitforlater.ecommerce.api.category.dto.CreateCategoryRequest;
import com.saveitforlater.ecommerce.api.category.dto.UpdateCategoryRequest;
import com.saveitforlater.ecommerce.api.category.mapper.CategoryMapper;
import com.saveitforlater.ecommerce.domain.category.exception.CategoryHasChildrenException;
import com.saveitforlater.ecommerce.domain.category.exception.CategoryNameAlreadyExistsException;
import com.saveitforlater.ecommerce.domain.category.exception.CategoryNotFoundException;
import com.saveitforlater.ecommerce.persistence.entity.category.Category;
import com.saveitforlater.ecommerce.persistence.repository.category.CategoryRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CategoryService {

    private final CategoryRepository categoryRepository;
    private final CategoryMapper categoryMapper;

    /**
     * Get all categories (accessible to everyone)
     */
    public List<CategoryResponse> getAllCategories() {
        log.debug("Fetching all categories");
        return categoryRepository.findAll()
                .stream()
                .map(categoryMapper::toCategoryResponse)
                .collect(Collectors.toList());
    }

    /**
     * Get paginated categories (accessible to everyone)
     */
    public Page<CategoryResponse> getCategories(Pageable pageable) {
        log.debug("Fetching categories with pagination: {}", pageable);
        return categoryRepository.findAll(pageable)
                .map(categoryMapper::toCategoryResponse);
    }

    /**
     * Get category by public ID (accessible to everyone)
     */
    public CategoryResponse getCategoryById(String publicId) {
        log.debug("Fetching category by ID: {}", publicId);
        Category category = categoryRepository.findByPublicId(publicId)
                .orElseThrow(() -> CategoryNotFoundException.byPublicId(publicId));

        return categoryMapper.toCategoryResponse(category);
    }

    /**
     * Get all top-level categories (no parent) (accessible to everyone)
     */
    public List<CategoryResponse> getTopLevelCategories() {
        log.debug("Fetching top-level categories");
        return categoryRepository.findByParentIsNull()
                .stream()
                .map(categoryMapper::toCategoryResponse)
                .collect(Collectors.toList());
    }

    /**
     * Create a new category (ADMIN ONLY)
     */
    @Transactional
    public CategoryResponse createCategory(CreateCategoryRequest request) {
        log.info("Creating new category with name: {}", request.name());

        // Check if category name already exists
        if (categoryRepository.findByName(request.name()).isPresent()) {
            throw CategoryNameAlreadyExistsException.withName(request.name());
        }

        // Map basic fields
        Category category = categoryMapper.toCategory(request);

        // Set parent if provided
        if (request.parentId() != null) {
            Category parent = categoryRepository.findByPublicId(request.parentId())
                    .orElseThrow(() -> CategoryNotFoundException.byPublicId(request.parentId()));
            category.setParent(parent);
            log.debug("Set parent category: {} for new category: {}", parent.getName(), request.name());
        }

        // Save category
        Category savedCategory = categoryRepository.save(category);
        log.info("Successfully created category with ID: {} and name: {}",
                savedCategory.getPublicId(), savedCategory.getName());

        return categoryMapper.toCategoryResponse(savedCategory);
    }

    /**
     * Update an existing category (ADMIN ONLY)
     */
    @Transactional
    public CategoryResponse updateCategory(String publicId, UpdateCategoryRequest request) {
        log.info("Updating category with ID: {}", publicId);

        // Find existing category
        Category existingCategory = categoryRepository.findByPublicId(publicId)
                .orElseThrow(() -> CategoryNotFoundException.byPublicId(publicId));

        // Check if new name conflicts with existing categories (excluding current category)
        categoryRepository.findByName(request.name())
                .filter(category -> !category.getPublicId().equals(publicId))
                .ifPresent(category -> {
                    throw CategoryNameAlreadyExistsException.withName(request.name());
                });

        // Update basic fields
        categoryMapper.updateCategoryFromRequest(request, existingCategory);

        // Update parent if provided
        if (request.parentId() != null) {
            // Prevent setting self as parent
            if (request.parentId().equals(publicId)) {
                throw new IllegalArgumentException("Category cannot be its own parent");
            }

            Category newParent = categoryRepository.findByPublicId(request.parentId())
                    .orElseThrow(() -> CategoryNotFoundException.byPublicId(request.parentId()));

            // Prevent circular references (simplified check - could be enhanced)
            if (isDescendant(newParent, existingCategory)) {
                throw new IllegalArgumentException("Cannot set a descendant category as parent");
            }

            existingCategory.setParent(newParent);
            log.debug("Updated parent category to: {} for category: {}", newParent.getName(), existingCategory.getName());
        } else {
            existingCategory.setParent(null);
            log.debug("Removed parent for category: {}", existingCategory.getName());
        }

        // Save updated category
        Category updatedCategory = categoryRepository.save(existingCategory);
        log.info("Successfully updated category with ID: {}", updatedCategory.getPublicId());

        return categoryMapper.toCategoryResponse(updatedCategory);
    }

    /**
     * Delete a category (ADMIN ONLY)
     */
    @Transactional
    public void deleteCategory(String publicId) {
        log.info("Deleting category with ID: {}", publicId);

        Category category = categoryRepository.findByPublicId(publicId)
                .orElseThrow(() -> CategoryNotFoundException.byPublicId(publicId));

        // Check if category has children
        if (!category.getChildren().isEmpty()) {
            throw CategoryHasChildrenException.withId(publicId);
        }

        // TODO: Check if category has products associated with it
        // This would require checking the Product entity relationships
        // For now, we'll rely on database constraints

        categoryRepository.delete(category);
        log.info("Successfully deleted category with ID: {}", publicId);
    }

    /**
     * Helper method to check if a category is a descendant of another
     */
    private boolean isDescendant(Category potentialDescendant, Category ancestor) {
        Category current = potentialDescendant.getParent();
        while (current != null) {
            if (current.getPublicId().equals(ancestor.getPublicId())) {
                return true;
            }
            current = current.getParent();
        }
        return false;
    }
}


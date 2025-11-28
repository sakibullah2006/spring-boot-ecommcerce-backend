package com.saveitforlater.ecommerce.api.category;

import com.saveitforlater.ecommerce.api.category.dto.CategoryResponse;
import com.saveitforlater.ecommerce.api.category.dto.CreateCategoryRequest;
import com.saveitforlater.ecommerce.api.category.dto.UpdateCategoryRequest;
import com.saveitforlater.ecommerce.domain.category.CategoryService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/categories")
@RequiredArgsConstructor
public class CategoryController {

    private final CategoryService categoryService;

    /**
     * Get all categories - accessible to everyone
     */
    @GetMapping
    public ResponseEntity<List<CategoryResponse>> getAllCategories() {
        log.debug("GET /api/categories - Fetching all categories");
        List<CategoryResponse> categories = categoryService.getAllCategories();
        return ResponseEntity.ok(categories);
    }

    /**
     * Get paginated categories - accessible to everyone
     */
    @GetMapping("/paginated")
    public ResponseEntity<Page<CategoryResponse>> getCategories(
            @PageableDefault(size = 20, sort = "name") Pageable pageable) {
        log.debug("GET /api/categories/paginated - Fetching categories with pagination: {}", pageable);
        Page<CategoryResponse> categories = categoryService.getCategories(pageable);
        return ResponseEntity.ok(categories);
    }

    /**
     * Get category by ID - accessible to everyone
     */
    @GetMapping("/{id}")
    public ResponseEntity<CategoryResponse> getCategoryById(@PathVariable String id) {
        log.debug("GET /api/categories/{} - Fetching category by ID", id);
        CategoryResponse category = categoryService.getCategoryById(id);
        return ResponseEntity.ok(category);
    }

    /**
     * Get top-level categories - accessible to everyone
     */
    @GetMapping("/top-level")
    public ResponseEntity<List<CategoryResponse>> getTopLevelCategories() {
        log.debug("GET /api/categories/top-level - Fetching top-level categories");
        List<CategoryResponse> categories = categoryService.getTopLevelCategories();
        return ResponseEntity.ok(categories);
    }

    /**
     * Create category - ADMIN ONLY
     */
    @PostMapping
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<CategoryResponse> createCategory(
            @Valid @RequestBody CreateCategoryRequest request) {
        log.info("POST /api/categories - Creating new category: {}", request.name());
        CategoryResponse createdCategory = categoryService.createCategory(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(createdCategory);
    }

    /**
     * Update category - ADMIN ONLY
     */
    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<CategoryResponse> updateCategory(
            @PathVariable String id,
            @Valid @RequestBody UpdateCategoryRequest request) {
        log.info("PUT /api/categories/{} - Updating category with new data", id);
        CategoryResponse updatedCategory = categoryService.updateCategory(id, request);
        return ResponseEntity.ok(updatedCategory);
    }

    /**
     * Delete category - ADMIN ONLY
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<Void> deleteCategory(@PathVariable String id) {
        log.info("DELETE /api/categories/{} - Deleting category", id);
        categoryService.deleteCategory(id);
        return ResponseEntity.noContent().build();
    }
}

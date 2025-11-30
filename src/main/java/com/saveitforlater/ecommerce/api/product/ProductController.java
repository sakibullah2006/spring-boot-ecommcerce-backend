package com.saveitforlater.ecommerce.api.product;

import com.saveitforlater.ecommerce.api.product.dto.CreateProductRequest;
import com.saveitforlater.ecommerce.api.product.dto.ProductFilterRequest;
import com.saveitforlater.ecommerce.api.product.dto.ProductResponse;
import com.saveitforlater.ecommerce.api.product.dto.UpdateProductRequest;
import com.saveitforlater.ecommerce.domain.file.ProductImageService;
import com.saveitforlater.ecommerce.domain.product.ProductService;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.math.BigDecimal;
import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/products")
@RequiredArgsConstructor
public class ProductController {

    private final ProductService productService;
    private final ProductImageService productImageService;
    private final ObjectMapper objectMapper;

    /**
     * Get all products - accessible to everyone
     */
    @GetMapping
    public ResponseEntity<List<ProductResponse>> getAllProducts() {
        log.debug("GET /api/products - Fetching all products");
        List<ProductResponse> products = productService.getAllProducts();
        return ResponseEntity.ok(products);
    }

    /**
     * Get paginated products - accessible to everyone
     */
    @GetMapping("/paginated")
    public ResponseEntity<Page<ProductResponse>> getProducts(
            @PageableDefault(size = 20, sort = "name") Pageable pageable) {
        log.debug("GET /api/products/paginated - Fetching products with pagination: {}", pageable);
        Page<ProductResponse> products = productService.getProducts(pageable);
        return ResponseEntity.ok(products);
    }

    /**
     * Search and filter products with pagination - accessible to everyone
     * Supports query parameters for filtering: searchTerm, categoryIds, minPrice, maxPrice, inStock
     */
    @GetMapping("/search")
    public ResponseEntity<Page<ProductResponse>> searchProducts(
            @RequestParam(required = false) String searchTerm,
            @RequestParam(required = false) List<String> categoryIds,
            @RequestParam(required = false) BigDecimal minPrice,
            @RequestParam(required = false) BigDecimal maxPrice,
            @RequestParam(required = false) Boolean inStock,
            @PageableDefault(size = 20, sort = "name") Pageable pageable) {
        log.debug("GET /api/products/search - Searching products with filters");
        
        // Build filter from query parameters
        ProductFilterRequest filter = new ProductFilterRequest(
            searchTerm, 
            categoryIds, 
            minPrice, 
            maxPrice, 
            inStock, 
            null  // attributes filtering not supported via query params (too complex)
        );
        
        Page<ProductResponse> products = productService.getProductsWithFilters(filter, pageable);
        return ResponseEntity.ok(products);
    }

    /**
     * Get product by ID - accessible to everyone
     */
    @GetMapping("/{id}")
    public ResponseEntity<ProductResponse> getProductById(@PathVariable String id) {
        log.debug("GET /api/products/{} - Fetching product by ID", id);
        ProductResponse product = productService.getProductById(id);
        return ResponseEntity.ok(product);
    }

    /**
     * Get product by SKU - accessible to everyone
     */
    @GetMapping("/sku/{sku}")
    public ResponseEntity<ProductResponse> getProductBySku(@PathVariable String sku) {
        log.debug("GET /api/products/sku/{} - Fetching product by SKU", sku);
        ProductResponse product = productService.getProductBySku(sku);
        return ResponseEntity.ok(product);
    }

    /**
     * Create product - ADMIN ONLY
     */
    @PostMapping
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<ProductResponse> createProduct(
            @Valid @RequestBody CreateProductRequest request) {
        log.info("POST /api/products - Creating new product: {}", request.name());
        ProductResponse createdProduct = productService.createProduct(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(createdProduct);
    }

    /**
     * Create product with images - ADMIN ONLY
     * Accepts multipart/form-data with product JSON and image files
     */
    @PostMapping(value = "/with-images", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<ProductResponse> createProductWithImages(
            @RequestParam("product") String productJson,
            @RequestParam(value = "images", required = false) List<MultipartFile> images,
            @RequestParam(value = "primaryImageIndex", required = false, defaultValue = "0") int primaryImageIndex) {
        
        try {
            log.info("POST /api/products/with-images - Creating new product with {} image(s)", 
                    images != null ? images.size() : 0);
            
            // Parse product JSON
            CreateProductRequest request = objectMapper.readValue(productJson, CreateProductRequest.class);
            
            // Create product
            ProductResponse createdProduct = productService.createProduct(request);
            
            // Upload images if provided
            if (images != null && !images.isEmpty()) {
                for (int i = 0; i < images.size(); i++) {
                    MultipartFile image = images.get(i);
                    boolean isPrimary = (i == primaryImageIndex);
                    int displayOrder = i;
                    
                    productImageService.uploadProductImage(
                            createdProduct.id(),
                            image,
                            isPrimary,
                            displayOrder,
                            null // altText can be added later
                    );
                }
                log.info("Successfully uploaded {} image(s) for product: {}", images.size(), createdProduct.id());
                
                // Fetch product again to get updated response with images
                createdProduct = productService.getProductById(createdProduct.id());
            }
            
            return ResponseEntity.status(HttpStatus.CREATED).body(createdProduct);
            
        } catch (Exception e) {
            log.error("Failed to create product with images: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to create product with images: " + e.getMessage(), e);
        }
    }

    /**
     * Update product - ADMIN ONLY
     */
    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<ProductResponse> updateProduct(
            @PathVariable String id,
            @Valid @RequestBody UpdateProductRequest request) {
        log.info("PUT /api/products/{} - Updating product with new data", id);
        ProductResponse updatedProduct = productService.updateProduct(id, request);
        return ResponseEntity.ok(updatedProduct);
    }

    /**
     * Delete product - ADMIN ONLY
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<Void> deleteProduct(@PathVariable String id) {
        log.info("DELETE /api/products/{} - Deleting product", id);
        productService.deleteProduct(id);
        return ResponseEntity.noContent().build();
    }
}


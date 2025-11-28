package com.saveitforlater.ecommerce.api.product;

import com.saveitforlater.ecommerce.api.product.dto.CreateProductRequest;
import com.saveitforlater.ecommerce.api.product.dto.ProductResponse;
import com.saveitforlater.ecommerce.api.product.dto.UpdateProductRequest;
import com.saveitforlater.ecommerce.domain.product.ProductService;
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
@RequestMapping("/api/products")
@RequiredArgsConstructor
public class ProductController {

    private final ProductService productService;

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


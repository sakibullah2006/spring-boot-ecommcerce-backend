# Product Module - Technical Documentation

## Overview

The Product Module manages the product catalog including product information, categories, attributes, descriptions, and images. It implements a reusable attribute system and supports rich HTML descriptions with XSS protection.

## Architecture

```
ProductController → ProductService → ProductRepository
                         ↓
                    HtmlSanitizer
                         ↓
                    ProductMapper → ProductResponse
```

## Core Components

### Entities

#### Product
**Package**: `com.saveitforlater.ecommerce.domain.product`

```java
@Entity
public class Product {
    @Id @GeneratedValue
    private Long id;
    
    private String publicId;           // UUID for API
    private String sku;                // Stock Keeping Unit (unique)
    private String name;
    private String slug;               // URL-friendly identifier
    private String shortDescription;   // VARCHAR(500)
    
    @Lob
    private String description;        // TEXT - Rich HTML content
    
    private BigDecimal price;
    private BigDecimal salePrice;
    private Integer stockQuantity;
    private Boolean isActive;
    
    @ManyToMany
    private Set<Category> categories;
    
    @OneToMany(mappedBy = "product")
    private List<ProductAttributeValue> attributes;
    
    @OneToMany(mappedBy = "product")
    private List<ProductImage> images;
}
```

**Key Features**:
- UUID-based public ID for external references
- SKU uniqueness enforced at database level
- SEO-friendly slug generation
- Rich HTML descriptions with sanitization
- Sale price optional (null means no discount)
- Stock quantity tracking
- Soft delete via `isActive` flag

### Service Layer

#### ProductService
**Package**: `com.saveitforlater.ecommerce.domain.product`

**Dependencies**:
- `ProductRepository` - Data access
- `CategoryRepository` - Category validation
- `AttributeRepository` - Attribute validation
- `HtmlSanitizer` - XSS protection
- `ProductMapper` - DTO mapping

**Key Methods**:

```java
// CRUD Operations
ProductResponse createProduct(CreateProductRequest request)
ProductResponse updateProduct(String publicId, UpdateProductRequest request)
void deleteProduct(String publicId)

// Retrieval
ProductResponse getProductById(String publicId)
ProductResponse getProductBySku(String sku)
ProductResponse getProductBySlug(String slug)
List<ProductResponse> getAllProducts()
Page<ProductResponse> getProducts(Pageable pageable)

// Search & Filter
List<ProductResponse> searchByName(String name)
List<ProductResponse> getProductsByCategory(String categoryId)
List<ProductResponse> getProductsInPriceRange(BigDecimal min, BigDecimal max)
```

**Business Logic**:
1. **HTML Sanitization**: All descriptions sanitized on create/update
2. **Slug Generation**: Auto-generated from product name if not provided
3. **Category Validation**: Ensures all category IDs exist
4. **Attribute Validation**: Verifies attribute-option relationships
5. **SKU Uniqueness**: Prevents duplicate SKUs
6. **Stock Management**: Validates stock quantity >= 0

#### HtmlSanitizer
**Package**: `com.saveitforlater.ecommerce.service`

**Library**: jsoup 1.17.2

```java
@Component
public class HtmlSanitizer {
    public String sanitizeRichText(String html) {
        if (html == null || html.isBlank()) return "";
        return Jsoup.clean(html, Safelist.relaxed());
    }
    
    public String sanitizeToPlainText(String html) {
        if (html == null || html.isBlank()) return "";
        return Jsoup.clean(html, Safelist.none());
    }
    
    public String sanitizeBasicFormatting(String html) {
        if (html == null || html.isBlank()) return "";
        return Jsoup.clean(html, Safelist.basic());
    }
}
```

**Safelist.relaxed() allows**:
- Headers: `<h1>` to `<h6>`
- Text formatting: `<strong>`, `<em>`, `<b>`, `<i>`, `<u>`
- Lists: `<ul>`, `<ol>`, `<li>`
- Links: `<a href="...">`
- Images: `<img src="..." alt="...">`
- Tables: `<table>`, `<tr>`, `<td>`, `<th>`
- Paragraphs: `<p>`, `<br>`, `<blockquote>`
- Code: `<code>`, `<pre>`

**Safelist blocks**:
- `<script>` tags
- JavaScript event handlers (onclick, onerror, etc.)
- `javascript:` URLs
- `data:` URIs
- `<iframe>` embeddings
- `<object>` and `<embed>` tags

### Repository Layer

#### ProductRepository
**Package**: `com.saveitforlater.ecommerce.domain.product`

```java
@Repository
public interface ProductRepository extends JpaRepository<Product, Long> {
    Optional<Product> findByPublicId(String publicId);
    Optional<Product> findBySku(String sku);
    Optional<Product> findBySlug(String slug);
    
    List<Product> findByNameContainingIgnoreCase(String name);
    List<Product> findByCategories_PublicId(String categoryId);
    List<Product> findByPriceBetween(BigDecimal min, BigDecimal max);
    
    boolean existsBySku(String sku);
    boolean existsBySlug(String slug);
    
    @Query("SELECT p FROM Product p LEFT JOIN FETCH p.categories WHERE p.publicId = :publicId")
    Optional<Product> findByPublicIdWithCategories(@Param("publicId") String publicId);
}
```

## API Endpoints

### Public Endpoints

#### Get All Products (Paginated)
```http
GET /api/products/paginated?page=0&size=20&sort=name,asc
```

**Response**:
```json
{
  "content": [
    {
      "id": "uuid",
      "sku": "IPHONE15-128-BLACK",
      "name": "iPhone 15 128GB Black",
      "slug": "iphone-15-128gb-black",
      "shortDescription": "Latest iPhone with A17 Pro chip...",
      "description": "<h2>Features</h2><ul>...</ul>",
      "price": 999.99,
      "salePrice": 949.99,
      "stockQuantity": 50,
      "categories": [...],
      "attributes": [...],
      "images": [...]
    }
  ],
  "pageable": {...},
  "totalPages": 5,
  "totalElements": 100
}
```

#### Get Product by ID/SKU/Slug
```http
GET /api/products/{id}
GET /api/products/sku/{sku}
GET /api/products/slug/{slug}
```

### Admin Endpoints

#### Create Product
```http
POST /api/products
Authorization: Admin
Content-Type: application/json

{
  "sku": "PROD-001",
  "name": "Product Name",
  "shortDescription": "Brief summary (max 500 chars)",
  "description": "<h2>Details</h2><p>Rich HTML content</p>",
  "price": 99.99,
  "salePrice": 79.99,
  "stockQuantity": 100,
  "categoryIds": ["category-uuid"],
  "attributes": [
    {
      "attributeId": "color-uuid",
      "options": [{"optionId": "red-uuid"}]
    }
  ]
}
```

#### Update Product
```http
PUT /api/products/{id}
Authorization: Admin
Content-Type: application/json

{
  "name": "Updated Name",
  "price": 109.99,
  ...
}
```

#### Delete Product
```http
DELETE /api/products/{id}
Authorization: Admin
```

**Response**: `204 No Content`

## Reusable Attribute System

### Concept

Instead of creating attributes per product, the system uses:
1. **Global Attributes**: Defined once (e.g., "Color", "Size", "Brand")
2. **Global Options**: Defined per attribute (e.g., "Red", "Blue" for Color)
3. **Product Assignments**: Products reference existing attribute-option pairs

### Benefits

- **Consistency**: Same "Red" across all products
- **Efficiency**: No duplicate attribute data
- **Flexibility**: Add new attributes without schema changes
- **Scalability**: Supports thousands of attribute combinations
- **Searchability**: Easy to filter by attributes

### Example

```
Attribute: Color
  └── Options: Red, Blue, Green, Black, White

Attribute: Size
  └── Options: XS, S, M, L, XL, XXL

Product: T-Shirt
  └── Color → Red
  └── Size → Large

Product: Hoodie  
  └── Color → Blue
  └── Size → XL
```

Same "Color" and "Red" used across multiple products.

## Validation Rules

### Product Creation
- ✓ SKU required, unique, max 100 chars
- ✓ Name required, max 255 chars
- ✓ Short description max 500 chars
- ✓ Description sanitized for XSS
- ✓ Price must be >= 0
- ✓ Sale price must be < price (if provided)
- ✓ Stock quantity must be >= 0
- ✓ Category IDs must exist
- ✓ Attribute-option relationships must be valid

### Product Update
- ✓ Partial updates supported
- ✓ SKU change requires uniqueness check
- ✓ Same validation rules as creation
- ✓ Null values preserve existing data

## Database Schema

```sql
CREATE TABLE product (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    public_id VARCHAR(36) UNIQUE NOT NULL,
    sku VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE,
    short_description VARCHAR(500),
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    sale_price DECIMAL(10,2),
    stock_quantity INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_sku (sku),
    INDEX idx_slug (slug),
    INDEX idx_name (name)
);

CREATE TABLE product_category (
    product_id BIGINT NOT NULL,
    category_id BIGINT NOT NULL,
    PRIMARY KEY (product_id, category_id),
    FOREIGN KEY (product_id) REFERENCES product(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES category(id) ON DELETE CASCADE
);

CREATE TABLE product_attribute_value (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT NOT NULL,
    attribute_id BIGINT NOT NULL,
    attribute_option_id BIGINT NOT NULL,
    FOREIGN KEY (product_id) REFERENCES product(id) ON DELETE CASCADE,
    FOREIGN KEY (attribute_id) REFERENCES attribute(id),
    FOREIGN KEY (attribute_option_id) REFERENCES attribute_option(id),
    UNIQUE KEY unique_product_attribute (product_id, attribute_id, attribute_option_id)
);
```

## Performance Optimization

### Indexing
- Primary key on `id`
- Unique indexes on `public_id`, `sku`, `slug`
- Foreign key indexes on junction tables
- Composite index on `product_category(product_id, category_id)`

### Query Optimization
- Pagination for list endpoints
- Lazy loading for collections (images, attributes)
- Eager loading option for categories (`@EntityGraph`)
- Custom queries with JOIN FETCH for performance

### Caching Potential
```java
@Cacheable(value = "products", key = "#publicId")
public ProductResponse getProductById(String publicId) { ... }
```

## Testing

### PowerShell Test Script
**File**: `powerShellScripts/test-product-module.ps1`

**Test Coverage**: 49 test cases
- Product CRUD operations
- Slug generation and uniqueness
- Validation (SKU, price, stock)
- Category associations
- Attribute assignments
- Search and filtering
- HTML sanitization

**Run Tests**:
```powershell
.\powerShellScripts\test-product-module.ps1
```

### Sample Test Cases
1. Create product with valid data → 201 Created
2. Create product with duplicate SKU → 409 Conflict
3. Create product with invalid price → 400 Bad Request
4. Update product with new categories → 200 OK
5. Delete product → 204 No Content
6. Get product with attributes → includes attribute details
7. Search products by name → returns matching products
8. HTML sanitization → removes <script> tags

## Common Use Cases

### 1. Create Product with Attributes
```java
CreateProductRequest request = new CreateProductRequest(
    "TSHIRT-001", "Cotton T-Shirt",
    "Comfortable cotton t-shirt",
    "<h2>Features</h2><ul><li>100% cotton</li></ul>",
    29.99, 24.99, 100,
    Set.of(categoryId),
    List.of(new AttributeAssignment(colorAttrId, List.of(redOptionId)))
);

ProductResponse product = productService.createProduct(request);
```

### 2. Update Product Price
```java
UpdateProductRequest request = new UpdateProductRequest();
request.setPrice(new BigDecimal("34.99"));
request.setSalePrice(new BigDecimal("29.99"));

productService.updateProduct(productId, request);
```

### 3. Search Products
```java
// By name
List<ProductResponse> products = productService.searchByName("iPhone");

// By category
List<ProductResponse> electronics = productService.getProductsByCategory(categoryId);

// By price range
List<ProductResponse> affordable = productService.getProductsInPriceRange(
    new BigDecimal("0"), new BigDecimal("50")
);
```

## Security Considerations

- **XSS Protection**: All HTML sanitized via jsoup
- **Authorization**: Only admins can create/update/delete
- **Input Validation**: Jakarta Bean Validation on all DTOs
- **SQL Injection**: Prevented via JPA parameterized queries

## Future Enhancements

- Product reviews and ratings
- Inventory tracking across warehouses
- Product variants (size/color combinations)
- Bulk import/export
- Product recommendations
- ElasticSearch integration for advanced search
- Product view tracking and analytics
- Wishlist functionality

---

**Related Documentation**:
- [Attribute System](./AttributeSystem.md)
- [File Storage Module](./FileStorageModule.md)
- [API Reference](../03-APIReference.md)

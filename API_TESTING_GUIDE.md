# API Testing Guide - Pagination and Filtering

## Quick Start Testing Guide

### 0. Product Creation (Admin)

#### Create Product - Full Example
```bash
curl -X POST "http://localhost:8080/api/products" \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "sku": "LAPTOP-XPS15-001",
    "name": "Dell XPS 15 Gaming Laptop",
    "slug": "dell-xps-15-gaming-laptop",
    "shortDescription": "High-performance laptop with Intel i9 processor and RTX 4070 graphics",
    "description": "<h2>Features</h2><ul><li>Intel Core i9-13900H processor</li><li>32GB DDR5 RAM</li><li>1TB NVMe SSD</li><li>NVIDIA RTX 4070 8GB</li><li>15.6 inch 4K OLED Display</li></ul>",
    "price": 2499.99,
    "salePrice": 2299.99,
    "stockQuantity": 25,
    "categoryIds": [
      "electronics-category-uuid",
      "laptops-category-uuid"
    ],
    "attributes": [
      {
        "attributeId": "color-attribute-uuid",
        "options": [
          {"optionId": "silver-option-uuid"}
        ]
      },
      {
        "attributeId": "storage-attribute-uuid",
        "options": [
          {"optionId": "1tb-option-uuid"}
        ]
      },
      {
        "attributeId": "ram-attribute-uuid",
        "options": [
          {"optionId": "32gb-option-uuid"}
        ]
      }
    ]
  }'
```

#### Create Product - Inline Attributes (No Pre-existing IDs)
```bash
curl -X POST "http://localhost:8080/api/products" \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "sku": "SMARTPHONE-001",
    "name": "Samsung Galaxy S24",
    "shortDescription": "Flagship Android smartphone",
    "price": 899.99,
    "stockQuantity": 50,
    "categoryIds": ["smartphones-uuid"],
    "attributes": [
      {
        "attributeName": "Color",
        "attributeSlug": "color",
        "attributeDescription": "Phone color",
        "options": [
          {
            "optionName": "Phantom Black",
            "optionSlug": "phantom-black",
            "optionDescription": "Black finish"
          }
        ]
      },
      {
        "attributeName": "Storage",
        "attributeSlug": "storage",
        "options": [
          {
            "optionName": "256GB",
            "optionSlug": "256gb"
          }
        ]
      }
    ]
  }'
```

#### Create Product - Minimal Example
```bash
curl -X POST "http://localhost:8080/api/products" \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "sku": "PROD-001",
    "name": "Basic Product",
    "price": 99.99,
    "stockQuantity": 100,
    "categoryIds": []
  }'
```

#### Create Product with Images (PowerShell)
```powershell
# Product data
$productData = @{
    sku = "LAPTOP-XPS15-001"
    name = "Dell XPS 15 Gaming Laptop"
    slug = "dell-xps-15-gaming-laptop"
    shortDescription = "High-performance laptop with Intel i9 processor"
    description = "<h2>Features</h2><ul><li>Intel Core i9</li><li>32GB RAM</li></ul>"
    price = 2499.99
    salePrice = 2299.99
    stockQuantity = 25
    categoryIds = @("electronics-uuid", "laptops-uuid")
    attributes = @(
        @{
            attributeId = "color-uuid"
            options = @(
                @{ optionId = "silver-uuid" }
            )
        }
    )
} | ConvertTo-Json -Compress

# Image files
$image1 = Get-Item "C:\path\to\laptop-front.jpg"
$image2 = Get-Item "C:\path\to\laptop-side.jpg"

# Create form data
$form = @{
    product = $productData
    images = $image1, $image2
    primaryImageIndex = "0"
}

# Send request
$response = Invoke-RestMethod -Uri "http://localhost:8080/api/products/with-images" `
    -Method Post `
    -Headers @{ "Authorization" = "Bearer $adminToken" } `
    -Form $form

$response | ConvertTo-Json -Depth 10
```

---

### 1. Product Filtering and Search

#### Basic Search
```bash
# Search products by name/description/SKU
curl -X GET "http://localhost:8080/api/products/search?searchTerm=laptop"
```

#### Filter by Price Range
```bash
# Products between $500 and $2000
curl -X GET "http://localhost:8080/api/products/search?minPrice=500&maxPrice=2000"

# Products under $1000
curl -X GET "http://localhost:8080/api/products/search?maxPrice=1000"

# Products over $500
curl -X GET "http://localhost:8080/api/products/search?minPrice=500"
```

#### Filter by Category
```bash
# Single category
curl -X GET "http://localhost:8080/api/products/search?categoryIds=category-uuid-1"

# Multiple categories
curl -X GET "http://localhost:8080/api/products/search?categoryIds=category-uuid-1&categoryIds=category-uuid-2"
```

#### Filter by Stock Status
```bash
# Only in-stock products
curl -X GET "http://localhost:8080/api/products/search?inStock=true"

# Only out-of-stock products
curl -X GET "http://localhost:8080/api/products/search?inStock=false"
```

#### Combined Filters with Pagination
```bash
# Search with multiple filters
curl -X GET "http://localhost:8080/api/products/search?searchTerm=laptop&minPrice=500&maxPrice=2000&inStock=true&page=0&size=10&sort=price,asc"

# Filter by categories and price
curl -X GET "http://localhost:8080/api/products/search?categoryIds=electronics-uuid&minPrice=500&maxPrice=1500&page=0&size=20"

# All parameters
curl -X GET "http://localhost:8080/api/products/search?searchTerm=laptop&categoryIds=cat-1&categoryIds=cat-2&minPrice=500&maxPrice=2000&inStock=true&page=0&size=10&sort=price,asc"
```

**Note:** Complex attribute filtering is not supported via query parameters. For advanced attribute filtering, you would need to use a POST endpoint with a JSON body.

---

### 2. Category Pagination

```bash
# Get first page of categories (20 items, sorted by name)
curl -X GET "http://localhost:8080/api/categories/paginated?page=0&size=20&sort=name,asc"

# Get second page
curl -X GET "http://localhost:8080/api/categories/paginated?page=1&size=20&sort=name,asc"

# Sort by createdAt descending
curl -X GET "http://localhost:8080/api/categories/paginated?page=0&size=10&sort=createdAt,desc"
```

---

### 3. Attribute Pagination

```bash
# Get first page of attributes
curl -X GET "http://localhost:8080/api/attributes/paginated?page=0&size=20&sort=name,asc"

# Get specific page with custom size
curl -X GET "http://localhost:8080/api/attributes/paginated?page=2&size=15&sort=name,desc"
```

---

### 4. Cart Items Pagination

**Note:** Requires authentication

```bash
# Get paginated cart items for current user
curl -X GET "http://localhost:8080/api/cart/items/paginated?page=0&size=10" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# With custom sorting
curl -X GET "http://localhost:8080/api/cart/items/paginated?page=0&size=10&sort=createdAt,desc" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

### 5. Order Pagination

#### User's Orders (Authenticated)
```bash
# Get paginated orders for current user
curl -X GET "http://localhost:8080/api/orders/my-orders/paginated?page=0&size=10" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Sort by creation date (newest first)
curl -X GET "http://localhost:8080/api/orders/my-orders/paginated?page=0&size=10&sort=createdAt,desc" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

#### All Orders (Admin Only)
```bash
# Get all orders with pagination (admin only)
curl -X GET "http://localhost:8080/api/orders/paginated?page=0&size=20&sort=createdAt,desc" \
  -H "Authorization: Bearer ADMIN_JWT_TOKEN"
```

#### Orders for Specific User (Admin Only)
```bash
# Get all orders for a specific user (admin only)
curl -X GET "http://localhost:8080/api/orders/user/{userPublicId}" \
  -H "Authorization: Bearer ADMIN_JWT_TOKEN"

# Get paginated orders for a specific user (admin only)
curl -X GET "http://localhost:8080/api/orders/user/{userPublicId}/paginated?page=0&size=10&sort=createdAt,desc" \
  -H "Authorization: Bearer ADMIN_JWT_TOKEN"
```

---

## Response Format

All paginated endpoints return a `Page` object with the following structure:

```json
{
  "content": [
    // Array of items
  ],
  "pageable": {
    "sort": {
      "empty": false,
      "sorted": true,
      "unsorted": false
    },
    "offset": 0,
    "pageNumber": 0,
    "pageSize": 20,
    "paged": true,
    "unpaged": false
  },
  "totalPages": 5,
  "totalElements": 100,
  "last": false,
  "size": 20,
  "number": 0,
  "sort": {
    "empty": false,
    "sorted": true,
    "unsorted": false
  },
  "numberOfElements": 20,
  "first": true,
  "empty": false
}
```

### Key Response Fields:
- `content`: Array of actual data items
- `totalPages`: Total number of pages
- `totalElements`: Total number of items across all pages
- `number`: Current page number (0-indexed)
- `size`: Page size
- `first`: Is this the first page?
- `last`: Is this the last page?
- `empty`: Is the page empty?

---

## Pagination Parameters

### Common Query Parameters

| Parameter | Description | Example | Default |
|-----------|-------------|---------|---------|
| `page` | Page number (0-indexed) | `page=0` | 0 |
| `size` | Items per page | `size=20` | 20 |
| `sort` | Sort field and direction | `sort=name,asc` | Varies |

### Multiple Sort Fields
```bash
# Sort by price ascending, then name ascending
curl -X GET "http://localhost:8080/api/products/paginated?sort=price,asc&sort=name,asc"
```

---

## Testing with PowerShell

### Product Search Test
```powershell
# Simple search
Invoke-RestMethod -Uri "http://localhost:8080/api/products/search?searchTerm=laptop" `
    -Method Get

# Search with filters
$uri = "http://localhost:8080/api/products/search?" +
       "searchTerm=laptop&" +
       "minPrice=500&" +
       "maxPrice=2000&" +
       "inStock=true&" +
       "categoryIds=category-uuid-1&" +
       "page=0&size=10&sort=price,asc"

Invoke-RestMethod -Uri $uri -Method Get
```

### Get Paginated Categories
```powershell
Invoke-RestMethod -Uri "http://localhost:8080/api/categories/paginated?page=0&size=20" `
    -Method Get
```

### Get Cart Items (with auth)
```powershell
$headers = @{
    "Authorization" = "Bearer YOUR_JWT_TOKEN"
}

Invoke-RestMethod -Uri "http://localhost:8080/api/cart/items/paginated?page=0&size=10" `
    -Method Get `
    -Headers $headers
```

---

## Performance Tips

1. **Use appropriate page sizes:**
   - Small screens/mobile: 10-15 items
   - Desktop: 20-50 items
   - Never go above 100

2. **Sort strategically:**
   - Default sorts should be the most commonly used
   - Consider database indexes for sort fields

3. **Filter early:**
   - Apply filters to reduce dataset before pagination
   - Combine multiple filters in single request

4. **Cache when possible:**
   - First page results are good candidates for caching
   - Category and attribute lists change infrequently

---

## Common Use Cases

### E-commerce Product Listing
```bash
# Get products in "Electronics" category, under $1000, in stock
curl -X GET "http://localhost:8080/api/products/search?categoryIds=electronics-uuid&maxPrice=1000&inStock=true&page=0&size=20&sort=price,asc"
```

### Admin Order Management
```bash
# Get recent orders (admin view)
curl -X GET "http://localhost:8080/api/orders/paginated?page=0&size=50&sort=createdAt,desc" \
  -H "Authorization: Bearer ADMIN_TOKEN"

# Get orders for a specific user (admin view)
curl -X GET "http://localhost:8080/api/orders/user/user-uuid-123/paginated?page=0&size=20&sort=createdAt,desc" \
  -H "Authorization: Bearer ADMIN_TOKEN"
```

### User Order History
```bash
# User's order history (newest first)
curl -X GET "http://localhost:8080/api/orders/my-orders/paginated?page=0&size=10&sort=createdAt,desc" \
  -H "Authorization: Bearer USER_TOKEN"
```

### Attribute Management UI
```bash
# Load attributes for admin panel
curl -X GET "http://localhost:8080/api/attributes/paginated?page=0&size=50&sort=name,asc"
```

---

## Error Handling

### Invalid Page Number
```json
{
  "error": "Bad Request",
  "message": "Page number cannot be negative",
  "status": 400
}
```

### Invalid Sort Field
Returns empty results or uses default sorting (implementation dependent)

### Authentication Required
```json
{
  "error": "Unauthorized",
  "message": "Full authentication is required",
  "status": 401
}
```

---

## Next Steps

1. **Start Server:**
   ```bash
   .\mvnw.cmd spring-boot:run
   ```

2. **Create Test Data:**
   - Use existing PowerShell scripts in `powerShellScripts/` folder
   - Or create products/categories via admin endpoints

3. **Test Endpoints:**
   - Start with simple pagination (categories, attributes)
   - Move to product search with filters
   - Test cart and order pagination with authenticated users

4. **Monitor Performance:**
   - Check query execution time
   - Monitor database queries (enable SQL logging if needed)
   - Test with larger datasets

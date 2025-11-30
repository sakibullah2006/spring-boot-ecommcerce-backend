# API Reference

## Base URL
```
http://localhost:8080/api
```

## Authentication

All authenticated endpoints require a valid session cookie obtained through login.

### Register User
```http
POST /auth/register
Content-Type: application/json

{
  "firstName": "John",
  "lastName": "Doe",
  "email": "john.doe@example.com",
  "password": "SecurePass123!"
}
```

**Response**: `201 Created`
```json
{
  "id": "uuid",
  "email": "john.doe@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "role": "CUSTOMER"
}
```

### Login
```http
POST /auth/login
Content-Type: application/json

{
  "email": "john.doe@example.com",
  "password": "SecurePass123!"
}
```

**Response**: `200 OK` + Session Cookie

### Logout
```http
POST /auth/logout
```

**Response**: `200 OK`

---

## Product API

### Get All Products (Paginated)
```http
GET /products/paginated?page=0&size=20&sort=name,asc
```

**Response**: `200 OK`
```json
{
  "content": [
    {
      "id": "uuid",
      "sku": "IPHONE15-128-BLACK",
      "name": "iPhone 15 128GB Black",
      "slug": "iphone-15-128gb-black",
      "shortDescription": "Latest iPhone with A17 Pro chip...",
      "description": "<h2>Features</h2><ul><li>...</li></ul>",
      "price": 999.99,
      "salePrice": 949.99,
      "stockQuantity": 50,
      "categories": [...],
      "attributes": [...],
      "images": [...]
    }
  ],
  "page": 0,
  "size": 20,
  "totalElements": 100,
  "totalPages": 5
}
```

### Get Product by ID
```http
GET /products/{id}
```

### Get Product by SKU
```http
GET /products/sku/{sku}
```

### Get Product by Slug
```http
GET /products/slug/{slug}
```

### Create Product (Admin Only)
```http
POST /products
Authorization: Required
Content-Type: application/json

{
  "sku": "PROD-001",
  "name": "Product Name",
  "shortDescription": "Brief description",
  "description": "<p>Rich HTML description</p>",
  "price": 99.99,
  "salePrice": 79.99,
  "stockQuantity": 100,
  "categoryIds": ["category-uuid"],
  "attributes": [
    {
      "attributeId": "attr-uuid",
      "options": [
        {"optionId": "option-uuid"}
      ]
    }
  ]
}
```

**Response**: `201 Created`

### Update Product (Admin Only)
```http
PUT /products/{id}
Content-Type: application/json

{
  "name": "Updated Name",
  "price": 109.99,
  ...
}
```

### Delete Product (Admin Only)
```http
DELETE /products/{id}
```

**Response**: `204 No Content`

---

## Category API

### Get All Categories
```http
GET /categories
```

### Get Category by ID
```http
GET /categories/{id}
```

### Get Category by Slug
```http
GET /categories/slug/{slug}
```

### Create Category (Admin Only)
```http
POST /categories
Content-Type: application/json

{
  "name": "Electronics",
  "description": "Electronic devices",
  "parentCategoryId": null
}
```

### Update Category (Admin Only)
```http
PUT /categories/{id}
```

### Delete Category (Admin Only)
```http
DELETE /categories/{id}
```

---

## Cart API

### Get My Cart
```http
GET /cart
Authorization: Required
```

**Response**: `200 OK`
```json
{
  "id": "cart-uuid",
  "items": [
    {
      "id": "item-uuid",
      "productId": "product-uuid",
      "productName": "iPhone 15",
      "productSku": "IPHONE15-128",
      "unitPrice": 999.99,
      "quantity": 2,
      "subtotal": 1999.98
    }
  ],
  "totalItems": 2,
  "totalAmount": 1999.98
}
```

### Add Item to Cart
```http
POST /cart/items
Authorization: Required
Content-Type: application/json

{
  "productId": "product-uuid",
  "quantity": 2
}
```

**Response**: `201 Created` (returns updated cart)

### Update Cart Item Quantity
```http
PUT /cart/items/{cartItemId}
Content-Type: application/json

{
  "quantity": 5
}
```

### Remove Item from Cart
```http
DELETE /cart/items/{cartItemId}
```

**Response**: `200 OK` (returns updated cart)

### Clear Cart
```http
DELETE /cart
```

---

## Order API

### Create Order
```http
POST /orders
Authorization: Required
Content-Type: application/json

{
  "shippingAddress": {
    "addressLine1": "123 Main St",
    "addressLine2": "Apt 4B",
    "city": "New York",
    "state": "NY",
    "postalCode": "10001",
    "country": "USA"
  },
  "billingAddress": {
    "addressLine1": "123 Main St",
    "city": "New York",
    "state": "NY",
    "postalCode": "10001",
    "country": "USA"
  },
  "customerEmail": "customer@example.com",
  "customerPhone": "+1234567890",
  "notes": "Optional delivery notes",
  "paymentMethod": "CREDIT_CARD"
}
```

**Response**: `201 Created`
```json
{
  "id": "order-uuid",
  "orderNumber": "ORD-20251130-4020",
  "status": "PENDING",
  "totalAmount": 1999.98,
  "items": [...],
  "payment": {
    "paymentStatus": "PENDING"
  }
}
```

### Process Payment
```http
POST /orders/{orderId}/pay
Content-Type: application/json

{
  "paymentDetails": {
    "cardNumber": "4111111111111111",
    "cardHolderName": "John Doe",
    "expiryMonth": "12",
    "expiryYear": "2025",
    "cvv": "123"
  }
}
```

**Response**: `200 OK` (order status changes to CONFIRMED on success)

### Get My Orders
```http
GET /orders/my-orders?page=0&size=20
Authorization: Required
```

### Get Order by ID
```http
GET /orders/{id}
Authorization: Required (Owner or Admin)
```

### Get All Orders (Admin Only)
```http
GET /orders?page=0&size=20
Authorization: Admin
```

### Update Order Status (Admin Only)
```http
PATCH /orders/{id}/status?status=SHIPPED
Authorization: Admin
```

### Update Payment Status (Admin Only)
```http
PATCH /orders/{id}/payment-status?paymentStatus=COMPLETED
Authorization: Admin
```

---

## Attribute API

### Get All Attributes
```http
GET /attributes
```

### Get Attribute by ID
```http
GET /attributes/{id}
```

### Create Attribute (Admin Only)
```http
POST /attributes
Content-Type: application/json

{
  "name": "Color",
  "description": "Product color options"
}
```

### Update Attribute (Admin Only)
```http
PUT /attributes/{id}
Content-Type: application/json

{
  "name": "Color",
  "description": "Updated description",
  "isActive": true
}
```

### Deactivate Attribute (Admin Only)
```http
DELETE /attributes/{id}
```

### Get Attribute Options
```http
GET /attributes/{attributeId}/options
```

### Create Attribute Option (Admin Only)
```http
POST /attributes/{attributeId}/options
Content-Type: application/json

{
  "name": "Red",
  "description": "Red color variant"
}
```

### Update Attribute Option (Admin Only)
```http
PUT /attributes/options/{optionId}
Content-Type: application/json

{
  "name": "Red",
  "description": "Updated description",
  "isActive": true
}
```

---

## File Storage API

### Upload Product Image (Admin Only)
```http
POST /files/products/{productId}/images
Authorization: Admin
Content-Type: multipart/form-data

Parameters:
- file: (binary)
- isPrimary: true
- displayOrder: 0
- altText: "Product image"
```

**Response**: `201 Created`
```json
{
  "publicId": "image-uuid",
  "fileName": "uuid.jpg",
  "fileUrl": "/api/files/images/image-uuid",
  "isPrimary": true,
  "displayOrder": 0,
  "altText": "Product image"
}
```

### Get Product Images
```http
GET /files/products/{productId}/images
```

### Get Image File
```http
GET /files/images/{imageId}
```

**Response**: Binary image file

### Update Image Metadata (Admin Only)
```http
PATCH /files/images/{imageId}
Content-Type: application/json

{
  "isPrimary": true,
  "displayOrder": 1,
  "altText": "Updated alt text"
}
```

### Delete Image (Admin Only)
```http
DELETE /files/images/{imageId}
```

### Delete All Product Images (Admin Only)
```http
DELETE /files/products/{productId}/images
```

---

## Error Responses

All errors follow RFC 7807 Problem Details format:

```json
{
  "type": "https://api.ecommerce.com/errors/resource-not-found",
  "title": "Resource Not Found",
  "status": 404,
  "detail": "Product with ID 'abc123' not found",
  "instance": "/api/products/abc123",
  "timestamp": "2025-11-30T10:00:00Z"
}
```

### Common Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created |
| 204 | No Content (successful deletion) |
| 400 | Bad Request (validation error) |
| 401 | Unauthorized (not logged in) |
| 403 | Forbidden (insufficient permissions) |
| 404 | Not Found |
| 409 | Conflict (duplicate resource) |
| 500 | Internal Server Error |

---

## Payment Methods

| Method | Value |
|--------|-------|
| Credit Card | `CREDIT_CARD` |
| Debit Card | `DEBIT_CARD` |
| PayPal | `PAYPAL` |
| Bank Transfer | `BANK_TRANSFER` |
| Cash on Delivery | `CASH_ON_DELIVERY` |

---

## Test Cards (Development)

| Card Number | Result |
|-------------|--------|
| 4111111111111111 | ✅ Success (VISA) |
| 5111111111111111 | ✅ Success (Mastercard) |
| 3111111111111111 | ✅ Success (AMEX) |
| xxxxxxxxxxxx0000 | ❌ Failed (any ending in 0000) |

---

**Related Documentation**:
- [Product Module](./modules/ProductModule.md)
- [Cart Module](./modules/CartModule.md)
- [Order Module](./modules/OrderModule.md)
- [File Storage Module](./modules/FileStorageModule.md)

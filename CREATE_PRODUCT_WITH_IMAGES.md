# Create Product with Images - Usage Guide

## Overview
You can now create a product and upload multiple images in a single request using the new `/api/products/with-images` endpoint.

## Endpoint

```
POST /api/products/with-images
Content-Type: multipart/form-data
Authorization: Bearer {ADMIN_TOKEN}
```

## Request Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `product` | String (JSON) | Yes | Product details as JSON string |
| `images` | MultipartFile[] | No | Array of image files |
| `primaryImageIndex` | Integer | No | Index of primary image (default: 0) |

## Product JSON Structure

The `product` parameter should be a JSON string with the following structure:

```json
{
  "sku": "PROD-001",
  "name": "Product Name",
  "slug": "product-name",
  "description": "Product description",
  "price": 99.99,
  "salePrice": 89.99,
  "stockQuantity": 100,
  "categoryIds": ["category-uuid-1", "category-uuid-2"],
  "attributes": [
    {
      "attributeId": "attr-uuid-1",
      "optionId": "option-uuid-1"
    }
  ]
}
```

## Usage Examples

### 1. Using cURL

```bash
# Create product with 3 images, second one as primary
curl -X POST http://localhost:8080/api/products/with-images \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -F 'product={
    "sku": "LAPTOP-001",
    "name": "Gaming Laptop",
    "description": "High-performance gaming laptop",
    "price": 1299.99,
    "salePrice": 1199.99,
    "stockQuantity": 50,
    "categoryIds": ["electronics-uuid"]
  }' \
  -F "images=@/path/to/image1.jpg" \
  -F "images=@/path/to/image2.jpg" \
  -F "images=@/path/to/image3.jpg" \
  -F "primaryImageIndex=1"
```

### 2. Using PowerShell

```powershell
# Configuration
$baseUrl = "http://localhost:8080"
$adminToken = "YOUR_ADMIN_TOKEN_HERE"

# Product data
$productData = @{
    sku = "LAPTOP-001"
    name = "Gaming Laptop"
    description = "High-performance gaming laptop"
    price = 1299.99
    salePrice = 1199.99
    stockQuantity = 50
    categoryIds = @("electronics-uuid")
} | ConvertTo-Json -Compress

# Image files
$image1 = Get-Item "C:\path\to\image1.jpg"
$image2 = Get-Item "C:\path\to\image2.jpg"
$image3 = Get-Item "C:\path\to\image3.jpg"

# Create form data
$form = @{
    product = $productData
    images = $image1, $image2, $image3
    primaryImageIndex = "1"
}

# Send request
$response = Invoke-RestMethod -Uri "$baseUrl/api/products/with-images" `
    -Method Post `
    -Headers @{ "Authorization" = "Bearer $adminToken" } `
    -Form $form

# Display response
$response | ConvertTo-Json -Depth 10
```

### 3. Using JavaScript/Fetch API

```javascript
async function createProductWithImages(productData, imageFiles, primaryIndex = 0) {
  const formData = new FormData();
  
  // Add product data as JSON string
  formData.append('product', JSON.stringify(productData));
  
  // Add image files
  imageFiles.forEach(file => {
    formData.append('images', file);
  });
  
  // Set primary image index
  formData.append('primaryImageIndex', primaryIndex);
  
  const response = await fetch('http://localhost:8080/api/products/with-images', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${adminToken}`
    },
    body: formData
  });
  
  return await response.json();
}

// Usage
const productData = {
  sku: 'LAPTOP-001',
  name: 'Gaming Laptop',
  description: 'High-performance gaming laptop',
  price: 1299.99,
  salePrice: 1199.99,
  stockQuantity: 50,
  categoryIds: ['electronics-uuid']
};

const imageFiles = [
  document.getElementById('image1').files[0],
  document.getElementById('image2').files[0],
  document.getElementById('image3').files[0]
];

createProductWithImages(productData, imageFiles, 1)
  .then(product => console.log('Product created:', product))
  .catch(error => console.error('Error:', error));
```

### 4. Using React with Axios

```jsx
import React, { useState } from 'react';
import axios from 'axios';

function CreateProductWithImages() {
  const [product, setProduct] = useState({
    sku: '',
    name: '',
    description: '',
    price: 0,
    salePrice: 0,
    stockQuantity: 0,
    categoryIds: []
  });
  const [images, setImages] = useState([]);
  const [primaryIndex, setPrimaryIndex] = useState(0);

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    const formData = new FormData();
    formData.append('product', JSON.stringify(product));
    
    images.forEach(image => {
      formData.append('images', image);
    });
    
    formData.append('primaryImageIndex', primaryIndex);
    
    try {
      const response = await axios.post(
        'http://localhost:8080/api/products/with-images',
        formData,
        {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('adminToken')}`,
            'Content-Type': 'multipart/form-data'
          }
        }
      );
      
      console.log('Product created:', response.data);
      alert('Product created successfully!');
    } catch (error) {
      console.error('Error creating product:', error);
      alert('Failed to create product');
    }
  };

  const handleImageChange = (e) => {
    setImages(Array.from(e.target.files));
  };

  return (
    <form onSubmit={handleSubmit}>
      <input
        type="text"
        placeholder="SKU"
        value={product.sku}
        onChange={(e) => setProduct({...product, sku: e.target.value})}
        required
      />
      
      <input
        type="text"
        placeholder="Product Name"
        value={product.name}
        onChange={(e) => setProduct({...product, name: e.target.value})}
        required
      />
      
      <textarea
        placeholder="Description"
        value={product.description}
        onChange={(e) => setProduct({...product, description: e.target.value})}
      />
      
      <input
        type="number"
        placeholder="Price"
        value={product.price}
        onChange={(e) => setProduct({...product, price: parseFloat(e.target.value)})}
        required
      />
      
      <input
        type="number"
        placeholder="Sale Price"
        value={product.salePrice}
        onChange={(e) => setProduct({...product, salePrice: parseFloat(e.target.value)})}
        required
      />
      
      <input
        type="number"
        placeholder="Stock Quantity"
        value={product.stockQuantity}
        onChange={(e) => setProduct({...product, stockQuantity: parseInt(e.target.value)})}
        required
      />
      
      <input
        type="file"
        multiple
        accept="image/*"
        onChange={handleImageChange}
      />
      
      <select 
        value={primaryIndex} 
        onChange={(e) => setPrimaryIndex(parseInt(e.target.value))}
      >
        {images.map((_, index) => (
          <option key={index} value={index}>
            Image {index + 1} as Primary
          </option>
        ))}
      </select>
      
      <button type="submit">Create Product with Images</button>
    </form>
  );
}

export default CreateProductWithImages;
```

### 5. Complete PowerShell Test Script

Create `test-create-product-with-images.ps1`:

```powershell
# Configuration
$baseUrl = "http://localhost:8080"
$adminToken = "YOUR_ADMIN_TOKEN_HERE"

# Product data
$productData = @{
    sku = "TEST-LAPTOP-$(Get-Date -Format 'yyyyMMddHHmmss')"
    name = "Test Gaming Laptop"
    slug = "test-gaming-laptop"
    description = "High-performance gaming laptop with RGB lighting"
    price = 1299.99
    salePrice = 1199.99
    stockQuantity = 50
    categoryIds = @()  # Add category UUIDs if you have them
    attributes = @()   # Add attributes if needed
} | ConvertTo-Json -Compress

Write-Host "Product Data:" -ForegroundColor Cyan
$productData | ConvertFrom-Json | ConvertTo-Json -Depth 10

# Prepare image files (replace with actual paths)
$imagePaths = @(
    "C:\path\to\laptop-front.jpg",
    "C:\path\to\laptop-side.jpg",
    "C:\path\to\laptop-back.jpg"
)

# Check if files exist
$imageFiles = @()
foreach ($path in $imagePaths) {
    if (Test-Path $path) {
        $imageFiles += Get-Item $path
        Write-Host "✓ Found image: $path" -ForegroundColor Green
    } else {
        Write-Host "✗ Image not found: $path" -ForegroundColor Red
    }
}

if ($imageFiles.Count -eq 0) {
    Write-Host "No images found. Please update image paths." -ForegroundColor Red
    exit
}

# Create form data
$form = @{
    product = $productData
    images = $imageFiles
    primaryImageIndex = "0"  # First image is primary
}

Write-Host "`nCreating product with $($imageFiles.Count) image(s)..." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/products/with-images" `
        -Method Post `
        -Headers @{ "Authorization" = "Bearer $adminToken" } `
        -Form $form
    
    Write-Host "✓ Product created successfully!" -ForegroundColor Green
    Write-Host "`nProduct Details:" -ForegroundColor Cyan
    $response | ConvertTo-Json -Depth 10
    
    $productId = $response.id
    
    # Fetch and display images
    Write-Host "`nFetching product images..." -ForegroundColor Yellow
    $images = Invoke-RestMethod -Uri "$baseUrl/api/files/products/$productId/images"
    
    Write-Host "✓ Found $($images.Count) image(s):" -ForegroundColor Green
    foreach ($img in $images) {
        $primaryTag = if ($img.isPrimary) { " [PRIMARY]" } else { "" }
        Write-Host "  - $($img.imageUrl)$primaryTag" -ForegroundColor Gray
    }
    
} catch {
    Write-Host "✗ Failed to create product" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails) {
        Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
}
```

## Response Example

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "sku": "LAPTOP-001",
  "name": "Gaming Laptop",
  "slug": "gaming-laptop",
  "description": "High-performance gaming laptop",
  "price": 1299.99,
  "salePrice": 1199.99,
  "stockQuantity": 50,
  "categories": [],
  "attributes": [],
  "images": []
}
```

Note: The `images` array in the response will be empty initially. To fetch images, use:
```
GET /api/files/products/{productId}/images
```

## Image Requirements

- **Allowed formats:** JPEG, PNG, GIF, WebP
- **Max file size:** 10MB per image
- **Max request size:** 10MB total

## Error Handling

### Common Errors

**400 Bad Request**
```json
{
  "title": "Invalid File Type",
  "detail": "Invalid file type. Expected image but got: application/pdf",
  "status": 400
}
```

**413 Payload Too Large**
```json
{
  "title": "File Too Large",
  "detail": "File size exceeds maximum allowed size of 10485760 bytes",
  "status": 413
}
```

**500 Internal Server Error**
```json
{
  "title": "File Storage Error",
  "detail": "Failed to store file: image.jpg",
  "status": 500
}
```

## Comparison: Two Approaches

### Approach 1: Separate Requests (Original)

**Step 1:** Create product
```bash
POST /api/products
Body: { "sku": "PROD-001", ... }
Response: { "id": "product-uuid", ... }
```

**Step 2:** Upload images
```bash
POST /api/files/products/{product-uuid}/images
Body: multipart with image file
```

**Pros:** Clean separation, easier to test individual parts  
**Cons:** Requires multiple requests, more complex for clients

### Approach 2: Single Request (New)

**Single Step:** Create product with images
```bash
POST /api/products/with-images
Body: multipart with product JSON + image files
Response: { "id": "product-uuid", ... }
```

**Pros:** Single request, simpler client code, atomic operation  
**Cons:** Slightly more complex request structure

## Best Practices

1. **Always validate images on client side** before sending to reduce errors
2. **Use appropriate image sizes** - compress images before upload
3. **Set meaningful primary image** - usually the main product view
4. **Handle errors gracefully** - provide user feedback
5. **Consider image order** - first image is index 0
6. **Test with different image formats** - ensure compatibility

## Testing Checklist

- [ ] Create product without images
- [ ] Create product with single image
- [ ] Create product with multiple images
- [ ] Set different images as primary (index 0, 1, 2, etc.)
- [ ] Test with maximum allowed file size
- [ ] Test with oversized file (should fail)
- [ ] Test with invalid file type (should fail)
- [ ] Verify images are accessible after creation
- [ ] Verify primary image is correctly marked

## Troubleshooting

### Issue: "Invalid file type" error
**Solution:** Ensure you're uploading JPEG, PNG, GIF, or WebP files

### Issue: "File too large" error
**Solution:** Compress images or increase limit in `application.yml`

### Issue: Product created but images failed
**Solution:** Check server logs for details. The product will exist but without images. You can upload images separately using `/api/files/products/{id}/images`

### Issue: Primary image index out of bounds
**Solution:** Ensure `primaryImageIndex` is less than the number of images (0-based index)

## Migration from Old Approach

If you have existing code using the two-step approach:

**Before:**
```javascript
// Create product
const product = await createProduct(productData);
// Upload images separately
await uploadImage(product.id, image1);
await uploadImage(product.id, image2);
```

**After:**
```javascript
// Create product with images in one call
const product = await createProductWithImages(productData, [image1, image2]);
```

Both approaches remain valid - use whichever fits your use case better!

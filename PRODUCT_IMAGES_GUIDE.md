# Product Image Management - Quick Start Guide

## Overview
You now have a complete, reusable file storage system for managing product images. This guide will help you test and use the new features.

## What Was Implemented

### ✅ Database Tables
- `file_metadata` - Stores file information (reusable for any entity)
- `product_image` - Links products to images with metadata

### ✅ Core Services
- **FileStorageService** (Reusable) - Handles file operations on local filesystem
- **ProductImageService** - Manages product images specifically

### ✅ API Endpoints
All endpoints are available at `http://localhost:8080/api/files/`

### ✅ Configuration
- Upload directory: `uploads/products/`
- Max file size: 10MB
- Allowed types: JPEG, PNG, GIF, WebP

## Testing the Features

### 1. Upload a Product Image

First, you need a product. Create one or use an existing product ID.

**Upload Image (Admin Only):**
```bash
curl -X POST http://localhost:8080/api/files/products/{productPublicId}/images \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -F "file=@C:/path/to/your/image.jpg" \
  -F "isPrimary=true" \
  -F "displayOrder=0" \
  -F "altText=Product main image"
```

**Using PowerShell:**
```powershell
$productId = "your-product-public-id"
$imagePath = "C:\path\to\your\image.jpg"

# Upload image
$response = Invoke-RestMethod -Uri "http://localhost:8080/api/files/products/$productId/images" `
  -Method Post `
  -Headers @{ "Authorization" = "Bearer YOUR_ADMIN_TOKEN" } `
  -Form @{
    file = Get-Item -Path $imagePath
    isPrimary = "true"
    displayOrder = "0"
    altText = "Product main image"
  }

$response | ConvertTo-Json
```

### 2. Get All Images for a Product (Public Access)

```bash
curl http://localhost:8080/api/files/products/{productPublicId}/images
```

**PowerShell:**
```powershell
$productId = "your-product-public-id"
$images = Invoke-RestMethod -Uri "http://localhost:8080/api/files/products/$productId/images"
$images | ConvertTo-Json
```

### 3. Get Primary Image (Public Access)

```bash
curl http://localhost:8080/api/files/products/{productPublicId}/images/primary
```

### 4. View Image in Browser

Simply open: `http://localhost:8080/api/files/images/{imagePublicId}`

Or use in HTML:
```html
<img src="http://localhost:8080/api/files/images/{imagePublicId}" alt="Product" />
```

### 5. Update Image Metadata (Admin Only)

```bash
curl -X PATCH http://localhost:8080/api/files/images/{imagePublicId} \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "isPrimary": true,
    "displayOrder": 1,
    "altText": "Updated alt text"
  }'
```

### 6. Delete an Image (Admin Only)

```bash
curl -X DELETE http://localhost:8080/api/files/images/{imagePublicId} \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

### 7. Delete All Product Images (Admin Only)

```bash
curl -X DELETE http://localhost:8080/api/files/products/{productPublicId}/images \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

## Complete Workflow Example

### PowerShell Script to Test Everything

Create a file `test-product-images.ps1`:

```powershell
# Configuration
$baseUrl = "http://localhost:8080"
$adminToken = "YOUR_ADMIN_TOKEN_HERE"
$productId = "YOUR_PRODUCT_ID_HERE"
$imagePath = "C:\path\to\test-image.jpg"

# Headers
$headers = @{
    "Authorization" = "Bearer $adminToken"
}

Write-Host "=== Testing Product Image Management ===" -ForegroundColor Green

# 1. Upload primary image
Write-Host "`n1. Uploading primary image..." -ForegroundColor Yellow
try {
    $uploadResponse = Invoke-RestMethod -Uri "$baseUrl/api/files/products/$productId/images" `
        -Method Post `
        -Headers $headers `
        -Form @{
            file = Get-Item -Path $imagePath
            isPrimary = "true"
            displayOrder = "0"
            altText = "Main product image"
        }
    
    $imageId = $uploadResponse.publicId
    Write-Host "✓ Image uploaded successfully. ID: $imageId" -ForegroundColor Green
    $uploadResponse | ConvertTo-Json
} catch {
    Write-Host "✗ Failed to upload image: $_" -ForegroundColor Red
    exit
}

# 2. Get all images for the product
Write-Host "`n2. Getting all product images..." -ForegroundColor Yellow
try {
    $images = Invoke-RestMethod -Uri "$baseUrl/api/files/products/$productId/images"
    Write-Host "✓ Found $($images.Count) image(s)" -ForegroundColor Green
    $images | ConvertTo-Json
} catch {
    Write-Host "✗ Failed to get images: $_" -ForegroundColor Red
}

# 3. Get primary image
Write-Host "`n3. Getting primary image..." -ForegroundColor Yellow
try {
    $primaryImage = Invoke-RestMethod -Uri "$baseUrl/api/files/products/$productId/images/primary"
    Write-Host "✓ Primary image retrieved" -ForegroundColor Green
    $primaryImage | ConvertTo-Json
} catch {
    Write-Host "✗ Failed to get primary image: $_" -ForegroundColor Red
}

# 4. Update image metadata
Write-Host "`n4. Updating image metadata..." -ForegroundColor Yellow
try {
    $updateBody = @{
        altText = "Updated product image"
        displayOrder = 1
    } | ConvertTo-Json
    
    $updated = Invoke-RestMethod -Uri "$baseUrl/api/files/images/$imageId" `
        -Method Patch `
        -Headers (@{
            "Authorization" = "Bearer $adminToken"
            "Content-Type" = "application/json"
        }) `
        -Body $updateBody
    
    Write-Host "✓ Image metadata updated" -ForegroundColor Green
    $updated | ConvertTo-Json
} catch {
    Write-Host "✗ Failed to update image: $_" -ForegroundColor Red
}

# 5. View image URL
Write-Host "`n5. Image URL for viewing:" -ForegroundColor Yellow
Write-Host "$baseUrl/api/files/images/$imageId" -ForegroundColor Cyan
Write-Host "Open this URL in your browser to see the image" -ForegroundColor Gray

# 6. Get product details (should include images in future)
Write-Host "`n6. Getting product details..." -ForegroundColor Yellow
try {
    $product = Invoke-RestMethod -Uri "$baseUrl/api/products/$productId"
    Write-Host "✓ Product retrieved" -ForegroundColor Green
    $product | ConvertTo-Json
} catch {
    Write-Host "✗ Failed to get product: $_" -ForegroundColor Red
}

Write-Host "`n=== Test completed ===" -ForegroundColor Green
Write-Host "`nNote: To delete the image, run:" -ForegroundColor Gray
Write-Host "Invoke-RestMethod -Uri '$baseUrl/api/files/images/$imageId' -Method Delete -Headers @{'Authorization'='Bearer $adminToken'}" -ForegroundColor Gray
```

## Frontend Integration Example

### React Component Example

```jsx
import React, { useState, useEffect } from 'react';

function ProductImages({ productId }) {
  const [images, setImages] = useState([]);
  const [selectedFile, setSelectedFile] = useState(null);

  useEffect(() => {
    fetchImages();
  }, [productId]);

  const fetchImages = async () => {
    const response = await fetch(
      `http://localhost:8080/api/files/products/${productId}/images`
    );
    const data = await response.json();
    setImages(data);
  };

  const uploadImage = async () => {
    const formData = new FormData();
    formData.append('file', selectedFile);
    formData.append('isPrimary', 'false');
    formData.append('displayOrder', images.length);

    const response = await fetch(
      `http://localhost:8080/api/files/products/${productId}/images`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        },
        body: formData
      }
    );

    if (response.ok) {
      fetchImages();
      setSelectedFile(null);
    }
  };

  return (
    <div>
      <h3>Product Images</h3>
      
      {/* Display Images */}
      <div className="image-gallery">
        {images.map(img => (
          <img 
            key={img.publicId}
            src={img.imageUrl}
            alt={img.altText}
            style={{ width: '200px', margin: '10px' }}
          />
        ))}
      </div>

      {/* Upload Form */}
      <div>
        <input 
          type="file" 
          accept="image/*"
          onChange={(e) => setSelectedFile(e.target.files[0])}
        />
        <button onClick={uploadImage} disabled={!selectedFile}>
          Upload Image
        </button>
      </div>
    </div>
  );
}
```

## File Storage Location

Images are stored at: `{project-root}/uploads/products/`

Each file gets a unique UUID-based name, e.g., `123e4567-e89b-12d3-a456-426614174000.jpg`

## Security Notes

- **Upload/Delete**: Requires ADMIN role
- **View/Download**: Public access
- **File Validation**: Only images allowed, max 10MB
- **Path Protection**: Prevents directory traversal attacks

## Troubleshooting

### Issue: "File too large"
**Solution:** Adjust in `application.yml`:
```yaml
spring:
  servlet:
    multipart:
      max-file-size: 20MB
      max-request-size: 20MB
app:
  file:
    max-size: 20971520  # 20MB in bytes
```

### Issue: "Invalid file type"
**Solution:** Only JPEG, PNG, GIF, and WebP are allowed. Check the file extension.

### Issue: "Upload directory not found"
**Solution:** The directory is created automatically. Check permissions if running on Linux/Mac.

## Next Steps

1. Test uploading images to your existing products
2. Display images on your frontend
3. Consider extending to other entities (categories, user avatars)
4. Implement image resizing/optimization (future enhancement)
5. Add cloud storage support (AWS S3, Azure Blob) when ready for production

## API Documentation

Full endpoint documentation is available in `FILE_STORAGE_MODULE.md`

## Questions?

Check the comprehensive documentation in:
- `FILE_STORAGE_MODULE.md` - Complete module documentation
- Database migration: `src/main/resources/db/migration/V8__Create_File_Storage_Tables.sql`
- Source code: `src/main/java/com/saveitforlater/ecommerce/domain/file/`

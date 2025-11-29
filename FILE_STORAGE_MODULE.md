# File Storage Module

## Overview
This is a reusable file storage module for the Spring Boot e-commerce application. It provides a comprehensive solution for managing files, particularly product images, using the local file system.

## Architecture

### Core Components

1. **FileStorageService** (Reusable Core)
   - Location: `domain/file/FileStorageService.java`
   - Purpose: Generic file storage operations on local file system
   - Can be reused for any file type (images, documents, videos, etc.)
   - Features:
     - Store files with unique names
     - Support for subdirectories
     - File validation (type, size)
     - File retrieval and deletion
     - Configurable storage location and file size limits

2. **ProductImageService** (Product-Specific Implementation)
   - Location: `domain/file/ProductImageService.java`
   - Purpose: Manage product images using FileStorageService
   - Features:
     - Upload images for products
     - Set primary image
     - Manage display order
     - Add alt text for accessibility
     - Retrieve all images or primary image
     - Update image metadata
     - Delete images

### Database Schema

#### file_metadata
Stores metadata for all uploaded files.
```sql
- id (BIGINT, PK)
- public_id (VARCHAR(36), UNIQUE)
- file_name (VARCHAR(255))
- original_file_name (VARCHAR(255))
- file_path (VARCHAR(500))
- file_size (BIGINT)
- content_type (VARCHAR(100))
- file_type (ENUM: IMAGE, DOCUMENT, VIDEO, OTHER)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

#### product_image
Links products to their images with additional metadata.
```sql
- id (BIGINT, PK)
- public_id (VARCHAR(36), UNIQUE)
- product_id (BIGINT, FK -> product.id)
- file_metadata_id (BIGINT, FK -> file_metadata.id)
- is_primary (BOOLEAN)
- display_order (INT)
- alt_text (VARCHAR(255))
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

## API Endpoints

### Upload Product Image
```http
POST /api/files/products/{productPublicId}/images
Authorization: Admin only
Content-Type: multipart/form-data

Parameters:
- file (required): Image file
- isPrimary (optional): Set as primary image (default: false)
- displayOrder (optional): Display order (default: 0)
- altText (optional): Alternative text for accessibility

Response: ProductImageResponse
```

### Get All Product Images
```http
GET /api/files/products/{productPublicId}/images
Authorization: Public

Response: List<ProductImageResponse>
```

### Get Primary Product Image
```http
GET /api/files/products/{productPublicId}/images/primary
Authorization: Public

Response: ProductImageResponse
```

### Serve Image File
```http
GET /api/files/images/{imagePublicId}
Authorization: Public

Response: Binary image file with proper content type
```

### Update Image Metadata
```http
PATCH /api/files/images/{imagePublicId}
Authorization: Admin only
Content-Type: application/json

Body:
{
  "isPrimary": true,
  "displayOrder": 1,
  "altText": "Product main image"
}

Response: ProductImageResponse
```

### Delete Product Image
```http
DELETE /api/files/images/{imagePublicId}
Authorization: Admin only

Response: 204 No Content
```

### Delete All Product Images
```http
DELETE /api/files/products/{productPublicId}/images
Authorization: Admin only

Response: 204 No Content
```

## Configuration

Add to `application.yml`:

```yaml
spring:
  servlet:
    multipart:
      enabled: true
      max-file-size: 10MB
      max-request-size: 10MB

app:
  file:
    upload-dir: uploads
    max-size: 10485760  # 10MB in bytes
```

## Usage Examples

### 1. Upload a Product Image (cURL)
```bash
curl -X POST http://localhost:8080/api/files/products/{productPublicId}/images \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -F "file=@/path/to/image.jpg" \
  -F "isPrimary=true" \
  -F "displayOrder=0" \
  -F "altText=Product main view"
```

### 2. Get All Images for a Product
```bash
curl http://localhost:8080/api/files/products/{productPublicId}/images
```

### 3. Display Product Image in Frontend
```html
<img src="http://localhost:8080/api/files/images/{imagePublicId}" 
     alt="Product image" />
```

### 4. Update Image to Primary
```bash
curl -X PATCH http://localhost:8080/api/files/images/{imagePublicId} \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"isPrimary": true}'
```

## Extending for Other Entities

This module is designed to be reusable. To add image support for other entities (e.g., categories, users):

### Step 1: Create Entity-Specific Image Table
```sql
CREATE TABLE category_image (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    public_id VARCHAR(36) NOT NULL UNIQUE,
    category_id BIGINT NOT NULL,
    file_metadata_id BIGINT NOT NULL,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_category_image_category FOREIGN KEY (category_id) REFERENCES category(id) ON DELETE CASCADE,
    CONSTRAINT fk_category_image_file_metadata FOREIGN KEY (file_metadata_id) REFERENCES file_metadata(id) ON DELETE CASCADE
);
```

### Step 2: Create Entity-Image Entity
```java
@Entity
@Table(name = "category_image")
public class CategoryImage {
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id", nullable = false)
    private Category category;

    @ManyToOne(fetch = FetchType.EAGER, cascade = CascadeType.ALL)
    @JoinColumn(name = "file_metadata_id", nullable = false)
    private FileMetadata fileMetadata;
    
    // ... other fields
}
```

### Step 3: Create Repository
```java
@Repository
public interface CategoryImageRepository extends JpaRepository<CategoryImage, Long> {
    Optional<CategoryImage> findByPublicId(String publicId);
    List<CategoryImage> findByCategoryPublicId(String categoryPublicId);
}
```

### Step 4: Create Service (Reuse FileStorageService)
```java
@Service
public class CategoryImageService {
    private final FileStorageService fileStorageService;
    private final CategoryImageRepository categoryImageRepository;
    
    // Implement similar methods as ProductImageService
}
```

## Supported File Types

### Images
- JPEG (.jpg, .jpeg)
- PNG (.png)
- GIF (.gif)
- WebP (.webp)

### File Size Limits
- Default: 10MB per file
- Configurable in `application.yml`

## Error Handling

The module includes custom exceptions:

- `FileStorageException`: File storage/retrieval errors
- `FileNotFoundException`: File not found
- `InvalidFileTypeException`: Unsupported file type
- `ProductImageNotFoundException`: Product image not found

All exceptions are handled by `FileExceptionHandler` with proper HTTP status codes and ProblemDetail responses.

## Security Considerations

1. **File Validation**: Only allowed image types can be uploaded
2. **Path Traversal Protection**: File names are sanitized
3. **Authorization**: Upload/Delete operations require ADMIN role
4. **File Size Limits**: Prevents DoS attacks via large files

## Testing Workflow

1. Start the application
2. Create a product using the product API
3. Upload an image for the product
4. Retrieve product details (should include images)
5. Access the image URL in browser
6. Update image metadata
7. Delete the image

## Future Enhancements

- [ ] Cloud storage support (AWS S3, Azure Blob)
- [ ] Image resizing/optimization
- [ ] Multiple image upload in single request
- [ ] Image cropping
- [ ] Video file support
- [ ] CDN integration
- [ ] Batch operations
- [ ] Image compression

## File Structure
```
src/main/java/com/saveitforlater/ecommerce/
├── api/file/
│   ├── FileController.java
│   └── exception/
│       └── FileExceptionHandler.java
├── domain/file/
│   ├── FileStorageService.java (reusable)
│   ├── ProductImageService.java
│   ├── dto/
│   │   ├── FileMetadataResponse.java
│   │   ├── ProductImageResponse.java
│   │   ├── UploadProductImageRequest.java
│   │   └── UpdateProductImageRequest.java
│   └── exception/
│       ├── FileStorageException.java
│       ├── FileNotFoundException.java
│       ├── InvalidFileTypeException.java
│       └── ProductImageNotFoundException.java
└── persistence/
    ├── entity/file/
    │   ├── FileMetadata.java
    │   └── ProductImage.java
    └── repository/file/
        ├── FileMetadataRepository.java
        └── ProductImageRepository.java
```

## Notes

- Files are stored in the `uploads/products/` directory by default
- Each file gets a unique UUID-based name to prevent conflicts
- The original filename is preserved in metadata
- Images are automatically deleted when products are deleted (cascade)
- The module follows the project's existing patterns (DTOs, exceptions, services)

# File Storage Module - Technical Documentation

## Overview

Reusable file storage system used primarily for product images. Provides upload, metadata management, and secure file serving.

## Architecture

```
FileController → ProductImageService → FileStorageService → FileMetadataRepository
                               ↓
                        ProductImageRepository
```

## Core Components

### Services

#### FileStorageService (Reusable Core)
- Store files with UUID names in configured upload directory
- Validate content type and size
- Serve files as `Resource`
- Delete files safely

```java
public Path store(MultipartFile file, String subDir)
public Resource loadAsResource(String fileName, String subDir)
public void delete(String fileName, String subDir)
```

#### ProductImageService (Product-Specific)
- Upload images for product
- Set primary image
- Manage display order and alt text
- List product images
- Delete single/all images

### Entities

#### FileMetadata
- `publicId`, `fileName`, `originalFileName`, `filePath`, `fileSize`, `contentType`, `fileType`

#### ProductImage
- `publicId`, `product`, `fileMetadata`, `isPrimary`, `displayOrder`, `altText`

## API Endpoints

- `POST /api/files/products/{productId}/images` — Upload image (admin)
- `GET /api/files/products/{productId}/images` — List images
- `GET /api/files/products/{productId}/images/primary` — Get primary image
- `GET /api/files/images/{imageId}` — Serve image file
- `PATCH /api/files/images/{imageId}` — Update metadata (admin)
- `DELETE /api/files/images/{imageId}` — Delete image (admin)
- `DELETE /api/files/products/{productId}/images` — Delete all images (admin)

## Configuration

`application.yml`:
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
    max-file-size: 10485760
    allowed-content-types:
      - image/jpeg
      - image/png
      - image/gif
      - image/webp
```

## Security

- Admin-only for mutation endpoints
- Public access for read (listing and serving)
- Path traversal protection via normalized paths and checks

## Validation

- File size and content type checked
- Unique filenames (UUID)
- Metadata persisted before file operations (transactional consistency)

## Error Handling

- 400: Invalid file type/size
- 404: File not found
- 500: Storage operation failure

## Performance

- Stream file responses (no in-memory buffering of entire file)
- Separate metadata table allows reuse for other modules

## Future Enhancements

- S3/Azure Blob storage adapters
- Image resizing/thumbnails
- CDN integration
- Virus scanning hook

---

**Related Documentation**:
- [Product Module](./ProductModule.md)
- [API Reference](../03-APIReference.md)
- [Security](../04-Security.md)

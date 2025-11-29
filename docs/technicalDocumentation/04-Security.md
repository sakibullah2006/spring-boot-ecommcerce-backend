# Security Documentation

## Authentication

### Strategy
Session-based authentication using Spring Security.

### Login Flow
1. User submits credentials to `/api/auth/login`
2. Server validates credentials against database (BCrypt password verification)
3. Session created and JSESSIONID cookie returned
4. Client includes cookie in subsequent requests

### Session Management
- **Session Timeout**: 30 minutes of inactivity
- **Concurrent Sessions**: Single session per user
- **Session Storage**: In-memory (configurable for Redis in production)

## Authorization

### Roles
- **ADMIN**: Full system access
- **CUSTOMER**: Limited to own resources

### Method-Level Security

```java
@PreAuthorize("hasAuthority('ADMIN')")
public ResponseEntity<ProductResponse> createProduct(...)

@PreAuthorize("isAuthenticated()")
public ResponseEntity<CartResponse> getMyCart(...)
```

### Authorization Matrix

| Endpoint | Public | Customer | Admin |
|----------|--------|----------|-------|
| GET /products | ✓ | ✓ | ✓ |
| POST /products | ✗ | ✗ | ✓ |
| GET /cart | ✗ | ✓ (own) | ✓ |
| POST /orders | ✗ | ✓ | ✓ |
| PATCH /orders/{id}/status | ✗ | ✗ | ✓ |
| POST /files/products/*/images | ✗ | ✗ | ✓ |

## Password Security

### Hashing
- **Algorithm**: BCrypt with strength 10
- **Salt**: Automatically generated per password
- **Storage**: Hashed password only (original never stored)

### Password Requirements
- Minimum 8 characters
- Recommended: Mix of uppercase, lowercase, numbers, symbols

## XSS Protection

### HTML Sanitization
**Library**: jsoup 1.17.2

**Implementation**: `HtmlSanitizer` component

```java
public String sanitizeRichText(String html) {
    return Jsoup.clean(html, Safelist.relaxed());
}
```

**Allowed Tags**: h1-h6, p, ul, ol, li, a, img, strong, em, table, blockquote, code

**Blocked Content**:
- `<script>` tags
- JavaScript event handlers (onclick, onerror, etc.)
- `javascript:` URLs
- `data:` URIs
- `<iframe>` tags

### Usage
Product descriptions automatically sanitized on create/update.

## CSRF Protection

### Configuration
CSRF protection enabled for state-changing operations (POST, PUT, DELETE, PATCH).

### Token Handling
- Token included in session
- Frontend must include CSRF token in headers or form data
- Token validated on each request

## SQL Injection Prevention

### JPA/Hibernate
All database queries use JPA with parameterized queries.

**Safe**:
```java
@Query("SELECT p FROM Product p WHERE p.name = :name")
Product findByName(@Param("name") String name);
```

**Never Used**:
```java
// String concatenation - VULNERABLE
query = "SELECT * FROM product WHERE name = '" + name + "'";
```

## File Upload Security

### Validation
1. **File Type**: Only images (JPEG, PNG, GIF, WebP)
2. **File Size**: Max 10MB
3. **File Name**: Sanitized to prevent path traversal

### Storage
- Files stored outside webroot
- Unique UUID-based filenames
- Original filenames logged but not used for storage

### Path Traversal Prevention
```java
Path filePath = uploadPath.resolve(fileName).normalize();
if (!filePath.startsWith(uploadPath)) {
    throw new FileStorageException("Invalid file path");
}
```

## API Security Headers

```http
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Content-Security-Policy: default-src 'self'
```

## Session Security

### Cookie Configuration
```yaml
server:
  servlet:
    session:
      cookie:
        http-only: true
        secure: true  # In production with HTTPS
        same-site: strict
```

## Audit Logging

All entities track:
- `created_at`: Entity creation timestamp
- `updated_at`: Last modification timestamp
- User context captured in service layer

## Security Best Practices

### Implemented
✓ Password hashing with BCrypt  
✓ Session-based authentication  
✓ Role-based access control  
✓ XSS protection via HTML sanitization  
✓ CSRF token validation  
✓ SQL injection prevention via JPA  
✓ File upload validation  
✓ Path traversal prevention  
✓ Secure cookie configuration  

### Recommended for Production
- Enable HTTPS/TLS
- Implement rate limiting
- Add API request logging
- Set up intrusion detection
- Regular security audits
- Dependency vulnerability scanning
- Use secrets management (e.g., AWS Secrets Manager)
- Implement JWT for stateless authentication (microservices)

## Compliance Considerations

### Data Protection
- User passwords never stored in plain text
- Personal data (email, names, addresses) stored securely
- Consider GDPR compliance for EU users

### PCI DSS
- Card numbers not stored (sent to payment gateway only)
- Payment details in memory only during transaction
- Consider PCI DSS compliance for production

---

**Related Documentation**:
- [System Architecture](./01-SystemArchitecture.md)
- [Deployment Guide](./05-DeploymentGuide.md)

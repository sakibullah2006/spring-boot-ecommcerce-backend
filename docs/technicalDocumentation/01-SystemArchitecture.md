# System Architecture

## Overview

The Spring Boot E-Commerce Backend is built using a layered architecture pattern with clear separation of concerns. The system follows Domain-Driven Design (DDD) principles and RESTful API design patterns.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENT LAYER                             │
│  (Frontend Applications, Mobile Apps, Third-party Integrations)  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       API LAYER (Controllers)                    │
│  • ProductController  • CartController    • OrderController      │
│  • AuthController     • FileController    • AttributeController  │
│  • CategoryController                                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      SERVICE LAYER (Business Logic)              │
│  • ProductService     • CartService       • OrderService         │
│  • AuthService        • FileStorageService • AttributeService    │
│  • PaymentService     • HtmlSanitizer                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    REPOSITORY LAYER (Data Access)                │
│  • ProductRepository  • CartRepository    • OrderRepository      │
│  • UserRepository     • FileMetadataRepository                   │
│  • AttributeRepository • AttributeOptionRepository               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         DATABASE LAYER                           │
│                      MySQL/MariaDB 5.5                           │
└─────────────────────────────────────────────────────────────────┘
```

## Layered Architecture

### 1. API Layer (Controllers)
**Package**: `com.saveitforlater.ecommerce.api.*`

Responsible for:
- HTTP request/response handling
- Input validation using Jakarta Bean Validation
- Authorization checks using Spring Security annotations
- Mapping between DTOs and domain models

**Key Controllers**:
- `ProductController` - Product catalog management
- `CartController` - Shopping cart operations
- `OrderController` - Order creation and management
- `AuthController` - User authentication and registration
- `FileController` - File upload and retrieval
- `AttributeController` - Attribute and option management
- `CategoryController` - Category hierarchy management

### 2. Service Layer (Business Logic)
**Package**: `com.saveitforlater.ecommerce.domain.*`

Responsible for:
- Business rule implementation
- Transaction management
- Coordination between multiple repositories
- Data transformation and validation
- External service integration

**Key Services**:
- `ProductService` - Product CRUD, search, and filtering
- `CartService` - Cart item management, total calculation
- `OrderService` - Order workflow, inventory management
- `PaymentService` - Payment processing and validation
- `FileStorageService` - Reusable file operations
- `ProductImageService` - Product-specific image management
- `AttributeService` - Attribute system management
- `HtmlSanitizer` - XSS protection for rich text content

### 3. Repository Layer (Data Access)
**Package**: `com.saveitforlater.ecommerce.domain.*`

Responsible for:
- Database queries using Spring Data JPA
- Custom query methods
- Pagination and sorting
- Transaction support

**Technologies**:
- Spring Data JPA
- Hibernate as JPA provider
- MySQL/MariaDB JDBC driver

### 4. Domain Layer (Entities)
**Package**: `com.saveitforlater.ecommerce.domain.*`

Core domain entities:
- `Product` - Product catalog items
- `Category` - Product categories with hierarchy
- `Cart` / `CartItem` - Shopping cart
- `Order` / `OrderItem` - Orders and line items
- `Payment` - Payment records
- `User` - User accounts
- `Attribute` / `AttributeOption` - Reusable attribute system
- `ProductAttributeValue` - Product-attribute associations
- `FileMetadata` - File storage metadata
- `ProductImage` - Product image associations

## Cross-Cutting Concerns

### Security
- **Framework**: Spring Security
- **Authentication**: Session-based authentication
- **Authorization**: Method-level security with `@PreAuthorize`
- **Roles**: ADMIN, CUSTOMER
- **CSRF**: Enabled for state-changing operations
- **XSS Protection**: HTML sanitization using jsoup library

### Exception Handling
- Global exception handlers using `@ControllerAdvice`
- Standardized error responses (RFC 7807 Problem Details)
- Custom exceptions for domain-specific errors

### Validation
- Jakarta Bean Validation (JSR-380)
- Custom validators for complex rules
- DTO-level validation

### Database Migration
- **Tool**: Flyway 10.10.0
- **Versioning**: Sequential version numbers (V1, V2, V3, etc.)
- **Location**: `src/main/resources/db/migration/`

### Logging
- **Framework**: SLF4J with Logback
- **Levels**: DEBUG for development, INFO for production
- **Pattern**: Structured logging with contextual information

## Design Patterns

### 1. Repository Pattern
Abstraction over data access layer using Spring Data JPA repositories.

### 2. Service Layer Pattern
Business logic separated from controllers and repositories.

### 3. DTO Pattern
Data Transfer Objects for API communication, separate from domain entities.

### 4. Builder Pattern
Used in test data creation and complex object construction.

### 5. Strategy Pattern
Payment processing with different payment method strategies.

### 6. Template Method Pattern
FileStorageService as reusable template for specific file operations.

## Module Interactions

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Product    │────▶│     Cart     │────▶│    Order     │
│   Module     │     │    Module    │     │   Module     │
└──────────────┘     └──────────────┘     └──────────────┘
        │                                         │
        ▼                                         ▼
┌──────────────┐                         ┌──────────────┐
│  Attribute   │                         │   Payment    │
│   System     │                         │   Module     │
└──────────────┘                         └──────────────┘
        │                                         
        ▼                                         
┌──────────────┐                         
│ File Storage │                         
│   Module     │                         
└──────────────┘                         
```

### Flow Description:
1. **Product Module** manages catalog with attributes and images
2. **Cart Module** holds selected products before checkout
3. **Order Module** processes cart into orders with payment
4. **Payment Module** handles payment processing
5. **Attribute System** provides reusable product characteristics
6. **File Storage** manages product images and other files

## Technology Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Framework | Spring Boot | 3.3.5 |
| Language | Java | 21 |
| Database | MySQL/MariaDB | 5.5+ |
| ORM | Hibernate (via Spring Data JPA) | 6.x |
| Migration | Flyway | 10.10.0 |
| Security | Spring Security | 6.x |
| Validation | Jakarta Bean Validation | 3.x |
| Mapping | MapStruct | 1.5.5 |
| HTML Sanitization | jsoup | 1.17.2 |
| Build Tool | Maven | 3.9.x |
| Testing | PowerShell Scripts | 7.x |

## Configuration Management

Configuration is managed through `application.yml`:

```yaml
server:
  port: 8080

spring:
  datasource:
    url: jdbc:mysql://localhost:3306/ecommerce_db
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
  
  jpa:
    hibernate:
      ddl-auto: validate
    show-sql: false
  
  flyway:
    enabled: true
    locations: classpath:db/migration
  
  servlet:
    multipart:
      max-file-size: 10MB
      max-request-size: 10MB

app:
  file:
    upload-dir: uploads
    max-file-size: 10485760  # 10MB in bytes
```

## Scalability Considerations

### Current Architecture
- Session-based authentication (suitable for single-server deployments)
- Local file storage (suitable for single-server deployments)
- Synchronous request processing

### Future Enhancements
- JWT-based authentication for distributed deployments
- Cloud storage (AWS S3, Azure Blob) for file storage
- Message queue for asynchronous order processing
- Caching layer (Redis) for frequently accessed data
- Database read replicas for query scaling
- API Gateway for load balancing

## Performance Optimizations

1. **Database Indexing**: Foreign keys and frequently queried columns
2. **JPA Fetch Strategies**: Lazy loading for collections
3. **Query Optimization**: Custom queries for complex operations
4. **Pagination**: Built-in pagination for list endpoints
5. **File Serving**: Direct file streaming without loading into memory

## Security Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Security Filter Chain                     │
├─────────────────────────────────────────────────────────────┤
│  1. CSRF Protection                                          │
│  2. Session Management                                       │
│  3. Authentication Filter                                    │
│  4. Authorization Filter                                     │
│  5. Exception Translation Filter                             │
└─────────────────────────────────────────────────────────────┘
```

**Security Features**:
- Password encryption using BCrypt
- Session-based authentication
- Role-based access control (RBAC)
- Method-level authorization
- XSS protection via HTML sanitization
- CSRF token validation
- SQL injection prevention via JPA/Hibernate

## Error Handling Strategy

All errors follow RFC 7807 Problem Details format:

```json
{
  "type": "https://api.ecommerce.com/errors/resource-not-found",
  "title": "Resource Not Found",
  "status": 404,
  "detail": "Product with ID '123' not found",
  "instance": "/api/products/123",
  "timestamp": "2025-11-30T10:00:00Z"
}
```

## API Versioning

Current: No versioning (initial release)
Future: URI-based versioning (`/api/v2/products`)

---

**Related Documentation**:
- [Database Design](./02-DatabaseDesign.md)
- [API Reference](./03-APIReference.md)
- [Security Documentation](./04-Security.md)

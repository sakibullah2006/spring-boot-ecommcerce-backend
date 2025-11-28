# Exception Handling Architecture

## 📐 Organized Exception Handler Structure

The exception handling follows a **layered architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────────────────┐
│         GlobalExceptionHandler (config/)            │
│  - Cross-cutting concerns (validation, security)    │
│  - Database constraint violations                   │
│  - Fallback for unhandled exceptions                │
│  - @Order(LOWEST_PRECEDENCE)                        │
└─────────────────────────────────────────────────────┘
                         ▲
                         │ fallback
                         │
        ┌────────────────┴────────────────┐
        │                                  │
┌───────┴────────┐              ┌─────────┴──────────┐
│ Auth Module    │              │ Product Module     │
│ Exception      │              │ Exception          │
│ Handler        │              │ Handler            │
│                │              │                    │
│ Handles:       │              │ Handles:           │
│ • User exists  │              │ • Product not found│
│ • Bad creds    │              │ • Duplicate SKU    │
│ • Validation   │              │                    │
└────────────────┘              └────────────────────┘
```

---

## 🎯 Handler Responsibilities

### 1. **Module-Specific Handlers** (High Priority)

#### `AuthExceptionHandler` (`api/auth/exception/`)
**Package:** `com.saveitforlater.ecommerce.api.auth`

Handles:
- ✅ `UserAlreadyExistsException` → 409 Conflict
- ✅ `InvalidCredentialsException` → 401 Unauthorized
- ✅ `BadCredentialsException` → 401 Unauthorized
- ✅ `AuthenticationException` → 401 Unauthorized
- ✅ Validation errors (within auth package)

---

#### `ProductExceptionHandler` (`api/product/exception/`)
**Package:** Global (catches all)

Handles:
- ✅ `ProductNotFoundException` → 404 Not Found
- ✅ `ProductSkuAlreadyExistsException` → 409 Conflict

---

### 2. **Global Handler** (Low Priority - Fallback)

#### `GlobalExceptionHandler` (`config/`)
**Order:** `LOWEST_PRECEDENCE` (runs only if module handlers don't catch)

Handles:
- ✅ **Validation** (`MethodArgumentNotValidException`) → 400 Bad Request
- ✅ **Security** (`AuthenticationException`) → 401 Unauthorized
- ✅ **Authorization** (`AccessDeniedException`) → 403 Forbidden
- ✅ **Database Constraints** (`DataIntegrityViolationException`) → 409 Conflict
  - Duplicate SKU (race conditions)
  - Duplicate email (race conditions)
  - Foreign key violations
  - NULL constraints
- ✅ **Generic Fallback** (`Exception`) → 500 Internal Server Error

---

## 🔄 Exception Flow Example

### Example 1: Duplicate Product SKU

```
1. ProductService.createProduct()
   ↓
2. Checks if SKU exists → ✅ Found!
   ↓
3. Throws ProductSkuAlreadyExistsException
   ↓
4. ProductExceptionHandler catches it → 409 Conflict
   ✓ Response: {"error": "PRODUCT_SKU_ALREADY_EXISTS", ...}
```

### Example 2: Race Condition (SKU inserted between check and save)

```
1. ProductService.createProduct()
   ↓
2. Checks if SKU exists → ❌ Not found
   ↓
3. Another request inserts same SKU
   ↓
4. productRepository.save() → DataIntegrityViolationException
   ↓
5. ProductService catches and re-throws ProductSkuAlreadyExistsException
   ↓
6. ProductExceptionHandler catches it → 409 Conflict
   ✓ Response: {"error": "PRODUCT_SKU_ALREADY_EXISTS", ...}
```

### Example 3: Database-level constraint (not caught by module handler)

```
1. Some operation causes DB constraint violation
   ↓
2. No module handler catches it
   ↓
3. GlobalExceptionHandler catches DataIntegrityViolationException
   ↓
4. Analyzes error message and returns appropriate response
   ✓ Response: {"error": "DUPLICATE_ENTRY", ...} → 409 Conflict
```

### Example 4: Validation Error

```
1. @Valid annotation triggers validation
   ↓
2. Throws MethodArgumentNotValidException
   ↓
3. GlobalExceptionHandler catches it → 400 Bad Request
   ✓ Response: {"error": "VALIDATION_FAILED", "message": "...""}
```

---

## 📋 Error Response Format

All handlers use the **same `ErrorResponse` format** for consistency:

```json
{
  "error": "ERROR_CODE",
  "message": "Human-readable error message",
  "status": 409,
  "timestamp": "2025-11-29T04:08:05",
  "path": "/api/products"
}
```

### Common Error Codes

| Code | Status | Handler | Description |
|------|--------|---------|-------------|
| `USER_ALREADY_EXISTS` | 409 | Auth | Email already registered |
| `AUTHENTICATION_FAILED` | 401 | Auth | Invalid credentials |
| `PRODUCT_NOT_FOUND` | 404 | Product | Product doesn't exist |
| `PRODUCT_SKU_ALREADY_EXISTS` | 409 | Product | Duplicate SKU |
| `VALIDATION_FAILED` | 400 | Global | Field validation error |
| `ACCESS_DENIED` | 403 | Global | Insufficient permissions |
| `AUTHENTICATION_REQUIRED` | 401 | Global | Not logged in |
| `DUPLICATE_SKU` | 409 | Global | DB-level SKU duplicate |
| `DUPLICATE_EMAIL` | 409 | Global | DB-level email duplicate |
| `FOREIGN_KEY_CONSTRAINT` | 409 | Global | Cannot delete due to relations |
| `INTERNAL_SERVER_ERROR` | 500 | Global | Unhandled exception |

---

## ✅ Benefits of This Architecture

### 1. **Separation of Concerns**
- Each module handles its own domain exceptions
- Global handler only handles cross-cutting concerns
- Clear ownership and maintainability

### 2. **No Duplication**
- Module handlers take precedence (`@Order`)
- Global handler is fallback
- Same `ErrorResponse` format everywhere

### 3. **Comprehensive Coverage**
- Module exceptions: Caught by specific handlers
- Database errors: Caught by global handler
- Validation: Caught by global handler
- Security: Caught by global handler
- Unknown errors: Caught by global fallback

### 4. **Easy to Extend**
When adding a new module (e.g., `OrderModule`):

```java
@RestControllerAdvice
public class OrderExceptionHandler {
    
    @ExceptionHandler(OrderNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleOrderNotFound(...) {
        // Handle order-specific exception
    }
}
```

Global handler automatically provides fallback for anything not caught!

---

## 🧪 Testing

Run the comprehensive test to verify all error scenarios:

```powershell
# Test duplicate SKU (409)
.\powerShellScripts\test-duplicate-sku.ps1

# Test all endpoints
.\powerShellScripts\test-master.ps1
```

---

## 📝 Summary

**Architecture Pattern:**
- ✅ Module handlers: Domain-specific exceptions
- ✅ Global handler: Cross-cutting + fallback
- ✅ Consistent error format across all handlers
- ✅ Clear priority with `@Order`
- ✅ Database constraint safety net

**No more 500 errors for known issues!** 🎉

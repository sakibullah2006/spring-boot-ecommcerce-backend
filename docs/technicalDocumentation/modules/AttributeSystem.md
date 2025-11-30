# Reusable Attribute System - Technical Documentation

## Overview

Centralized attribute definitions (e.g., Color, Size, Brand) with options reused across products. Products reference attribute-option pairs via junction table.

## Architecture

```
AttributeController → AttributeService → AttributeRepository
                                     ↓
                         AttributeOptionRepository
```

## Entities

### Attribute
- `publicId`, `name` (unique), `description`, `isActive`

### AttributeOption
- `publicId`, `attribute` (FK), `name` (unique per attribute), `description`, `isActive`

### ProductAttributeValue
- Links `product` to (`attribute`, `attributeOption`)
- Unique composite constraint `(product_id, attribute_id, attribute_option_id)`

## API Endpoints

Below is a complete and grouped list of endpoints for the Reusable Attribute System. Routes assume base path `/api` and JSON request/response bodies unless noted. Mentioned admin-only endpoints require appropriate authorization.

### Attribute endpoints

- `GET /api/attributes` — List attributes (supports paging & filtering)
  - Query params: `?page=..&size=..&active=true|false&search=...`
  - Response: paged list of attribute objects (`publicId`, `name`, `description`, `isActive`, `createdAt`, ...)

- `GET /api/attributes/{attributeId}` — Get one attribute by `publicId`
  - Response: attribute object with metadata and optionally its options (configurable)

- `POST /api/attributes` — Create attribute (admin)
  - Body: `{ "name": "Color", "description": "Product color", "isActive": true }`
  - Response: created attribute object (201)

- `PUT /api/attributes/{attributeId}` — Update attribute (admin)
  - Body: partial or full attribute object fields to update
  - Response: updated attribute object

- `DELETE /api/attributes/{attributeId}` — Deactivate attribute (admin)
  - Soft-delete: sets `isActive=false`. Returns 204 or updated attribute depending on implementation

### Attribute Option endpoints

- `GET /api/attributes/{attributeId}/options` — List options for an attribute
  - Query params: `?active=true|false&search=...`
  - Response: list of `AttributeOption` objects (`publicId`, `name`, `description`, `isActive`)

- `GET /api/attributes/options/{optionId}` — Get option by `publicId`

- `POST /api/attributes/{attributeId}/options` — Create option (admin)
  - Body: `{ "name": "Red", "description": "Bright red", "isActive": true }`
  - Response: created option (201)

- `PUT /api/attributes/options/{optionId}` — Update option (admin)
  - Body: partial/full fields to update; response: updated option

- `DELETE /api/attributes/options/{optionId}` — Deactivate option (admin)
  - Soft-delete: sets `isActive=false`

### Product ↔ Attribute assignment endpoints (ProductAttributeValue)

These endpoints let you assign attribute-option pairs to products and manage them.

- `GET /api/products/{productId}/attributes` — List attribute assignments for a product
  - Response: list of product attribute values, each linking to `attribute` and `attributeOption` (IDs + names)

- `POST /api/products/{productId}/attributes` — Add one or more attribute assignments to a product
  - Body example:
    {
      "attributes": [
        { "attributeId": "color-uuid", "optionId": "red-uuid" },
        { "attributeId": "size-uuid", "optionId": "large-uuid" }
      ]
    }
  - Response: list of created `ProductAttributeValue` records

- `PUT /api/products/{productId}/attributes` — Update/replace product attributes (admin or owner)
  - Body: full set to replace existing assignments for the product (idempotent replace)

- `DELETE /api/products/{productId}/attributes/{attributeId}` — Remove a specific attribute assignment from a product
  - Alternatively: `DELETE /api/products/{productId}/attributes/values/{valueId}` if you expose the assignment id

### Search, filtering and convenience endpoints

- `GET /api/attributes/options` — (optional) Search across all options with filters: `?attributeId=...&name=...&active=true`

- `GET /api/attributes/summary` — (optional) Returns a compact map of attributes -> options for fast client bootstrap

### Notes on behavior & permissions

- Admin-only: creating, updating, and deactivating attributes and options typically require admin privileges.
- Product assignment endpoints may require product ownership or admin privileges depending on system rules.
- Deletions are implemented as deactivation (`isActive=false`) to preserve historical product data.
- Validation rules enforced by the API:
  - Attribute name unique (case-insensitive)
  - Option name unique per attribute
  - Composite uniqueness for `ProductAttributeValue` `(product_id, attribute_id, attribute_option_id)`

If additional endpoints are added in the codebase (for bulk import/export, CSV templates, or audit logs), list them here as they are implemented.

## Validation Rules

- Attribute name unique (case-insensitive recommended)
- Option name unique within attribute
- Active flags respected by product queries

## Database Schema

See `docs/technicalDocumentation/02-DatabaseDesign.md` for DDL and indexing.

## Usage Patterns

### Assign existing attribute-option to product
```json
{
  "attributes": [
    {
      "attributeId": "color-uuid",
      "options": [ { "optionId": "red-uuid" } ]
    }
  ]
}
```

### Add new option to existing attribute (admin)
```http
POST /api/attributes/{attributeId}/options
{
  "name": "128GB",
  "description": "Storage capacity"
}
```

## Benefits

- Consistency across catalog
- Efficient filtering/searching
- Minimal duplication
- Flexible evolution of catalog metadata

## Testing

- Covered by `powerShellScripts/test-product-module.ps1` and attribute-specific tests

---

**Related Documentation**:
- [Product Module](./ProductModule.md)
- [API Reference](../03-APIReference.md)

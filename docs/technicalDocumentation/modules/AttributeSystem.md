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

- `GET /api/attributes` — list attributes
- `POST /api/attributes` — create attribute (admin)
- `PUT /api/attributes/{id}` — update attribute (admin)
- `DELETE /api/attributes/{id}` — deactivate attribute (admin)
- `GET /api/attributes/{attributeId}/options` — list options
- `POST /api/attributes/{attributeId}/options` — create option (admin)
- `PUT /api/attributes/options/{optionId}` — update option (admin)

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

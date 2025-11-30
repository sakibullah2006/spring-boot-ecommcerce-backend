# Reusable Product Attributes System

This document demonstrates how to use the new reusable product attributes system.

## Overview

The new system allows attributes and their options to be reused across different products, making attribute management more efficient and consistent.

### Key Features

1. **Unique Attributes**: Attributes like "Color", "Size", "Material" are created once and reused
2. **Unique Options**: Options like "Red", "Large", "Cotton" are created once per attribute and reused
3. **Flexible Assignment**: Products can have any combination of attribute-option pairs
4. **API Management**: Full CRUD operations for attributes and options via REST API

## Entity Structure

```
Attribute (e.g., "Color")
├── AttributeOption (e.g., "Red")
├── AttributeOption (e.g., "Blue")
└── AttributeOption (e.g., "Green")

Product
├── ProductAttributeValue (Color -> Red)
├── ProductAttributeValue (Size -> Large)
└── ProductAttributeValue (Material -> Cotton)
```

## API Usage Examples

### 1. Managing Attributes

#### Get all attributes
```http
GET /api/attributes
```

#### Create a new attribute
```http
POST /api/attributes
{
    "name": "Storage Capacity",
    "description": "Device storage capacity options"
}
```

#### Update an attribute
```http
PUT /api/attributes/{attributeId}
{
    "name": "Storage Capacity", 
    "description": "Updated description",
    "isActive": true
}
```

### 2. Managing Attribute Options

#### Get options for an attribute
```http
GET /api/attributes/{attributeId}/options
```

#### Create option for an attribute
```http
POST /api/attributes/{attributeId}/options
{
    "name": "128GB",
    "description": "128 gigabytes storage"
}
```

#### Update an attribute option
```http
PUT /api/attributes/options/{optionId}
{
    "name": "128GB",
    "description": "Updated description", 
    "isActive": true
}
```

### 3. Creating Products with Attributes

#### Option 1: Using existing attributes and options by ID
```http
POST /api/products
{
    "name": "Red Cotton T-Shirt",
    "sku": "SHIRT-001",
    "price": 29.99,
    "salePrice": 24.99,
    "stockQuantity": 100,
    "description": "Comfortable red cotton t-shirt",
    "categoryIds": ["category-uuid"],
    "attributes": [
        {
            "attributeId": "color-attribute-uuid",
            "options": [
                {
                    "optionId": "red-option-uuid"
                }
            ]
        },
        {
            "attributeId": "material-attribute-uuid", 
            "options": [
                {
                    "optionId": "cotton-option-uuid"
                }
            ]
        },
        {
            "attributeId": "size-attribute-uuid",
            "options": [
                {
                    "optionId": "medium-option-uuid"
                }
            ]
        }
    ]
}
```

#### Option 2: Creating new attributes/options on the fly
```http
POST /api/products
{
    "name": "Wireless Headphones",
    "sku": "HEADPHONES-001", 
    "price": 199.99,
    "salePrice": 179.99,
    "stockQuantity": 50,
    "description": "High-quality wireless headphones",
    "categoryIds": ["electronics-category-uuid"],
    "attributes": [
        {
            "attributeName": "Connectivity",
            "attributeDescription": "Device connectivity options",
            "options": [
                {
                    "optionName": "Bluetooth 5.0",
                    "optionDescription": "Latest Bluetooth technology"
                }
            ]
        },
        {
            "attributeId": "color-attribute-uuid",
            "options": [
                {
                    "optionName": "Midnight Black",
                    "optionDescription": "Elegant black finish"
                }
            ]
        }
    ]
}
```

### 4. System Benefits

#### Before (Old System)
```json
// Each product had its own attributes, leading to duplication
Product A: { "attributes": [{"name": "Color", "options": ["Red"]}] }
Product B: { "attributes": [{"name": "Color", "options": ["Red"]}] } 
Product C: { "attributes": [{"name": "Color", "options": ["Red"]}] }
```

#### After (New System)
```json
// Attributes are reused across products
Attribute: { "id": "color-uuid", "name": "Color" }
Option: { "id": "red-uuid", "name": "Red", "attributeId": "color-uuid" }

Product A: { "attributeValues": [{"attributeId": "color-uuid", "optionId": "red-uuid"}] }
Product B: { "attributeValues": [{"attributeId": "color-uuid", "optionId": "red-uuid"}] }
Product C: { "attributeValues": [{"attributeId": "color-uuid", "optionId": "red-uuid"}] }
```

### 5. Advanced Scenarios

#### Multiple Options for Same Attribute
A product can have multiple options for the same attribute (e.g., available in multiple colors):

```http
POST /api/products
{
    "name": "Multi-Color T-Shirt",
    "sku": "SHIRT-MULTI-001",
    "attributes": [
        {
            "attributeId": "color-attribute-uuid",
            "options": [
                {"optionId": "red-option-uuid"},
                {"optionId": "blue-option-uuid"}, 
                {"optionId": "green-option-uuid"}
            ]
        }
    ]
}
```

#### Consistent Attribute Management
Since attributes are reused, updating an attribute name or description affects all products using it:

```http
PUT /api/attributes/{color-attribute-uuid}
{
    "name": "Primary Color",  // This updates the attribute for ALL products
    "description": "Primary color variations"
}
```

### 6. Database Schema

```sql
-- Reusable attributes
attribute (id, public_id, name, slug, description, is_active)

-- Reusable options per attribute  
attribute_option (id, public_id, name, slug, description, attribute_id, is_active)

-- Junction table linking products to attribute-option combinations
product_attribute_value (id, product_id, attribute_id, attribute_option_id, is_active)
```

This design ensures:
- ✅ Attributes are unique and reusable
- ✅ Options are unique per attribute and reusable  
- ✅ Consistent attribute management across all products
- ✅ Flexible product-attribute assignments
- ✅ Efficient storage and querying
- ✅ API-driven attribute management
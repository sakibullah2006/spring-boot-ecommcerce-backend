# Database Migration Documentation

## Overview
This document outlines the organized database migration structure for the Spring Boot E-commerce backend application with reusable product attributes system.

## Migration Structure

### V1: Initial Schema (`V1__Initial_Schema.sql`)
**Purpose**: Creates the core database schema with fundamental entities and relationships.

**Tables Created**:
- `appuser` - User accounts with role-based access (ADMIN/CUSTOMER)
- `category` - Product categories with hierarchical structure
- `product` - Product catalog with pricing and inventory
- `product_category` - Many-to-many relationship between products and categories

**Key Features**:
- UUID-based public identifiers for all entities
- Hierarchical category support with `parent_category_id`
- Proper indexing on foreign keys and unique constraints
- Timestamp tracking with `created_at` and `updated_at`

### V2: Reusable Attribute System (`V2__Create_Reusable_Attribute_System.sql`)
**Purpose**: Implements the reusable attribute system for product variations.

**Tables Created**:
- `attribute` - Defines reusable attribute types (Color, Size, Brand, etc.)
- `attribute_option` - Specific values for each attribute (Red, Large, Nike, etc.)
- `product_attribute_value` - Links products to their specific attribute values

**Key Features**:
- **Reusability**: Attributes and options can be shared across multiple products
- **Flexibility**: Easy to add new attributes and options without schema changes
- **Data Integrity**: Composite unique constraints prevent duplicate assignments
- **Performance**: Proper indexing on all junction table relationships

### V3: Sample Attributes Data (`V3__Sample_Attributes_Data.sql`)
**Purpose**: Populates the database with commonly used e-commerce attributes and their options.

**Attributes Included**:
- **Color**: Red, Blue, Green, Black, White, Gray, Yellow, Orange
- **Size**: XS, S, M, L, XL, XXL
- **Material**: Cotton, Polyester, Leather, Denim, Wool
- **Brand**: Nike, Adidas, Apple, Samsung, Sony
- **Storage**: 64GB, 128GB, 256GB, 512GB, 1TB
- **Additional**: RAM, Screen Size, Weight, Style, Operating System

### V4: Sample Categories and Products (`V4__Sample_Categories_Products_And_Attributes.sql`)
**Purpose**: Demonstrates the reusable attribute system with realistic product data.

**Sample Data Includes**:
- **Category Hierarchy**: Electronics > Smartphones/Laptops/Tablets, Clothing > Men's/Women's/Shoes
- **Sample Products**: iPhone 15, Samsung Galaxy, MacBook Pro, Nike T-Shirts, Adidas Hoodies
- **Attribute Assignments**: Shows how the same attributes (Color, Brand, Size) are reused across different products

## Reusable Attribute System Benefits

### 1. **Data Consistency**
- Centralized attribute definitions prevent typos and inconsistencies
- Standard attribute options ensure uniform data quality
- Easy to maintain and update attribute values globally

### 2. **Flexibility**
- Add new attributes without changing product table structure
- Support for any number of attributes per product
- Easy to filter and search products by attribute combinations

### 3. **Scalability**
- Efficient storage with normalized data structure
- Optimized queries with proper indexing
- Supports millions of products with thousands of attribute combinations

### 4. **Maintainability**
- Clear separation of concerns between product data and attribute data
- Easy to add/remove/modify attributes without affecting existing products
- Simple to implement attribute-based filtering and search

## Database Schema Relationships

```
appuser (1) ──────────────────── (∞) orders [future]
  │
  └── role: ENUM('ADMIN', 'CUSTOMER')

category (1) ──── parent_category_id ──── (1) category [self-reference]
  │
  └── (∞) product_category (∞) ──── (1) product
                                      │
                                      └── (∞) product_attribute_value
                                              │
                                              ├── (1) attribute
                                              │     │
                                              │     └── (∞) attribute_option
                                              │
                                              └── (1) attribute_option
```

## Usage Examples

### Adding a New Attribute
```sql
-- 1. Create the attribute
INSERT INTO attribute (public_id, name, slug, description, is_active) 
VALUES (UUID(), 'Battery Life', 'battery-life', 'Device battery duration', TRUE);

-- 2. Add attribute options
INSERT INTO attribute_option (public_id, name, slug, description, is_active, attribute_id)
SELECT UUID(), '8 Hours', '8-hours', '8 hour battery life', TRUE, id 
FROM attribute WHERE slug = 'battery-life';
```

### Assigning Attributes to Products
```sql
-- Assign "Red" color to a product
INSERT INTO product_attribute_value (product_id, attribute_id, attribute_option_id)
SELECT p.id, a.id, ao.id 
FROM product p, attribute a, attribute_option ao
WHERE p.sku = 'PRODUCT-SKU' AND a.slug = 'color' AND ao.slug = 'red';
```

### Querying Products by Attributes
```sql
-- Find all red Nike products
SELECT DISTINCT p.* 
FROM product p
JOIN product_attribute_value pav1 ON p.id = pav1.product_id
JOIN attribute a1 ON pav1.attribute_id = a1.id
JOIN attribute_option ao1 ON pav1.attribute_option_id = ao1.id
JOIN product_attribute_value pav2 ON p.id = pav2.product_id
JOIN attribute a2 ON pav2.attribute_id = a2.id
JOIN attribute_option ao2 ON pav2.attribute_option_id = ao2.id
WHERE a1.slug = 'color' AND ao1.slug = 'red'
  AND a2.slug = 'brand' AND ao2.slug = 'nike';
```

## Migration Validation

After running these migrations, you should have:
- ✅ Clean, organized schema structure
- ✅ Proper foreign key relationships
- ✅ Realistic sample data for testing
- ✅ Working reusable attribute system
- ✅ Optimized indexes for performance

## Next Steps

1. **Test API Endpoints**: Use the provided PowerShell scripts to test product creation and attribute management
2. **Add More Attributes**: Extend the attribute system with domain-specific attributes as needed
3. **Implement Search**: Build search functionality using the attribute system for filtering
4. **Performance Tuning**: Monitor query performance and add additional indexes if needed

## File Locations

All migration files are located in:
```
src/main/resources/db/migration/
├── V1__Initial_Schema.sql
├── V2__Create_Reusable_Attribute_System.sql
├── V3__Sample_Attributes_Data.sql
└── V4__Sample_Categories_Products_And_Attributes.sql
```
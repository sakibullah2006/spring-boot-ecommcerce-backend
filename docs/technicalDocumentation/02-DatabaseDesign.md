# Database Design

## Overview

The e-commerce database is designed using normalized relational schema with support for hierarchical categories, reusable attributes, shopping carts, and order management. All tables use surrogate keys (auto-increment IDs) for internal relationships and UUIDs for external API references.

## Entity Relationship Diagram

```
┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│   appuser    │         │   category   │         │   product    │
├──────────────┤         ├──────────────┤         ├──────────────┤
│ id (PK)      │         │ id (PK)      │         │ id (PK)      │
│ public_id    │         │ public_id    │         │ public_id    │
│ email        │◀──┐     │ name         │         │ sku          │
│ password     │   │     │ slug         │         │ name         │
│ first_name   │   │     │ description  │         │ slug         │
│ last_name    │   │     │ parent_id(FK)│◀────┐   │ short_desc   │
│ role         │   │     └──────────────┘     │   │ description  │
└──────────────┘   │                          │   │ price        │
                   │     ┌──────────────┐     │   │ sale_price   │
                   │     │product_      │     │   │ stock_qty    │
                   │     │  category    │     │   └──────────────┘
                   │     ├──────────────┤     │          │
                   │     │ product_id(FK├─────┘          │
                   │     │ category_id  ├────────────────┘
                   │     └──────────────┘
                   │
                   │     ┌──────────────┐         ┌──────────────┐
                   │     │     cart     │         │  cart_item   │
                   │     ├──────────────┤         ├──────────────┤
                   │     │ id (PK)      │         │ id (PK)      │
                   └─────┤ user_id (FK) │         │ public_id    │
                         │ public_id    │◀────────┤ cart_id (FK) │
                         └──────────────┘         │ product_id   │
                                                  │ quantity     │
                                                  └──────────────┘

┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│    order     │         │  order_item  │         │   payment    │
├──────────────┤         ├──────────────┤         ├──────────────┤
│ id (PK)      │         │ id (PK)      │         │ id (PK)      │
│ public_id    │◀────────┤ order_id (FK)│         │ public_id    │
│ user_id (FK) │         │ product_id   │         │ order_id(FK) │◀┐
│ order_number │         │ product_name │         │ amount       │ │
│ status       │         │ quantity     │         │ method       │ │
│ payment_id   ├─────────┤ unit_price   │         │ status       │ │
│ total_amount │         │ subtotal     │         │ txn_id       │ │
│ shipping_addr│         └──────────────┘         │ card_details │ │
│ billing_addr │                                  └──────────────┘ │
│ customer_email│                                                  │
│ customer_phone│                                                  │
└──────────────┘──────────────────────────────────────────────────┘

┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│  attribute   │         │ attribute_   │         │   product_   │
│              │         │   option     │         │  attribute_  │
├──────────────┤         ├──────────────┤         │    value     │
│ id (PK)      │         │ id (PK)      │         ├──────────────┤
│ public_id    │◀────────┤ attribute_id │         │ id (PK)      │
│ name         │         │ public_id    │◀────────┤ product_id   │
│ description  │         │ name         │         │ attribute_id │
│ is_active    │         │ description  │         │ option_id    │
└──────────────┘         │ is_active    │         └──────────────┘
                         └──────────────┘

┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│file_metadata │         │product_image │         │   product    │
├──────────────┤         ├──────────────┤         ├──────────────┤
│ id (PK)      │◀────────┤ file_meta_id │         │ id (PK)      │
│ public_id    │         │ product_id───┼────────▶│ public_id    │
│ file_name    │         │ is_primary   │         └──────────────┘
│ original_name│         │ display_order│
│ file_path    │         │ alt_text     │
│ file_size    │         └──────────────┘
│ content_type │
│ file_type    │
└──────────────┘
```

## Migration History

### V1: Initial Schema
**File**: `V1__Initial_Schema.sql`

Creates core tables:
- `appuser` - User accounts with roles
- `category` - Product categories with hierarchy
- `product` - Product catalog
- `product_category` - Many-to-many product-category relationship

**Key Features**:
- UUID-based public identifiers for API exposure
- Hierarchical categories via self-referencing foreign key
- Proper indexing on foreign keys
- Timestamp tracking (created_at, updated_at)

### V2: Reusable Attribute System
**File**: `V2__Create_Reusable_Attribute_System.sql`

Creates attribute tables:
- `attribute` - Reusable attribute definitions (Color, Size, Brand)
- `attribute_option` - Specific values for attributes (Red, Large, Nike)
- `product_attribute_value` - Junction table linking products to attribute values

**Benefits**:
- **Reusability**: Same attributes across multiple products
- **Flexibility**: Add attributes without schema changes
- **Data Integrity**: Composite unique constraints
- **Performance**: Indexed relationships

### V3: Sample Attributes Data
**File**: `V3__Sample_Attributes_Data.sql`

Populates common e-commerce attributes:
- Color: Red, Blue, Green, Black, White, Gray, Yellow, Orange
- Size: XS, S, M, L, XL, XXL
- Material: Cotton, Polyester, Leather, Denim, Wool
- Brand: Nike, Adidas, Apple, Samsung, Sony
- Storage: 64GB, 128GB, 256GB, 512GB, 1TB
- RAM, Screen Size, Weight, Style, Operating System

### V4: Add Product Description Fields
**File**: `V4__Add_Short_Description_To_Product.sql`

Enhances product table:
- `short_description` VARCHAR(500) - Brief product summary
- `description` TEXT - Rich HTML content for detailed descriptions

### V5: Sample Products and Categories
**File**: `V5__Sample_Categories_Products_And_Attributes.sql`

Seeds database with:
- Category hierarchy (Electronics, Clothing, Sports)
- 10 sample products with descriptions
- Product-category associations
- Product-attribute assignments

### V6: Fix UUID Column Type
**File**: `V6__Fix_UUID_Column_Type.sql`

Standardizes UUID columns to VARCHAR(36).

### V7: Add Slug Fields
**File**: `V7__Add_Slug_To_Product_And_Category.sql`

Adds SEO-friendly slugs:
- `product.slug` - URL-friendly product identifier
- `category.slug` - URL-friendly category identifier

### V8: Cart Tables
**File**: `V8__Create_Cart_Tables.sql`

Creates shopping cart:
- `cart` - User shopping carts
- `cart_item` - Items in cart with quantities

### V9: File Storage Tables
**File**: `V9__Create_File_Storage_Tables.sql`

Creates file management system:
- `file_metadata` - Reusable file metadata storage
- `product_image` - Product-specific image associations

**Features**:
- Reusable file storage for any entity
- Primary image designation
- Display order control
- Alt text for accessibility

### V10: Order Tables
**File**: `V10__Create_Order_Tables.sql`

Creates order management:
- `order` - Order header with addresses and customer info
- `order_item` - Line items with product snapshots
- `payment` - Payment records with transaction details

**Payment Methods**: CREDIT_CARD, DEBIT_CARD, PAYPAL, BANK_TRANSFER, CASH_ON_DELIVERY

**Order Status**: PENDING, CONFIRMED, SHIPPED, DELIVERED, CANCELLED

**Payment Status**: PENDING, COMPLETED, FAILED, REFUNDED

## Table Schemas

### appuser
```sql
CREATE TABLE appuser (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    public_id VARCHAR(36) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    role ENUM('ADMIN', 'CUSTOMER') DEFAULT 'CUSTOMER',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### category
```sql
CREATE TABLE category (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    public_id VARCHAR(36) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE,
    description TEXT,
    parent_category_id BIGINT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_category_id) REFERENCES category(id) ON DELETE CASCADE
);
```

### product
```sql
CREATE TABLE product (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    public_id VARCHAR(36) UNIQUE NOT NULL,
    sku VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE,
    short_description VARCHAR(500),
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    sale_price DECIMAL(10,2),
    stock_quantity INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### attribute
```sql
CREATE TABLE attribute (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    public_id VARCHAR(36) UNIQUE NOT NULL,
    name VARCHAR(100) UNIQUE NOT NULL,
    description VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### attribute_option
```sql
CREATE TABLE attribute_option (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    public_id VARCHAR(36) UNIQUE NOT NULL,
    attribute_id BIGINT NOT NULL,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (attribute_id) REFERENCES attribute(id) ON DELETE CASCADE,
    UNIQUE KEY unique_attribute_option (attribute_id, name)
);
```

### cart
```sql
CREATE TABLE cart (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    public_id VARCHAR(36) UNIQUE NOT NULL,
    user_id BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES appuser(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_cart (user_id)
);
```

### order
```sql
CREATE TABLE `order` (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    public_id VARCHAR(36) UNIQUE NOT NULL,
    user_id BIGINT NOT NULL,
    order_number VARCHAR(50) UNIQUE NOT NULL,
    status ENUM('PENDING', 'CONFIRMED', 'SHIPPED', 'DELIVERED', 'CANCELLED') DEFAULT 'PENDING',
    payment_id BIGINT,
    total_amount DECIMAL(10,2) NOT NULL,
    shipping_address_line1 VARCHAR(255) NOT NULL,
    shipping_address_line2 VARCHAR(255),
    shipping_city VARCHAR(100) NOT NULL,
    shipping_state VARCHAR(100) NOT NULL,
    shipping_postal_code VARCHAR(20) NOT NULL,
    shipping_country VARCHAR(100) NOT NULL,
    billing_address_line1 VARCHAR(255) NOT NULL,
    billing_address_line2 VARCHAR(255),
    billing_city VARCHAR(100) NOT NULL,
    billing_state VARCHAR(100) NOT NULL,
    billing_postal_code VARCHAR(20) NOT NULL,
    billing_country VARCHAR(100) NOT NULL,
    customer_email VARCHAR(255) NOT NULL,
    customer_phone VARCHAR(20) NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES appuser(id)
);
```

### file_metadata
```sql
CREATE TABLE file_metadata (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    public_id VARCHAR(36) UNIQUE NOT NULL,
    file_name VARCHAR(255) UNIQUE NOT NULL,
    original_file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT NOT NULL,
    content_type VARCHAR(100) NOT NULL,
    file_type ENUM('IMAGE', 'DOCUMENT', 'VIDEO', 'OTHER') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

## Indexing Strategy

### Primary Indexes
All tables have auto-increment `id` as primary key.

### Unique Indexes
- `public_id` on all entities (for API exposure)
- `email` on appuser
- `sku` on product
- `slug` on product and category
- `file_name` on file_metadata
- `order_number` on order
- Composite unique keys on junction tables

### Foreign Key Indexes
Automatic indexes on all foreign key columns for join optimization.

### Query Optimization Indexes
- `category.parent_category_id` for hierarchy queries
- `product_category.category_id` for category filtering
- `cart.user_id` for user cart lookups
- `order.user_id` for user order history

## Data Integrity Constraints

### Referential Integrity
- **CASCADE DELETE**: Categories, cart items, product associations
- **RESTRICT DELETE**: Products with active orders
- **NULL ON DELETE**: Optional relationships

### Check Constraints
- `price >= 0` and `sale_price >= 0`
- `stock_quantity >= 0`
- `quantity > 0` for cart items and order items

### Business Rules
- User can have only one active cart (UNIQUE constraint)
- Product SKU must be unique
- Attribute options unique per attribute
- Order numbers auto-generated and unique

## Performance Considerations

### Normalization
- Third Normal Form (3NF) for most tables
- Denormalization in `order_item` (stores product snapshot)

### Query Patterns
- Pagination on product lists
- Eager loading for product-category relationships
- Lazy loading for large collections (images, attributes)
- Indexed searches on name, SKU, slug

### Scalability
- UUID-based public IDs for distributed systems
- Separate file metadata table for reusability
- Order item snapshots prevent issues with product changes

## Backup and Recovery

### Recommended Strategy
- Daily full backups
- Hourly incremental backups
- Transaction log backups every 15 minutes
- Point-in-time recovery capability

### Critical Tables (Priority Order)
1. `order`, `order_item`, `payment` - Financial data
2. `appuser` - User accounts
3. `product`, `cart`, `cart_item` - Business operations
4. `category`, `attribute`, `attribute_option` - Configuration
5. `file_metadata`, `product_image` - File references

---

**Related Documentation**:
- [System Architecture](./01-SystemArchitecture.md)
- [Product Module](./modules/ProductModule.md)
- [Order Module](./modules/OrderModule.md)

-- ===================================================================
-- V6: Add Slug Fields to Product and Category
-- Adds slug columns for SEO-friendly URLs
-- ===================================================================

-- Add slug column to product table (nullable first, then populate and make NOT NULL)
ALTER TABLE product
ADD COLUMN slug VARCHAR(255) AFTER name;

-- Add slug column to category table (nullable first, then populate and make NOT NULL)
ALTER TABLE category
ADD COLUMN slug VARCHAR(255) AFTER name;

-- Populate slug for products from name (lowercase, replace spaces with hyphens)
UPDATE product 
SET slug = LOWER(REPLACE(TRIM(name), ' ', '-'));

-- Populate slug for categories from name (lowercase, replace spaces with hyphens)
UPDATE category 
SET slug = LOWER(REPLACE(TRIM(name), ' ', '-'));

-- Now make slug NOT NULL and UNIQUE
ALTER TABLE product
MODIFY COLUMN slug VARCHAR(255) NOT NULL UNIQUE;

ALTER TABLE category
MODIFY COLUMN slug VARCHAR(255) NOT NULL UNIQUE;

-- Create indexes for slug fields for better performance
CREATE INDEX idx_product_slug ON product(slug);
CREATE INDEX idx_category_slug ON category(slug);

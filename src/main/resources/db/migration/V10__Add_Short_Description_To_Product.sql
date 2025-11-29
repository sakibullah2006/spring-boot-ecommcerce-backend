-- V10: Add short description to product and modify description column type for rich text HTML
-- This migration adds a short_description field (VARCHAR 500) and changes description to TEXT for HTML content

-- Add short_description column
ALTER TABLE product
ADD COLUMN short_description VARCHAR(500);

-- Modify description column to TEXT type to store rich text HTML content
-- PostgreSQL allows this change without data loss
ALTER TABLE product
ALTER COLUMN description TYPE TEXT;

-- Add comment for documentation
COMMENT ON COLUMN product.short_description IS 'Short product description (plain text, max 500 chars)';
COMMENT ON COLUMN product.description IS 'Full product description (supports rich text HTML content)';

-- V10: Add short description to product and modify description column type for rich text HTML
-- This migration adds a short_description field (VARCHAR 500) and changes description to TEXT for HTML content

-- Add short_description column if it doesn't exist
ALTER TABLE product
ADD COLUMN IF NOT EXISTS short_description VARCHAR(500);

-- Modify description column to TEXT type to store rich text HTML content
-- MySQL/MariaDB syntax
ALTER TABLE product
MODIFY COLUMN description TEXT;

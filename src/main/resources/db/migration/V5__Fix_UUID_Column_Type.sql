-- ===================================================================
-- V5: Fix UUID Column Type
-- Changes public_id column from VARCHAR to CHAR(36) to properly store UUID values
-- ===================================================================

-- Modify the appuser table to use CHAR(36) for UUID storage
ALTER TABLE appuser MODIFY COLUMN public_id CHAR(36) NOT NULL;

-- Modify the category table to use CHAR(36) for UUID storage  
ALTER TABLE category MODIFY COLUMN public_id CHAR(36) NOT NULL;

-- Modify the product table to use CHAR(36) for UUID storage
ALTER TABLE product MODIFY COLUMN public_id CHAR(36) NOT NULL;
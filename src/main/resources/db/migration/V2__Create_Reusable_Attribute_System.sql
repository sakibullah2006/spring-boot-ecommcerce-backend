-- ===================================================================
-- V2: Reusable Attribute System
-- Creates the attribute system for product attributes that can be reused
-- across multiple products: attribute -> attribute_option -> product_attribute_value
-- ===================================================================

-- Create attribute table (reusable attribute definitions)
CREATE TABLE attribute (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    public_id VARCHAR(36) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(500),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create attribute_option table (reusable options for each attribute)
CREATE TABLE attribute_option (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    public_id VARCHAR(36) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    attribute_id BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_attribute_option_attribute FOREIGN KEY (attribute_id) REFERENCES attribute(id) ON DELETE CASCADE,
    CONSTRAINT uk_attribute_option_name UNIQUE (attribute_id, name),
    CONSTRAINT uk_attribute_option_slug UNIQUE (attribute_id, slug)
);

-- Create product_attribute_value junction table (links products to specific attribute-option combinations)
CREATE TABLE product_attribute_value (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT NOT NULL,
    attribute_id BIGINT NOT NULL,
    attribute_option_id BIGINT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_product_attribute_value_product FOREIGN KEY (product_id) REFERENCES product(id) ON DELETE CASCADE,
    CONSTRAINT fk_product_attribute_value_attribute FOREIGN KEY (attribute_id) REFERENCES attribute(id) ON DELETE CASCADE,
    CONSTRAINT fk_product_attribute_value_option FOREIGN KEY (attribute_option_id) REFERENCES attribute_option(id) ON DELETE CASCADE,
    CONSTRAINT uk_product_attribute_value UNIQUE (product_id, attribute_id, attribute_option_id)
);

-- Create indexes for the attribute system
CREATE INDEX idx_attribute_name ON attribute(name);
CREATE INDEX idx_attribute_slug ON attribute(slug);
CREATE INDEX idx_attribute_public_id ON attribute(public_id);
CREATE INDEX idx_attribute_active ON attribute(is_active);

CREATE INDEX idx_attribute_option_attribute_id ON attribute_option(attribute_id);
CREATE INDEX idx_attribute_option_public_id ON attribute_option(public_id);
CREATE INDEX idx_attribute_option_active ON attribute_option(is_active);
CREATE INDEX idx_attribute_option_name ON attribute_option(name);

CREATE INDEX idx_product_attribute_value_product ON product_attribute_value(product_id);
CREATE INDEX idx_product_attribute_value_attribute ON product_attribute_value(attribute_id);
CREATE INDEX idx_product_attribute_value_option ON product_attribute_value(attribute_option_id);
CREATE INDEX idx_product_attribute_value_active ON product_attribute_value(is_active);
-- ===================================================================
-- V3: Sample Data - Initial Attributes and Options
-- Inserts commonly used attributes and their options for e-commerce products
-- ===================================================================

-- Insert common attributes for e-commerce products
INSERT INTO attribute (public_id, name, slug, description, is_active) VALUES
(UUID(), 'Color', 'color', 'Product color variations', TRUE),
(UUID(), 'Size', 'size', 'Product size variations (clothing, shoes, etc.)', TRUE),
(UUID(), 'Material', 'material', 'Product material composition', TRUE),
(UUID(), 'Brand', 'brand', 'Product brand/manufacturer', TRUE),
(UUID(), 'Storage', 'storage', 'Storage capacity for electronics', TRUE),
(UUID(), 'RAM', 'ram', 'Memory capacity for computers/phones', TRUE),
(UUID(), 'Screen Size', 'screen-size', 'Display screen dimensions', TRUE),
(UUID(), 'Weight', 'weight', 'Product weight categories', TRUE),
(UUID(), 'Style', 'style', 'Product style/design variations', TRUE),
(UUID(), 'Operating System', 'operating-system', 'Software operating system', TRUE);

-- Insert color options
INSERT INTO attribute_option (public_id, name, slug, description, is_active, attribute_id)
SELECT UUID(), 'Red', 'red', 'Red color variant', TRUE, id FROM attribute WHERE slug = 'color';

INSERT INTO attribute_option (public_id, name, slug, description, is_active, attribute_id)
SELECT UUID(), 'Blue', 'blue', 'Blue color variant', TRUE, id FROM attribute WHERE slug = 'color';

INSERT INTO attribute_option (public_id, name, slug, description, is_active, attribute_id)
SELECT UUID(), 'Green', 'green', 'Green color variant', TRUE, id FROM attribute WHERE slug = 'color';

INSERT INTO attribute_option (public_id, name, slug, description, is_active, attribute_id)
SELECT UUID(), 'Black', 'black', 'Black color variant', TRUE, id FROM attribute WHERE slug = 'color';

INSERT INTO attribute_option (public_id, name, slug, description, is_active, attribute_id)
SELECT UUID(), 'White', 'white', 'White color variant', TRUE, id FROM attribute WHERE slug = 'color';

INSERT INTO attribute_option (public_id, name, slug, description, is_active, attribute_id)
SELECT UUID(), 'Gray', 'gray', 'Gray color variant', TRUE, id FROM attribute WHERE slug = 'color';

INSERT INTO attribute_option (public_id, name, slug, description, is_active, attribute_id)
SELECT UUID(), 'Yellow', 'yellow', 'Yellow color variant', TRUE, id FROM attribute WHERE slug = 'color';

INSERT INTO attribute_option (public_id, name, slug, description, is_active, attribute_id)
SELECT UUID(), 'Orange', 'orange', 'Orange color variant', TRUE, id FROM attribute WHERE slug = 'color';

-- Insert size options
INSERT INTO attribute_option (public_id, name, slug, description, is_active, attribute_id)
SELECT UUID(), 'XS', 'xs', 'Extra Small', TRUE, id FROM attribute WHERE slug = 'size';

INSERT INTO attribute_option (public_id, name, slug, description, is_active, attribute_id)
SELECT UUID(), 'S', 's', 'Small', TRUE, id FROM attribute WHERE slug = 'size';

INSERT INTO attribute_option (public_id, name, slug, description, is_active, attribute_id)
SELECT UUID(), 'M', 'm', 'Medium', TRUE, id FROM attribute WHERE slug = 'size';

INSERT INTO attribute_option (public_id, name, slug, description, is_active, attribute_id)
SELECT UUID(), 'L', 'l', 'Large', TRUE, id FROM attribute WHERE slug = 'size';

INSERT INTO attribute_option (public_id, name, slug, description, is_active, attribute_id)
SELECT UUID(), 'XL', 'xl', 'Extra Large', TRUE, id FROM attribute WHERE slug = 'size';

INSERT INTO attribute_option (public_id, name, slug, description, is_active, attribute_id)
SELECT UUID(), 'XXL', 'xxl', 'Double Extra Large', TRUE, id FROM attribute WHERE slug = 'size';

-- Insert material options
INSERT INTO attribute_option (public_id, name, slug, description, is_active, attribute_id)
SELECT UUID(), 'Cotton', 'cotton', '100% Cotton material', TRUE, id FROM attribute WHERE slug = 'material';

INSERT INTO attribute_option (public_id, name, slug, description, is_active, attribute_id)
SELECT UUID(), 'Polyester', 'polyester', 'Polyester fabric', TRUE, id FROM attribute WHERE slug = 'material';

INSERT INTO attribute_option (public_id, name, slug, description, is_active, attribute_id)
SELECT UUID(), 'Leather', 'leather', 'Genuine leather material', TRUE, id FROM attribute WHERE slug = 'material';

INSERT INTO attribute_option (public_id, name, slug, description, is_active, attribute_id)
SELECT UUID(), 'Denim', 'denim', 'Denim/Jeans material', TRUE, id FROM attribute WHERE slug = 'material';

INSERT INTO attribute_option (public_id, name, slug, description, is_active, attribute_id)
SELECT UUID(), 'Wool', 'wool', 'Wool material', TRUE, id FROM attribute WHERE slug = 'material';

-- Insert brand options (popular brands)
INSERT INTO attribute_option (public_id, name, slug, description, is_active, attribute_id)
SELECT UUID(), 'Nike', 'nike', 'Nike brand products', TRUE, id FROM attribute WHERE slug = 'brand';

INSERT INTO attribute_option (public_id, name, slug, description, is_active, attribute_id)
SELECT UUID(), 'Adidas', 'adidas', 'Adidas brand products', TRUE, id FROM attribute WHERE slug = 'brand';

INSERT INTO attribute_option (public_id, name, slug, description, is_active, attribute_id)
SELECT UUID(), 'Apple', 'apple', 'Apple brand products', TRUE, id FROM attribute WHERE slug = 'brand';

INSERT INTO attribute_option (public_id, name, slug, description, is_active, attribute_id)
SELECT UUID(), 'Samsung', 'samsung', 'Samsung brand products', TRUE, id FROM attribute WHERE slug = 'brand';

INSERT INTO attribute_option (public_id, name, slug, description, is_active, attribute_id)
SELECT UUID(), 'Sony', 'sony', 'Sony brand products', TRUE, id FROM attribute WHERE slug = 'brand';

-- Insert storage options
INSERT INTO attribute_option (public_id, name, slug, description, is_active, attribute_id)
SELECT UUID(), '64GB', '64gb', '64 Gigabytes storage', TRUE, id FROM attribute WHERE slug = 'storage';

INSERT INTO attribute_option (public_id, name, slug, description, is_active, attribute_id)
SELECT UUID(), '128GB', '128gb', '128 Gigabytes storage', TRUE, id FROM attribute WHERE slug = 'storage';

INSERT INTO attribute_option (public_id, name, slug, description, is_active, attribute_id)
SELECT UUID(), '256GB', '256gb', '256 Gigabytes storage', TRUE, id FROM attribute WHERE slug = 'storage';

INSERT INTO attribute_option (public_id, name, slug, description, is_active, attribute_id)
SELECT UUID(), '512GB', '512gb', '512 Gigabytes storage', TRUE, id FROM attribute WHERE slug = 'storage';

INSERT INTO attribute_option (public_id, name, slug, description, is_active, attribute_id)
SELECT UUID(), '1TB', '1tb', '1 Terabyte storage', TRUE, id FROM attribute WHERE slug = 'storage';
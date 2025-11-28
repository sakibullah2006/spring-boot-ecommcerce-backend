-- ===================================================================
-- V4: Sample Data - Categories and Products with Attribute Assignments
-- Creates sample categories, products, and demonstrates reusable attribute system
-- ===================================================================

-- Insert sample categories with hierarchy
INSERT INTO category (public_id, name, description, parent_category_id) VALUES
(UUID(), 'Electronics', 'Electronic devices and gadgets', NULL),
(UUID(), 'Clothing', 'Apparel and fashion items', NULL),
(UUID(), 'Sports & Outdoors', 'Sporting goods and outdoor equipment', NULL);

-- Insert subcategories for Electronics
INSERT INTO category (public_id, name, description, parent_category_id)
SELECT UUID(), 'Smartphones', 'Mobile phones and accessories', id FROM category WHERE name = 'Electronics';

INSERT INTO category (public_id, name, description, parent_category_id)
SELECT UUID(), 'Laptops', 'Portable computers and accessories', id FROM category WHERE name = 'Electronics';

INSERT INTO category (public_id, name, description, parent_category_id)
SELECT UUID(), 'Tablets', 'Tablet computers and accessories', id FROM category WHERE name = 'Electronics';

-- Insert subcategories for Clothing
INSERT INTO category (public_id, name, description, parent_category_id)
SELECT UUID(), 'Men''s Clothing', 'Men''s fashion and apparel', id FROM category WHERE name = 'Clothing';

INSERT INTO category (public_id, name, description, parent_category_id)
SELECT UUID(), 'Women''s Clothing', 'Women''s fashion and apparel', id FROM category WHERE name = 'Clothing';

INSERT INTO category (public_id, name, description, parent_category_id)
SELECT UUID(), 'Shoes', 'Footwear for all genders', id FROM category WHERE name = 'Clothing';

-- Insert subcategories for Sports & Outdoors
INSERT INTO category (public_id, name, description, parent_category_id)
SELECT UUID(), 'Athletic Wear', 'Sports clothing and activewear', id FROM category WHERE name = 'Sports & Outdoors';

INSERT INTO category (public_id, name, description, parent_category_id)
SELECT UUID(), 'Fitness Equipment', 'Exercise and fitness gear', id FROM category WHERE name = 'Sports & Outdoors';

-- Insert sample products
-- Electronics Products
INSERT INTO product (public_id, sku, name, description, price, sale_price, stock_quantity) VALUES
(UUID(), 'IPHONE15-128-BLACK', 'iPhone 15 128GB Black', 'Latest iPhone with 128GB storage in black color', 999.99, 949.99, 50),
(UUID(), 'SAMSUNG-S24-256-BLUE', 'Samsung Galaxy S24 256GB Blue', 'Samsung flagship phone with 256GB storage in blue', 899.99, 849.99, 30),
(UUID(), 'MACBOOK-PRO-16-SILVER', 'MacBook Pro 16" Silver', '16-inch MacBook Pro with M3 chip in silver', 2499.99, 2399.99, 15),
(UUID(), 'IPAD-AIR-256-GRAY', 'iPad Air 256GB Space Gray', 'iPad Air with 256GB storage in space gray', 749.99, 699.99, 25);

-- Clothing Products
INSERT INTO product (public_id, sku, name, description, price, sale_price, stock_quantity) VALUES
(UUID(), 'NIKE-TSHIRT-CTN-RED-M', 'Nike Cotton T-Shirt Red Medium', 'Nike cotton t-shirt in red color, medium size', 29.99, 24.99, 100),
(UUID(), 'ADIDAS-HOODIE-BLK-L', 'Adidas Black Hoodie Large', 'Adidas black hoodie in large size', 79.99, 74.99, 75),
(UUID(), 'LEVIS-JEANS-DENIM-32', 'Levi''s Denim Jeans Size 32', 'Classic Levi''s denim jeans in size 32', 89.99, 79.99, 60),
(UUID(), 'NIKE-SNEAKERS-WHT-10', 'Nike White Sneakers Size 10', 'Nike white sneakers in size 10', 119.99, 109.99, 40);

-- Sports Products
INSERT INTO product (public_id, sku, name, description, price, sale_price, stock_quantity) VALUES
(UUID(), 'NIKE-SHORTS-POLY-BLK-M', 'Nike Athletic Shorts Black Medium', 'Nike polyester athletic shorts in black, medium size', 39.99, 34.99, 80),
(UUID(), 'YOGA-MAT-PINK-STD', 'Premium Yoga Mat Pink', 'High-quality yoga mat in pink color', 49.99, 44.99, 45);

-- Assign categories to products
-- iPhone 15 -> Smartphones
INSERT INTO product_category (product_id, category_id)
SELECT p.id, c.id FROM product p, category c 
WHERE p.sku = 'IPHONE15-128-BLACK' AND c.name = 'Smartphones';

-- Samsung Galaxy -> Smartphones  
INSERT INTO product_category (product_id, category_id)
SELECT p.id, c.id FROM product p, category c 
WHERE p.sku = 'SAMSUNG-S24-256-BLUE' AND c.name = 'Smartphones';

-- MacBook -> Laptops
INSERT INTO product_category (product_id, category_id)
SELECT p.id, c.id FROM product p, category c 
WHERE p.sku = 'MACBOOK-PRO-16-SILVER' AND c.name = 'Laptops';

-- iPad -> Tablets
INSERT INTO product_category (product_id, category_id)
SELECT p.id, c.id FROM product p, category c 
WHERE p.sku = 'IPAD-AIR-256-GRAY' AND c.name = 'Tablets';

-- Nike T-Shirt -> Men's Clothing
INSERT INTO product_category (product_id, category_id)
SELECT p.id, c.id FROM product p, category c 
WHERE p.sku = 'NIKE-TSHIRT-CTN-RED-M' AND c.name = 'Men''s Clothing';

-- Adidas Hoodie -> Men's Clothing
INSERT INTO product_category (product_id, category_id)
SELECT p.id, c.id FROM product p, category c 
WHERE p.sku = 'ADIDAS-HOODIE-BLK-L' AND c.name = 'Men''s Clothing';

-- Levi's Jeans -> Men's Clothing
INSERT INTO product_category (product_id, category_id)
SELECT p.id, c.id FROM product p, category c 
WHERE p.sku = 'LEVIS-JEANS-DENIM-32' AND c.name = 'Men''s Clothing';

-- Nike Sneakers -> Shoes
INSERT INTO product_category (product_id, category_id)
SELECT p.id, c.id FROM product p, category c 
WHERE p.sku = 'NIKE-SNEAKERS-WHT-10' AND c.name = 'Shoes';

-- Nike Athletic Shorts -> Athletic Wear
INSERT INTO product_category (product_id, category_id)
SELECT p.id, c.id FROM product p, category c 
WHERE p.sku = 'NIKE-SHORTS-POLY-BLK-M' AND c.name = 'Athletic Wear';

-- Yoga Mat -> Fitness Equipment
INSERT INTO product_category (product_id, category_id)
SELECT p.id, c.id FROM product p, category c 
WHERE p.sku = 'YOGA-MAT-PINK-STD' AND c.name = 'Fitness Equipment';

-- ===================================================================
-- ASSIGN REUSABLE ATTRIBUTES TO PRODUCTS
-- This demonstrates how the same attributes can be reused across different products
-- ===================================================================

-- iPhone 15 Attributes: Color=Black, Brand=Apple, Storage=128GB
INSERT INTO product_attribute_value (product_id, attribute_id, attribute_option_id)
SELECT p.id, a.id, ao.id 
FROM product p, attribute a, attribute_option ao
WHERE p.sku = 'IPHONE15-128-BLACK' AND a.slug = 'color' AND ao.slug = 'black';

INSERT INTO product_attribute_value (product_id, attribute_id, attribute_option_id)
SELECT p.id, a.id, ao.id 
FROM product p, attribute a, attribute_option ao
WHERE p.sku = 'IPHONE15-128-BLACK' AND a.slug = 'brand' AND ao.slug = 'apple';

INSERT INTO product_attribute_value (product_id, attribute_id, attribute_option_id)
SELECT p.id, a.id, ao.id 
FROM product p, attribute a, attribute_option ao
WHERE p.sku = 'IPHONE15-128-BLACK' AND a.slug = 'storage' AND ao.slug = '128gb';

-- Samsung Galaxy Attributes: Color=Blue, Brand=Samsung, Storage=256GB
INSERT INTO product_attribute_value (product_id, attribute_id, attribute_option_id)
SELECT p.id, a.id, ao.id 
FROM product p, attribute a, attribute_option ao
WHERE p.sku = 'SAMSUNG-S24-256-BLUE' AND a.slug = 'color' AND ao.slug = 'blue';

INSERT INTO product_attribute_value (product_id, attribute_id, attribute_option_id)
SELECT p.id, a.id, ao.id 
FROM product p, attribute a, attribute_option ao
WHERE p.sku = 'SAMSUNG-S24-256-BLUE' AND a.slug = 'brand' AND ao.slug = 'samsung';

INSERT INTO product_attribute_value (product_id, attribute_id, attribute_option_id)
SELECT p.id, a.id, ao.id 
FROM product p, attribute a, attribute_option ao
WHERE p.sku = 'SAMSUNG-S24-256-BLUE' AND a.slug = 'storage' AND ao.slug = '256gb';

-- MacBook Pro Attributes: Color=Gray, Brand=Apple, Storage=512GB
INSERT INTO product_attribute_value (product_id, attribute_id, attribute_option_id)
SELECT p.id, a.id, ao.id 
FROM product p, attribute a, attribute_option ao
WHERE p.sku = 'MACBOOK-PRO-16-SILVER' AND a.slug = 'color' AND ao.slug = 'gray';

INSERT INTO product_attribute_value (product_id, attribute_id, attribute_option_id)
SELECT p.id, a.id, ao.id 
FROM product p, attribute a, attribute_option ao
WHERE p.sku = 'MACBOOK-PRO-16-SILVER' AND a.slug = 'brand' AND ao.slug = 'apple';

INSERT INTO product_attribute_value (product_id, attribute_id, attribute_option_id)
SELECT p.id, a.id, ao.id 
FROM product p, attribute a, attribute_option ao
WHERE p.sku = 'MACBOOK-PRO-16-SILVER' AND a.slug = 'storage' AND ao.slug = '512gb';

-- iPad Air Attributes: Color=Gray, Brand=Apple, Storage=256GB
INSERT INTO product_attribute_value (product_id, attribute_id, attribute_option_id)
SELECT p.id, a.id, ao.id 
FROM product p, attribute a, attribute_option ao
WHERE p.sku = 'IPAD-AIR-256-GRAY' AND a.slug = 'color' AND ao.slug = 'gray';

INSERT INTO product_attribute_value (product_id, attribute_id, attribute_option_id)
SELECT p.id, a.id, ao.id 
FROM product p, attribute a, attribute_option ao
WHERE p.sku = 'IPAD-AIR-256-GRAY' AND a.slug = 'brand' AND ao.slug = 'apple';

INSERT INTO product_attribute_value (product_id, attribute_id, attribute_option_id)
SELECT p.id, a.id, ao.id 
FROM product p, attribute a, attribute_option ao
WHERE p.sku = 'IPAD-AIR-256-GRAY' AND a.slug = 'storage' AND ao.slug = '256gb';

-- Nike T-Shirt Attributes: Color=Red, Size=M, Material=Cotton, Brand=Nike
INSERT INTO product_attribute_value (product_id, attribute_id, attribute_option_id)
SELECT p.id, a.id, ao.id 
FROM product p, attribute a, attribute_option ao
WHERE p.sku = 'NIKE-TSHIRT-CTN-RED-M' AND a.slug = 'color' AND ao.slug = 'red';

INSERT INTO product_attribute_value (product_id, attribute_id, attribute_option_id)
SELECT p.id, a.id, ao.id 
FROM product p, attribute a, attribute_option ao
WHERE p.sku = 'NIKE-TSHIRT-CTN-RED-M' AND a.slug = 'size' AND ao.slug = 'm';

INSERT INTO product_attribute_value (product_id, attribute_id, attribute_option_id)
SELECT p.id, a.id, ao.id 
FROM product p, attribute a, attribute_option ao
WHERE p.sku = 'NIKE-TSHIRT-CTN-RED-M' AND a.slug = 'material' AND ao.slug = 'cotton';

INSERT INTO product_attribute_value (product_id, attribute_id, attribute_option_id)
SELECT p.id, a.id, ao.id 
FROM product p, attribute a, attribute_option ao
WHERE p.sku = 'NIKE-TSHIRT-CTN-RED-M' AND a.slug = 'brand' AND ao.slug = 'nike';

-- Adidas Hoodie Attributes: Color=Black, Size=L, Brand=Adidas
INSERT INTO product_attribute_value (product_id, attribute_id, attribute_option_id)
SELECT p.id, a.id, ao.id 
FROM product p, attribute a, attribute_option ao
WHERE p.sku = 'ADIDAS-HOODIE-BLK-L' AND a.slug = 'color' AND ao.slug = 'black';

INSERT INTO product_attribute_value (product_id, attribute_id, attribute_option_id)
SELECT p.id, a.id, ao.id 
FROM product p, attribute a, attribute_option ao
WHERE p.sku = 'ADIDAS-HOODIE-BLK-L' AND a.slug = 'size' AND ao.slug = 'l';

INSERT INTO product_attribute_value (product_id, attribute_id, attribute_option_id)
SELECT p.id, a.id, ao.id 
FROM product p, attribute a, attribute_option ao
WHERE p.sku = 'ADIDAS-HOODIE-BLK-L' AND a.slug = 'brand' AND ao.slug = 'adidas';

-- Levi's Jeans Attributes: Material=Denim, Size=L (32 waist ~ L)
INSERT INTO product_attribute_value (product_id, attribute_id, attribute_option_id)
SELECT p.id, a.id, ao.id 
FROM product p, attribute a, attribute_option ao
WHERE p.sku = 'LEVIS-JEANS-DENIM-32' AND a.slug = 'material' AND ao.slug = 'denim';

INSERT INTO product_attribute_value (product_id, attribute_id, attribute_option_id)
SELECT p.id, a.id, ao.id 
FROM product p, attribute a, attribute_option ao
WHERE p.sku = 'LEVIS-JEANS-DENIM-32' AND a.slug = 'size' AND ao.slug = 'l';

-- Nike Sneakers Attributes: Color=White, Brand=Nike
INSERT INTO product_attribute_value (product_id, attribute_id, attribute_option_id)
SELECT p.id, a.id, ao.id 
FROM product p, attribute a, attribute_option ao
WHERE p.sku = 'NIKE-SNEAKERS-WHT-10' AND a.slug = 'color' AND ao.slug = 'white';

INSERT INTO product_attribute_value (product_id, attribute_id, attribute_option_id)
SELECT p.id, a.id, ao.id 
FROM product p, attribute a, attribute_option ao
WHERE p.sku = 'NIKE-SNEAKERS-WHT-10' AND a.slug = 'brand' AND ao.slug = 'nike';

-- Nike Athletic Shorts Attributes: Color=Black, Size=M, Material=Polyester, Brand=Nike
INSERT INTO product_attribute_value (product_id, attribute_id, attribute_option_id)
SELECT p.id, a.id, ao.id 
FROM product p, attribute a, attribute_option ao
WHERE p.sku = 'NIKE-SHORTS-POLY-BLK-M' AND a.slug = 'color' AND ao.slug = 'black';

INSERT INTO product_attribute_value (product_id, attribute_id, attribute_option_id)
SELECT p.id, a.id, ao.id 
FROM product p, attribute a, attribute_option ao
WHERE p.sku = 'NIKE-SHORTS-POLY-BLK-M' AND a.slug = 'size' AND ao.slug = 'm';

INSERT INTO product_attribute_value (product_id, attribute_id, attribute_option_id)
SELECT p.id, a.id, ao.id 
FROM product p, attribute a, attribute_option ao
WHERE p.sku = 'NIKE-SHORTS-POLY-BLK-M' AND a.slug = 'material' AND ao.slug = 'polyester';

INSERT INTO product_attribute_value (product_id, attribute_id, attribute_option_id)
SELECT p.id, a.id, ao.id 
FROM product p, attribute a, attribute_option ao
WHERE p.sku = 'NIKE-SHORTS-POLY-BLK-M' AND a.slug = 'brand' AND ao.slug = 'nike';

-- Yoga Mat Attributes: Color=Pink
INSERT INTO product_attribute_value (product_id, attribute_id, attribute_option_id)
SELECT p.id, a.id, ao.id 
FROM product p, attribute a, attribute_option ao
WHERE p.sku = 'YOGA-MAT-PINK-STD' AND a.slug = 'color' AND ao.slug = 'red'; -- Using red as closest to pink
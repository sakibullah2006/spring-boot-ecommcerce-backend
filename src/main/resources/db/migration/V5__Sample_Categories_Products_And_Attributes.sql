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

-- Insert sample products with short descriptions and rich text HTML
-- Electronics Products
INSERT INTO product (public_id, sku, name, short_description, description, price, sale_price, stock_quantity) VALUES
(UUID(), 'IPHONE15-128-BLACK', 'iPhone 15 128GB Black', 
 'Latest iPhone with A17 Pro chip, advanced camera system, and stunning display', 
 '<h2>iPhone 15 Features</h2><ul><li><strong>A17 Pro chip</strong> - Lightning-fast performance</li><li><strong>48MP Main camera</strong> - Pro-level photography</li><li><strong>128GB storage</strong> - Plenty of space for photos and apps</li><li><strong>All-day battery</strong> - Up to 20 hours video playback</li></ul><p>Available in elegant <em>black finish</em> with aerospace-grade aluminum design.</p>', 
 999.99, 949.99, 50),
(UUID(), 'SAMSUNG-S24-256-BLUE', 'Samsung Galaxy S24 256GB Blue', 
 'Flagship Samsung phone with AI features, incredible camera, and 256GB storage', 
 '<h2>Galaxy S24 Highlights</h2><ul><li><strong>Galaxy AI</strong> - Advanced AI features built-in</li><li><strong>50MP Camera</strong> - Nightography and 3x optical zoom</li><li><strong>256GB Storage</strong> - Ample space for everything</li><li><strong>6.2" Display</strong> - Stunning AMOLED screen</li></ul><p>Featuring the latest <strong>Snapdragon 8 Gen 3</strong> processor in a beautiful blue finish.</p>', 
 899.99, 849.99, 30),
(UUID(), 'MACBOOK-PRO-16-SILVER', 'MacBook Pro 16" Silver', 
 'Powerful 16-inch MacBook Pro with M3 chip for professional workflows', 
 '<h2>MacBook Pro Specifications</h2><ul><li><strong>M3 Chip</strong> - Next-generation Apple silicon</li><li><strong>16-inch Liquid Retina XDR</strong> - Stunning display</li><li><strong>Up to 22 hours battery</strong> - All-day performance</li><li><strong>Three Thunderbolt 4 ports</strong> - Ultimate connectivity</li></ul><p>Perfect for <em>creative professionals</em> working with video editing, 3D rendering, and software development.</p>', 
 2499.99, 2399.99, 15),
(UUID(), 'IPAD-AIR-256-GRAY', 'iPad Air 256GB Space Gray', 
 'Versatile iPad Air with M1 chip, perfect for creativity and productivity', 
 '<h2>iPad Air Features</h2><ul><li><strong>M1 chip</strong> - Desktop-class performance</li><li><strong>10.9-inch display</strong> - Liquid Retina screen</li><li><strong>256GB storage</strong> - Store more, do more</li><li><strong>12MP cameras</strong> - Front and back</li></ul><p>Works seamlessly with <strong>Apple Pencil</strong> and <strong>Magic Keyboard</strong> (sold separately).</p>', 
 749.99, 699.99, 25);

-- Clothing Products
INSERT INTO product (public_id, sku, name, short_description, description, price, sale_price, stock_quantity) VALUES
(UUID(), 'NIKE-TSHIRT-CTN-RED-M', 'Nike Cotton T-Shirt Red Medium', 
 'Classic Nike cotton t-shirt in vibrant red, medium size', 
 '<h2>Product Details</h2><ul><li><strong>Material:</strong> 100% premium cotton</li><li><strong>Size:</strong> Medium</li><li><strong>Color:</strong> Vibrant red</li><li><strong>Care:</strong> Machine washable</li></ul><p>Features the iconic <em>Nike Swoosh</em> logo. Perfect for casual wear or workouts.</p>', 
 29.99, 24.99, 100),
(UUID(), 'ADIDAS-HOODIE-BLK-L', 'Adidas Black Hoodie Large', 
 'Comfortable Adidas hoodie with classic design, large size', 
 '<h2>Hoodie Features</h2><ul><li><strong>Material:</strong> Cotton-polyester blend</li><li><strong>Size:</strong> Large</li><li><strong>Color:</strong> Classic black</li><li><strong>Features:</strong> Kangaroo pocket, drawstring hood</li></ul><p>Stay warm and stylish with the <strong>3-Stripes</strong> branding on the sleeves.</p>', 
 79.99, 74.99, 75),
(UUID(), 'LEVIS-JEANS-DENIM-32', 'Levi''s Denim Jeans Size 32', 
 'Classic Levi''s 501 denim jeans with timeless style, waist size 32', 
 '<h2>Classic Levi''s 501</h2><ul><li><strong>Fit:</strong> Original straight fit</li><li><strong>Material:</strong> 100% cotton denim</li><li><strong>Waist:</strong> 32 inches</li><li><strong>Style:</strong> Button fly</li></ul><p>The <em>iconic jean</em> that started it all. Built to last with <strong>reinforced stitching</strong>.</p>', 
 89.99, 79.99, 60),
(UUID(), 'NIKE-SNEAKERS-WHT-10', 'Nike White Sneakers Size 10', 
 'Stylish Nike sneakers in classic white, size 10', 
 '<h2>Sneaker Specifications</h2><ul><li><strong>Size:</strong> US 10</li><li><strong>Color:</strong> Clean white</li><li><strong>Upper:</strong> Leather and synthetic</li><li><strong>Sole:</strong> Rubber for traction</li></ul><p>Versatile design that goes with everything. Features <em>cushioned insole</em> for all-day comfort.</p>', 
 119.99, 109.99, 40);

-- Sports Products
INSERT INTO product (public_id, sku, name, short_description, description, price, sale_price, stock_quantity) VALUES
(UUID(), 'NIKE-SHORTS-POLY-BLK-M', 'Nike Athletic Shorts Black Medium', 
 'High-performance Nike athletic shorts for training and sports', 
 '<h2>Athletic Performance</h2><ul><li><strong>Material:</strong> Moisture-wicking polyester</li><li><strong>Size:</strong> Medium</li><li><strong>Features:</strong> Elastic waistband, side pockets</li><li><strong>Technology:</strong> Dri-FIT for sweat management</li></ul><p>Designed for <em>maximum mobility</em> during intense workouts and sports activities.</p>', 
 39.99, 34.99, 80),
(UUID(), 'YOGA-MAT-PINK-STD', 'Premium Yoga Mat Pink', 
 'Eco-friendly yoga mat with excellent grip and cushioning', 
 '<h2>Yoga Mat Features</h2><ul><li><strong>Thickness:</strong> 6mm for optimal cushioning</li><li><strong>Material:</strong> Non-toxic TPE</li><li><strong>Size:</strong> 183cm x 61cm</li><li><strong>Features:</strong> Non-slip surface, carrying strap included</li></ul><p>Perfect for <strong>yoga</strong>, <strong>pilates</strong>, and <em>meditation</em>. Easy to clean and maintain.</p>', 
 49.99, 44.99, 45);

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
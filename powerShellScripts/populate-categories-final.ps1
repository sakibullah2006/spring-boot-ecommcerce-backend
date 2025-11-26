# populate-categories-final.ps1
# Date: 2025-11-27
# Purpose: Populate 'category' table in MySQL with sample hierarchical data
# Auth: springboot/springboot
# DB: springboot
# Notes:
# - Uses database 'id' as foreign key in 'parent_category_id' (correct for JPA)
# - Generates UUIDs for 'public_id' (what your API exposes)
# - Idempotent via INSERT IGNORE (safe to re-run)

param(
    [string]$DbHost = "localhost",
    [int]$DbPort = 3306,
    [string]$DbName = "springboot",
    [string]$DbUser = "springboot",
    [string]$DbPassword = "springboot"
)

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Populate Categories (MySQL)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Host: $DbHost  Port: $DbPort  DB: $DbName  User: $DbUser" -ForegroundColor White

# Detect mysql client
$mysqlCandidates = @(
    "C:\xampp\mysql\bin\mysql.exe",
    "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe",
    "C:\Program Files\MySQL\MySQL Server 5.7\bin\mysql.exe"
)
$mysqlExe = $null
foreach ($path in $mysqlCandidates) { if (Test-Path $path) { $mysqlExe = $path; break } }
if (-not $mysqlExe) {
    try { $null = Get-Command mysql -ErrorAction Stop; $mysqlExe = "mysql" } catch {}
}
if (-not $mysqlExe) { Write-Host "ERROR: MySQL client not found. Add it to PATH or update script paths." -ForegroundColor Red; exit 1 }
Write-Host "Using MySQL client: $mysqlExe" -ForegroundColor Green

# Prepare SQL
$insertSql = @"
USE $DbName;

-- Main categories
INSERT IGNORE INTO category (name, description, public_id, created_at, updated_at) VALUES
('Electronics','Electronic devices and gadgets',UUID(),NOW(),NOW()),
('Clothing','Apparel and fashion items',UUID(),NOW(),NOW()),
('Books','Physical and digital books',UUID(),NOW(),NOW()),
('Home & Garden','Home improvement and garden supplies',UUID(),NOW(),NOW()),
('Sports & Outdoors','Sports equipment and outdoor gear',UUID(),NOW(),NOW()),
('Toys & Games','Toys, games, and entertainment',UUID(),NOW(),NOW()),
('Food & Beverages','Food items and drinks',UUID(),NOW(),NOW()),
('Health & Beauty','Health products and beauty items',UUID(),NOW(),NOW()),
('Automotive','Car parts and accessories',UUID(),NOW(),NOW()),
('Office Supplies','Office equipment and stationery',UUID(),NOW(),NOW());

-- Electronics children
INSERT IGNORE INTO category (name,description,parent_category_id,public_id,created_at,updated_at)
SELECT 'Smartphones','Mobile phones and accessories',id,UUID(),NOW(),NOW() FROM category WHERE name='Electronics';
INSERT IGNORE INTO category (name,description,parent_category_id,public_id,created_at,updated_at)
SELECT 'Laptops','Portable computers',id,UUID(),NOW(),NOW() FROM category WHERE name='Electronics';
INSERT IGNORE INTO category (name,description,parent_category_id,public_id,created_at,updated_at)
SELECT 'Tablets','Tablet computers',id,UUID(),NOW(),NOW() FROM category WHERE name='Electronics';
INSERT IGNORE INTO category (name,description,parent_category_id,public_id,created_at,updated_at)
SELECT 'Cameras','Digital and film cameras',id,UUID(),NOW(),NOW() FROM category WHERE name='Electronics';
INSERT IGNORE INTO category (name,description,parent_category_id,public_id,created_at,updated_at)
SELECT 'Audio Equipment','Speakers, headphones, and audio devices',id,UUID(),NOW(),NOW() FROM category WHERE name='Electronics';

-- Clothing children
INSERT IGNORE INTO category (name,description,parent_category_id,public_id,created_at,updated_at)
SELECT 'Mens Clothing','Clothing for men',id,UUID(),NOW(),NOW() FROM category WHERE name='Clothing';
INSERT IGNORE INTO category (name,description,parent_category_id,public_id,created_at,updated_at)
SELECT 'Womens Clothing','Clothing for women',id,UUID(),NOW(),NOW() FROM category WHERE name='Clothing';
INSERT IGNORE INTO category (name,description,parent_category_id,public_id,created_at,updated_at)
SELECT 'Kids Clothing','Clothing for children',id,UUID(),NOW(),NOW() FROM category WHERE name='Clothing';
INSERT IGNORE INTO category (name,description,parent_category_id,public_id,created_at,updated_at)
SELECT 'Shoes','Footwear for all ages',id,UUID(),NOW(),NOW() FROM category WHERE name='Clothing';
INSERT IGNORE INTO category (name,description,parent_category_id,public_id,created_at,updated_at)
SELECT 'Accessories','Fashion accessories',id,UUID(),NOW(),NOW() FROM category WHERE name='Clothing';

-- Books children
INSERT IGNORE INTO category (name,description,parent_category_id,public_id,created_at,updated_at)
SELECT 'Fiction','Fictional literature',id,UUID(),NOW(),NOW() FROM category WHERE name='Books';
INSERT IGNORE INTO category (name,description,parent_category_id,public_id,created_at,updated_at)
SELECT 'Non-Fiction','Non-fictional books',id,UUID(),NOW(),NOW() FROM category WHERE name='Books';
INSERT IGNORE INTO category (name,description,parent_category_id,public_id,created_at,updated_at)
SELECT 'Comics & Graphic Novels','Comic books and graphic novels',id,UUID(),NOW(),NOW() FROM category WHERE name='Books';
INSERT IGNORE INTO category (name,description,parent_category_id,public_id,created_at,updated_at)
SELECT 'Educational','Educational and textbooks',id,UUID(),NOW(),NOW() FROM category WHERE name='Books';

-- Sports & Outdoors children
INSERT IGNORE INTO category (name,description,parent_category_id,public_id,created_at,updated_at)
SELECT 'Exercise & Fitness','Fitness equipment',id,UUID(),NOW(),NOW() FROM category WHERE name='Sports & Outdoors';
INSERT IGNORE INTO category (name,description,parent_category_id,public_id,created_at,updated_at)
SELECT 'Camping & Hiking','Outdoor camping gear',id,UUID(),NOW(),NOW() FROM category WHERE name='Sports & Outdoors';
INSERT IGNORE INTO category (name,description,parent_category_id,public_id,created_at,updated_at)
SELECT 'Team Sports','Equipment for team sports',id,UUID(),NOW(),NOW() FROM category WHERE name='Sports & Outdoors';
INSERT IGNORE INTO category (name,description,parent_category_id,public_id,created_at,updated_at)
SELECT 'Water Sports','Swimming and water sport equipment',id,UUID(),NOW(),NOW() FROM category WHERE name='Sports & Outdoors';
"@

# Execute
$env:MYSQL_PWD = $DbPassword
Write-Host "Executing inserts..." -ForegroundColor Yellow
try {
    $out = echo $insertSql | & $mysqlExe -h $DbHost -P $DbPort -u $DbUser $DbName 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Host $out -ForegroundColor Red; throw "MySQL insert failed" }
} finally { Remove-Item Env:\MYSQL_PWD -ErrorAction SilentlyContinue }

# Summary
$env:MYSQL_PWD = $DbPassword
$summarySql = @"
SELECT (SELECT COUNT(*) FROM category WHERE parent_category_id IS NULL) AS main,
       (SELECT COUNT(*) FROM category WHERE parent_category_id IS NOT NULL) AS sub,
       COUNT(*) AS total
FROM category;
"@
$summary = echo $summarySql | & $mysqlExe -h $DbHost -P $DbPort -u $DbUser $DbName --skip-column-names 2>&1
Remove-Item Env:\MYSQL_PWD -ErrorAction SilentlyContinue

Write-Host "Done. Summary (main, sub, total): $summary" -ForegroundColor Green


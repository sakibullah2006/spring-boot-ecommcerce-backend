# populate-data.ps1
# Purpose: Populate database with sample categories, attributes, and products
# Usage: .\populate-data.ps1 [-BaseUrl "http://localhost:8080"] [-AdminEmail "admin@example.com"] [-AdminPassword "password"]

param(
  [string]$BaseUrl = "http://localhost:8080",
  [string]$AdminEmail = "sakibullah@gmail.com",
  [string]$AdminPassword = "password123"
)

$ErrorActionPreference = 'Stop'

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " 📦 Data Population Script" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "API: $BaseUrl" -ForegroundColor White
Write-Host "User: $AdminEmail" -ForegroundColor White
Write-Host ""

# Stats
$categoriesCreated = 0
$attributesCreated = 0
$productsCreated = 0

function Show-ErrorResponse {
  param($ErrorRecord)
  try {
    if ($ErrorRecord.Exception.Response) {
      $stream = $ErrorRecord.Exception.Response.GetResponseStream()
      $reader = New-Object System.IO.StreamReader($stream)
      $responseBody = $reader.ReadToEnd()
      Write-Host "    Error: $responseBody" -ForegroundColor Red
    }
  } catch {
    Write-Host "    Error: $($ErrorRecord.Exception.Message)" -ForegroundColor Red
  }
}

# Login
Write-Host "Logging in..." -ForegroundColor Yellow
$loginBody = @{ email = $AdminEmail; password = $AdminPassword } | ConvertTo-Json
try {
  $loginResponse = Invoke-RestMethod -Uri "$BaseUrl/api/auth/login" -Method POST -ContentType 'application/json' -Body $loginBody -SessionVariable session
  Write-Host "  ✓ Logged in as $($loginResponse.email)" -ForegroundColor Green
} catch {
  Write-Host "  ✗ Login failed" -ForegroundColor Red
  Show-ErrorResponse $_
  exit 1
}

# ============================================
# 1. CREATE CATEGORIES
# ============================================

Write-Host "`n=== Creating Categories ===" -ForegroundColor Cyan

$categories = @(
  @{ name = "Electronics"; description = "Electronic devices and gadgets"; parentId = $null },
  @{ name = "Clothing"; description = "Apparel and fashion items"; parentId = $null },
  @{ name = "Books"; description = "Physical and digital books"; parentId = $null },
  @{ name = "Home & Garden"; description = "Home improvement and garden supplies"; parentId = $null },
  @{ name = "Sports & Outdoors"; description = "Sports equipment and outdoor gear"; parentId = $null }
)

$categoryMap = @{}

foreach ($cat in $categories) {
  try {
    $body = @{
      name = $cat.name
      description = $cat.description
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/categories" -Method POST -ContentType 'application/json' -Body $body -WebSession $session
    $categoryMap[$cat.name] = $response.id
    $categoriesCreated++
    Write-Host "  ✓ Created: $($cat.name) (ID: $($response.id))" -ForegroundColor Green
  } catch {
    Write-Host "  ⚠ Skipped: $($cat.name) (may already exist)" -ForegroundColor Yellow
  }
}

# Create subcategories
$subCategories = @(
  @{ name = "Laptops"; description = "Portable computers"; parentName = "Electronics" },
  @{ name = "Smartphones"; description = "Mobile phones"; parentName = "Electronics" },
  @{ name = "Tablets"; description = "Tablet devices"; parentName = "Electronics" },
  @{ name = "Men's Clothing"; description = "Clothing for men"; parentName = "Clothing" },
  @{ name = "Women's Clothing"; description = "Clothing for women"; parentName = "Clothing" }
)

foreach ($subCat in $subCategories) {
  if ($categoryMap.ContainsKey($subCat.parentName)) {
    try {
      $body = @{
        name = $subCat.name
        description = $subCat.description
        parentCategoryId = $categoryMap[$subCat.parentName]
      } | ConvertTo-Json
      
      $response = Invoke-RestMethod -Uri "$BaseUrl/api/categories" -Method POST -ContentType 'application/json' -Body $body -WebSession $session
      $categoryMap[$subCat.name] = $response.id
      $categoriesCreated++
      Write-Host "  ✓ Created: $($subCat.name) (ID: $($response.id), Parent: $($subCat.parentName))" -ForegroundColor Green
    } catch {
      Write-Host "  ⚠ Skipped: $($subCat.name) (may already exist)" -ForegroundColor Yellow
    }
  }
}

# ============================================
# 2. CREATE COMMON ATTRIBUTES
# ============================================

Write-Host "`n=== Creating Common Attributes ===" -ForegroundColor Cyan

$attributes = @(
  @{ name = "Brand"; description = "Product manufacturer or brand" },
  @{ name = "Color"; description = "Product color" },
  @{ name = "Size"; description = "Product size" },
  @{ name = "Material"; description = "Product material" },
  @{ name = "Weight"; description = "Product weight" }
)

$attributeMap = @{}

foreach ($attr in $attributes) {
  try {
    $body = @{
      name = $attr.name
      description = $attr.description
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/attributes" -Method POST -ContentType 'application/json' -Body $body -WebSession $session
    $attributeMap[$attr.name] = $response.id
    $attributesCreated++
    Write-Host "  ✓ Created: $($attr.name) (ID: $($response.id))" -ForegroundColor Green
  } catch {
    Write-Host "  ⚠ Skipped: $($attr.name) (may already exist)" -ForegroundColor Yellow
  }
}

# ============================================
# 3. CREATE SAMPLE PRODUCTS
# ============================================

Write-Host "`n=== Creating Sample Products ===" -ForegroundColor Cyan

# Get laptops category ID
$laptopsCategoryId = $categoryMap["Laptops"]

if ($laptopsCategoryId) {
  
  # Product 1: Dell XPS 13
  try {
    $product1 = @{
      name = "Dell XPS 13"
      description = "Premium ultrabook with stunning InfinityEdge display"
      sku = "DELL-XPS13-2024"
      price = 1299.99
      stockQuantity = 25
      categoryIds = @($laptopsCategoryId)
      attributes = @(
        @{ attributeName = "Brand"; optionValue = "Dell" },
        @{ attributeName = "Processor"; attributeDescription = "CPU"; optionValue = "Intel Core i7-1355U" },
        @{ attributeName = "RAM"; attributeDescription = "Memory"; optionValue = "16GB LPDDR5" },
        @{ attributeName = "Storage"; attributeDescription = "Disk"; optionValue = "512GB NVMe SSD" },
        @{ attributeName = "Display"; attributeDescription = "Screen"; optionValue = "13.4-inch FHD+" },
        @{ attributeName = "Graphics"; attributeDescription = "GPU"; optionValue = "Intel Iris Xe" },
        @{ attributeName = "Color"; optionValue = "Platinum Silver" },
        @{ attributeName = "Weight"; optionValue = "1.27 kg" }
      )
    } | ConvertTo-Json -Depth 10
    
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/products" -Method POST -ContentType 'application/json' -Body $product1 -WebSession $session
    $productsCreated++
    Write-Host "  ✓ Created: Dell XPS 13 (ID: $($response.id), Attributes: $($response.attributes.Count))" -ForegroundColor Green
  } catch {
    Write-Host "  ⚠ Failed to create: Dell XPS 13" -ForegroundColor Yellow
    Show-ErrorResponse $_
  }
  
  # Product 2: MacBook Air M2
  try {
    $product2 = @{
      name = "MacBook Air M2"
      description = "Supercharged by M2 chip. Incredibly portable and powerful."
      sku = "APPLE-MBA-M2-2024"
      price = 1499.99
      stockQuantity = 30
      categoryIds = @($laptopsCategoryId)
      attributes = @(
        @{ attributeName = "Brand"; optionValue = "Apple" },
        @{ attributeName = "Processor"; attributeDescription = "CPU"; optionValue = "Apple M2" },
        @{ attributeName = "RAM"; attributeDescription = "Memory"; optionValue = "16GB Unified Memory" },
        @{ attributeName = "Storage"; attributeDescription = "Disk"; optionValue = "512GB SSD" },
        @{ attributeName = "Display"; attributeDescription = "Screen"; optionValue = "13.6-inch Liquid Retina" },
        @{ attributeName = "Graphics"; attributeDescription = "GPU"; optionValue = "10-core GPU" },
        @{ attributeName = "Color"; optionValue = "Midnight" },
        @{ attributeName = "Weight"; optionValue = "1.24 kg" }
      )
    } | ConvertTo-Json -Depth 10
    
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/products" -Method POST -ContentType 'application/json' -Body $product2 -WebSession $session
    $productsCreated++
    Write-Host "  ✓ Created: MacBook Air M2 (ID: $($response.id), Attributes: $($response.attributes.Count))" -ForegroundColor Green
  } catch {
    Write-Host "  ⚠ Failed to create: MacBook Air M2" -ForegroundColor Yellow
    Show-ErrorResponse $_
  }
  
  # Product 3: HP Spectre x360
  try {
    $product3 = @{
      name = "HP Spectre x360 14"
      description = "Convertible laptop with stunning OLED display"
      sku = "HP-SPEC-X360-2024"
      price = 1699.99
      stockQuantity = 15
      categoryIds = @($laptopsCategoryId)
      attributes = @(
        @{ attributeName = "Brand"; optionValue = "HP" },
        @{ attributeName = "Processor"; attributeDescription = "CPU"; optionValue = "Intel Core i7-1355U" },
        @{ attributeName = "RAM"; attributeDescription = "Memory"; optionValue = "16GB DDR4" },
        @{ attributeName = "Storage"; attributeDescription = "Disk"; optionValue = "1TB PCIe SSD" },
        @{ attributeName = "Display"; attributeDescription = "Screen"; optionValue = "13.5-inch 3K2K OLED" },
        @{ attributeName = "Graphics"; attributeDescription = "GPU"; optionValue = "Intel Iris Xe" },
        @{ attributeName = "Color"; optionValue = "Nightfall Black" },
        @{ attributeName = "Weight"; optionValue = "1.39 kg" },
        @{ attributeName = "Touchscreen"; attributeDescription = "Touch support"; optionValue = "Yes" }
      )
    } | ConvertTo-Json -Depth 10
    
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/products" -Method POST -ContentType 'application/json' -Body $product3 -WebSession $session
    $productsCreated++
    Write-Host "  ✓ Created: HP Spectre x360 14 (ID: $($response.id), Attributes: $($response.attributes.Count))" -ForegroundColor Green
  } catch {
    Write-Host "  ⚠ Failed to create: HP Spectre x360 14" -ForegroundColor Yellow
    Show-ErrorResponse $_
  }
  
  # Product 4: Lenovo ThinkPad X1 Carbon
  try {
    $product4 = @{
      name = "Lenovo ThinkPad X1 Carbon Gen 11"
      description = "Business ultrabook with legendary ThinkPad durability"
      sku = "LEN-X1C-G11-2024"
      price = 1899.99
      stockQuantity = 20
      categoryIds = @($laptopsCategoryId)
      attributes = @(
        @{ attributeName = "Brand"; optionValue = "Lenovo" },
        @{ attributeName = "Processor"; attributeDescription = "CPU"; optionValue = "Intel Core i7-1365U" },
        @{ attributeName = "RAM"; attributeDescription = "Memory"; optionValue = "32GB LPDDR5" },
        @{ attributeName = "Storage"; attributeDescription = "Disk"; optionValue = "1TB PCIe Gen 4 SSD" },
        @{ attributeName = "Display"; attributeDescription = "Screen"; optionValue = "14-inch WUXGA IPS" },
        @{ attributeName = "Graphics"; attributeDescription = "GPU"; optionValue = "Intel Iris Xe" },
        @{ attributeName = "Color"; optionValue = "Deep Black" },
        @{ attributeName = "Weight"; optionValue = "1.12 kg" },
        @{ attributeName = "Durability"; attributeDescription = "Mil-spec"; optionValue = "MIL-STD-810H" }
      )
    } | ConvertTo-Json -Depth 10
    
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/products" -Method POST -ContentType 'application/json' -Body $product4 -WebSession $session
    $productsCreated++
    Write-Host "  ✓ Created: Lenovo ThinkPad X1 Carbon (ID: $($response.id), Attributes: $($response.attributes.Count))" -ForegroundColor Green
  } catch {
    Write-Host "  ⚠ Failed to create: Lenovo ThinkPad X1 Carbon" -ForegroundColor Yellow
    Show-ErrorResponse $_
  }
  
  # Product 5: ASUS ROG Zephyrus G14
  try {
    $product5 = @{
      name = "ASUS ROG Zephyrus G14"
      description = "Compact gaming powerhouse with AMD Ryzen and RTX graphics"
      sku = "ASUS-ROG-G14-2024"
      price = 1999.99
      stockQuantity = 12
      categoryIds = @($laptopsCategoryId)
      attributes = @(
        @{ attributeName = "Brand"; optionValue = "ASUS" },
        @{ attributeName = "Processor"; attributeDescription = "CPU"; optionValue = "AMD Ryzen 9 7940HS" },
        @{ attributeName = "RAM"; attributeDescription = "Memory"; optionValue = "32GB DDR5" },
        @{ attributeName = "Storage"; attributeDescription = "Disk"; optionValue = "1TB PCIe 4.0 SSD" },
        @{ attributeName = "Display"; attributeDescription = "Screen"; optionValue = "14-inch QHD+ 165Hz" },
        @{ attributeName = "Graphics"; attributeDescription = "GPU"; optionValue = "NVIDIA RTX 4060" },
        @{ attributeName = "Color"; optionValue = "Moonlight White" },
        @{ attributeName = "Weight"; optionValue = "1.65 kg" },
        @{ attributeName = "Refresh Rate"; attributeDescription = "Display refresh"; optionValue = "165Hz" }
      )
    } | ConvertTo-Json -Depth 10
    
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/products" -Method POST -ContentType 'application/json' -Body $product5 -WebSession $session
    $productsCreated++
    Write-Host "  ✓ Created: ASUS ROG Zephyrus G14 (ID: $($response.id), Attributes: $($response.attributes.Count))" -ForegroundColor Green
  } catch {
    Write-Host "  ⚠ Failed to create: ASUS ROG Zephyrus G14" -ForegroundColor Yellow
    Show-ErrorResponse $_
  }
  
} else {
  Write-Host "  ⚠ Laptops category not found. Skipping product creation." -ForegroundColor Yellow
}

# ============================================
# SUMMARY
# ============================================

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " 📊 Population Summary" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

Write-Host "`nCategories created: $categoriesCreated" -ForegroundColor Green
Write-Host "Attributes created: $attributesCreated" -ForegroundColor Green
Write-Host "Products created: $productsCreated" -ForegroundColor Green

Write-Host "`n✅ Data population complete!" -ForegroundColor Green
Write-Host ""

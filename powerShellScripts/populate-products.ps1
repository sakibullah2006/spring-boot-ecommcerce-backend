# populate-products.ps1
# Purpose: Populate 'product' table with sample data via REST API
# Prerequisites:
#   - API running (default http://localhost:8080)
#   - Admin user exists: sakibullah@gmail.com / password123
#   - Categories have been created (run populate-categories-final.ps1 first)
# Usage:
#   .\populate-products.ps1
#   .\populate-products.ps1 -BaseUrl "http://localhost:8080"

param(
  [string]$BaseUrl = "http://localhost:8080"
)

$ErrorActionPreference = 'Stop'

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Populate Products via REST API" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "API Base URL: $BaseUrl" -ForegroundColor White
Write-Host ""

# Stats
$productsCreated = 0
$productsFailed  = 0
$productsSkipped = 0

function Show-ErrorResponse {
  param($ErrorRecord)
  try {
    if ($ErrorRecord.Exception.Response) {
      $stream = $ErrorRecord.Exception.Response.GetResponseStream()
      $reader = New-Object System.IO.StreamReader($stream)
      $responseBody = $reader.ReadToEnd()
      Write-Host "    Response: $responseBody" -ForegroundColor Red
    }
  } catch {}
}

# 1) Login as admin and capture session (cookie-based)
Write-Host "Logging in as admin..." -ForegroundColor Cyan
$loginBody = @{ email = "sakibullah@gmail.com"; password = "password123" } | ConvertTo-Json
try {
  $loginResponse = Invoke-RestMethod -Uri "$BaseUrl/api/auth/login" -Method POST -ContentType 'application/json' -Body $loginBody -SessionVariable session
  Write-Host "  Logged in as: $($loginResponse.email) (Role: $($loginResponse.role))" -ForegroundColor Green
} catch {
  Write-Host "  Login failed. Ensure API is running and admin user exists." -ForegroundColor Red
  Show-ErrorResponse $_
  exit 1
}

# 2) Fetch categories and build a map Name -> Id (case-insensitive)
Write-Host "Fetching categories..." -ForegroundColor Cyan
try {
  $categories = Invoke-RestMethod -Uri "$BaseUrl/api/categories" -Method GET -WebSession $session
  $categories = @($categories) # force array
  if (-not $categories -or $categories.Count -eq 0) {
    Write-Host "  No categories found. Please run populate-categories-final.ps1 first." -ForegroundColor Yellow
    exit 1
  }
  Write-Host "  Found $($categories.Count) categories" -ForegroundColor Green
} catch {
  Write-Host "  Failed to fetch categories." -ForegroundColor Red
  Show-ErrorResponse $_
  exit 1
}

$categoryMap = @{}
foreach ($c in $categories) {
  # Use case-insensitive keys
  $categoryMap[$c.name.ToLower()] = $c.id
}

function Get-CategoryIds {
  param([string[]]$CategoryNames)
  $ids = @()
  foreach ($n in $CategoryNames) {
    $key = $n.ToLower()
    if ($categoryMap.ContainsKey($key)) { $ids += $categoryMap[$key] }
    else { Write-Host "  WARN: Category '$n' not found" -ForegroundColor Yellow }
  }
  return ,$ids # return as array
}

# 3) Helper to create product
function New-Product {
  param(
    [string]$Sku,
    [string]$Name,
    [string]$Description,
    [decimal]$Price,
    [decimal]$SalePrice,
    [int]$Stock,
    [string[]]$CategoryNames,
    [array]$Attributes = @()
  )

  $categoryIds = Get-CategoryIds -CategoryNames $CategoryNames
  if (-not $categoryIds -or $categoryIds.Count -eq 0) {
    Write-Host "  SKIP: $Name (no valid categories)" -ForegroundColor Yellow
    $script:productsSkipped++
    return
  }

  $body = @{
    sku = $Sku
    name = $Name
    description = $Description
    price = $Price
    salePrice = $SalePrice
    stockQuantity = $Stock
    categoryIds = $categoryIds
    attributes = $Attributes
  } | ConvertTo-Json -Depth 5

  try {
    $resp = Invoke-RestMethod -Uri "$BaseUrl/api/products" -Method POST -ContentType 'application/json' -Body $body -WebSession $session
    Write-Host ("  [OK] Created: {0} (SKU: {1}, Price: {2}, Stock: {3})" -f $resp.name, $resp.sku, $resp.price, $resp.stockQuantity) -ForegroundColor Green
    $script:productsCreated++
  } catch {
    if ($_.Exception.Response -and ($_.Exception.Response.StatusCode.value__ -eq 409)) {
      Write-Host "  SKIP (exists): $Name (SKU: $Sku)" -ForegroundColor Yellow
      $script:productsSkipped++
    } else {
      Write-Host "  [FAIL] Failed: $Name (SKU: $Sku)" -ForegroundColor Red
      Show-ErrorResponse $_
      $script:productsFailed++
    }
  }
}

Write-Host "Creating products..." -ForegroundColor Cyan

# Electronics - Smartphones
New-Product -Sku 'ELEC-PHONE-001' -Name 'iPhone 15 Pro' -Description 'A17 Pro chip, titanium design' -Price 999.99 -SalePrice 949.99 -Stock 150 -CategoryNames @('Smartphones','Electronics') -Attributes @(
  @{ name = 'Color'; slug = 'color'; options = @(@{ name = 'Natural Titanium'; slug = 'natural-titanium' }, @{ name = 'Blue Titanium'; slug = 'blue-titanium' }, @{ name = 'White Titanium'; slug = 'white-titanium' }, @{ name = 'Black Titanium'; slug = 'black-titanium' }) },
  @{ name = 'Storage'; slug = 'storage'; options = @(@{ name = '128GB'; slug = '128gb' }, @{ name = '256GB'; slug = '256gb' }, @{ name = '512GB'; slug = '512gb' }, @{ name = '1TB'; slug = '1tb' }) }
)
New-Product -Sku 'ELEC-PHONE-002' -Name 'Samsung Galaxy S24 Ultra' -Description 'S Pen, 200MP camera' -Price 1199.99 -SalePrice 1099.99 -Stock 120 -CategoryNames @('Smartphones','Electronics') -Attributes @(
  @{ name = 'Color'; slug = 'color'; options = @(@{ name = 'Titanium Gray'; slug = 'titanium-gray' }, @{ name = 'Titanium Black'; slug = 'titanium-black' }, @{ name = 'Titanium Violet'; slug = 'titanium-violet' }, @{ name = 'Titanium Yellow'; slug = 'titanium-yellow' }) },
  @{ name = 'Storage'; slug = 'storage'; options = @(@{ name = '256GB'; slug = '256gb' }, @{ name = '512GB'; slug = '512gb' }, @{ name = '1TB'; slug = '1tb' }) }
)
New-Product -Sku 'ELEC-PHONE-003' -Name 'Google Pixel 8 Pro' -Description 'Advanced AI features' -Price 899.99 -SalePrice 849.99 -Stock 100 -CategoryNames @('Smartphones','Electronics') -Attributes @(
  @{ name = 'Color'; slug = 'color'; options = @(@{ name = 'Obsidian'; slug = 'obsidian' }, @{ name = 'Porcelain'; slug = 'porcelain' }, @{ name = 'Bay'; slug = 'bay' }) },
  @{ name = 'Storage'; slug = 'storage'; options = @(@{ name = '128GB'; slug = '128gb' }, @{ name = '256GB'; slug = '256gb' }, @{ name = '512GB'; slug = '512gb' }) }
)

# Electronics - Laptops
New-Product -Sku 'ELEC-LAP-001' -Name 'MacBook Pro 16 M3' -Description 'M3 Max, 16-inch display' -Price 2499.99 -SalePrice 2399.99 -Stock 50 -CategoryNames @('Laptops','Electronics') -Attributes @(
  @{ name = 'Processor'; slug = 'processor'; options = @(@{ name = 'M3 Pro'; slug = 'm3-pro' }, @{ name = 'M3 Max'; slug = 'm3-max' }) },
  @{ name = 'RAM'; slug = 'ram'; options = @(@{ name = '18GB'; slug = '18gb' }, @{ name = '36GB'; slug = '36gb' }, @{ name = '48GB'; slug = '48gb' }) },
  @{ name = 'Storage'; slug = 'storage'; options = @(@{ name = '512GB'; slug = '512gb' }, @{ name = '1TB'; slug = '1tb' }, @{ name = '2TB'; slug = '2tb' }, @{ name = '4TB'; slug = '4tb' }) },
  @{ name = 'Color'; slug = 'color'; options = @(@{ name = 'Space Black'; slug = 'space-black' }, @{ name = 'Silver'; slug = 'silver' }) }
)
New-Product -Sku 'ELEC-LAP-002' -Name 'Dell XPS 15' -Description 'InfinityEdge display' -Price 1799.99 -SalePrice 1699.99 -Stock 60 -CategoryNames @('Laptops','Electronics') -Attributes @(
  @{ name = 'Processor'; slug = 'processor'; options = @(@{ name = 'Intel i7-13700H'; slug = 'intel-i7-13700h' }, @{ name = 'Intel i9-13900H'; slug = 'intel-i9-13900h' }) },
  @{ name = 'RAM'; slug = 'ram'; options = @(@{ name = '16GB'; slug = '16gb' }, @{ name = '32GB'; slug = '32gb' }, @{ name = '64GB'; slug = '64gb' }) },
  @{ name = 'Storage'; slug = 'storage'; options = @(@{ name = '512GB SSD'; slug = '512gb-ssd' }, @{ name = '1TB SSD'; slug = '1tb-ssd' }, @{ name = '2TB SSD'; slug = '2tb-ssd' }) },
  @{ name = 'Screen'; slug = 'screen'; options = @(@{ name = '15.6" FHD+'; slug = '15-6-fhd' }, @{ name = '15.6" 3.5K OLED'; slug = '15-6-3-5k-oled' }) }
)

# Electronics - Audio
New-Product -Sku 'ELEC-AUD-001' -Name 'Sony WH-1000XM5' -Description 'Noise-canceling headphones' -Price 399.99 -SalePrice 349.99 -Stock 200 -CategoryNames @('Audio Equipment','Electronics') -Attributes @(
  @{ name = 'Color'; slug = 'color'; options = @(@{ name = 'Black'; slug = 'black' }, @{ name = 'Silver'; slug = 'silver' }, @{ name = 'Midnight Blue'; slug = 'midnight-blue' }) }
)
New-Product -Sku 'ELEC-AUD-002' -Name 'Apple AirPods Pro 2' -Description 'Adaptive audio' -Price 249.99 -SalePrice 229.99 -Stock 250 -CategoryNames @('Audio Equipment','Electronics') -Attributes @(
  @{ name = 'Connectivity'; slug = 'connectivity'; options = @(@{ name = 'USB-C'; slug = 'usb-c' }, @{ name = 'Lightning'; slug = 'lightning' }) }
)

# Clothing - Men
New-Product -Sku 'CLOTH-MEN-001' -Name "Levi's 501 Jeans" -Description 'Classic straight-leg jeans' -Price 69.99 -SalePrice 59.99 -Stock 200 -CategoryNames @('Mens Clothing','Clothing') -Attributes @(
  @{ name = 'Size'; slug = 'size'; options = @(@{ name = '30x30'; slug = '30x30' }, @{ name = '32x30'; slug = '32x30' }, @{ name = '32x32'; slug = '32x32' }, @{ name = '34x32'; slug = '34x32' }, @{ name = '34x34'; slug = '34x34' }, @{ name = '36x32'; slug = '36x32' }, @{ name = '36x34'; slug = '36x34' }) },
  @{ name = 'Color'; slug = 'color'; options = @(@{ name = 'Dark Blue'; slug = 'dark-blue' }, @{ name = 'Light Blue'; slug = 'light-blue' }, @{ name = 'Black'; slug = 'black' }) }
)
New-Product -Sku 'CLOTH-MEN-002' -Name 'Nike Dri-FIT Shirt' -Description 'Performance athletic shirt' -Price 35.99 -SalePrice 29.99 -Stock 300 -CategoryNames @('Mens Clothing','Clothing') -Attributes @(
  @{ name = 'Size'; slug = 'size'; options = @(@{ name = 'S'; slug = 's' }, @{ name = 'M'; slug = 'm' }, @{ name = 'L'; slug = 'l' }, @{ name = 'XL'; slug = 'xl' }, @{ name = 'XXL'; slug = 'xxl' }) },
  @{ name = 'Color'; slug = 'color'; options = @(@{ name = 'Black'; slug = 'black' }, @{ name = 'White'; slug = 'white' }, @{ name = 'Navy'; slug = 'navy' }, @{ name = 'Red'; slug = 'red' }) }
)

# Clothing - Women
New-Product -Sku 'CLOTH-WOM-001' -Name 'Lululemon Align Leggings' -Description 'High-waist yoga pants' -Price 98.99 -SalePrice 88.99 -Stock 250 -CategoryNames @('Womens Clothing','Clothing') -Attributes @(
  @{ name = 'Size'; slug = 'size'; options = @(@{ name = 'XS'; slug = 'xs' }, @{ name = 'S'; slug = 's' }, @{ name = 'M'; slug = 'm' }, @{ name = 'L'; slug = 'l' }, @{ name = 'XL'; slug = 'xl' }) },
  @{ name = 'Color'; slug = 'color'; options = @(@{ name = 'Black'; slug = 'black' }, @{ name = 'Navy'; slug = 'navy' }, @{ name = 'Grey'; slug = 'grey' }, @{ name = 'Pink'; slug = 'pink' }) },
  @{ name = 'Length'; slug = 'length'; options = @(@{ name = '25"'; slug = '25-inch' }, @{ name = '28"'; slug = '28-inch' }, @{ name = '31"'; slug = '31-inch' }) }
)
New-Product -Sku 'CLOTH-WOM-002' -Name 'Zara Floral Dress' -Description 'Elegant summer dress' -Price 79.99 -SalePrice 69.99 -Stock 120 -CategoryNames @('Womens Clothing','Clothing') -Attributes @(
  @{ name = 'Size'; slug = 'size'; options = @(@{ name = 'XS'; slug = 'xs' }, @{ name = 'S'; slug = 's' }, @{ name = 'M'; slug = 'm' }, @{ name = 'L'; slug = 'l' }, @{ name = 'XL'; slug = 'xl' }) },
  @{ name = 'Color'; slug = 'color'; options = @(@{ name = 'Blue Floral'; slug = 'blue-floral' }, @{ name = 'Pink Floral'; slug = 'pink-floral' }, @{ name = 'Yellow Floral'; slug = 'yellow-floral' }) }
)

# Books
New-Product -Sku 'BOOK-FIC-001' -Name 'The Midnight Library' -Description 'Parallel lives novel' -Price 16.99 -SalePrice 14.99 -Stock 500 -CategoryNames @('Fiction','Books') -Attributes @(
  @{ name = 'Format'; slug = 'format'; options = @(@{ name = 'Hardcover'; slug = 'hardcover' }, @{ name = 'Paperback'; slug = 'paperback' }, @{ name = 'Kindle'; slug = 'kindle' }) }
)
New-Product -Sku 'BOOK-NON-001' -Name 'Atomic Habits' -Description 'Build better habits' -Price 19.99 -SalePrice 17.99 -Stock 600 -CategoryNames @('Non-Fiction','Books') -Attributes @(
  @{ name = 'Format'; slug = 'format'; options = @(@{ name = 'Hardcover'; slug = 'hardcover' }, @{ name = 'Paperback'; slug = 'paperback' }, @{ name = 'Kindle'; slug = 'kindle' }, @{ name = 'Audiobook'; slug = 'audiobook' }) }
)
New-Product -Sku 'BOOK-EDU-001' -Name 'Clean Code' -Description 'Software engineering best practices' -Price 49.99 -SalePrice 44.99 -Stock 300 -CategoryNames @('Educational','Books') -Attributes @(
  @{ name = 'Format'; slug = 'format'; options = @(@{ name = 'Hardcover'; slug = 'hardcover' }, @{ name = 'Paperback'; slug = 'paperback' }, @{ name = 'Kindle'; slug = 'kindle' }) }
)

# Sports & Outdoors
New-Product -Sku 'SPORT-FIT-001' -Name 'Bowflex Adjustable Dumbbells' -Description 'Home gym equipment' -Price 349.99 -SalePrice 319.99 -Stock 80 -CategoryNames @("Exercise & Fitness","Sports & Outdoors") -Attributes @(
  @{ name = 'Weight Range'; slug = 'weight-range'; options = @(@{ name = '5-52.5 lbs'; slug = '5-52-5-lbs' }, @{ name = '10-90 lbs'; slug = '10-90-lbs' }) }
)
New-Product -Sku 'SPORT-CAMP-001' -Name 'Coleman 4-Person Tent' -Description 'Family camping tent' -Price 129.99 -SalePrice 109.99 -Stock 100 -CategoryNames @("Camping & Hiking","Sports & Outdoors") -Attributes @(
  @{ name = 'Capacity'; slug = 'capacity'; options = @(@{ name = '4-Person'; slug = '4-person' }, @{ name = '6-Person'; slug = '6-person' }) },
  @{ name = 'Color'; slug = 'color'; options = @(@{ name = 'Green'; slug = 'green' }, @{ name = 'Blue'; slug = 'blue' }) }
)

# Home & Garden
New-Product -Sku 'HOME-001' -Name 'Dyson V15 Vacuum' -Description 'Laser dust detection' -Price 649.99 -SalePrice 599.99 -Stock 70 -CategoryNames @("Home & Garden") -Attributes @(
  @{ name = 'Color'; slug = 'color'; options = @(@{ name = 'Yellow/Nickel'; slug = 'yellow-nickel' }, @{ name = 'Iron/Purple'; slug = 'iron-purple' }) }
)
New-Product -Sku 'HOME-002' -Name 'Ninja Air Fryer' -Description '8-quart air fryer' -Price 129.99 -SalePrice 109.99 -Stock 150 -CategoryNames @("Home & Garden") -Attributes @(
  @{ name = 'Capacity'; slug = 'capacity'; options = @(@{ name = '4-Quart'; slug = '4-quart' }, @{ name = '6-Quart'; slug = '6-quart' }, @{ name = '8-Quart'; slug = '8-quart' }) },
  @{ name = 'Color'; slug = 'color'; options = @(@{ name = 'Black'; slug = 'black' }, @{ name = 'Grey'; slug = 'grey' }) }
)

# Toys & Games
New-Product -Sku 'TOY-001' -Name 'Nintendo Switch OLED' -Description 'Vibrant OLED display' -Price 349.99 -SalePrice 329.99 -Stock 120 -CategoryNames @("Toys & Games") -Attributes @(
  @{ name = 'Color'; slug = 'color'; options = @(@{ name = 'White'; slug = 'white' }, @{ name = 'Neon Red/Blue'; slug = 'neon-red-blue' }) }
)
New-Product -Sku 'TOY-002' -Name 'LEGO Star Wars Falcon' -Description 'Collector set' -Price 849.99 -SalePrice 799.99 -Stock 50 -CategoryNames @("Toys & Games") -Attributes @(
  @{ name = 'Edition'; slug = 'edition'; options = @(@{ name = 'Standard'; slug = 'standard' }, @{ name = 'Ultimate Collector'; slug = 'ultimate-collector' }) }
)

# Health & Beauty
New-Product -Sku 'HEALTH-001' -Name 'Fitbit Charge 6' -Description 'Fitness tracker' -Price 159.99 -SalePrice 149.99 -Stock 200 -CategoryNames @("Health & Beauty") -Attributes @(
  @{ name = 'Color'; slug = 'color'; options = @(@{ name = 'Black'; slug = 'black' }, @{ name = 'Coral'; slug = 'coral' }, @{ name = 'Champagne Gold'; slug = 'champagne-gold' }) },
  @{ name = 'Size'; slug = 'size'; options = @(@{ name = 'Small'; slug = 'small' }, @{ name = 'Large'; slug = 'large' }) }
)

# Automotive
New-Product -Sku 'AUTO-001' -Name 'Car Dash Camera 4K' -Description 'Front and rear dash cam' -Price 149.99 -SalePrice 129.99 -Stock 120 -CategoryNames @('Automotive') -Attributes @(
  @{ name = 'Resolution'; slug = 'resolution'; options = @(@{ name = '1080p'; slug = '1080p' }, @{ name = '2K'; slug = '2k' }, @{ name = '4K'; slug = '4k' }) },
  @{ name = 'Storage'; slug = 'storage'; options = @(@{ name = '32GB'; slug = '32gb' }, @{ name = '64GB'; slug = '64gb' }, @{ name = '128GB'; slug = '128gb' }) }
)

# Office Supplies
New-Product -Sku 'OFFICE-001' -Name 'Logitech MX Master 3S' -Description 'Advanced wireless mouse' -Price 99.99 -SalePrice 89.99 -Stock 150 -CategoryNames @('Office Supplies') -Attributes @(
  @{ name = 'Color'; slug = 'color'; options = @(@{ name = 'Graphite'; slug = 'graphite' }, @{ name = 'Pale Grey'; slug = 'pale-grey' }, @{ name = 'Black'; slug = 'black' }) },
  @{ name = 'Connectivity'; slug = 'connectivity'; options = @(@{ name = 'Bluetooth'; slug = 'bluetooth' }, @{ name = 'USB Receiver'; slug = 'usb-receiver' }) }
)

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Summary" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ("Created:  {0}" -f $productsCreated) -ForegroundColor Green
Write-Host ("Skipped:  {0}" -f $productsSkipped) -ForegroundColor Yellow
Write-Host ("Failed:   {0}" -f $productsFailed) -ForegroundColor $(if ($productsFailed -gt 0) { 'Red' } else { 'Green' })

if ($productsFailed -eq 0) { exit 0 } else { exit 1 }


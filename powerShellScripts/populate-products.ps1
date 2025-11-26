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
    [string[]]$CategoryNames
  )

  $categoryIds = Get-CategoryIds -CategoryNames $CategoryNames
  if (-not $categoryIds -or $categoryIds.Count -eq 0) {
    Write-Host "  SKIP: $Name (no valid categories)" -ForegroundColor Yellow
    $script:productsSkipped++
    return
  }

  $body = @{ sku = $Sku; name = $Name; description = $Description; price = $Price; salePrice = $SalePrice; stockQuantity = $Stock; categoryIds = $categoryIds } | ConvertTo-Json -Depth 5

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
New-Product -Sku 'ELEC-PHONE-001' -Name 'iPhone 15 Pro' -Description 'A17 Pro chip, titanium design' -Price 999.99 -SalePrice 949.99 -Stock 150 -CategoryNames @('Smartphones','Electronics')
New-Product -Sku 'ELEC-PHONE-002' -Name 'Samsung Galaxy S24 Ultra' -Description 'S Pen, 200MP camera' -Price 1199.99 -SalePrice 1099.99 -Stock 120 -CategoryNames @('Smartphones','Electronics')
New-Product -Sku 'ELEC-PHONE-003' -Name 'Google Pixel 8 Pro' -Description 'Advanced AI features' -Price 899.99 -SalePrice 849.99 -Stock 100 -CategoryNames @('Smartphones','Electronics')

# Electronics - Laptops
New-Product -Sku 'ELEC-LAP-001' -Name 'MacBook Pro 16 M3' -Description 'M3 Max, 16-inch display' -Price 2499.99 -SalePrice 2399.99 -Stock 50 -CategoryNames @('Laptops','Electronics')
New-Product -Sku 'ELEC-LAP-002' -Name 'Dell XPS 15' -Description 'InfinityEdge display' -Price 1799.99 -SalePrice 1699.99 -Stock 60 -CategoryNames @('Laptops','Electronics')

# Electronics - Audio
New-Product -Sku 'ELEC-AUD-001' -Name 'Sony WH-1000XM5' -Description 'Noise-canceling headphones' -Price 399.99 -SalePrice 349.99 -Stock 200 -CategoryNames @('Audio Equipment','Electronics')
New-Product -Sku 'ELEC-AUD-002' -Name 'Apple AirPods Pro 2' -Description 'Adaptive audio' -Price 249.99 -SalePrice 229.99 -Stock 250 -CategoryNames @('Audio Equipment','Electronics')

# Clothing - Men
New-Product -Sku 'CLOTH-MEN-001' -Name "Levi's 501 Jeans" -Description 'Classic straight-leg jeans' -Price 69.99 -SalePrice 59.99 -Stock 200 -CategoryNames @('Mens Clothing','Clothing')
New-Product -Sku 'CLOTH-MEN-002' -Name 'Nike Dri-FIT Shirt' -Description 'Performance athletic shirt' -Price 35.99 -SalePrice 29.99 -Stock 300 -CategoryNames @('Mens Clothing','Clothing')

# Clothing - Women
New-Product -Sku 'CLOTH-WOM-001' -Name 'Lululemon Align Leggings' -Description 'High-waist yoga pants' -Price 98.99 -SalePrice 88.99 -Stock 250 -CategoryNames @('Womens Clothing','Clothing')
New-Product -Sku 'CLOTH-WOM-002' -Name 'Zara Floral Dress' -Description 'Elegant summer dress' -Price 79.99 -SalePrice 69.99 -Stock 120 -CategoryNames @('Womens Clothing','Clothing')

# Books
New-Product -Sku 'BOOK-FIC-001' -Name 'The Midnight Library' -Description 'Parallel lives novel' -Price 16.99 -SalePrice 14.99 -Stock 500 -CategoryNames @('Fiction','Books')
New-Product -Sku 'BOOK-NON-001' -Name 'Atomic Habits' -Description 'Build better habits' -Price 19.99 -SalePrice 17.99 -Stock 600 -CategoryNames @('Non-Fiction','Books')
New-Product -Sku 'BOOK-EDU-001' -Name 'Clean Code' -Description 'Software engineering best practices' -Price 49.99 -SalePrice 44.99 -Stock 300 -CategoryNames @('Educational','Books')

# Sports & Outdoors
New-Product -Sku 'SPORT-FIT-001' -Name 'Bowflex Adjustable Dumbbells' -Description 'Home gym equipment' -Price 349.99 -SalePrice 319.99 -Stock 80 -CategoryNames @("Exercise & Fitness","Sports & Outdoors")
New-Product -Sku 'SPORT-CAMP-001' -Name 'Coleman 4-Person Tent' -Description 'Family camping tent' -Price 129.99 -SalePrice 109.99 -Stock 100 -CategoryNames @("Camping & Hiking","Sports & Outdoors")

# Home & Garden
New-Product -Sku 'HOME-001' -Name 'Dyson V15 Vacuum' -Description 'Laser dust detection' -Price 649.99 -SalePrice 599.99 -Stock 70 -CategoryNames @("Home & Garden")
New-Product -Sku 'HOME-002' -Name 'Ninja Air Fryer' -Description '8-quart air fryer' -Price 129.99 -SalePrice 109.99 -Stock 150 -CategoryNames @("Home & Garden")

# Toys & Games
New-Product -Sku 'TOY-001' -Name 'Nintendo Switch OLED' -Description 'Vibrant OLED display' -Price 349.99 -SalePrice 329.99 -Stock 120 -CategoryNames @("Toys & Games")
New-Product -Sku 'TOY-002' -Name 'LEGO Star Wars Falcon' -Description 'Collector set' -Price 849.99 -SalePrice 799.99 -Stock 50 -CategoryNames @("Toys & Games")

# Health & Beauty
New-Product -Sku 'HEALTH-001' -Name 'Fitbit Charge 6' -Description 'Fitness tracker' -Price 159.99 -SalePrice 149.99 -Stock 200 -CategoryNames @("Health & Beauty")

# Automotive
New-Product -Sku 'AUTO-001' -Name 'Car Dash Camera 4K' -Description 'Front and rear dash cam' -Price 149.99 -SalePrice 129.99 -Stock 120 -CategoryNames @('Automotive')

# Office Supplies
New-Product -Sku 'OFFICE-001' -Name 'Logitech MX Master 3S' -Description 'Advanced wireless mouse' -Price 99.99 -SalePrice 89.99 -Stock 150 -CategoryNames @('Office Supplies')

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Summary" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ("Created:  {0}" -f $productsCreated) -ForegroundColor Green
Write-Host ("Skipped:  {0}" -f $productsSkipped) -ForegroundColor Yellow
Write-Host ("Failed:   {0}" -f $productsFailed) -ForegroundColor $(if ($productsFailed -gt 0) { 'Red' } else { 'Green' })

if ($productsFailed -eq 0) { exit 0 } else { exit 1 }


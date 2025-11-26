# test-product-attributes.ps1
# Purpose: Test creating a product with attributes and verify they are saved
# Usage: .\test-product-attributes.ps1

param(
  [string]$BaseUrl = "http://localhost:8080"
)

$ErrorActionPreference = 'Stop'

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Test Product Attributes Creation" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "API Base URL: $BaseUrl" -ForegroundColor White
Write-Host ""

# 1) Login as admin
Write-Host "Logging in as admin..." -ForegroundColor Cyan
$loginBody = @{ email = "sakibullah@gmail.com"; password = "password123" } | ConvertTo-Json
try {
  $loginResponse = Invoke-RestMethod -Uri "$BaseUrl/api/auth/login" -Method POST -ContentType 'application/json' -Body $loginBody -SessionVariable session
  Write-Host "  Logged in as: $($loginResponse.email)" -ForegroundColor Green
} catch {
  Write-Host "  Login failed. Ensure API is running and admin user exists." -ForegroundColor Red
  exit 1
}

# 2) Fetch categories
Write-Host "Fetching categories..." -ForegroundColor Cyan
try {
  $categories = Invoke-RestMethod -Uri "$BaseUrl/api/categories" -Method GET -WebSession $session
  $categories = @($categories)
  if (-not $categories -or $categories.Count -eq 0) {
    Write-Host "  No categories found. Please run populate-categories-final.ps1 first." -ForegroundColor Yellow
    exit 1
  }
  $firstCategory = $categories[0]
  Write-Host "  Using category: $($firstCategory.name) (ID: $($firstCategory.id))" -ForegroundColor Green
} catch {
  Write-Host "  Failed to fetch categories." -ForegroundColor Red
  exit 1
}

# 3) Create a test product with attributes
Write-Host ""
Write-Host "Creating test product with attributes..." -ForegroundColor Cyan
$testProduct = @{
  sku = "TEST-ATTR-001"
  name = "Test Product with Attributes"
  description = "Testing attribute creation"
  price = 99.99
  salePrice = 89.99
  stockQuantity = 50
  categoryIds = @($firstCategory.id)
  attributes = @(
    @{
      name = "Color"
      slug = "color"
      options = @(
        @{ name = "Red"; slug = "red" }
        @{ name = "Blue"; slug = "blue" }
        @{ name = "Green"; slug = "green" }
      )
    }
    @{
      name = "Size"
      slug = "size"
      options = @(
        @{ name = "Small"; slug = "small" }
        @{ name = "Medium"; slug = "medium" }
        @{ name = "Large"; slug = "large" }
      )
    }
  )
} | ConvertTo-Json -Depth 5

try {
  $createdProduct = Invoke-RestMethod -Uri "$BaseUrl/api/products" -Method POST -ContentType 'application/json' -Body $testProduct -WebSession $session
  Write-Host "  [OK] Created product: $($createdProduct.name)" -ForegroundColor Green
  Write-Host "  Product ID: $($createdProduct.id)" -ForegroundColor White
  Write-Host "  SKU: $($createdProduct.sku)" -ForegroundColor White

  if ($createdProduct.attributes -and $createdProduct.attributes.Count -gt 0) {
    Write-Host "  Attributes: $($createdProduct.attributes.Count) found" -ForegroundColor Green
    foreach ($attr in $createdProduct.attributes) {
      Write-Host "    - $($attr.name) ($($attr.slug)): $($attr.options.Count) options" -ForegroundColor Cyan
      foreach ($opt in $attr.options) {
        Write-Host "      * $($opt.name) ($($opt.slug))" -ForegroundColor Gray
      }
    }
  } else {
    Write-Host "  WARNING: No attributes found in response!" -ForegroundColor Red
  }
} catch {
  if ($_.Exception.Response -and ($_.Exception.Response.StatusCode.value__ -eq 409)) {
    Write-Host "  Product already exists. Fetching by SKU..." -ForegroundColor Yellow
    try {
      $existingProduct = Invoke-RestMethod -Uri "$BaseUrl/api/products/sku/TEST-ATTR-001" -Method GET -WebSession $session
      Write-Host "  [OK] Found existing product: $($existingProduct.name)" -ForegroundColor Green

      if ($existingProduct.attributes -and $existingProduct.attributes.Count -gt 0) {
        Write-Host "  Attributes: $($existingProduct.attributes.Count) found" -ForegroundColor Green
        foreach ($attr in $existingProduct.attributes) {
          Write-Host "    - $($attr.name) ($($attr.slug)): $($attr.options.Count) options" -ForegroundColor Cyan
        }
      } else {
        Write-Host "  WARNING: No attributes found!" -ForegroundColor Red
      }
    } catch {
      Write-Host "  Failed to fetch existing product." -ForegroundColor Red
      exit 1
    }
  } else {
    Write-Host "  [FAIL] Failed to create test product" -ForegroundColor Red
    exit 1
  }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Test Complete" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan


# test-master.ps1
# Purpose: Comprehensive test suite for E-Commerce API
# Tests all POST endpoints with session authentication
# Usage: .\test-master.ps1 [-BaseUrl "http://localhost:8080"] [-AdminEmail "admin@example.com"] [-AdminPassword "password"]

param(
  [string]$BaseUrl = "http://localhost:8080",
  [string]$AdminEmail = "sakibullah@gmail.com",
  [string]$AdminPassword = "password123"
)

$ErrorActionPreference = 'Continue'

Write-Host "`n============================================" -ForegroundColor Magenta
Write-Host " 🧪 E-Commerce API Test Master" -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "API Base URL: $BaseUrl" -ForegroundColor White
Write-Host "Admin User: $AdminEmail" -ForegroundColor White
Write-Host ""

# Test counters
$script:testsRun = 0
$script:testsPassed = 0
$script:testsFailed = 0

# Function to display error details
function Show-ErrorResponse {
  param($ErrorRecord)
  try {
    if ($ErrorRecord.Exception.Response) {
      $stream = $ErrorRecord.Exception.Response.GetResponseStream()
      $reader = New-Object System.IO.StreamReader($stream)
      $responseBody = $reader.ReadToEnd()
      Write-Host "    Response: $responseBody" -ForegroundColor Red
    }
  } catch {
    Write-Host "    Error: $($ErrorRecord.Exception.Message)" -ForegroundColor Red
  }
}

# Function to test endpoint
function Test-Endpoint {
  param(
    [string]$Name,
    [scriptblock]$TestBlock
  )
  
  $script:testsRun++
  Write-Host "`n[$script:testsRun] Testing: $Name" -ForegroundColor Cyan
  
  try {
    & $TestBlock
    $script:testsPassed++
    Write-Host "    ✓ PASSED" -ForegroundColor Green
    return $true
  } catch {
    $script:testsFailed++
    Write-Host "    ✗ FAILED" -ForegroundColor Red
    Show-ErrorResponse $_
    return $false
  }
}

# ============================================
# 1. AUTHENTICATION TESTS
# ============================================

Write-Host "`n=== Authentication Tests ===" -ForegroundColor Yellow

# Test 1: Register user (might already exist)
Test-Endpoint "User Registration" {
  $registerBody = @{
    firstName = "Test"
    lastName = "User"
    email = "testuser@example.com"
    password = "testpass123"
  } | ConvertTo-Json
  
  try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/auth/register" -Method POST -ContentType 'application/json' -Body $registerBody
    Write-Host "    User registered: $($response.email)" -ForegroundColor Gray
  } catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 400) {
      Write-Host "    User already exists (OK)" -ForegroundColor Gray
    } else {
      throw
    }
  }
}

# Test 2: Admin login
$script:session = $null
Test-Endpoint "Admin Login" {
  $loginBody = @{ 
    email = $AdminEmail
    password = $AdminPassword 
  } | ConvertTo-Json
  
  $response = Invoke-RestMethod -Uri "$BaseUrl/api/auth/login" -Method POST -ContentType 'application/json' -Body $loginBody -SessionVariable session
  $script:session = $session
  Write-Host "    Logged in: $($response.email) (Role: $($response.role))" -ForegroundColor Gray
}

if (-not $script:session) {
  Write-Host "`n❌ Cannot proceed without valid session. Exiting." -ForegroundColor Red
  exit 1
}

# ============================================
# 2. CATEGORY TESTS
# ============================================

Write-Host "`n=== Category Tests ===" -ForegroundColor Yellow

$script:categoryId = $null

# Test 3: Create root category
Test-Endpoint "Create Root Category" {
  $categoryBody = @{
    name = "Test Electronics"
    description = "Test category for electronic devices"
  } | ConvertTo-Json
  
  $response = Invoke-RestMethod -Uri "$BaseUrl/api/categories" -Method POST -ContentType 'application/json' -Body $categoryBody -WebSession $script:session
  $script:categoryId = $response.id
  Write-Host "    Category created: $($response.name) (ID: $($response.id))" -ForegroundColor Gray
}

$script:subCategoryId = $null

# Test 4: Create subcategory
if ($script:categoryId) {
  Test-Endpoint "Create Subcategory" {
    $subCategoryBody = @{
      name = "Test Laptops"
      description = "Test subcategory for laptops"
      parentCategoryId = $script:categoryId
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/categories" -Method POST -ContentType 'application/json' -Body $subCategoryBody -WebSession $script:session
    $script:subCategoryId = $response.id
    Write-Host "    Subcategory created: $($response.name) (ID: $($response.id))" -ForegroundColor Gray
  }
}

# ============================================
# 3. ATTRIBUTE TESTS
# ============================================

Write-Host "`n=== Attribute Tests ===" -ForegroundColor Yellow

$script:brandAttributeId = $null
$script:ramAttributeId = $null

# Test 5: Create Brand attribute
Test-Endpoint "Create Brand Attribute" {
  $attributeBody = @{
    name = "Brand"
    description = "Product brand/manufacturer"
  } | ConvertTo-Json
  
  $response = Invoke-RestMethod -Uri "$BaseUrl/api/attributes" -Method POST -ContentType 'application/json' -Body $attributeBody -WebSession $script:session
  $script:brandAttributeId = $response.id
  Write-Host "    Attribute created: $($response.name) (ID: $($response.id))" -ForegroundColor Gray
}

# Test 6: Create RAM attribute
Test-Endpoint "Create RAM Attribute" {
  $attributeBody = @{
    name = "RAM"
    description = "Memory capacity"
  } | ConvertTo-Json
  
  $response = Invoke-RestMethod -Uri "$BaseUrl/api/attributes" -Method POST -ContentType 'application/json' -Body $attributeBody -WebSession $script:session
  $script:ramAttributeId = $response.id
  Write-Host "    Attribute created: $($response.name) (ID: $($response.id))" -ForegroundColor Gray
}

# Test 7: Create attribute option
if ($script:brandAttributeId) {
  Test-Endpoint "Create Attribute Option" {
    $optionBody = @{
      value = "Dell"
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/attributes/$script:brandAttributeId/options" -Method POST -ContentType 'application/json' -Body $optionBody -WebSession $script:session
    Write-Host "    Option created: $($response.value) for attribute $($response.attributeName)" -ForegroundColor Gray
  }
}

# ============================================
# 4. PRODUCT TESTS (Basic)
# ============================================

Write-Host "`n=== Product Tests (Basic) ===" -ForegroundColor Yellow

$script:simpleProductId = $null

# Test 8: Create product without attributes
if ($script:categoryId) {
  Test-Endpoint "Create Product (No Attributes)" {
    $productBody = @{
      name = "Test Generic Laptop"
      description = "A basic test laptop"
      sku = "TEST-LAPTOP-001"
      price = 599.99
      stockQuantity = 10
      categoryIds = @($script:categoryId)
      attributes = @()
    } | ConvertTo-Json -Depth 10
    
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/products" -Method POST -ContentType 'application/json' -Body $productBody -WebSession $script:session
    $script:simpleProductId = $response.id
    Write-Host "    Product created: $($response.name) (ID: $($response.id))" -ForegroundColor Gray
    Write-Host "    Price: $($response.price), Stock: $($response.stockQuantity)" -ForegroundColor Gray
  }
}

# ============================================
# 5. PRODUCT TESTS (With Attributes)
# ============================================

Write-Host "`n=== Product Tests (With Attributes) ===" -ForegroundColor Yellow

$script:advancedProductId = $null

# Test 9: Create product with NEW attributes (dynamic creation)
if ($script:categoryId) {
  Test-Endpoint "Create Product with NEW Attributes" {
    $productBody = @{
      name = "HP Pavilion 15"
      description = "HP laptop with dynamic attributes"
      sku = "HP-PAV-15-2024"
      price = 749.99
      stockQuantity = 15
      categoryIds = @($script:categoryId)
      attributes = @(
        @{
          attributeName = "Processor"
          attributeDescription = "CPU type"
          optionValue = "Intel Core i5"
        },
        @{
          attributeName = "Storage"
          attributeDescription = "Storage capacity"
          optionValue = "512GB SSD"
        },
        @{
          attributeName = "Display"
          attributeDescription = "Screen size"
          optionValue = "15.6 inches"
        }
      )
    } | ConvertTo-Json -Depth 10
    
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/products" -Method POST -ContentType 'application/json' -Body $productBody -WebSession $script:session
    $script:advancedProductId = $response.id
    Write-Host "    Product created: $($response.name) (ID: $($response.id))" -ForegroundColor Gray
    Write-Host "    Attributes created: $($response.attributes.Count)" -ForegroundColor Gray
    foreach ($attr in $response.attributes) {
      Write-Host "      - $($attr.attributeName): $($attr.optionValue)" -ForegroundColor DarkGray
    }
  }
}

# Test 10: Create product with EXISTING attribute references
if ($script:categoryId -and $script:brandAttributeId -and $script:ramAttributeId) {
  Test-Endpoint "Create Product with EXISTING Attributes" {
    $productBody = @{
      name = "Lenovo ThinkPad X1"
      description = "Lenovo laptop using existing attributes"
      sku = "LEN-TP-X1-2024"
      price = 1299.99
      stockQuantity = 8
      categoryIds = @($script:categoryId)
      attributes = @(
        @{
          attributeId = $script:brandAttributeId
          optionValue = "Lenovo"
        },
        @{
          attributeId = $script:ramAttributeId
          optionValue = "16GB DDR4"
        },
        @{
          attributeName = "Graphics"
          attributeDescription = "GPU"
          optionValue = "Intel Iris Xe"
        }
      )
    } | ConvertTo-Json -Depth 10
    
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/products" -Method POST -ContentType 'application/json' -Body $productBody -WebSession $script:session
    Write-Host "    Product created: $($response.name) (ID: $($response.id))" -ForegroundColor Gray
    Write-Host "    Attributes: $($response.attributes.Count)" -ForegroundColor Gray
    foreach ($attr in $response.attributes) {
      Write-Host "      - $($attr.attributeName): $($attr.optionValue)" -ForegroundColor DarkGray
    }
  }
}

# Test 11: Complex product with many attributes
if ($script:categoryId) {
  Test-Endpoint "Create Complex Product (7+ Attributes)" {
    $productBody = @{
      name = "ASUS ROG Strix G16"
      description = "High-end gaming laptop"
      sku = "ASUS-ROG-G16-2024"
      price = 1899.99
      stockQuantity = 5
      categoryIds = @($script:categoryId)
      attributes = @(
        @{ attributeName = "Brand"; attributeDescription = "Manufacturer"; optionValue = "ASUS" },
        @{ attributeName = "Processor"; attributeDescription = "CPU"; optionValue = "Intel Core i9-13980HX" },
        @{ attributeName = "Graphics Card"; attributeDescription = "GPU"; optionValue = "NVIDIA RTX 4070" },
        @{ attributeName = "RAM"; attributeDescription = "Memory"; optionValue = "32GB DDR5" },
        @{ attributeName = "Storage"; attributeDescription = "Disk"; optionValue = "1TB SSD" },
        @{ attributeName = "Screen Size"; attributeDescription = "Display"; optionValue = "16 inches" },
        @{ attributeName = "Color"; attributeDescription = "Product color"; optionValue = "Eclipse Gray" }
      )
    } | ConvertTo-Json -Depth 10
    
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/products" -Method POST -ContentType 'application/json' -Body $productBody -WebSession $script:session
    Write-Host "    Product created: $($response.name) (ID: $($response.id))" -ForegroundColor Gray
    Write-Host "    Attributes: $($response.attributes.Count)" -ForegroundColor Gray
    foreach ($attr in $response.attributes) {
      Write-Host "      - $($attr.attributeName): $($attr.optionValue)" -ForegroundColor DarkGray
    }
  }
}

# ============================================
# 6. LOGOUT TEST
# ============================================

Write-Host "`n=== Logout Test ===" -ForegroundColor Yellow

# Test 12: Logout
Test-Endpoint "Logout" {
  $response = Invoke-RestMethod -Uri "$BaseUrl/api/auth/logout" -Method POST -WebSession $script:session
  Write-Host "    Logged out successfully" -ForegroundColor Gray
}

# ============================================
# 7. TEST SUMMARY
# ============================================

Write-Host "`n============================================" -ForegroundColor Magenta
Write-Host " 📊 Test Summary" -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta

Write-Host "`nTotal Tests Run: $script:testsRun" -ForegroundColor White
Write-Host "Passed: $script:testsPassed" -ForegroundColor Green
Write-Host "Failed: $script:testsFailed" -ForegroundColor $(if ($script:testsFailed -eq 0) { "Green" } else { "Red" })

$successRate = [math]::Round(($script:testsPassed / $script:testsRun) * 100, 2)
Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 90) { "Green" } elseif ($successRate -ge 70) { "Yellow" } else { "Red" })

if ($script:testsFailed -eq 0) {
  Write-Host "`n✅ All tests passed!" -ForegroundColor Green
} else {
  Write-Host "`n⚠️ Some tests failed. Review the output above." -ForegroundColor Yellow
}

Write-Host "`n🔍 Created Resources:" -ForegroundColor Cyan
if ($script:categoryId) { Write-Host "   Category ID: $script:categoryId" -ForegroundColor Gray }
if ($script:subCategoryId) { Write-Host "   Subcategory ID: $script:subCategoryId" -ForegroundColor Gray }
if ($script:brandAttributeId) { Write-Host "   Brand Attribute ID: $script:brandAttributeId" -ForegroundColor Gray }
if ($script:ramAttributeId) { Write-Host "   RAM Attribute ID: $script:ramAttributeId" -ForegroundColor Gray }
if ($script:simpleProductId) { Write-Host "   Simple Product ID: $script:simpleProductId" -ForegroundColor Gray }
if ($script:advancedProductId) { Write-Host "   Advanced Product ID: $script:advancedProductId" -ForegroundColor Gray }

Write-Host "`n📚 Key Features Tested:" -ForegroundColor Cyan
Write-Host "   ✓ Session-based authentication" -ForegroundColor White
Write-Host "   ✓ Category creation (parent/child)" -ForegroundColor White
Write-Host "   ✓ Attribute & option management" -ForegroundColor White
Write-Host "   ✓ Product creation (no attributes)" -ForegroundColor White
Write-Host "   ✓ Product creation (new attributes)" -ForegroundColor White
Write-Host "   ✓ Product creation (existing attributes)" -ForegroundColor White
Write-Host "   ✓ Complex product (7+ attributes)" -ForegroundColor White

Write-Host ""

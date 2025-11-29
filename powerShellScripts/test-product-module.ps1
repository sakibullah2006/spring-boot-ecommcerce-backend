# ========================================
# Product Module Comprehensive Test Script
# ========================================
# This script tests all Product and Attribute endpoints with various scenarios
# ========================================

param(
    [string]$BaseUrl = "http://localhost:8080",
    [string]$AdminEmail = "sakibullah@gmail.com",
    [string]$AdminPassword = "password123"
)

# ========================================
# Configuration
# ========================================
$ErrorActionPreference = "Continue"
$script:PassedTests = 0
$script:FailedTests = 0
$script:TestResults = @()

# ========================================
# Helper Functions
# ========================================

function Write-TestHeader {
    param([string]$Title)
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
}

function Write-TestCase {
    param([string]$Name)
    Write-Host "`n▶ Test: $Name" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host "  ✓ $Message" -ForegroundColor Green
    $script:PassedTests++
    $script:TestResults += [PSCustomObject]@{
        Test = $Message
        Result = "PASS"
    }
}

function Write-Failure {
    param([string]$Message, [string]$Details = "")
    Write-Host "  ✗ $Message" -ForegroundColor Red
    if ($Details) {
        Write-Host "    Details: $Details" -ForegroundColor DarkRed
    }
    $script:FailedTests++
    $script:TestResults += [PSCustomObject]@{
        Test = $Message
        Result = "FAIL"
        Details = $Details
    }
}

function Invoke-ApiRequest {
    param(
        [string]$Method,
        [string]$Uri,
        [string]$Body = $null,
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession = $null,
        [int]$ExpectedStatusCode = 200,
        [string]$TestName
    )
    
    try {
        $params = @{
            Uri = $Uri
            Method = $Method
            ContentType = "application/json"
        }
        
        if ($Body) { $params.Body = $Body }
        if ($WebSession) { $params.WebSession = $WebSession }
        
        $response = Invoke-RestMethod @params -ErrorAction Stop
        
        Write-Success "$TestName - Status: $ExpectedStatusCode"
        return $response
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq $ExpectedStatusCode) {
            Write-Success "$TestName - Expected error: $ExpectedStatusCode"
            return $null
        }
        else {
            Write-Failure "$TestName" "Expected: $ExpectedStatusCode, Got: $statusCode - $($_.Exception.Message)"
            return $null
        }
    }
}

# ========================================
# Authentication
# ========================================

Write-TestHeader "Authentication Setup"

Write-TestCase "Admin Login"
try {
    $loginBody = @{
        email = $AdminEmail
        password = $AdminPassword
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Uri "$BaseUrl/api/auth/login" `
        -Method Post `
        -Body $loginBody `
        -ContentType "application/json" `
        -SessionVariable adminSession

    Write-Success "Admin logged in as: $($loginResponse.firstName) $($loginResponse.lastName)"
    Write-Host "  Role: $($loginResponse.role)" -ForegroundColor Cyan
}
catch {
    Write-Failure "Admin login failed" $_.Exception.Message
    exit 1
}

# ========================================
# Product Tests - GET (Public Access)
# ========================================

Write-TestHeader "Product GET Tests (Public Access)"

# Test 1: Get All Products
Write-TestCase "GET /api/products - Get all products"
$allProducts = Invoke-ApiRequest -Method Get -Uri "$BaseUrl/api/products" `
    -ExpectedStatusCode 200 -TestName "Get all products"

if ($allProducts) {
    Write-Host "  Found $($allProducts.Count) products" -ForegroundColor Cyan
}

# Test 2: Get Paginated Products
Write-TestCase "GET /api/products/paginated - Get paginated products"
$paginatedProducts = Invoke-ApiRequest -Method Get -Uri "$BaseUrl/api/products/paginated?page=0&size=5" `
    -ExpectedStatusCode 200 -TestName "Get paginated products"

if ($paginatedProducts) {
    Write-Host "  Total Elements: $($paginatedProducts.totalElements)" -ForegroundColor Cyan
    Write-Host "  Total Pages: $($paginatedProducts.totalPages)" -ForegroundColor Cyan
    Write-Host "  Current Page Size: $($paginatedProducts.content.Count)" -ForegroundColor Cyan
}

# Test 3: Get Paginated Products with Sorting
Write-TestCase "GET /api/products/paginated - With custom sorting"
$sortedProducts = Invoke-ApiRequest -Method Get -Uri "$BaseUrl/api/products/paginated?page=0&size=5&sort=price,desc" `
    -ExpectedStatusCode 200 -TestName "Get products sorted by price DESC"

# ========================================
# Product Tests - CREATE (Admin Only)
# ========================================

Write-TestHeader "Product CREATE Tests (Admin Only)"

# Get a valid category ID for testing
Write-TestCase "Get categories for product creation"
try {
    $categories = Invoke-RestMethod -Uri "$BaseUrl/api/categories" -Method Get
    $categoryId = $categories[0].id
    Write-Host "  Using category: $($categories[0].name) (ID: $categoryId)" -ForegroundColor Cyan
}
catch {
    Write-Failure "Failed to get categories" $_.Exception.Message
    $categoryId = "ceb0d1b7-cc97-11f0-aa56-00e04c816b21" # Fallback
}

# Test 4: Create Simple Product (No Attributes, No Slug - Auto-generated)
Write-TestCase "POST /api/products - Create simple product without slug"
$simpleProductBody = @{
    sku = "TEST-SIMPLE-$(Get-Random -Maximum 99999)"
    name = "Test Simple Product"
    shortDescription = "A brief summary of the test product for quick overview"
    description = "<h2>Product Description</h2><p>A simple test product <strong>without attributes</strong>.</p><ul><li>Easy to use</li><li>High quality</li></ul>"
    price = 99.99
    salePrice = 79.99
    stockQuantity = 50
    categoryIds = @($categoryId)
} | ConvertTo-Json

$simpleProduct = Invoke-ApiRequest -Method Post -Uri "$BaseUrl/api/products" `
    -Body $simpleProductBody -WebSession $adminSession `
    -ExpectedStatusCode 201 -TestName "Create simple product without slug"

$simpleProductId = $simpleProduct.id
if ($simpleProduct) {
    Write-Host "  Created Product ID: $simpleProductId" -ForegroundColor Cyan
    Write-Host "  Auto-generated Slug: $($simpleProduct.slug)" -ForegroundColor Cyan
    if ($simpleProduct.slug -eq "test-simple-product") {
        Write-Success "Slug auto-generated correctly from product name"
    } else {
        Write-Failure "Slug auto-generation" "Expected: test-simple-product, Got: $($simpleProduct.slug)"
    }
}

# Test 4b: Create Product with Custom Slug
Write-TestCase "POST /api/products - Create product with custom slug"
$customSlugBody = @{
    sku = "TEST-CUSTOM-SLUG-$(Get-Random -Maximum 99999)"
    name = "Custom Slug Product"
    slug = "my-custom-product-slug"
    shortDescription = "Product with a custom URL-friendly slug identifier"
    description = "<h2>Custom Slug Product</h2><p>This product demonstrates <em>custom slug</em> functionality.</p><p>The slug is used for <strong>SEO-friendly URLs</strong>.</p>"
    price = 149.99
    salePrice = 129.99
    stockQuantity = 40
    categoryIds = @($categoryId)
} | ConvertTo-Json

$customSlugProduct = Invoke-ApiRequest -Method Post -Uri "$BaseUrl/api/products" `
    -Body $customSlugBody -WebSession $adminSession `
    -ExpectedStatusCode 201 -TestName "Create product with custom slug"

$customSlugProductId = $customSlugProduct.id
if ($customSlugProduct) {
    Write-Host "  Created Product ID: $customSlugProductId" -ForegroundColor Cyan
    Write-Host "  Custom Slug: $($customSlugProduct.slug)" -ForegroundColor Cyan
    if ($customSlugProduct.slug -eq "my-custom-product-slug") {
        Write-Success "Custom slug preserved correctly"
    } else {
        Write-Failure "Custom slug preservation" "Expected: my-custom-product-slug, Got: $($customSlugProduct.slug)"
    }
}

# Test 4c: Create Product with Duplicate Name (Slug Auto-increment)
Write-TestCase "POST /api/products - Create product with duplicate name (slug conflict)"
$duplicateNameBody = @{
    sku = "TEST-DUP-NAME-$(Get-Random -Maximum 99999)"
    name = "Test Simple Product"
    shortDescription = "Another product with same name to test slug auto-increment"
    description = "<h2>Duplicate Name Test</h2><p>This product has the <strong>same name</strong> as another product.</p><p>The system should auto-increment the slug to avoid conflicts.</p>"
    price = 89.99
    salePrice = 79.99
    stockQuantity = 25
    categoryIds = @($categoryId)
} | ConvertTo-Json

$duplicateNameProduct = Invoke-ApiRequest -Method Post -Uri "$BaseUrl/api/products" `
    -Body $duplicateNameBody -WebSession $adminSession `
    -ExpectedStatusCode 201 -TestName "Create product with duplicate name"

$duplicateNameProductId = $duplicateNameProduct.id
if ($duplicateNameProduct) {
    Write-Host "  Created Product ID: $duplicateNameProductId" -ForegroundColor Cyan
    Write-Host "  Auto-generated Slug with Counter: $($duplicateNameProduct.slug)" -ForegroundColor Cyan
    if ($duplicateNameProduct.slug -match "^test-simple-product-\d+$") {
        Write-Success "Slug conflict resolved with counter"
    } else {
        Write-Failure "Slug conflict resolution" "Expected pattern: test-simple-product-N, Got: $($duplicateNameProduct.slug)"
    }
}

# Test 5: Create Product with Attributes
Write-TestCase "POST /api/products - Create product with attributes"
$productWithAttrsBody = @{
    sku = "TEST-ATTRS-$(Get-Random -Maximum 99999)"
    name = "Test Product with Attributes"
    shortDescription = "Feature-rich product with multiple attributes like color and size"
    description = "<h2>Product with Attributes</h2><p>This product showcases the <strong>reusable attribute system</strong>.</p><ul><li><em>Color:</em> Red</li><li><em>Size:</em> Large</li></ul><p>Attributes help customers find the <strong>perfect match</strong> for their needs.</p>"
    price = 149.99
    salePrice = 129.99
    stockQuantity = 100
    categoryIds = @($categoryId)
    attributes = @(
        @{
            attributeName = "Color"
            attributeDescription = "Product color"
            selectedOptions = @(
                @{ optionName = "Red"; optionDescription = "Red color" },
                @{ optionName = "Blue"; optionDescription = "Blue color" }
            )
        },
        @{
            attributeName = "Size"
            attributeDescription = "Product size"
            selectedOptions = @(
                @{ optionName = "Medium"; optionDescription = "M size" },
                @{ optionName = "Large"; optionDescription = "L size" }
            )
        }
    )
} | ConvertTo-Json -Depth 10

$productWithAttrs = Invoke-ApiRequest -Method Post -Uri "$BaseUrl/api/products" `
    -Body $productWithAttrsBody -WebSession $adminSession `
    -ExpectedStatusCode 201 -TestName "Create product with attributes"

$productWithAttrsId = $productWithAttrs.id
if ($productWithAttrs) {
    Write-Host "  Created Product ID: $productWithAttrsId" -ForegroundColor Cyan
    Write-Host "  Attributes Count: $($productWithAttrs.attributes.Count)" -ForegroundColor Cyan
}

# Test 6: Create Product - Invalid Data (Missing Required Fields)
Write-TestCase "POST /api/products - Invalid data (missing SKU)"
$invalidProductBody = @{
    name = "Invalid Product"
    price = 99.99
    stockQuantity = 10
    categoryIds = @($categoryId)
} | ConvertTo-Json

Invoke-ApiRequest -Method Post -Uri "$BaseUrl/api/products" `
    -Body $invalidProductBody -WebSession $adminSession `
    -ExpectedStatusCode 400 -TestName "Create product with invalid data"

# Test 7: Create Product - Negative Price
Write-TestCase "POST /api/products - Invalid price (negative)"
$negPriceBody = @{
    sku = "TEST-NEG-$(Get-Random)"
    name = "Negative Price Product"
    price = -50.00
    stockQuantity = 10
    categoryIds = @($categoryId)
} | ConvertTo-Json

Invoke-ApiRequest -Method Post -Uri "$BaseUrl/api/products" `
    -Body $negPriceBody -WebSession $adminSession `
    -ExpectedStatusCode 400 -TestName "Create product with negative price"

# Test 8: Create Product - Unauthorized (No Auth)
Write-TestCase "POST /api/products - Unauthorized access"
$unauthBody = @{
    sku = "UNAUTH-$(Get-Random)"
    name = "Unauthorized Product"
    price = 99.99
    stockQuantity = 10
    categoryIds = @($categoryId)
} | ConvertTo-Json

Invoke-ApiRequest -Method Post -Uri "$BaseUrl/api/products" `
    -Body $unauthBody `
    -ExpectedStatusCode 401 -TestName "Create product without authentication"

# ========================================
# Product Tests - GET by ID and SKU
# ========================================

Write-TestHeader "Product GET by ID/SKU Tests"

# Test 9: Get Product by Valid ID
if ($simpleProductId) {
    Write-TestCase "GET /api/products/{id} - Valid product ID"
    $productById = Invoke-ApiRequest -Method Get -Uri "$BaseUrl/api/products/$simpleProductId" `
        -ExpectedStatusCode 200 -TestName "Get product by valid ID"
    
    if ($productById) {
        Write-Host "  Product: $($productById.name)" -ForegroundColor Cyan
        Write-Host "  SKU: $($productById.sku)" -ForegroundColor Cyan
    }
}

# Test 10: Get Product by Invalid ID
Write-TestCase "GET /api/products/{id} - Invalid product ID"
Invoke-ApiRequest -Method Get -Uri "$BaseUrl/api/products/invalid-id-12345" `
    -ExpectedStatusCode 404 -TestName "Get product by invalid ID"

# Test 11: Get Product by SKU
if ($simpleProduct) {
    Write-TestCase "GET /api/products/sku/{sku} - Valid SKU"
    $productBySku = Invoke-ApiRequest -Method Get -Uri "$BaseUrl/api/products/sku/$($simpleProduct.sku)" `
        -ExpectedStatusCode 200 -TestName "Get product by valid SKU"
    
    if ($productBySku) {
        Write-Host "  Product: $($productBySku.name)" -ForegroundColor Cyan
    }
}

# Test 12: Get Product by Invalid SKU
Write-TestCase "GET /api/products/sku/{sku} - Invalid SKU"
Invoke-ApiRequest -Method Get -Uri "$BaseUrl/api/products/sku/INVALID-SKU-999999" `
    -ExpectedStatusCode 404 -TestName "Get product by invalid SKU"

# ========================================
# Product Tests - UPDATE (Admin Only)
# ========================================

Write-TestHeader "Product UPDATE Tests (Admin Only)"

# Test 13: Update Product - Valid Data
if ($simpleProductId) {
    Write-TestCase "PUT /api/products/{id} - Update product"
    $updateBody = @{
        sku = $simpleProduct.sku  # Required field
        name = "Updated Simple Product"
        shortDescription = "Updated short description with new product information"
        description = "<h2>Updated Description</h2><p>This product has been <strong>updated</strong>.</p><ul><li>New features</li><li>Better price</li></ul>"
        price = 119.99
        salePrice = 99.99
        stockQuantity = 75
        categoryIds = @($categoryId)
    } | ConvertTo-Json
    
    $updatedProduct = Invoke-ApiRequest -Method Put -Uri "$BaseUrl/api/products/$simpleProductId" `
        -Body $updateBody -WebSession $adminSession `
        -ExpectedStatusCode 200 -TestName "Update product with valid data"
    
    if ($updatedProduct) {
        Write-Host "  Updated Name: $($updatedProduct.name)" -ForegroundColor Cyan
        Write-Host "  Updated Price: $($updatedProduct.price)" -ForegroundColor Cyan
    }
}

# Test 14: Update Product - Add Attributes
if ($simpleProductId) {
    Write-TestCase "PUT /api/products/{id} - Add attributes to product"
    $addAttrsBody = @{
        sku = $simpleProduct.sku  # Required field
        name = "Updated Simple Product"
        description = "Now with attributes"
        price = 119.99
        salePrice = 99.99
        stockQuantity = 75
        categoryIds = @($categoryId)
        attributes = @(
            @{
                attributeName = "Material"
                attributeDescription = "Product material"
                selectedOptions = @(
                    @{ optionName = "Cotton"; optionDescription = "Cotton material" }
                )
            }
        )
    } | ConvertTo-Json -Depth 10
    
    $updatedWithAttrs = Invoke-ApiRequest -Method Put -Uri "$BaseUrl/api/products/$simpleProductId" `
        -Body $addAttrsBody -WebSession $adminSession `
        -ExpectedStatusCode 200 -TestName "Add attributes to existing product"
    
    if ($updatedWithAttrs) {
        Write-Host "  Attributes Count: $($updatedWithAttrs.attributes.Count)" -ForegroundColor Cyan
    }
}

# Test 15: Update Product - Invalid ID
Write-TestCase "PUT /api/products/{id} - Invalid product ID"
$updateInvalidBody = @{
    sku = "INVALID-SKU"
    name = "Should Not Update"
    price = 99.99
    stockQuantity = 10
    categoryIds = @($categoryId)
} | ConvertTo-Json

Invoke-ApiRequest -Method Put -Uri "$BaseUrl/api/products/invalid-id-99999" `
    -Body $updateInvalidBody -WebSession $adminSession `
    -ExpectedStatusCode 404 -TestName "Update product with invalid ID"

# Test 16: Update Product - Unauthorized
if ($simpleProductId) {
    Write-TestCase "PUT /api/products/{id} - Unauthorized access"
    $unauthUpdateBody = @{
        sku = $simpleProduct.sku
        name = "Unauthorized Update"
        price = 99.99
        stockQuantity = 10
        categoryIds = @($categoryId)
    } | ConvertTo-Json
    
    Invoke-ApiRequest -Method Put -Uri "$BaseUrl/api/products/$simpleProductId" `
        -Body $unauthUpdateBody `
        -ExpectedStatusCode 401 -TestName "Update product without authentication"
}

# ========================================
# Attribute Tests - GET (Public Access)
# ========================================

Write-TestHeader "Attribute GET Tests (Public Access)"

# Test 17: Get All Attributes
Write-TestCase "GET /api/attributes - Get all attributes"
$allAttributes = Invoke-ApiRequest -Method Get -Uri "$BaseUrl/api/attributes" `
    -ExpectedStatusCode 200 -TestName "Get all attributes"

if ($allAttributes -and $allAttributes.Count -gt 0) {
    Write-Host "  Found $($allAttributes.Count) attributes" -ForegroundColor Cyan
    $testAttributeId = $allAttributes[0].id
    
    # Test 18: Get Attribute by ID
    Write-TestCase "GET /api/attributes/{id} - Get attribute by ID"
    $attributeById = Invoke-ApiRequest -Method Get -Uri "$BaseUrl/api/attributes/$testAttributeId" `
        -ExpectedStatusCode 200 -TestName "Get attribute by valid ID"
    
    if ($attributeById) {
        Write-Host "  Attribute: $($attributeById.name)" -ForegroundColor Cyan
    }
    
    # Test 19: Get Attribute Options
    Write-TestCase "GET /api/attributes/{id}/options - Get attribute options"
    $attributeOptions = Invoke-ApiRequest -Method Get -Uri "$BaseUrl/api/attributes/$testAttributeId/options" `
        -ExpectedStatusCode 200 -TestName "Get attribute options"
    
    if ($attributeOptions) {
        Write-Host "  Found $($attributeOptions.Count) options" -ForegroundColor Cyan
    }
}

# Test 20: Get Attribute by Invalid ID
Write-TestCase "GET /api/attributes/{id} - Invalid attribute ID"
Invoke-ApiRequest -Method Get -Uri "$BaseUrl/api/attributes/invalid-attr-id" `
    -ExpectedStatusCode 400 -TestName "Get attribute by invalid ID (expects 400)"

# ========================================
# Attribute Tests - CREATE (Admin Only)
# ========================================

Write-TestHeader "Attribute CREATE Tests (Admin Only)"

# Test 21: Create New Attribute
Write-TestCase "POST /api/attributes - Create attribute"
$createAttrBody = @{
    name = "Test Attribute $(Get-Random -Maximum 9999)"
    description = "Test attribute description"
} | ConvertTo-Json

$newAttribute = Invoke-ApiRequest -Method Post -Uri "$BaseUrl/api/attributes" `
    -Body $createAttrBody -WebSession $adminSession `
    -ExpectedStatusCode 201 -TestName "Create new attribute"

$newAttributeId = $newAttribute.id
if ($newAttribute) {
    Write-Host "  Created Attribute ID: $newAttributeId" -ForegroundColor Cyan
    Write-Host "  Name: $($newAttribute.name)" -ForegroundColor Cyan
}

# Test 22: Create Attribute - Unauthorized
Write-TestCase "POST /api/attributes - Unauthorized access"
$unauthAttrBody = @{
    name = "Unauthorized Attribute"
    description = "Should not be created"
} | ConvertTo-Json

Invoke-ApiRequest -Method Post -Uri "$BaseUrl/api/attributes" `
    -Body $unauthAttrBody `
    -ExpectedStatusCode 401 -TestName "Create attribute without authentication"

# ========================================
# Attribute Option Tests - CREATE (Admin Only)
# ========================================

Write-TestHeader "Attribute Option Tests (Admin Only)"

# Test 23: Create Attribute Option
if ($newAttributeId) {
    Write-TestCase "POST /api/attributes/{id}/options - Create attribute option"
    $createOptionBody = @{
        name = "Test Option $(Get-Random -Maximum 999)"
        description = "Test option description"
    } | ConvertTo-Json
    
    $newOption = Invoke-ApiRequest -Method Post -Uri "$BaseUrl/api/attributes/$newAttributeId/options" `
        -Body $createOptionBody -WebSession $adminSession `
        -ExpectedStatusCode 201 -TestName "Create attribute option"
    
    $newOptionId = $newOption.id
    if ($newOption) {
        Write-Host "  Created Option ID: $newOptionId" -ForegroundColor Cyan
        Write-Host "  Name: $($newOption.name)" -ForegroundColor Cyan
    }
    
    # Test 24: Update Attribute Option
    if ($newOptionId) {
        Write-TestCase "PUT /api/attributes/options/{id} - Update attribute option"
        $updateOptionBody = @{
            name = "Updated Option Name"
            description = "Updated description"
            isActive = $true
        } | ConvertTo-Json
        
        $updatedOption = Invoke-ApiRequest -Method Put -Uri "$BaseUrl/api/attributes/options/$newOptionId" `
            -Body $updateOptionBody -WebSession $adminSession `
            -ExpectedStatusCode 200 -TestName "Update attribute option"
        
        if ($updatedOption) {
            Write-Host "  Updated Name: $($updatedOption.name)" -ForegroundColor Cyan
        }
    }
}

# Test 25: Create Option - Invalid Attribute ID
Write-TestCase "POST /api/attributes/{id}/options - Invalid attribute ID"
$invalidOptionBody = @{
    name = "Invalid Option"
    description = "Should fail"
} | ConvertTo-Json

Invoke-ApiRequest -Method Post -Uri "$BaseUrl/api/attributes/invalid-id/options" `
    -Body $invalidOptionBody -WebSession $adminSession `
    -ExpectedStatusCode 400 -TestName "Create option for invalid attribute (expects 400)"

# ========================================
# Attribute Tests - UPDATE (Admin Only)
# ========================================

Write-TestHeader "Attribute UPDATE Tests (Admin Only)"

# Test 26: Update Attribute
if ($newAttributeId) {
    Write-TestCase "PUT /api/attributes/{id} - Update attribute"
    $updateAttrBody = @{
        name = "Updated Attribute Name $(Get-Random -Maximum 9999)"
        description = "Updated attribute description"
        isActive = $true
    } | ConvertTo-Json
    
    $updatedAttr = Invoke-ApiRequest -Method Put -Uri "$BaseUrl/api/attributes/$newAttributeId" `
        -Body $updateAttrBody -WebSession $adminSession `
        -ExpectedStatusCode 200 -TestName "Update attribute"
    
    if ($updatedAttr) {
        Write-Host "  Updated Name: $($updatedAttr.name)" -ForegroundColor Cyan
    }
}

# Test 27: Update Attribute - Invalid ID
Write-TestCase "PUT /api/attributes/{id} - Invalid attribute ID"
$invalidUpdateAttrBody = @{
    name = "Should Not Update"
    description = "Invalid"
    isActive = $true
} | ConvertTo-Json

Invoke-ApiRequest -Method Put -Uri "$BaseUrl/api/attributes/invalid-attr-id-999" `
    -Body $invalidUpdateAttrBody -WebSession $adminSession `
    -ExpectedStatusCode 400 -TestName "Update attribute with invalid ID (expects 400)"

# ========================================
# Product Tests - DELETE (Admin Only)
# ========================================

Write-TestHeader "Product DELETE Tests (Admin Only)"

# Test 28: Delete Product - Unauthorized
if ($simpleProductId) {
    Write-TestCase "DELETE /api/products/{id} - Unauthorized access"
    Invoke-ApiRequest -Method Delete -Uri "$BaseUrl/api/products/$simpleProductId" `
        -ExpectedStatusCode 401 -TestName "Delete product without authentication"
}

# Test 29: Delete Product - Invalid ID
Write-TestCase "DELETE /api/products/{id} - Invalid product ID"
Invoke-ApiRequest -Method Delete -Uri "$BaseUrl/api/products/invalid-id-to-delete" `
    -WebSession $adminSession `
    -ExpectedStatusCode 404 -TestName "Delete product with invalid ID"

# Test 30: Delete Product - Valid (Simple Product)
if ($simpleProductId) {
    Write-TestCase "DELETE /api/products/{id} - Valid product"
    Invoke-ApiRequest -Method Delete -Uri "$BaseUrl/api/products/$simpleProductId" `
        -WebSession $adminSession `
        -ExpectedStatusCode 204 -TestName "Delete simple product"
    
    # Verify deletion
    Write-TestCase "Verify product deletion"
    Invoke-ApiRequest -Method Get -Uri "$BaseUrl/api/products/$simpleProductId" `
        -ExpectedStatusCode 404 -TestName "Verify deleted product is not found"
}

# Test 31: Delete Product with Attributes
if ($productWithAttrsId) {
    Write-TestCase "DELETE /api/products/{id} - Product with attributes"
    Invoke-ApiRequest -Method Delete -Uri "$BaseUrl/api/products/$productWithAttrsId" `
        -WebSession $adminSession `
        -ExpectedStatusCode 204 -TestName "Delete product with attributes"
}

# ========================================
# Attribute DELETE Tests (Admin Only)
# ========================================

Write-TestHeader "Attribute DELETE Tests (Admin Only)"

# Test 32: Deactivate Attribute Option
if ($newOptionId) {
    Write-TestCase "DELETE /api/attributes/options/{id} - Deactivate option"
    Invoke-ApiRequest -Method Delete -Uri "$BaseUrl/api/attributes/options/$newOptionId" `
        -WebSession $adminSession `
        -ExpectedStatusCode 204 -TestName "Deactivate attribute option"
}

# Test 33: Deactivate Attribute
if ($newAttributeId) {
    Write-TestCase "DELETE /api/attributes/{id} - Deactivate attribute"
    Invoke-ApiRequest -Method Delete -Uri "$BaseUrl/api/attributes/$newAttributeId" `
        -WebSession $adminSession `
        -ExpectedStatusCode 204 -TestName "Deactivate attribute"
}

# Test 34: Deactivate Attribute - Unauthorized
Write-TestCase "DELETE /api/attributes/{id} - Unauthorized access"
Invoke-ApiRequest -Method Delete -Uri "$BaseUrl/api/attributes/some-attr-id" `
    -ExpectedStatusCode 401 -TestName "Deactivate attribute without authentication"

# ========================================
# Category Slug Tests (Admin Only)
# ========================================

Write-TestHeader "Category Slug Auto-Generation Tests (Admin Only)"

# Test 35: Create Category without Slug (Auto-generated)
Write-TestCase "POST /api/categories - Create category without slug"
$categoryNoSlugBody = @{
    name = "Electronics & Gadgets $(Get-Random -Maximum 999)"
    description = "Category for electronics and gadgets"
} | ConvertTo-Json

$categoryNoSlug = Invoke-ApiRequest -Method Post -Uri "$BaseUrl/api/categories" `
    -Body $categoryNoSlugBody -WebSession $adminSession `
    -ExpectedStatusCode 201 -TestName "Create category without slug"

$categoryNoSlugId = $categoryNoSlug.id
if ($categoryNoSlug) {
    Write-Host "  Created Category ID: $categoryNoSlugId" -ForegroundColor Cyan
    Write-Host "  Auto-generated Slug: $($categoryNoSlug.slug)" -ForegroundColor Cyan
    if ($categoryNoSlug.slug -match "^electronics-gadgets-\d+$") {
        Write-Success "Category slug auto-generated correctly"
    } else {
        Write-Host "  Expected pattern: electronics-gadgets-N" -ForegroundColor DarkYellow
    }
}

# Test 36: Create Category with Custom Slug
Write-TestCase "POST /api/categories - Create category with custom slug"
$categoryCustomSlugBody = @{
    name = "Custom Category Name"
    slug = "my-custom-category-slug"
    description = "Category with custom slug"
} | ConvertTo-Json

$categoryCustomSlug = Invoke-ApiRequest -Method Post -Uri "$BaseUrl/api/categories" `
    -Body $categoryCustomSlugBody -WebSession $adminSession `
    -ExpectedStatusCode 201 -TestName "Create category with custom slug"

$categoryCustomSlugId = $categoryCustomSlug.id
if ($categoryCustomSlug) {
    Write-Host "  Created Category ID: $categoryCustomSlugId" -ForegroundColor Cyan
    Write-Host "  Custom Slug: $($categoryCustomSlug.slug)" -ForegroundColor Cyan
    if ($categoryCustomSlug.slug -eq "my-custom-category-slug") {
        Write-Success "Custom category slug preserved correctly"
    } else {
        Write-Failure "Custom category slug preservation" "Expected: my-custom-category-slug, Got: $($categoryCustomSlug.slug)"
    }
}

# Test 37: Create Category with Same Slug (Should Auto-increment)
Write-TestCase "POST /api/categories - Create category with conflicting slug"
$categoryDupNameBody = @{
    name = "Another Custom Category $(Get-Random -Maximum 999)"
    slug = "my-custom-category-slug"  # Same slug as Test 36
    description = "Category with conflicting slug"
} | ConvertTo-Json

$categoryDupName = Invoke-ApiRequest -Method Post -Uri "$BaseUrl/api/categories" `
    -Body $categoryDupNameBody -WebSession $adminSession `
    -ExpectedStatusCode 201 -TestName "Create category with conflicting slug"

$categoryDupNameId = $categoryDupName.id
if ($categoryDupName) {
    Write-Host "  Created Category ID: $categoryDupNameId" -ForegroundColor Cyan
    Write-Host "  Auto-incremented Slug: $($categoryDupName.slug)" -ForegroundColor Cyan
    if ($categoryDupName.slug -match "^my-custom-category-slug-\d+$") {
        Write-Success "Category slug conflict resolved with counter"
    } else {
        Write-Failure "Category slug conflict resolution" "Expected pattern: my-custom-category-slug-N, Got: $($categoryDupName.slug)"
    }
}

# Test 38: Create Category with Special Characters in Name
Write-TestCase "POST /api/categories - Create category with special characters"
$categorySpecialCharsBody = @{
    name = "Sports & Outdoor Activities! @2024"
    description = "Category with special characters in name"
} | ConvertTo-Json

$categorySpecialChars = Invoke-ApiRequest -Method Post -Uri "$BaseUrl/api/categories" `
    -Body $categorySpecialCharsBody -WebSession $adminSession `
    -ExpectedStatusCode 201 -TestName "Create category with special characters"

$categorySpecialCharsId = $categorySpecialChars.id
if ($categorySpecialChars) {
    Write-Host "  Created Category ID: $categorySpecialCharsId" -ForegroundColor Cyan
    Write-Host "  Sanitized Slug: $($categorySpecialChars.slug)" -ForegroundColor Cyan
    if ($categorySpecialChars.slug -match "^sports-outdoor-activities") {
        Write-Success "Special characters removed from slug correctly"
    } else {
        Write-Host "  Generated slug: $($categorySpecialChars.slug)" -ForegroundColor DarkYellow
    }
}

# Cleanup created categories
if ($categoryNoSlugId) {
    try {
        Invoke-RestMethod -Uri "$BaseUrl/api/categories/$categoryNoSlugId" `
            -Method Delete -WebSession $adminSession | Out-Null
    } catch { }
}
if ($categoryCustomSlugId) {
    try {
        Invoke-RestMethod -Uri "$BaseUrl/api/categories/$categoryCustomSlugId" `
            -Method Delete -WebSession $adminSession | Out-Null
    } catch { }
}
if ($categoryDupNameId) {
    try {
        Invoke-RestMethod -Uri "$BaseUrl/api/categories/$categoryDupNameId" `
            -Method Delete -WebSession $adminSession | Out-Null
    } catch { }
}
if ($categorySpecialCharsId) {
    try {
        Invoke-RestMethod -Uri "$BaseUrl/api/categories/$categorySpecialCharsId" `
            -Method Delete -WebSession $adminSession | Out-Null
    } catch { }
}

# Cleanup test products with custom slugs
if ($customSlugProductId) {
    try {
        Invoke-RestMethod -Uri "$BaseUrl/api/products/$customSlugProductId" `
            -Method Delete -WebSession $adminSession | Out-Null
    } catch { }
}
if ($duplicateNameProductId) {
    try {
        Invoke-RestMethod -Uri "$BaseUrl/api/products/$duplicateNameProductId" `
            -Method Delete -WebSession $adminSession | Out-Null
    } catch { }
}

# ========================================
# Edge Cases and Special Scenarios
# ========================================

Write-TestHeader "Edge Cases and Special Scenarios"

# Clean up any leftover test products from previous runs
Write-Host "\nCleaning up test products from previous runs..." -ForegroundColor Cyan
try {
    $allProducts = Invoke-RestMethod -Uri "$BaseUrl/api/products" -Method Get
    $testProducts = $allProducts | Where-Object { $_.sku -match '^(MULTI-CAT|ZERO-STOCK|DUP-ATTR)-' }
    foreach ($product in $testProducts) {
        try {
            Invoke-RestMethod -Uri "$BaseUrl/api/products/$($product.id)" -Method Delete -WebSession $adminSession | Out-Null
            Write-Host "  Cleaned up: $($product.sku)" -ForegroundColor DarkGray
        } catch {
            # Ignore errors during cleanup
        }
    }
} catch {
    Write-Host "  Cleanup skipped (no products to clean)" -ForegroundColor DarkGray
}

# Test 39: Create Product with Multiple Categories
Write-TestCase "POST /api/products - Product with multiple categories"
try {
    $categories = Invoke-RestMethod -Uri "$BaseUrl/api/categories" -Method Get
    $multiCategoryIds = $categories[0..1].id
    
    $uniqueId = [guid]::NewGuid().ToString().Substring(0, 8)
    $multiCatBody = @{
        sku = "MULTI-CAT-$uniqueId"
        name = "Multi-Category Product"
        description = "Product in multiple categories"
        price = 199.99
        salePrice = 179.99
        stockQuantity = 30
        categoryIds = $multiCategoryIds
    } | ConvertTo-Json
    
    $multiCatProduct = Invoke-ApiRequest -Method Post -Uri "$BaseUrl/api/products" `
        -Body $multiCatBody -WebSession $adminSession `
        -ExpectedStatusCode 201 -TestName "Create product with multiple categories"
    
    if ($multiCatProduct) {
        Write-Host "  Categories Count: $($multiCatProduct.categories.Count)" -ForegroundColor Cyan
        
        # Clean up
        Invoke-RestMethod -Uri "$BaseUrl/api/products/$($multiCatProduct.id)" `
            -Method Delete -WebSession $adminSession | Out-Null
    }
}
catch {
    Write-Failure "Multi-category product test" $_.Exception.Message
}

# Test 40: Create Product with Zero Stock
Write-TestCase "POST /api/products - Product with zero stock"
$uniqueId = [guid]::NewGuid().ToString().Substring(0, 8)
$zeroStockBody = @{
    sku = "ZERO-STOCK-$uniqueId"
    name = "Out of Stock Product"
    shortDescription = "Currently unavailable - sign up for restock notifications"
    description = "<h2>Out of Stock</h2><p>This product is <strong>currently unavailable</strong>.</p><p><em>Join our waitlist</em> to be notified when it's back in stock!</p>"
    price = 99.99
    salePrice = 89.99
    stockQuantity = 0
    categoryIds = @($categoryId)
} | ConvertTo-Json

$zeroStockProduct = Invoke-ApiRequest -Method Post -Uri "$BaseUrl/api/products" `
    -Body $zeroStockBody -WebSession $adminSession `
    -ExpectedStatusCode 201 -TestName "Create product with zero stock"

if ($zeroStockProduct) {
    Write-Host "  Stock Quantity: $($zeroStockProduct.stockQuantity)" -ForegroundColor Cyan
    
    # Clean up
    Invoke-RestMethod -Uri "$BaseUrl/api/products/$($zeroStockProduct.id)" `
        -Method Delete -WebSession $adminSession | Out-Null
}

# Test 41: Create Product with Same Attribute Multiple Times (Should handle gracefully)
Write-TestCase "POST /api/products - Duplicate attribute handling"
$uniqueId = [guid]::NewGuid().ToString().Substring(0, 8)
$dupAttrBody = @{
    sku = "DUP-ATTR-$uniqueId"
    name = "Duplicate Attribute Test"
    price = 99.99
    salePrice = 89.99
    stockQuantity = 10
    categoryIds = @($categoryId)
    attributes = @(
        @{
            attributeName = "Color"
            selectedOptions = @(@{ optionName = "Red" })
        },
        @{
            attributeName = "Color"
            selectedOptions = @(@{ optionName = "Blue" })
        }
    )
} | ConvertTo-Json -Depth 10

$dupAttrProduct = Invoke-ApiRequest -Method Post -Uri "$BaseUrl/api/products" `
    -Body $dupAttrBody -WebSession $adminSession `
    -ExpectedStatusCode 201 -TestName "Create product with duplicate attributes"

if ($dupAttrProduct) {
    # Clean up
    Invoke-RestMethod -Uri "$BaseUrl/api/products/$($dupAttrProduct.id)" `
        -Method Delete -WebSession $adminSession | Out-Null
}

# Test 42: Pagination Edge Cases
Write-TestCase "GET /api/products/paginated - Large page size"
Invoke-ApiRequest -Method Get -Uri "$BaseUrl/api/products/paginated?page=0&size=1000" `
    -ExpectedStatusCode 200 -TestName "Get products with large page size"

Write-TestCase "GET /api/products/paginated - Invalid page number"
Invoke-ApiRequest -Method Get -Uri "$BaseUrl/api/products/paginated?page=-1&size=10" `
    -ExpectedStatusCode 200 -TestName "Get products with negative page number"

# ========================================
# Test Summary
# ========================================

Write-TestHeader "Test Summary"

Write-Host "`nTotal Tests Run: $($script:PassedTests + $script:FailedTests)" -ForegroundColor White
Write-Host "Passed: $script:PassedTests" -ForegroundColor Green
Write-Host "Failed: $script:FailedTests" -ForegroundColor Red

$successRate = if (($script:PassedTests + $script:FailedTests) -gt 0) {
    [math]::Round(($script:PassedTests / ($script:PassedTests + $script:FailedTests)) * 100, 2)
} else {
    0
}
Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 90) { "Green" } elseif ($successRate -ge 70) { "Yellow" } else { "Red" })

# Export results to CSV
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$reportPath = Join-Path $PSScriptRoot "test-results-$timestamp.csv"
$script:TestResults | Export-Csv -Path $reportPath -NoTypeInformation
Write-Host "`nDetailed results exported to: $reportPath" -ForegroundColor Cyan

# Exit with appropriate code
exit $(if ($script:FailedTests -eq 0) { 0 } else { 1 })

# Comprehensive test script for all Product endpoints

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing All Product Endpoints" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$baseUrl = "http://localhost:8080"
$testsPassed = 0
$testsFailed = 0

function Test-Endpoint {
    param($name, $scriptBlock)
    Write-Host ""
    Write-Host "TEST: $name" -ForegroundColor Yellow
    try {
        & $scriptBlock
        $script:testsPassed++
        Write-Host "  PASSED" -ForegroundColor Green
        return $true
    } catch {
        $script:testsFailed++
        Write-Host "  FAILED: $_" -ForegroundColor Red
        if ($_.Exception.Response) {
            $stream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $responseBody = $reader.ReadToEnd()
            Write-Host "  Response: $responseBody" -ForegroundColor Red
        }
        return $false
    }
}

# Login as admin
Write-Host ""
Write-Host "Logging in as admin..." -ForegroundColor Cyan
$loginBody = @{
    email = "sakibullah@gmail.com"
    password = "password123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method POST -ContentType "application/json" -Body $loginBody -SessionVariable session
    Write-Host "  Logged in as: $($loginResponse.email) (Role: $($loginResponse.role))" -ForegroundColor Green
} catch {
    Write-Host "  Login failed. Please ensure admin user exists." -ForegroundColor Red
    exit 1
}

# Variables to store IDs
$categoryId = $null
$productId = $null
$product2Id = $null

# TEST 1: Create a category first (needed for products)
Test-Endpoint "Create Test Category" {
    $categoryBody = @{
        name = "Test Electronics"
        description = "Test category for products"
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri "$baseUrl/api/categories" -Method POST -ContentType "application/json" -Body $categoryBody -WebSession $session
    Write-Host "    Created category ID: $($response.id), Name: $($response.name)"
    $script:categoryId = $response.id
}

# TEST 2: Create a product
Test-Endpoint "Create Product" {
    if ($categoryId) {
        $productBody = @{
            sku = "PROD-TEST-001"
            name = "Test Laptop"
            description = "High-performance test laptop"
            price = 999.99
            salePrice = 899.99
            stockQuantity = 50
            categoryIds = @($categoryId)
        } | ConvertTo-Json

        $response = Invoke-RestMethod -Uri "$baseUrl/api/products" -Method POST -ContentType "application/json" -Body $productBody -WebSession $session
        Write-Host "    Created product ID: $($response.id), SKU: $($response.sku), Name: $($response.name)"
        Write-Host "    Price: $($response.price), Sale Price: $($response.salePrice), Stock: $($response.stockQuantity)"
        $script:productId = $response.id
    } else {
        throw "No category ID available"
    }
}

# TEST 3: Create another product
Test-Endpoint "Create Second Product" {
    if ($categoryId) {
        $productBody = @{
            sku = "PROD-TEST-002"
            name = "Test Smartphone"
            description = "Advanced test smartphone"
            price = 599.99
            salePrice = 549.99
            stockQuantity = 100
            categoryIds = @($categoryId)
        } | ConvertTo-Json

        $response = Invoke-RestMethod -Uri "$baseUrl/api/products" -Method POST -ContentType "application/json" -Body $productBody -WebSession $session
        Write-Host "    Created product ID: $($response.id), SKU: $($response.sku), Name: $($response.name)"
        $script:product2Id = $response.id
    } else {
        throw "No category ID available"
    }
}

# TEST 4: Get all products (should work without authentication)
Test-Endpoint "Get All Products" {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/products" -Method GET -WebSession $session
    Write-Host "    Found $($response.Count) products"
    if ($response.Count -gt 0) {
        Write-Host "    First product: $($response[0].name)"
    }
}

# TEST 5: Get paginated products (should work without authentication)
Test-Endpoint "Get Paginated Products" {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/products/paginated?page=0&size=10" -Method GET -WebSession $session
    Write-Host "    Total elements: $($response.totalElements), Total pages: $($response.totalPages)"
    Write-Host "    Current page size: $($response.size), Current page number: $($response.number)"
}

# TEST 6: Get product by ID (should work without authentication)
Test-Endpoint "Get Product by ID" {
    if ($productId) {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/products/$productId" -Method GET -WebSession $session
        Write-Host "    Retrieved product: $($response.name), SKU: $($response.sku)"
        Write-Host "    Categories: $($response.categories.Count) category(ies)"
    } else {
        throw "No product ID available"
    }
}

# TEST 7: Get product by SKU (should work without authentication)
Test-Endpoint "Get Product by SKU" {
    $sku = "PROD-TEST-001"
    $response = Invoke-RestMethod -Uri "$baseUrl/api/products/sku/$sku" -Method GET -WebSession $session
    Write-Host "    Retrieved product: $($response.name), ID: $($response.id)"
}

# TEST 8: Update product
Test-Endpoint "Update Product" {
    if ($productId) {
        $updateBody = @{
            sku = "PROD-TEST-001-UPDATED"
            name = "Test Laptop - Updated Edition"
            description = "Updated high-performance laptop with new features"
            price = 1099.99
            salePrice = 999.99
            stockQuantity = 45
            categoryIds = @($categoryId)
        } | ConvertTo-Json

        $response = Invoke-RestMethod -Uri "$baseUrl/api/products/$productId" -Method PUT -ContentType "application/json" -Body $updateBody -WebSession $session
        Write-Host "    Updated product name to: $($response.name)"
        Write-Host "    Updated SKU to: $($response.sku)"
        Write-Host "    Updated price to: $($response.price), Sale price: $($response.salePrice)"
    } else {
        throw "No product ID available"
    }
}

# TEST 9: Try to create duplicate SKU (should fail)
Test-Endpoint "Create Duplicate SKU Product (Should Fail)" {
    $duplicateBody = @{
        sku = "PROD-TEST-001-UPDATED"
        name = "Duplicate Product"
        description = "This should fail"
        price = 99.99
        salePrice = 89.99
        stockQuantity = 10
        categoryIds = @($categoryId)
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/products" -Method POST -ContentType "application/json" -Body $duplicateBody -WebSession $session
        throw "Should have failed with duplicate SKU error"
    } catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 409) {
            Write-Host "    Correctly rejected duplicate SKU"
        } else {
            throw $_
        }
    }
}

# TEST 10: Try to create product with invalid category (should fail)
Test-Endpoint "Create Product with Invalid Category (Should Fail)" {
    $invalidCategoryId = "00000000-0000-0000-0000-000000000000"
    $invalidBody = @{
        sku = "PROD-TEST-999"
        name = "Invalid Product"
        description = "This should fail"
        price = 99.99
        salePrice = 89.99
        stockQuantity = 10
        categoryIds = @($invalidCategoryId)
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/products" -Method POST -ContentType "application/json" -Body $invalidBody -WebSession $session
        throw "Should have failed with category not found error"
    } catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 404) {
            Write-Host "    Correctly rejected invalid category ID"
        } else {
            throw $_
        }
    }
}

# TEST 11: Try to access protected endpoint without auth (should fail)
Test-Endpoint "Create Product Without Auth (Should Fail)" {
    $productBody = @{
        sku = "PROD-UNAUTH-001"
        name = "Unauthorized Product"
        description = "This should fail"
        price = 99.99
        salePrice = 89.99
        stockQuantity = 10
        categoryIds = @()
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/products" -Method POST -ContentType "application/json" -Body $productBody
        throw "Should have failed with authentication error"
    } catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 401) {
            Write-Host "    Correctly rejected unauthenticated request"
        } else {
            throw $_
        }
    }
}

# TEST 12: Try to update without auth (should fail)
Test-Endpoint "Update Product Without Auth (Should Fail)" {
    if ($productId) {
        $updateBody = @{
            sku = "PROD-TEST-UNAUTH"
            name = "Unauthorized Update"
            description = "This should fail"
            price = 99.99
            salePrice = 89.99
            stockQuantity = 10
            categoryIds = @()
        } | ConvertTo-Json

        try {
            $response = Invoke-RestMethod -Uri "$baseUrl/api/products/$productId" -Method PUT -ContentType "application/json" -Body $updateBody
            throw "Should have failed with authentication error"
        } catch {
            if ($_.Exception.Response.StatusCode.value__ -eq 401) {
                Write-Host "    Correctly rejected unauthenticated request"
            } else {
                throw $_
            }
        }
    } else {
        throw "No product ID available"
    }
}

# TEST 13: Delete first product
Test-Endpoint "Delete First Product" {
    if ($productId) {
        Invoke-RestMethod -Uri "$baseUrl/api/products/$productId" -Method DELETE -WebSession $session
        Write-Host "    Deleted product ID: $productId"
    } else {
        throw "No product ID available"
    }
}

# TEST 14: Delete second product
Test-Endpoint "Delete Second Product" {
    if ($product2Id) {
        Invoke-RestMethod -Uri "$baseUrl/api/products/$product2Id" -Method DELETE -WebSession $session
        Write-Host "    Deleted product ID: $product2Id"
    } else {
        throw "No second product ID available"
    }
}

# TEST 15: Try to get deleted product (should fail)
Test-Endpoint "Get Deleted Product (Should Fail)" {
    if ($productId) {
        try {
            $response = Invoke-RestMethod -Uri "$baseUrl/api/products/$productId" -Method GET -WebSession $session
            throw "Should have failed with 404"
        } catch {
            if ($_.Exception.Response.StatusCode.value__ -eq 404) {
                Write-Host "    Correctly returned 404 for deleted product"
            } else {
                throw $_
            }
        }
    } else {
        throw "No product ID available"
    }
}

# TEST 16: Try to get product by non-existent SKU (should fail)
Test-Endpoint "Get Product by Non-existent SKU (Should Fail)" {
    $nonExistentSku = "NON-EXISTENT-SKU-999"
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/products/sku/$nonExistentSku" -Method GET -WebSession $session
        throw "Should have failed with 404"
    } catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 404) {
            Write-Host "    Correctly returned 404 for non-existent SKU"
        } else {
            throw $_
        }
    }
}

# TEST 17: Try to delete without auth (should fail)
Test-Endpoint "Delete Product Without Auth (Should Fail)" {
    $fakeId = "00000000-0000-0000-0000-000000000001"
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/products/$fakeId" -Method DELETE
        throw "Should have failed with authentication error"
    } catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 401) {
            Write-Host "    Correctly rejected unauthenticated request"
        } else {
            throw $_
        }
    }
}

# Cleanup: Delete test category
Test-Endpoint "Cleanup - Delete Test Category" {
    if ($categoryId) {
        Invoke-RestMethod -Uri "$baseUrl/api/categories/$categoryId" -Method DELETE -WebSession $session
        Write-Host "    Deleted test category ID: $categoryId"
    } else {
        throw "No category ID available"
    }
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Tests Passed: $testsPassed" -ForegroundColor Green
Write-Host "Tests Failed: $testsFailed" -ForegroundColor $(if ($testsFailed -gt 0) { "Red" } else { "Green" })
Write-Host ""

if ($testsFailed -eq 0) {
    Write-Host "All tests passed successfully!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Some tests failed. Please review the errors above." -ForegroundColor Red
    exit 1
}


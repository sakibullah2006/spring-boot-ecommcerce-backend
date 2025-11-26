# Comprehensive test script for all Category endpoints

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing All Category Endpoints" -ForegroundColor Cyan
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

$categoryId = $null

# TEST 1: Create a category
Test-Endpoint "Create Category" {
    $categoryBody = @{
        name = "Electronics"
        description = "Electronic devices and accessories"
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri "$baseUrl/api/categories" -Method POST -ContentType "application/json" -Body $categoryBody -WebSession $session
    Write-Host "    Created category ID: $($response.id), Name: $($response.name)"
    $script:categoryId = $response.id
}

# TEST 2: Get all categories (should work without authentication)
Test-Endpoint "Get All Categories" {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/categories" -Method GET -WebSession $session
    Write-Host "    Found $($response.Count) categories"
}

# TEST 3: Get category by ID (should work without authentication)
Test-Endpoint "Get Category by ID" {
    if ($categoryId) {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/categories/$categoryId" -Method GET -WebSession $session
        Write-Host "    Retrieved category: $($response.name)"
    } else {
        throw "No category ID available"
    }
}

# TEST 4: Create a child category
$childCategoryId = $null
Test-Endpoint "Create Child Category" {
    $childBody = @{
        name = "Smartphones"
        description = "Mobile phones and smartphones"
        parentId = $categoryId
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri "$baseUrl/api/categories" -Method POST -ContentType "application/json" -Body $childBody -WebSession $session
    Write-Host "    Created child category ID: $($response.id), Name: $($response.name), Parent: $($response.parent.name)"
    $script:childCategoryId = $response.id
}

# TEST 5: Update category
Test-Endpoint "Update Category" {
    if ($categoryId) {
        $updateBody = @{
            name = "Electronics & Gadgets"
            description = "Electronic devices, gadgets and accessories"
        } | ConvertTo-Json

        $response = Invoke-RestMethod -Uri "$baseUrl/api/categories/$categoryId" -Method PUT -ContentType "application/json" -Body $updateBody -WebSession $session
        Write-Host "    Updated category name to: $($response.name)"
    } else {
        throw "No category ID available"
    }
}

# TEST 6: Try to create duplicate category (should fail)
Test-Endpoint "Create Duplicate Category (Should Fail)" {
    $duplicateBody = @{
        name = "Electronics & Gadgets"
        description = "Duplicate"
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/categories" -Method POST -ContentType "application/json" -Body $duplicateBody -WebSession $session
        throw "Should have failed with duplicate name error"
    } catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 409) {
            Write-Host "    Correctly rejected duplicate category name"
        } else {
            throw $_
        }
    }
}

# TEST 7: Try to access protected endpoint without auth (should fail)
Test-Endpoint "Create Category Without Auth (Should Fail)" {
    $categoryBody = @{
        name = "TestCategory"
        description = "Test"
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/categories" -Method POST -ContentType "application/json" -Body $categoryBody
        throw "Should have failed with authentication error"
    } catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 401) {
            Write-Host "    Correctly rejected unauthenticated request"
        } else {
            throw $_
        }
    }
}

# TEST 8: Get category with children
Test-Endpoint "Get Category with Children" {
    if ($categoryId) {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/categories/$categoryId" -Method GET -WebSession $session
        if ($response.children -and $response.children.Count -gt 0) {
            Write-Host "    Category has $($response.children.Count) child(ren): $($response.children.name -join ', ')"
        } else {
            Write-Host "    Category retrieved (no children shown in response)"
        }
    } else {
        throw "No category ID available"
    }
}

# TEST 9: Delete child category
Test-Endpoint "Delete Child Category" {
    if ($childCategoryId) {
        Invoke-RestMethod -Uri "$baseUrl/api/categories/$childCategoryId" -Method DELETE -WebSession $session
        Write-Host "    Deleted child category ID: $childCategoryId"
    } else {
        throw "No child category ID available"
    }
}

# TEST 10: Delete parent category
Test-Endpoint "Delete Parent Category" {
    if ($categoryId) {
        Invoke-RestMethod -Uri "$baseUrl/api/categories/$categoryId" -Method DELETE -WebSession $session
        Write-Host "    Deleted parent category ID: $categoryId"
    } else {
        throw "No category ID available"
    }
}

# TEST 11: Try to get deleted category (should fail)
Test-Endpoint "Get Deleted Category (Should Fail)" {
    if ($categoryId) {
        try {
            $response = Invoke-RestMethod -Uri "$baseUrl/api/categories/$categoryId" -Method GET -WebSession $session
            throw "Should have failed with 404"
        } catch {
            if ($_.Exception.Response.StatusCode.value__ -eq 404) {
                Write-Host "    Correctly returned 404 for deleted category"
            } else {
                throw $_
            }
        }
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


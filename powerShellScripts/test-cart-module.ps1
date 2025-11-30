# ========================================
# Cart Module Comprehensive Test Script
# ========================================
# This script tests all Cart endpoints with various scenarios
# ========================================

param(
    [string]$BaseUrl = "http://localhost:8080",
    [string]$AdminEmail = "sakibullah@gmail.com",
    [string]$AdminPassword = "password123",
    [string]$CustomerEmail = "customer@example.com",
    [string]$CustomerPassword = "password123"
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
# Authentication Setup
# ========================================

Write-TestHeader "Authentication Setup"

# Admin Login
Write-TestCase "Admin Login"
try {
    $loginBody = @{
        email = $AdminEmail
        password = $AdminPassword
    } | ConvertTo-Json

    $adminLoginResponse = Invoke-RestMethod -Uri "$BaseUrl/api/auth/login" `
        -Method Post `
        -Body $loginBody `
        -ContentType "application/json" `
        -SessionVariable adminSession

    Write-Success "Admin logged in as: $($adminLoginResponse.firstName) $($adminLoginResponse.lastName)"
    Write-Host "  Role: $($adminLoginResponse.role)" -ForegroundColor Cyan
    $adminUserId = $adminLoginResponse.id
}
catch {
    Write-Failure "Admin login failed" $_.Exception.Message
    exit 1
}

# Customer Login (or Register if doesn't exist)
Write-TestCase "Customer Login/Registration"
try {
    $customerLoginBody = @{
        email = $CustomerEmail
        password = $CustomerPassword
    } | ConvertTo-Json

    try {
        $customerLoginResponse = Invoke-RestMethod -Uri "$BaseUrl/api/auth/login" `
            -Method Post `
            -Body $customerLoginBody `
            -ContentType "application/json" `
            -SessionVariable customerSession
        
        Write-Success "Customer logged in: $($customerLoginResponse.email)"
    }
    catch {
        # Try to register
        Write-Host "  Customer not found, attempting registration..." -ForegroundColor Yellow
        $registerBody = @{
            firstName = "Test"
            lastName = "Customer"
            email = $CustomerEmail
            password = $CustomerPassword
        } | ConvertTo-Json

        $registerResponse = Invoke-RestMethod -Uri "$BaseUrl/api/auth/register" `
            -Method Post `
            -Body $registerBody `
            -ContentType "application/json"
        
        # Login after registration
        $customerLoginResponse = Invoke-RestMethod -Uri "$BaseUrl/api/auth/login" `
            -Method Post `
            -Body $customerLoginBody `
            -ContentType "application/json" `
            -SessionVariable customerSession
        
        Write-Success "Customer registered and logged in: $($customerLoginResponse.email)"
    }
    
    Write-Host "  Customer ID: $($customerLoginResponse.id)" -ForegroundColor Cyan
    $customerId = $customerLoginResponse.id
}
catch {
    Write-Failure "Customer authentication failed" $_.Exception.Message
    exit 1
}

# ========================================
# Setup - Get Test Products
# ========================================

Write-TestHeader "Setup - Get Test Products"

Write-TestCase "Get available products for cart testing"
try {
    $products = Invoke-RestMethod -Uri "$BaseUrl/api/products" -Method Get
    
    if ($products.Count -eq 0) {
        Write-Failure "No products available for testing" "Please create some products first"
        exit 1
    }
    
    $testProduct1 = $products[0]
    $testProduct2 = if ($products.Count -gt 1) { $products[1] } else { $products[0] }
    
    Write-Success "Found products for testing"
    Write-Host "  Product 1: $($testProduct1.name) (ID: $($testProduct1.id), Stock: $($testProduct1.stockQuantity))" -ForegroundColor Cyan
    Write-Host "  Product 2: $($testProduct2.name) (ID: $($testProduct2.id), Stock: $($testProduct2.stockQuantity))" -ForegroundColor Cyan
}
catch {
    Write-Failure "Failed to get products" $_.Exception.Message
    exit 1
}

# ========================================
# Cart Tests - GET (Empty Cart)
# ========================================

Write-TestHeader "Cart GET Tests - Initial State"

# Clear cart first to ensure clean state
Write-TestCase "Setup - Clear cart for clean state"
try {
    Invoke-RestMethod -Method Delete -Uri "$BaseUrl/api/cart" `
        -WebSession $customerSession -ErrorAction SilentlyContinue | Out-Null
    Write-Host "  Cart cleared for clean test state" -ForegroundColor DarkGray
}
catch {
    Write-Host "  No existing cart to clear" -ForegroundColor DarkGray
}

# Test 1: Get Empty Cart (Auto-creates cart)
Write-TestCase "GET /api/cart - Get customer's cart (should auto-create if not exists)"
$emptyCart = Invoke-ApiRequest -Method Get -Uri "$BaseUrl/api/cart" `
    -WebSession $customerSession `
    -ExpectedStatusCode 200 -TestName "Get customer's empty cart"

if ($emptyCart) {
    Write-Host "  Cart ID: $($emptyCart.id)" -ForegroundColor Cyan
    Write-Host "  User ID: $($emptyCart.userId)" -ForegroundColor Cyan
    Write-Host "  Items Count: $($emptyCart.totalItems)" -ForegroundColor Cyan
    Write-Host "  Total Price: $($emptyCart.totalPrice)" -ForegroundColor Cyan
    
    if ($emptyCart.totalItems -eq 0) {
        Write-Success "Cart is empty as expected"
    } else {
        Write-Failure "Cart should be empty" "Found $($emptyCart.totalItems) items"
    }
}

# Test 2: Unauthorized Access (No Auth)
Write-TestCase "GET /api/cart - Unauthorized access"
Invoke-ApiRequest -Method Get -Uri "$BaseUrl/api/cart" `
    -ExpectedStatusCode 401 -TestName "Get cart without authentication"

# ========================================
# Cart Tests - ADD Items
# ========================================

Write-TestHeader "Cart ADD Item Tests"

# Test 3: Add First Item to Cart
Write-TestCase "POST /api/cart/items - Add first item to cart"
$addItem1Body = @{
    productId = $testProduct1.id
    quantity = 2
} | ConvertTo-Json

$cartWithItem1 = Invoke-ApiRequest -Method Post -Uri "$BaseUrl/api/cart/items" `
    -Body $addItem1Body -WebSession $customerSession `
    -ExpectedStatusCode 201 -TestName "Add first item to cart"

if ($cartWithItem1) {
    Write-Host "  Items Count: $($cartWithItem1.totalItems)" -ForegroundColor Cyan
    Write-Host "  Total Price: $($cartWithItem1.totalPrice)" -ForegroundColor Cyan
    
    if ($cartWithItem1.items.Count -eq 1) {
        Write-Success "Cart has 1 item as expected"
        $cartItem1Id = $cartWithItem1.items[0].id
    } else {
        Write-Failure "Cart should have 1 item" "Found $($cartWithItem1.items.Count) items"
    }
}

# Test 4: Add Same Item Again (Should Update Quantity)
Write-TestCase "POST /api/cart/items - Add same item again (quantity update)"
$addItem1AgainBody = @{
    productId = $testProduct1.id
    quantity = 3
} | ConvertTo-Json

$cartUpdated = Invoke-ApiRequest -Method Post -Uri "$BaseUrl/api/cart/items" `
    -Body $addItem1AgainBody -WebSession $customerSession `
    -ExpectedStatusCode 201 -TestName "Add same item again"

if ($cartUpdated) {
    Write-Host "  Items Count: $($cartUpdated.totalItems)" -ForegroundColor Cyan
    Write-Host "  Total Price: $($cartUpdated.totalPrice)" -ForegroundColor Cyan
    
    if ($cartUpdated.items.Count -eq 1) {
        Write-Success "Still 1 unique item in cart"
        $expectedQuantity = 5  # 2 + 3
        $actualQuantity = $cartUpdated.items[0].quantity
        
        if ($actualQuantity -eq $expectedQuantity) {
            Write-Success "Quantity updated correctly: $actualQuantity"
        } else {
            Write-Failure "Quantity should be $expectedQuantity" "Got $actualQuantity"
        }
    } else {
        Write-Failure "Cart should still have 1 unique item" "Found $($cartUpdated.items.Count) items"
    }
}

# Test 5: Add Different Item
Write-TestCase "POST /api/cart/items - Add different product"
$addItem2Body = @{
    productId = $testProduct2.id
    quantity = 1
} | ConvertTo-Json

$cartWith2Items = Invoke-ApiRequest -Method Post -Uri "$BaseUrl/api/cart/items" `
    -Body $addItem2Body -WebSession $customerSession `
    -ExpectedStatusCode 201 -TestName "Add different product"

if ($cartWith2Items) {
    Write-Host "  Unique Items: $($cartWith2Items.items.Count)" -ForegroundColor Cyan
    Write-Host "  Total Items: $($cartWith2Items.totalItems)" -ForegroundColor Cyan
    Write-Host "  Total Price: $($cartWith2Items.totalPrice)" -ForegroundColor Cyan
    
    if ($cartWith2Items.items.Count -eq 2) {
        Write-Success "Cart has 2 unique items"
        $cartItem2Id = $cartWith2Items.items[1].id
    } else {
        Write-Failure "Cart should have 2 unique items" "Found $($cartWith2Items.items.Count) items"
    }
}

# Test 6: Add Item - Invalid Product ID
Write-TestCase "POST /api/cart/items - Invalid product ID"
$invalidProductBody = @{
    productId = "invalid-product-id-12345"
    quantity = 1
} | ConvertTo-Json

Invoke-ApiRequest -Method Post -Uri "$BaseUrl/api/cart/items" `
    -Body $invalidProductBody -WebSession $customerSession `
    -ExpectedStatusCode 404 -TestName "Add item with invalid product ID"

# Test 7: Add Item - Invalid Quantity (Zero)
Write-TestCase "POST /api/cart/items - Invalid quantity (zero)"
$zeroQuantityBody = @{
    productId = $testProduct1.id
    quantity = 0
} | ConvertTo-Json

Invoke-ApiRequest -Method Post -Uri "$BaseUrl/api/cart/items" `
    -Body $zeroQuantityBody -WebSession $customerSession `
    -ExpectedStatusCode 400 -TestName "Add item with zero quantity"

# Test 8: Add Item - Invalid Quantity (Negative)
Write-TestCase "POST /api/cart/items - Invalid quantity (negative)"
$negativeQuantityBody = @{
    productId = $testProduct1.id
    quantity = -5
} | ConvertTo-Json

Invoke-ApiRequest -Method Post -Uri "$BaseUrl/api/cart/items" `
    -Body $negativeQuantityBody -WebSession $customerSession `
    -ExpectedStatusCode 400 -TestName "Add item with negative quantity"

# Test 9: Add Item - Exceeds Stock (if stock is limited)
if ($testProduct1.stockQuantity -lt 1000) {
    Write-TestCase "POST /api/cart/items - Quantity exceeds stock"
    $excessQuantityBody = @{
        productId = $testProduct1.id
        quantity = $testProduct1.stockQuantity + 100
    } | ConvertTo-Json

    Invoke-ApiRequest -Method Post -Uri "$BaseUrl/api/cart/items" `
        -Body $excessQuantityBody -WebSession $customerSession `
        -ExpectedStatusCode 400 -TestName "Add item exceeding stock"
}

# Test 10: Add Item - Unauthorized
Write-TestCase "POST /api/cart/items - Unauthorized access"
$unauthAddBody = @{
    productId = $testProduct1.id
    quantity = 1
} | ConvertTo-Json

Invoke-ApiRequest -Method Post -Uri "$BaseUrl/api/cart/items" `
    -Body $unauthAddBody `
    -ExpectedStatusCode 401 -TestName "Add item without authentication"

# ========================================
# Cart Tests - UPDATE Items
# ========================================

Write-TestHeader "Cart UPDATE Item Tests"

# Test 11: Update Cart Item Quantity
if ($cartItem1Id) {
    Write-TestCase "PUT /api/cart/items/{id} - Update item quantity"
    $updateQuantityBody = @{
        quantity = 3
    } | ConvertTo-Json

    $cartAfterUpdate = Invoke-ApiRequest -Method Put -Uri "$BaseUrl/api/cart/items/$cartItem1Id" `
        -Body $updateQuantityBody -WebSession $customerSession `
        -ExpectedStatusCode 200 -TestName "Update cart item quantity"

    if ($cartAfterUpdate) {
        $updatedItem = $cartAfterUpdate.items | Where-Object { $_.id -eq $cartItem1Id }
        if ($updatedItem.quantity -eq 3) {
            Write-Success "Item quantity updated to 3"
        } else {
            Write-Failure "Quantity should be 3" "Got $($updatedItem.quantity)"
        }
        Write-Host "  Total Items: $($cartAfterUpdate.totalItems)" -ForegroundColor Cyan
        Write-Host "  Total Price: $($cartAfterUpdate.totalPrice)" -ForegroundColor Cyan
    }
}

# Test 12: Update Cart Item - Invalid ID
Write-TestCase "PUT /api/cart/items/{id} - Invalid cart item ID"
$updateInvalidBody = @{
    quantity = 5
} | ConvertTo-Json

Invoke-ApiRequest -Method Put -Uri "$BaseUrl/api/cart/items/invalid-item-id-12345" `
    -Body $updateInvalidBody -WebSession $customerSession `
    -ExpectedStatusCode 404 -TestName "Update non-existent cart item"

# Test 13: Update Cart Item - Invalid Quantity
if ($cartItem1Id) {
    Write-TestCase "PUT /api/cart/items/{id} - Invalid quantity (zero)"
    $updateZeroBody = @{
        quantity = 0
    } | ConvertTo-Json

    Invoke-ApiRequest -Method Put -Uri "$BaseUrl/api/cart/items/$cartItem1Id" `
        -Body $updateZeroBody -WebSession $customerSession `
        -ExpectedStatusCode 400 -TestName "Update item with zero quantity"
}

# Test 14: Update Cart Item - Unauthorized
if ($cartItem1Id) {
    Write-TestCase "PUT /api/cart/items/{id} - Unauthorized access"
    $updateUnauthBody = @{
        quantity = 2
    } | ConvertTo-Json

    Invoke-ApiRequest -Method Put -Uri "$BaseUrl/api/cart/items/$cartItem1Id" `
        -Body $updateUnauthBody `
        -ExpectedStatusCode 401 -TestName "Update item without authentication"
}

# ========================================
# Cart Tests - REMOVE Items
# ========================================

Write-TestHeader "Cart REMOVE Item Tests"

# Test 15: Remove Cart Item
if ($cartItem2Id) {
    Write-TestCase "DELETE /api/cart/items/{id} - Remove item from cart"
    $cartAfterRemove = Invoke-ApiRequest -Method Delete -Uri "$BaseUrl/api/cart/items/$cartItem2Id" `
        -WebSession $customerSession `
        -ExpectedStatusCode 200 -TestName "Remove item from cart"

    if ($cartAfterRemove) {
        Write-Host "  Remaining Items: $($cartAfterRemove.items.Count)" -ForegroundColor Cyan
        Write-Host "  Total Items: $($cartAfterRemove.totalItems)" -ForegroundColor Cyan
        Write-Host "  Total Price: $($cartAfterRemove.totalPrice)" -ForegroundColor Cyan
        
        if ($cartAfterRemove.items.Count -eq 1) {
            Write-Success "Item removed successfully, 1 item remaining"
        } else {
            Write-Failure "Should have 1 item remaining" "Found $($cartAfterRemove.items.Count) items"
        }
    }
}

# Test 16: Remove Cart Item - Invalid ID
Write-TestCase "DELETE /api/cart/items/{id} - Invalid cart item ID"
Invoke-ApiRequest -Method Delete -Uri "$BaseUrl/api/cart/items/invalid-item-id-12345" `
    -WebSession $customerSession `
    -ExpectedStatusCode 404 -TestName "Remove non-existent cart item"

# Test 17: Remove Cart Item - Unauthorized
if ($cartItem1Id) {
    Write-TestCase "DELETE /api/cart/items/{id} - Unauthorized access"
    Invoke-ApiRequest -Method Delete -Uri "$BaseUrl/api/cart/items/$cartItem1Id" `
        -ExpectedStatusCode 401 -TestName "Remove item without authentication"
}

# ========================================
# Cart Tests - CLEAR Cart
# ========================================

Write-TestHeader "Cart CLEAR Tests"

# Add some items back for clear test
Write-TestCase "Setup - Add items for clear test"
$setupBody = @{
    productId = $testProduct1.id
    quantity = 2
} | ConvertTo-Json

Invoke-RestMethod -Method Post -Uri "$BaseUrl/api/cart/items" `
    -Body $setupBody -ContentType "application/json" `
    -WebSession $customerSession | Out-Null

# Test 18: Clear Cart
Write-TestCase "DELETE /api/cart - Clear entire cart"
$clearedCart = Invoke-ApiRequest -Method Delete -Uri "$BaseUrl/api/cart" `
    -WebSession $customerSession `
    -ExpectedStatusCode 200 -TestName "Clear entire cart"

if ($clearedCart) {
    Write-Host "  Items Count: $($clearedCart.items.Count)" -ForegroundColor Cyan
    Write-Host "  Total Items: $($clearedCart.totalItems)" -ForegroundColor Cyan
    Write-Host "  Total Price: $($clearedCart.totalPrice)" -ForegroundColor Cyan
    
    if ($clearedCart.items.Count -eq 0 -and $clearedCart.totalItems -eq 0) {
        Write-Success "Cart cleared successfully"
    } else {
        Write-Failure "Cart should be empty" "Found $($clearedCart.items.Count) items"
    }
}

# Test 19: Clear Already Empty Cart
Write-TestCase "DELETE /api/cart - Clear already empty cart"
$clearedAgain = Invoke-ApiRequest -Method Delete -Uri "$BaseUrl/api/cart" `
    -WebSession $customerSession `
    -ExpectedStatusCode 200 -TestName "Clear already empty cart"

# Test 20: Clear Cart - Unauthorized
Write-TestCase "DELETE /api/cart - Unauthorized access"
Invoke-ApiRequest -Method Delete -Uri "$BaseUrl/api/cart" `
    -ExpectedStatusCode 401 -TestName "Clear cart without authentication"

# ========================================
# Cart Tests - Admin Access
# ========================================

Write-TestHeader "Cart Admin Access Tests"

# Test 21: Admin Get Cart by User ID
Write-TestCase "GET /api/cart/user/{userId} - Admin access to user's cart"
$adminViewCart = Invoke-ApiRequest -Method Get -Uri "$BaseUrl/api/cart/user/$customerId" `
    -WebSession $adminSession `
    -ExpectedStatusCode 200 -TestName "Admin get customer's cart"

if ($adminViewCart) {
    Write-Host "  User ID: $($adminViewCart.userId)" -ForegroundColor Cyan
    Write-Host "  Items Count: $($adminViewCart.totalItems)" -ForegroundColor Cyan
    Write-Success "Admin can access customer's cart"
}

# Test 22: Customer Try to Access Another User's Cart (Should Fail)
Write-TestCase "GET /api/cart/user/{userId} - Customer access denied"
Invoke-ApiRequest -Method Get -Uri "$BaseUrl/api/cart/user/$adminUserId" `
    -WebSession $customerSession `
    -ExpectedStatusCode 403 -TestName "Customer cannot access other user's cart"

# Test 23: Admin Get Cart by Invalid User ID
Write-TestCase "GET /api/cart/user/{userId} - Invalid user ID"
Invoke-ApiRequest -Method Get -Uri "$BaseUrl/api/cart/user/invalid-user-id-12345" `
    -WebSession $adminSession `
    -ExpectedStatusCode 404 -TestName "Admin get cart with invalid user ID"

# ========================================
# Cart Tests - Complex Scenarios
# ========================================

Write-TestHeader "Cart Complex Scenario Tests"

# Test 24: Add Multiple Items and Verify Total Calculations
Write-TestCase "Complex - Add multiple items and verify totals"

# Clear cart first
Invoke-RestMethod -Method Delete -Uri "$BaseUrl/api/cart" `
    -WebSession $customerSession | Out-Null

# Add first product (quantity 2)
$add1 = @{
    productId = $testProduct1.id
    quantity = 2
} | ConvertTo-Json

$cart1 = Invoke-RestMethod -Method Post -Uri "$BaseUrl/api/cart/items" `
    -Body $add1 -ContentType "application/json" `
    -WebSession $customerSession

# Add second product (quantity 3)
$add2 = @{
    productId = $testProduct2.id
    quantity = 3
} | ConvertTo-Json

$cart2 = Invoke-RestMethod -Method Post -Uri "$BaseUrl/api/cart/items" `
    -Body $add2 -ContentType "application/json" `
    -WebSession $customerSession

# Verify totals
$expectedTotalItems = 5  # 2 + 3

if ($cart2.totalItems -eq $expectedTotalItems) {
    Write-Success "Total items calculated correctly: $($cart2.totalItems)"
} else {
    Write-Failure "Total items mismatch" "Expected: $expectedTotalItems, Got: $($cart2.totalItems)"
}

# Verify unique items
if ($cart2.items.Count -eq 2) {
    Write-Success "Unique items count correct: 2"
} else {
    Write-Failure "Unique items mismatch" "Expected: 2, Got: $($cart2.items.Count)"
}

# Verify total price is sum of all item subtotals
$calculatedTotal = ($cart2.items | ForEach-Object { $_.subtotal } | Measure-Object -Sum).Sum
if ([Math]::Round($cart2.totalPrice, 2) -eq [Math]::Round($calculatedTotal, 2)) {
    Write-Success "Total price calculated correctly: $($cart2.totalPrice)"
} else {
    Write-Failure "Total price mismatch" "Expected: $calculatedTotal, Got: $($cart2.totalPrice)"
}

Write-Host "`n  Cart Summary:" -ForegroundColor Cyan
Write-Host "    Unique Items: $($cart2.items.Count)" -ForegroundColor White
Write-Host "    Total Items: $($cart2.totalItems)" -ForegroundColor White
Write-Host "    Total Price: `$$($cart2.totalPrice)" -ForegroundColor White

# Test 25: Verify Price Snapshot
Write-TestCase "Complex - Verify price snapshot at addition"
if ($cart2.items.Count -gt 0) {
    $item = $cart2.items[0]
    Write-Host "  Price at Addition: $($item.priceAtAddition)" -ForegroundColor Cyan
    Write-Host "  Current Price: $($item.currentPrice)" -ForegroundColor Cyan
    
    if ($item.priceAtAddition -ne $null -and $item.currentPrice -ne $null) {
        Write-Success "Price snapshot preserved"
    } else {
        Write-Failure "Price snapshot missing" "priceAtAddition or currentPrice is null"
    }
}

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
$reportPath = Join-Path $PSScriptRoot "cart-test-results-$timestamp.csv"
$script:TestResults | Export-Csv -Path $reportPath -NoTypeInformation
Write-Host "`nDetailed results exported to: $reportPath" -ForegroundColor Cyan

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Cart Module Testing Complete!" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Exit with appropriate code
exit $(if ($script:FailedTests -eq 0) { 0 } else { 1 })

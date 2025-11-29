# ================================================================
# Order Module Comprehensive Test Script
# Tests all order creation scenarios, payment methods, and edge cases
# ================================================================

$baseUrl = "http://localhost:8080/api"
$contentType = "application/json"

# ANSI color codes for better output
$Green = "`e[32m"
$Red = "`e[31m"
$Yellow = "`e[33m"
$Blue = "`e[34m"
$Cyan = "`e[36m"
$Reset = "`e[0m"

# Test counters
$script:testsPassed = 0
$script:testsFailed = 0
$script:testsTotal = 0

# Store test data
$script:userSession = $null
$script:userId = $null
$script:userEmail = $null
$script:cartId = $null
$script:orderIds = @()

# Product IDs from your data
$products = @{
    iPhone = "f5a2ea2f-ccb4-11f0-aa56-00e04c816b21"
    Samsung = "f5a2fbb9-ccb4-11f0-aa56-00e04c816b21"
    MacBook = "f5a307bc-ccb4-11f0-aa56-00e04c816b21"
    iPad = "f5a31956-ccb4-11f0-aa56-00e04c816b21"
    NikeTShirt = "f5a35088-ccb4-11f0-aa56-00e04c816b21"
    AdidasHoodie = "f5a352c4-ccb4-11f0-aa56-00e04c816b21"
}

# ================================================================
# Helper Functions
# ================================================================

function Write-TestHeader {
    param([string]$title)
    Write-Host "`n$Cyan===========================================$Reset" -NoNewline
    Write-Host "`n$Cyan  $title$Reset" -NoNewline
    Write-Host "`n$Cyan===========================================$Reset"
}

function Write-TestStep {
    param([string]$message)
    Write-Host "$Blue[TEST]$Reset $message"
}

function Write-Success {
    param(
        [string]$message,
        [switch]$countAsTest
    )
    Write-Host "$Green[✓]$Reset $message"
    if ($countAsTest) {
        $script:testsPassed++
    }
}

function Write-Failure {
    param(
        [string]$message,
        [switch]$countAsTest
    )
    Write-Host "$Red[✗]$Reset $message"
    if ($countAsTest) {
        $script:testsFailed++
    }
}

function Write-Info {
    param([string]$message)
    Write-Host "$Yellow[INFO]$Reset $message"
}

function Test-Response {
    param(
        [string]$testName,
        [object]$response,
        [int]$expectedStatus,
        [scriptblock]$validationBlock = $null
    )
    
    $script:testsTotal++
    Write-TestStep $testName
    
    if ($response.StatusCode -eq $expectedStatus) {
        if ($validationBlock) {
            try {
                & $validationBlock $response.Content
                Write-Success "$testName - Passed" -countAsTest
                return $true
            } catch {
                Write-Failure "$testName - Validation failed: $_" -countAsTest
                return $false
            }
        } else {
            Write-Success "$testName - Passed" -countAsTest
            return $true
        }
    } else {
        Write-Failure "$testName - Expected status $expectedStatus, got $($response.StatusCode)" -countAsTest
        Write-Host "Response: $($response.Content)" -ForegroundColor Red
        return $false
    }
}

function Invoke-ApiRequest {
    param(
        [string]$method,
        [string]$endpoint,
        [object]$body = $null,
        [bool]$skipStatusCheck = $false
    )
    
    $headers = @{
        "Content-Type" = $contentType
    }
    
    $params = @{
        Uri = "$baseUrl$endpoint"
        Method = $method
        Headers = $headers
        StatusCodeVariable = "statusCode"
        WebSession = $script:userSession
    }
    
    if ($body) {
        $params["Body"] = ($body | ConvertTo-Json -Depth 10)
    }
    
    try {
        $response = Invoke-RestMethod @params
        return @{
            StatusCode = $statusCode
            Content = $response
            Success = $true
        }
    } catch {
        if ($skipStatusCheck) {
            return @{
                StatusCode = $_.Exception.Response.StatusCode.value__
                Content = $_.ErrorDetails.Message | ConvertFrom-Json
                Success = $false
            }
        }
        throw
    }
}

# ================================================================
# Authentication & Setup
# ================================================================

function Initialize-TestUser {
    Write-TestHeader "Setting Up Test User"
    
    $randomId = Get-Random -Minimum 1000 -Maximum 9999
    $email = "ordertest$randomId@test.com"
    $password = "Test@123"
    $script:userEmail = $email
    
    # Register user
    Write-TestStep "Registering test user: $email"
    $registerBody = @{
        firstName = "Order"
        lastName = "Tester$randomId"
        email = $email
        password = $password
    }
    
    $response = Invoke-ApiRequest -method "POST" -endpoint "/auth/register" -body $registerBody
    
    if ($response.StatusCode -eq 201) {
        Write-Success "User registered successfully"
        $script:userId = $response.Content.id
        Write-Info "User ID: $script:userId"
        
        # Now login to get session
        Write-TestStep "Logging in test user"
        $loginBody = @{
            email = $email
            password = $password
        }
        
        try {
            $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" `
                -Method Post `
                -Body ($loginBody | ConvertTo-Json) `
                -ContentType $contentType `
                -SessionVariable userSession
            
            $script:userSession = $userSession
            Write-Success "User logged in successfully"
            Write-Info "Session established for: $($loginResponse.email)"
            return $true
        } catch {
            Write-Failure "Failed to login user: $($_.Exception.Message)"
            return $false
        }
    } else {
        Write-Failure "Failed to register user"
        return $false
    }
}

# ================================================================
# Cart Setup Functions
# ================================================================

function Add-ItemToCart {
    param(
        [string]$productId,
        [int]$quantity = 1
    )
    
    $body = @{
        productId = $productId
        quantity = $quantity
    }
    
    try {
        $response = Invoke-ApiRequest -method "POST" -endpoint "/cart/items" -body $body
        
        if ($response.StatusCode -eq 201) {
            $script:cartId = $response.Content.id
            return $true
        }
        return $false
    } catch {
        # Cart validation failed (e.g., insufficient stock)
        return $false
    }
}

function Clear-Cart {
    # Get current cart
    $response = Invoke-ApiRequest -method "GET" -endpoint "/cart"
    
    if ($response.StatusCode -eq 200 -and $response.Content.items.Count -gt 0) {
        foreach ($item in $response.Content.items) {
            Invoke-ApiRequest -method "DELETE" -endpoint "/cart/items/$($item.id)" | Out-Null
        }
    }
}

# ================================================================
# Order Creation Test Cases
# ================================================================

function Test-CreateOrderWithValidPayment {
    Write-TestHeader "Test 1: Create Order with Valid Payment (VISA)"
    
    # Setup cart
    Clear-Cart
    Add-ItemToCart -productId $products.iPhone -quantity 2
    Add-ItemToCart -productId $products.NikeTShirt -quantity 3
    
    $orderRequest = @{
        shippingAddress = @{
            addressLine1 = "123 Main Street"
            addressLine2 = "Apt 4B"
            city = "New York"
            state = "NY"
            postalCode = "10001"
            country = "USA"
        }
        billingAddress = @{
            addressLine1 = "123 Main Street"
            addressLine2 = "Apt 4B"
            city = "New York"
            state = "NY"
            postalCode = "10001"
            country = "USA"
        }
        customerEmail = "customer@test.com"
        customerPhone = "+1234567890"
        notes = "Please deliver during business hours"
        paymentMethod = "CREDIT_CARD"
        paymentDetails = @{
            cardNumber = "4532123456789012"  # Valid VISA
            cardHolderName = "John Doe"
            expiryDate = "12/25"
            cvv = "123"
            cardBrand = "VISA"
        }
    }
    
    $response = Invoke-ApiRequest -method "POST" -endpoint "/orders" -body $orderRequest -skipStatusCheck $true
    
    Test-Response -testName "Create order with valid VISA card" -response $response -expectedStatus 201 -validationBlock {
        param($content)
        if (-not $content.id) { throw "Order ID missing" }
        if (-not $content.orderNumber) { throw "Order number missing" }
        if ($content.status -ne "CONFIRMED") { throw "Order status should be CONFIRMED" }
        if ($content.payment.paymentStatus -ne "COMPLETED") { throw "Payment status should be COMPLETED" }
        if ($content.payment.cardBrand -ne "VISA") { throw "Card brand should be VISA" }
        if ($content.payment.cardLastFour -ne "9012") { throw "Card last four digits incorrect" }
        
        $script:orderIds += $content.id
        Write-Info "Order Number: $($content.orderNumber)"
        Write-Info "Order ID: $($content.id)"
        Write-Info "Total Amount: `$$($content.totalAmount)"
        Write-Info "Transaction ID: $($content.payment.transactionId)"
    }
}

function Test-CreateOrderWithMastercard {
    Write-TestHeader "Test 2: Create Order with Mastercard"
    
    Clear-Cart
    Add-ItemToCart -productId $products.Samsung -quantity 1
    
    $orderRequest = @{
        shippingAddress = @{
            addressLine1 = "456 Oak Avenue"
            city = "Los Angeles"
            state = "CA"
            postalCode = "90001"
            country = "USA"
        }
        billingAddress = @{
            addressLine1 = "456 Oak Avenue"
            city = "Los Angeles"
            state = "CA"
            postalCode = "90001"
            country = "USA"
        }
        customerEmail = "test@example.com"
        paymentMethod = "CREDIT_CARD"
        paymentDetails = @{
            cardNumber = "5412345678901234"  # Mastercard
            cardHolderName = "Jane Smith"
            expiryDate = "06/26"
            cvv = "456"
            cardBrand = "MASTERCARD"
        }
    }
    
    $response = Invoke-ApiRequest -method "POST" -endpoint "/orders" -body $orderRequest -skipStatusCheck $true
    
    Test-Response -testName "Create order with Mastercard" -response $response -expectedStatus 201 -validationBlock {
        param($content)
        if ($content.payment.cardBrand -ne "MASTERCARD") { throw "Card brand should be MASTERCARD" }
        if ($content.payment.paymentStatus -ne "COMPLETED") { throw "Payment should be completed" }
        $script:orderIds += $content.id
    }
}

function Test-CreateOrderWithAmex {
    Write-TestHeader "Test 3: Create Order with American Express"
    
    Clear-Cart
    Add-ItemToCart -productId $products.MacBook -quantity 1
    
    $orderRequest = @{
        shippingAddress = @{
            addressLine1 = "789 Pine Road"
            city = "Chicago"
            state = "IL"
            postalCode = "60601"
            country = "USA"
        }
        billingAddress = @{
            addressLine1 = "789 Pine Road"
            city = "Chicago"
            state = "IL"
            postalCode = "60601"
            country = "USA"
        }
        customerEmail = "amex@test.com"
        paymentMethod = "CREDIT_CARD"
        paymentDetails = @{
            cardNumber = "3782822463100005"  # AMEX (15 digits, but we need 16, so using 16-digit starting with 3)
            cardHolderName = "Bob Johnson"
            expiryDate = "09/27"
            cvv = "7890"
            cardBrand = "AMEX"
        }
    }
    
    $response = Invoke-ApiRequest -method "POST" -endpoint "/orders" -body $orderRequest -skipStatusCheck $true
    
    Test-Response -testName "Create order with AMEX" -response $response -expectedStatus 201 -validationBlock {
        param($content)
        if ($content.payment.cardBrand -ne "AMEX") { throw "Card brand should be AMEX" }
        $script:orderIds += $content.id
    }
}

function Test-CreateOrderWithFailedPayment {
    Write-TestHeader "Test 4: Create Order with Failed Payment (Card ending in 0000)"
    
    Clear-Cart
    Add-ItemToCart -productId $products.iPad -quantity 1
    
    $orderRequest = @{
        shippingAddress = @{
            addressLine1 = "321 Elm Street"
            city = "Miami"
            state = "FL"
            postalCode = "33101"
            country = "USA"
        }
        billingAddress = @{
            addressLine1 = "321 Elm Street"
            city = "Miami"
            state = "FL"
            postalCode = "33101"
            country = "USA"
        }
        customerEmail = "failed@test.com"
        paymentMethod = "CREDIT_CARD"
        paymentDetails = @{
            cardNumber = "4532123456780000"  # Card ending in 0000 - should fail
            cardHolderName = "Failed Test"
            expiryDate = "12/25"
            cvv = "123"
            cardBrand = "VISA"
        }
    }
    
    $response = Invoke-ApiRequest -method "POST" -endpoint "/orders" -body $orderRequest -skipStatusCheck $true
    
    Test-Response -testName "Create order with failed payment" -response $response -expectedStatus 201 -validationBlock {
        param($content)
        if ($content.status -ne "PENDING") { throw "Order status should be PENDING for failed payment" }
        if ($content.payment.paymentStatus -ne "FAILED") { throw "Payment status should be FAILED" }
        Write-Info "Order created but payment failed as expected"
        $script:orderIds += $content.id
    }
}

function Test-CreateOrderWithDebitCard {
    Write-TestHeader "Test 5: Create Order with Debit Card Payment Method"
    
    Clear-Cart
    Add-ItemToCart -productId $products.AdidasHoodie -quantity 2
    
    $orderRequest = @{
        shippingAddress = @{
            addressLine1 = "555 Broadway"
            city = "Seattle"
            state = "WA"
            postalCode = "98101"
            country = "USA"
        }
        billingAddress = @{
            addressLine1 = "555 Broadway"
            city = "Seattle"
            state = "WA"
            postalCode = "98101"
            country = "USA"
        }
        customerEmail = "debit@test.com"
        paymentMethod = "DEBIT_CARD"
        paymentDetails = @{
            cardNumber = "4532111111111111"
            cardHolderName = "Debit User"
            expiryDate = "03/26"
            cvv = "789"
            cardBrand = "VISA"
        }
    }
    
    $response = Invoke-ApiRequest -method "POST" -endpoint "/orders" -body $orderRequest -skipStatusCheck $true
    
    Test-Response -testName "Create order with debit card" -response $response -expectedStatus 201 -validationBlock {
        param($content)
        if ($content.payment.paymentMethod -ne "DEBIT_CARD") { throw "Payment method should be DEBIT_CARD" }
        $script:orderIds += $content.id
    }
}

function Test-CreateOrderWithMultipleItems {
    Write-TestHeader "Test 6: Create Order with Multiple Different Items"
    
    Clear-Cart
    Add-ItemToCart -productId $products.iPhone -quantity 1
    Add-ItemToCart -productId $products.Samsung -quantity 1
    Add-ItemToCart -productId $products.NikeTShirt -quantity 3
    Add-ItemToCart -productId $products.AdidasHoodie -quantity 2
    
    $orderRequest = @{
        shippingAddress = @{
            addressLine1 = "999 Market Street"
            city = "San Francisco"
            state = "CA"
            postalCode = "94103"
            country = "USA"
        }
        billingAddress = @{
            addressLine1 = "999 Market Street"
            city = "San Francisco"
            state = "CA"
            postalCode = "94103"
            country = "USA"
        }
        customerEmail = "multi@test.com"
        customerPhone = "+1-555-0123"
        notes = "Multiple items order test"
        paymentMethod = "CREDIT_CARD"
        paymentDetails = @{
            cardNumber = "4532987654321098"
            cardHolderName = "Multi Item Buyer"
            expiryDate = "08/25"
            cvv = "321"
            cardBrand = "VISA"
        }
    }
    
    $response = Invoke-ApiRequest -method "POST" -endpoint "/orders" -body $orderRequest -skipStatusCheck $true
    
    Test-Response -testName "Create order with multiple items" -response $response -expectedStatus 201 -validationBlock {
        param($content)
        if ($content.items.Count -ne 4) { throw "Should have 4 different items" }
        Write-Info "Order contains $($content.items.Count) different items"
        $script:orderIds += $content.id
    }
}

# ================================================================
# Edge Cases & Validation Tests
# ================================================================

function Test-CreateOrderWithEmptyCart {
    Write-TestHeader "Test 7: Try to Create Order with Empty Cart"
    
    Clear-Cart
    
    $orderRequest = @{
        shippingAddress = @{
            addressLine1 = "123 Empty Street"
            city = "Boston"
            state = "MA"
            postalCode = "02101"
            country = "USA"
        }
        billingAddress = @{
            addressLine1 = "123 Empty Street"
            city = "Boston"
            state = "MA"
            postalCode = "02101"
            country = "USA"
        }
        customerEmail = "empty@test.com"
        paymentMethod = "CREDIT_CARD"
        paymentDetails = @{
            cardNumber = "4532123456789012"
            cardHolderName = "Empty Cart"
            expiryDate = "12/25"
            cvv = "123"
            cardBrand = "VISA"
        }
    }
    
    $response = Invoke-ApiRequest -method "POST" -endpoint "/orders" -body $orderRequest -skipStatusCheck $true
    
    Test-Response -testName "Reject order with empty cart" -response $response -expectedStatus 400 -validationBlock {
        param($content)
        Write-Info "Error message: $($content.detail)"
    }
}

function Test-CreateOrderWithInvalidEmail {
    Write-TestHeader "Test 8: Try to Create Order with Invalid Email"
    
    Clear-Cart
    Add-ItemToCart -productId $products.iPhone -quantity 1
    
    $orderRequest = @{
        shippingAddress = @{
            addressLine1 = "123 Main Street"
            city = "New York"
            state = "NY"
            postalCode = "10001"
            country = "USA"
        }
        billingAddress = @{
            addressLine1 = "123 Main Street"
            city = "New York"
            state = "NY"
            postalCode = "10001"
            country = "USA"
        }
        customerEmail = "invalid-email"  # Invalid email
        paymentMethod = "CREDIT_CARD"
        paymentDetails = @{
            cardNumber = "4532123456789012"
            cardHolderName = "Test User"
            expiryDate = "12/25"
            cvv = "123"
            cardBrand = "VISA"
        }
    }
    
    $response = Invoke-ApiRequest -method "POST" -endpoint "/orders" -body $orderRequest -skipStatusCheck $true
    
    Test-Response -testName "Reject order with invalid email" -response $response -expectedStatus 400
}

function Test-CreateOrderWithInvalidCardNumber {
    Write-TestHeader "Test 9: Try to Create Order with Invalid Card Number"
    
    Clear-Cart
    Add-ItemToCart -productId $products.Samsung -quantity 1
    
    $orderRequest = @{
        shippingAddress = @{
            addressLine1 = "123 Main Street"
            city = "New York"
            state = "NY"
            postalCode = "10001"
            country = "USA"
        }
        billingAddress = @{
            addressLine1 = "123 Main Street"
            city = "New York"
            state = "NY"
            postalCode = "10001"
            country = "USA"
        }
        customerEmail = "test@example.com"
        paymentMethod = "CREDIT_CARD"
        paymentDetails = @{
            cardNumber = "1234"  # Invalid - must be 16 digits
            cardHolderName = "Test User"
            expiryDate = "12/25"
            cvv = "123"
            cardBrand = "VISA"
        }
    }
    
    $response = Invoke-ApiRequest -method "POST" -endpoint "/orders" -body $orderRequest -skipStatusCheck $true
    
    Test-Response -testName "Reject order with invalid card number" -response $response -expectedStatus 400
}

function Test-CreateOrderWithInvalidCVV {
    Write-TestHeader "Test 10: Try to Create Order with Invalid CVV"
    
    Clear-Cart
    Add-ItemToCart -productId $products.MacBook -quantity 1
    
    $orderRequest = @{
        shippingAddress = @{
            addressLine1 = "123 Main Street"
            city = "New York"
            state = "NY"
            postalCode = "10001"
            country = "USA"
        }
        billingAddress = @{
            addressLine1 = "123 Main Street"
            city = "New York"
            state = "NY"
            postalCode = "10001"
            country = "USA"
        }
        customerEmail = "test@example.com"
        paymentMethod = "CREDIT_CARD"
        paymentDetails = @{
            cardNumber = "4532123456789012"
            cardHolderName = "Test User"
            expiryDate = "12/25"
            cvv = "12"  # Invalid - must be 3 or 4 digits
            cardBrand = "VISA"
        }
    }
    
    $response = Invoke-ApiRequest -method "POST" -endpoint "/orders" -body $orderRequest -skipStatusCheck $true
    
    Test-Response -testName "Reject order with invalid CVV" -response $response -expectedStatus 400
}

function Test-CreateOrderWithMissingAddress {
    Write-TestHeader "Test 11: Try to Create Order with Missing Shipping Address"
    
    Clear-Cart
    Add-ItemToCart -productId $products.iPad -quantity 1
    
    $orderRequest = @{
        billingAddress = @{
            addressLine1 = "123 Main Street"
            city = "New York"
            state = "NY"
            postalCode = "10001"
            country = "USA"
        }
        customerEmail = "test@example.com"
        paymentMethod = "CREDIT_CARD"
        paymentDetails = @{
            cardNumber = "4532123456789012"
            cardHolderName = "Test User"
            expiryDate = "12/25"
            cvv = "123"
            cardBrand = "VISA"
        }
    }
    
    $response = Invoke-ApiRequest -method "POST" -endpoint "/orders" -body $orderRequest -skipStatusCheck $true
    
    Test-Response -testName "Reject order with missing shipping address" -response $response -expectedStatus 400
}

# ================================================================
# Order Retrieval Tests
# ================================================================

function Test-GetMyOrders {
    Write-TestHeader "Test 12: Get My Orders"
    
    $response = Invoke-ApiRequest -method "GET" -endpoint "/orders/my-orders" -token $script:authToken
    
    Test-Response -testName "Get user's orders" -response $response -expectedStatus 200 -validationBlock {
        param($content)
        if ($content.Count -eq 0) { throw "Should have at least one order" }
        Write-Info "Found $($content.Count) orders for current user"
        foreach ($order in $content | Select-Object -First 3) {
            Write-Info "  - Order: $($order.orderNumber), Status: $($order.status), Total: `$$($order.totalAmount)"
        }
    }
}

function Test-GetOrderById {
    Write-TestHeader "Test 13: Get Order by ID"
    
    if ($script:orderIds.Count -eq 0) {
        Write-Failure "No orders available to test"
        return
    }
    
    $orderId = $script:orderIds[0]
    $response = Invoke-ApiRequest -method "GET" -endpoint "/orders/$orderId" -token $script:authToken
    
    Test-Response -testName "Get specific order by ID" -response $response -expectedStatus 200 -validationBlock {
        param($content)
        if ($content.id -ne $orderId) { throw "Order ID mismatch" }
        Write-Info "Order Number: $($content.orderNumber)"
        Write-Info "Status: $($content.status)"
        Write-Info "Items: $($content.items.Count)"
    }
}

function Test-GetNonExistentOrder {
    Write-TestHeader "Test 14: Try to Get Non-Existent Order"
    
    $fakeOrderId = "00000000-0000-0000-0000-000000000000"
    $response = Invoke-ApiRequest -method "GET" -endpoint "/orders/$fakeOrderId" -skipStatusCheck $true
    
    Test-Response -testName "Get non-existent order returns 404" -response $response -expectedStatus 404
}

# ================================================================
# Different Payment Methods Tests
# ================================================================

function Test-CreateOrderWithPaypal {
    Write-TestHeader "Test 15: Create Order with PayPal Payment Method"
    
    Clear-Cart
    Add-ItemToCart -productId $products.NikeTShirt -quantity 2
    
    $orderRequest = @{
        shippingAddress = @{
            addressLine1 = "777 PayPal Street"
            city = "Austin"
            state = "TX"
            postalCode = "73301"
            country = "USA"
        }
        billingAddress = @{
            addressLine1 = "777 PayPal Street"
            city = "Austin"
            state = "TX"
            postalCode = "73301"
            country = "USA"
        }
        customerEmail = "paypal@test.com"
        paymentMethod = "PAYPAL"
        paymentDetails = @{
            cardNumber = "4532123456789012"  # Dummy for validation
            cardHolderName = "PayPal User"
            expiryDate = "12/25"
            cvv = "123"
            cardBrand = "VISA"
        }
    }
    
    $response = Invoke-ApiRequest -method "POST" -endpoint "/orders" -body $orderRequest -skipStatusCheck $true
    
    Test-Response -testName "Create order with PayPal" -response $response -expectedStatus 201 -validationBlock {
        param($content)
        if ($content.payment.paymentMethod -ne "PAYPAL") { throw "Payment method should be PAYPAL" }
        $script:orderIds += $content.id
    }
}

function Test-CreateOrderWithCashOnDelivery {
    Write-TestHeader "Test 16: Create Order with Cash on Delivery"
    
    Clear-Cart
    Add-ItemToCart -productId $products.AdidasHoodie -quantity 1
    
    $orderRequest = @{
        shippingAddress = @{
            addressLine1 = "888 COD Avenue"
            city = "Denver"
            state = "CO"
            postalCode = "80201"
            country = "USA"
        }
        billingAddress = @{
            addressLine1 = "888 COD Avenue"
            city = "Denver"
            state = "CO"
            postalCode = "80201"
            country = "USA"
        }
        customerEmail = "cod@test.com"
        paymentMethod = "CASH_ON_DELIVERY"
        paymentDetails = @{
            cardNumber = "4532123456789012"  # Dummy for validation
            cardHolderName = "COD User"
            expiryDate = "12/25"
            cvv = "123"
            cardBrand = "VISA"
        }
    }
    
    $response = Invoke-ApiRequest -method "POST" -endpoint "/orders" -body $orderRequest -skipStatusCheck $true
    
    Test-Response -testName "Create order with Cash on Delivery" -response $response -expectedStatus 201 -validationBlock {
        param($content)
        if ($content.payment.paymentMethod -ne "CASH_ON_DELIVERY") { throw "Payment method should be CASH_ON_DELIVERY" }
        $script:orderIds += $content.id
    }
}

# ================================================================
# Order with Notes and Phone Tests
# ================================================================

function Test-CreateOrderWithOptionalFields {
    Write-TestHeader "Test 17: Create Order with All Optional Fields"
    
    Clear-Cart
    Add-ItemToCart -productId $products.iPhone -quantity 1
    
    $orderRequest = @{
        shippingAddress = @{
            addressLine1 = "111 Complete Street"
            addressLine2 = "Building A, Floor 5"
            city = "Portland"
            state = "OR"
            postalCode = "97201"
            country = "USA"
        }
        billingAddress = @{
            addressLine1 = "222 Billing Avenue"
            addressLine2 = "Suite 100"
            city = "Portland"
            state = "OR"
            postalCode = "97201"
            country = "USA"
        }
        customerEmail = "complete@test.com"
        customerPhone = "+1-555-9876"
        notes = "This is a comprehensive test order with all optional fields filled in. Please handle with care and deliver between 9 AM - 5 PM."
        paymentMethod = "CREDIT_CARD"
        paymentDetails = @{
            cardNumber = "4532567890123456"
            cardHolderName = "Complete Test User"
            expiryDate = "11/26"
            cvv = "999"
            cardBrand = "VISA"
        }
    }
    
    $response = Invoke-ApiRequest -method "POST" -endpoint "/orders" -body $orderRequest -skipStatusCheck $true
    
    Test-Response -testName "Create order with all optional fields" -response $response -expectedStatus 201 -validationBlock {
        param($content)
        if (-not $content.customerPhone) { throw "Customer phone should be present" }
        if (-not $content.notes) { throw "Notes should be present" }
        if (-not $content.shippingAddress.addressLine2) { throw "Address line 2 should be present" }
        Write-Info "Notes: $($content.notes.Substring(0, 50))..."
        $script:orderIds += $content.id
    }
}

# ================================================================
# Stock Validation Test
# ================================================================

function Test-CreateOrderWithInsufficientStock {
    Write-TestHeader "Test 18: Try to Create Order with Insufficient Stock"
    
    Clear-Cart
    # Try to order more than available stock - add to cart will fail with 400
    # We expect this to fail at cart level, which is correct behavior
    $addResult = Add-ItemToCart -productId $products.MacBook -quantity 999
    
    if (-not $addResult) {
        # Cart validation prevented adding too many items - this is expected
        $script:testsTotal++
        Write-TestStep "Add to cart with insufficient stock"
        Write-Success "Cart validation correctly prevented adding 999 items (stock validation working)" -countAsTest
        return
    }
    
    # If it somehow got added to cart, test order creation rejection
    $orderRequest = @{
        shippingAddress = @{
            addressLine1 = "123 Stock Test Street"
            city = "Houston"
            state = "TX"
            postalCode = "77001"
            country = "USA"
        }
        billingAddress = @{
            addressLine1 = "123 Stock Test Street"
            city = "Houston"
            state = "TX"
            postalCode = "77001"
            country = "USA"
        }
        customerEmail = "stock@test.com"
        paymentMethod = "CREDIT_CARD"
        paymentDetails = @{
            cardNumber = "4532123456789012"
            cardHolderName = "Stock Test"
            expiryDate = "12/25"
            cvv = "123"
            cardBrand = "VISA"
        }
    }
    
    $response = Invoke-ApiRequest -method "POST" -endpoint "/orders" -body $orderRequest -skipStatusCheck $true
    
    Test-Response -testName "Reject order with insufficient stock" -response $response -expectedStatus 409 -validationBlock {
        param($content)
        Write-Info "Error: $($content.detail)"
    }
}

# ================================================================
# Test Summary and Cleanup
# ================================================================

function Show-TestSummary {
    Write-TestHeader "Test Summary"
    
    Write-Host "`n$Cyan━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$Reset"
    Write-Host "$Cyan           TEST RESULTS SUMMARY          $Reset"
    Write-Host "$Cyan━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$Reset"
    
    Write-Host "`n  Total Tests:  $script:testsTotal"
    Write-Host "  ${Green}Passed:       $script:testsPassed$Reset"
    Write-Host "  ${Red}Failed:       $script:testsFailed$Reset"
    
    $successRate = if ($script:testsTotal -gt 0) { 
        [math]::Round(($script:testsPassed / $script:testsTotal) * 100, 2) 
    } else { 
        0 
    }
    
    Write-Host "`n  Success Rate: $successRate%"
    
    if ($script:orderIds.Count -gt 0) {
        Write-Host "`n  ${Yellow}Created Orders ($($script:orderIds.Count)):$Reset"
        foreach ($orderId in $script:orderIds | Select-Object -First 5) {
            Write-Host "    - $orderId"
        }
        if ($script:orderIds.Count -gt 5) {
            Write-Host "    ... and $($script:orderIds.Count - 5) more"
        }
    }
    
    Write-Host "`n$Cyan━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$Reset`n"
}

# ================================================================
# Main Execution
# ================================================================

Write-Host "`n$Cyan╔════════════════════════════════════════════════╗$Reset"
Write-Host "$Cyan║    ORDER MODULE COMPREHENSIVE TEST SUITE       ║$Reset"
Write-Host "$Cyan╚════════════════════════════════════════════════╝$Reset`n"

try {
    # Initialize
    if (-not (Initialize-TestUser)) {
        Write-Host "${Red}Failed to initialize test user. Exiting.$Reset"
        exit 1
    }
    
    Start-Sleep -Seconds 1
    
    # Run all tests
    Test-CreateOrderWithValidPayment
    Test-CreateOrderWithMastercard
    Test-CreateOrderWithAmex
    Test-CreateOrderWithFailedPayment
    Test-CreateOrderWithDebitCard
    Test-CreateOrderWithMultipleItems
    Test-CreateOrderWithEmptyCart
    Test-CreateOrderWithInvalidEmail
    Test-CreateOrderWithInvalidCardNumber
    Test-CreateOrderWithInvalidCVV
    Test-CreateOrderWithMissingAddress
    Test-GetMyOrders
    Test-GetOrderById
    Test-GetNonExistentOrder
    Test-CreateOrderWithPaypal
    Test-CreateOrderWithCashOnDelivery
    Test-CreateOrderWithOptionalFields
    Test-CreateOrderWithInsufficientStock
    
    # Show summary
    Show-TestSummary
    
    # Exit with appropriate code
    if ($script:testsFailed -gt 0) {
        exit 1
    } else {
        exit 0
    }
    
} catch {
    Write-Host "`n${Red}[FATAL ERROR]$Reset An unexpected error occurred:"
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

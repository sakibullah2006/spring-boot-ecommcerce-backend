# Test script for Product Attribute Controller endpoints
# Tests the newly implemented /api/products/{productId}/attributes endpoints

$baseUrl = "http://localhost:8080"
$productId = "a67be663-ce00-11f0-a6d2-00155d226310"  # Replace with actual product ID from your test
$adminToken = "YOUR_ADMIN_JWT_TOKEN"  # Replace with actual admin JWT token

# Headers for authenticated requests
$headers = @{
    "Authorization" = "Bearer $adminToken"
    "Content-Type" = "application/json"
}

Write-Host "=== Testing Product Attribute Endpoints ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: GET - List all attributes for a product (public)
Write-Host "1. GET /api/products/$productId/attributes - Fetching product attributes" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/products/$productId/attributes" -Method Get
    Write-Host "   Success: Found $($response.Count) attribute(s)" -ForegroundColor Green
    $response | ForEach-Object {
        Write-Host "   - $($_.attributeName): $($_.optionName)" -ForegroundColor Gray
    }
} catch {
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 2: POST - Add attributes to a product (admin only)
Write-Host "2. POST /api/products/$productId/attributes - Adding new attributes" -ForegroundColor Yellow
$addAttributesBody = @{
    attributes = @(
        @{
            attributeId = "ATTRIBUTE_PUBLIC_ID_HERE"  # Replace with actual attribute ID (e.g., color)
            optionId = "OPTION_PUBLIC_ID_HERE"       # Replace with actual option ID (e.g., red)
        }
    )
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/products/$productId/attributes" `
        -Method Post -Headers $headers -Body $addAttributesBody
    Write-Host "   Success: Added $($response.Count) attribute(s)" -ForegroundColor Green
    $response | ForEach-Object {
        Write-Host "   - Added: $($_.attributeName) = $($_.optionName)" -ForegroundColor Gray
    }
} catch {
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "   Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
}
Write-Host ""

# Test 3: PUT - Replace all attributes (admin only)
Write-Host "3. PUT /api/products/$productId/attributes - Replacing all attributes" -ForegroundColor Yellow
$replaceAttributesBody = @{
    attributes = @(
        @{
            attributeId = "ATTRIBUTE_PUBLIC_ID_1"
            optionId = "OPTION_PUBLIC_ID_1"
        },
        @{
            attributeId = "ATTRIBUTE_PUBLIC_ID_2"
            optionId = "OPTION_PUBLIC_ID_2"
        }
    )
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/products/$productId/attributes" `
        -Method Put -Headers $headers -Body $replaceAttributesBody
    Write-Host "   Success: Replaced with $($response.Count) attribute(s)" -ForegroundColor Green
    $response | ForEach-Object {
        Write-Host "   - $($_.attributeName) = $($_.optionName)" -ForegroundColor Gray
    }
} catch {
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 4: DELETE - Remove a specific attribute from product (admin only)
Write-Host "4. DELETE /api/products/$productId/attributes/{attributeId} - Removing attribute" -ForegroundColor Yellow
$attributeIdToRemove = "ATTRIBUTE_PUBLIC_ID"  # Replace with actual attribute ID
try {
    Invoke-RestMethod -Uri "$baseUrl/api/products/$productId/attributes/$attributeIdToRemove" `
        -Method Delete -Headers $headers
    Write-Host "   Success: Attribute removed" -ForegroundColor Green
} catch {
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 5: DELETE - Remove specific attribute-option pair (admin only)
Write-Host "5. DELETE /api/products/$productId/attributes/{attributeId}/options/{optionId} - Removing option" -ForegroundColor Yellow
$attributeId = "ATTRIBUTE_PUBLIC_ID"
$optionId = "OPTION_PUBLIC_ID"
try {
    Invoke-RestMethod -Uri "$baseUrl/api/products/$productId/attributes/$attributeId/options/$optionId" `
        -Method Delete -Headers $headers
    Write-Host "   Success: Attribute option removed" -ForegroundColor Green
} catch {
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

Write-Host "=== Test Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Note: Replace placeholder IDs with actual values from your database:" -ForegroundColor Yellow
Write-Host "  - productId: Use a valid product public_id" -ForegroundColor Gray
Write-Host "  - attributeId: Use a valid attribute public_id (e.g., from /api/attributes)" -ForegroundColor Gray
Write-Host "  - optionId: Use a valid attribute_option public_id" -ForegroundColor Gray
Write-Host "  - adminToken: Use a valid JWT token for an admin user" -ForegroundColor Gray

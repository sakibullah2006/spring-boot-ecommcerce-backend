# test-duplicate-sku.ps1
# Tests duplicate SKU error handling - should return 409 Conflict with proper error message

$BaseUrl = "http://localhost:8080"

Write-Host "`n=== Testing Duplicate SKU Error Handling ===" -ForegroundColor Cyan

# Login
Write-Host "`n1. Logging in..." -ForegroundColor Yellow
$loginBody = @{ email = "sakibullah@gmail.com"; password = "password123" } | ConvertTo-Json
$loginResponse = Invoke-RestMethod -Uri "$BaseUrl/api/auth/login" -Method POST -ContentType 'application/json' -Body $loginBody -SessionVariable session
Write-Host "   ✓ Logged in as: $($loginResponse.email)" -ForegroundColor Green

# Try to create product with duplicate SKU
Write-Host "`n2. Attempting to create product with duplicate SKU 'TEST-LAPTOP-001'..." -ForegroundColor Yellow

$productBody = @{
  name = "Test Duplicate SKU Product"
  description = "This should fail with 409 Conflict"
  sku = "TEST-LAPTOP-001"  # This SKU already exists
  price = 599.99
  stockQuantity = 10
  categoryIds = @("8554f6c9-9ef9-4dfa-8fdf-1f510309f010")
  attributes = @()
} | ConvertTo-Json -Depth 10

try {
  $response = Invoke-RestMethod -Uri "$BaseUrl/api/products" -Method POST -ContentType 'application/json' -Body $productBody -WebSession $session -ErrorAction Stop
  Write-Host "   ✗ UNEXPECTED: Product was created (should have failed)" -ForegroundColor Red
  Write-Host "   Product ID: $($response.id)" -ForegroundColor Red
} catch {
  $statusCode = $_.Exception.Response.StatusCode.value__
  
  if ($statusCode -eq 409) {
    Write-Host "   ✓ Correct status code: 409 Conflict" -ForegroundColor Green
    
    # Read error response
    try {
      $errorJson = $_.ErrorDetails.Message | ConvertFrom-Json
      Write-Host "`n   Error Response:" -ForegroundColor Cyan
      Write-Host "   Title: $($errorJson.title)" -ForegroundColor White
      Write-Host "   Detail: $($errorJson.detail)" -ForegroundColor White
      Write-Host "   Type: $($errorJson.type)" -ForegroundColor White
      if ($errorJson.timestamp) {
        Write-Host "   Timestamp: $($errorJson.timestamp)" -ForegroundColor White
      }
    } catch {
      Write-Host "   Could not parse error response" -ForegroundColor Yellow
    }
  } elseif ($statusCode -eq 500) {
    Write-Host "   ✗ FAIL: Got 500 Internal Server Error (should be 409)" -ForegroundColor Red
  } else {
    Write-Host "   ⚠ Unexpected status code: $statusCode" -ForegroundColor Yellow
  }
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
Write-Host "Expected: 409 Conflict with detailed error message" -ForegroundColor White
Write-Host "This validates that duplicate SKU errors are handled properly" -ForegroundColor White
Write-Host ""

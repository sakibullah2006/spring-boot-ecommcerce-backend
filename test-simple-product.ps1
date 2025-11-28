# Simple product creation test (no attributes)
$baseUrl = "http://localhost:8080"

# Login
$loginResponse = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" `
    -Method Post `
    -Body '{"email":"sakibullah@gmail.com","password":"password123"}' `
    -ContentType "application/json" `
    -SessionVariable session

Write-Host "Logged in as: $($loginResponse.firstName)" -ForegroundColor Green

# Create product without attributes
$productResponse = Invoke-RestMethod -Uri "$baseUrl/api/products" `
    -Method Post `
    -Body '{"name":"Simple Test","sku":"SIMPLE-TEST-123","price":99.99,"salePrice":89.99,"stockQuantity":100,"categoryIds":["ceb0d1b7-cc97-11f0-aa56-00e04c816b21"]}' `
    -ContentType "application/json" `
    -WebSession $session

Write-Host "✓ Product created: $($productResponse.name) (ID: $($productResponse.id))" -ForegroundColor Green

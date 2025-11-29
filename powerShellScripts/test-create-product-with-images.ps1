# Test script for creating a product with images in a single request
# Prerequisites: Server running on http://localhost:8080

# Configuration
$baseUrl = "http://localhost:8080/api"
$username = "admin@example.com"
$password = "admin123"

Write-Host "=== Testing Create Product with Images ===" -ForegroundColor Cyan

# Step 1: Authenticate and get token
Write-Host "`n1. Authenticating..." -ForegroundColor Yellow
$loginBody = @{
    email = $username
    password = $password
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post `
        -Body $loginBody -ContentType "application/json"
    $token = $loginResponse.token
    Write-Host "✓ Authentication successful" -ForegroundColor Green
} catch {
    Write-Host "✗ Authentication failed: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Create product with images
Write-Host "`n2. Creating product with images..." -ForegroundColor Yellow

# Product data
$product = @{
    name = "Test Product with Images"
    description = "Created using single API call"
    price = 99.99
    stockQuantity = 50
    sku = "TEST-IMG-$(Get-Random -Minimum 1000 -Maximum 9999)"
    categoryId = 1
} | ConvertTo-Json

# You need to replace these paths with actual image files on your system
$imagePaths = @(
    # Add actual image file paths here, for example:
    # "C:\Users\YourUsername\Pictures\product1.jpg",
    # "C:\Users\YourUsername\Pictures\product2.jpg",
    # "C:\Users\YourUsername\Pictures\product3.jpg"
)

# Check if image paths are provided
if ($imagePaths.Count -eq 0 -or $imagePaths[0] -eq "") {
    Write-Host "`n⚠ WARNING: No image paths configured!" -ForegroundColor Yellow
    Write-Host "Please edit this script and add actual image file paths in the `$imagePaths array." -ForegroundColor Yellow
    Write-Host "`nExample:" -ForegroundColor Cyan
    Write-Host '  $imagePaths = @(' -ForegroundColor Gray
    Write-Host '      "C:\Users\YourName\Pictures\image1.jpg",' -ForegroundColor Gray
    Write-Host '      "C:\Users\YourName\Pictures\image2.jpg"' -ForegroundColor Gray
    Write-Host '  )' -ForegroundColor Gray
    Write-Host "`nContinuing without images (testing product creation only)..." -ForegroundColor Yellow
    $skipImages = $true
} else {
    # Validate image files exist
    $validImages = @()
    foreach ($path in $imagePaths) {
        if (Test-Path $path) {
            $validImages += $path
        } else {
            Write-Host "⚠ Warning: Image not found: $path" -ForegroundColor Yellow
        }
    }
    
    if ($validImages.Count -eq 0) {
        Write-Host "✗ No valid image files found!" -ForegroundColor Red
        $skipImages = $true
    } else {
        Write-Host "Found $($validImages.Count) valid image(s)" -ForegroundColor Green
        $imagePaths = $validImages
        $skipImages = $false
    }
}

# Build multipart form data
$boundary = [System.Guid]::NewGuid().ToString()
$LF = "`r`n"

# Start building the body
$bodyLines = @()

# Add product JSON part
$bodyLines += "--$boundary"
$bodyLines += "Content-Disposition: form-data; name=`"product`""
$bodyLines += "Content-Type: application/json"
$bodyLines += ""
$bodyLines += $product
$bodyLines += ""

# Add image files (if available)
if (-not $skipImages) {
    for ($i = 0; $i -lt $imagePaths.Count; $i++) {
        $imagePath = $imagePaths[$i]
        $fileName = [System.IO.Path]::GetFileName($imagePath)
        $imageBytes = [System.IO.File]::ReadAllBytes($imagePath)
        $imageBase64 = [System.Convert]::ToBase64String($imageBytes)
        
        $bodyLines += "--$boundary"
        $bodyLines += "Content-Disposition: form-data; name=`"images`"; filename=`"$fileName`""
        $bodyLines += "Content-Type: image/jpeg"
        $bodyLines += ""
        # Note: In PowerShell, we need to use byte array for binary data
        # For simplicity, we'll use curl instead for this test
    }
}

# Add primaryImageIndex parameter (only if we have images)
if (-not $skipImages) {
    $bodyLines += "--$boundary"
    $bodyLines += "Content-Disposition: form-data; name=`"primaryImageIndex`""
    $bodyLines += ""
    $bodyLines += "0"
    $bodyLines += ""
}

$bodyLines += "--$boundary--"

# Since PowerShell's Invoke-RestMethod has limitations with multipart/form-data binary files,
# we'll use curl if available, otherwise provide instructions
$curlAvailable = Get-Command curl -ErrorAction SilentlyContinue

if ($skipImages) {
    # Test without images using simple approach
    Write-Host "Testing endpoint without images..." -ForegroundColor Cyan
    
    # Create temp file for product JSON
    $tempFile = [System.IO.Path]::GetTempFileName()
    $product | Out-File -FilePath $tempFile -Encoding UTF8 -NoNewline
    
    try {
        # Use Invoke-WebRequest for better control
        $headers = @{
            "Authorization" = "Bearer $token"
        }
        
        $form = @{
            product = Get-Content $tempFile -Raw
        }
        
        $response = Invoke-WebRequest -Uri "$baseUrl/products/with-images" `
            -Method Post -Headers $headers -Form $form
        
        $result = $response.Content | ConvertFrom-Json
        
        Write-Host "✓ Product created successfully!" -ForegroundColor Green
        Write-Host "`nProduct Details:" -ForegroundColor Cyan
        Write-Host "  ID: $($result.id)" -ForegroundColor White
        Write-Host "  Name: $($result.name)" -ForegroundColor White
        Write-Host "  SKU: $($result.sku)" -ForegroundColor White
        Write-Host "  Price: `$$($result.price)" -ForegroundColor White
        Write-Host "  Stock: $($result.stockQuantity)" -ForegroundColor White
        Write-Host "  Images: $($result.images.Count)" -ForegroundColor White
        
    } catch {
        Write-Host "✗ Failed to create product: $_" -ForegroundColor Red
        if ($_.ErrorDetails) {
            Write-Host "Error details: $($_.ErrorDetails)" -ForegroundColor Red
        }
    } finally {
        Remove-Item $tempFile -ErrorAction SilentlyContinue
    }
    
} elseif ($curlAvailable) {
    Write-Host "Using curl for multipart upload..." -ForegroundColor Cyan
    
    # Build curl command
    $curlArgs = @(
        "-X", "POST"
        "$baseUrl/products/with-images"
        "-H", "Authorization: Bearer $token"
        "-F", "product=$product;type=application/json"
    )
    
    # Add each image file
    foreach ($imagePath in $imagePaths) {
        $curlArgs += "-F"
        $curlArgs += "images=@`"$imagePath`""
    }
    
    # Add primary image index
    $curlArgs += "-F"
    $curlArgs += "primaryImageIndex=0"
    
    try {
        $response = & curl @curlArgs 2>&1
        $result = $response | ConvertFrom-Json
        
        Write-Host "✓ Product created successfully with images!" -ForegroundColor Green
        Write-Host "`nProduct Details:" -ForegroundColor Cyan
        Write-Host "  ID: $($result.id)" -ForegroundColor White
        Write-Host "  Name: $($result.name)" -ForegroundColor White
        Write-Host "  SKU: $($result.sku)" -ForegroundColor White
        Write-Host "  Price: `$$($result.price)" -ForegroundColor White
        Write-Host "  Stock: $($result.stockQuantity)" -ForegroundColor White
        Write-Host "  Images: $($result.images.Count)" -ForegroundColor White
        
        if ($result.images.Count -gt 0) {
            Write-Host "`n  Image URLs:" -ForegroundColor Cyan
            foreach ($img in $result.images) {
                $primaryMark = if ($img.primary) { " [PRIMARY]" } else { "" }
                Write-Host "    - $($img.imageUrl)$primaryMark" -ForegroundColor Gray
            }
        }
        
        Write-Host "`n✓ Test completed successfully!" -ForegroundColor Green
        
    } catch {
        Write-Host "✗ Failed to create product: $_" -ForegroundColor Red
    }
    
} else {
    Write-Host "`n⚠ curl not found in PATH" -ForegroundColor Yellow
    Write-Host "To test with images, please install curl or use the following curl command manually:" -ForegroundColor Yellow
    
    Write-Host "`ncurl command:" -ForegroundColor Cyan
    Write-Host "curl -X POST http://localhost:8080/api/products/with-images \" -ForegroundColor Gray
    Write-Host "  -H `"Authorization: Bearer YOUR_TOKEN`" \" -ForegroundColor Gray
    Write-Host "  -F 'product={`"name`":`"Test Product`",`"price`":99.99,`"stockQuantity`":50,`"sku`":`"TEST-001`",`"categoryId`":1};type=application/json' \" -ForegroundColor Gray
    Write-Host "  -F 'images=@/path/to/image1.jpg' \" -ForegroundColor Gray
    Write-Host "  -F 'images=@/path/to/image2.jpg' \" -ForegroundColor Gray
    Write-Host "  -F 'primaryImageIndex=0'" -ForegroundColor Gray
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan

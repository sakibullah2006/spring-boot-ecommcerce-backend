# Test script for improved authentication exception handling

Write-Host "Testing improved authentication exception handling..."

$baseUrl = "http://localhost:8080"

function Get-ErrorDetails {
    param($Exception)

    try {
        if ($Exception.Response) {
            $statusCode = $Exception.Response.StatusCode.value__
            $stream = $Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $responseBody = $reader.ReadToEnd()
            $reader.Close()

            try {
                $errorResponse = $responseBody | ConvertFrom-Json
                return @{
                    StatusCode = $statusCode
                    Error = $errorResponse.error
                    Message = $errorResponse.message
                    RawBody = $responseBody
                }
            } catch {
                return @{
                    StatusCode = $statusCode
                    Error = "PARSE_ERROR"
                    Message = "Could not parse error response"
                    RawBody = $responseBody
                }
            }
        } else {
            return @{
                StatusCode = "N/A"
                Error = "CONNECTION_ERROR"
                Message = $Exception.Message
                RawBody = $Exception.Message
            }
        }
    } catch {
        return @{
            StatusCode = "N/A"
            Error = "UNKNOWN_ERROR"
            Message = $Exception.Message
            RawBody = $Exception.Message
        }
    }
}

Write-Host "1. Testing registration with duplicate email..."
try {
    # First registration should succeed
    $registerBody = @{
        firstName = "Test"
        lastName = "User"
        email = "duplicate@example.com"
        password = "password123"
    } | ConvertTo-Json

    $response1 = Invoke-RestMethod -Uri "$baseUrl/api/auth/register" -Method POST -ContentType "application/json" -Body $registerBody
    Write-Host "First registration successful: $($response1.email)"

    # Second registration should fail with proper error
    try {
        $response2 = Invoke-RestMethod -Uri "$baseUrl/api/auth/register" -Method POST -ContentType "application/json" -Body $registerBody
        Write-Host "ERROR: Second registration should have failed!"
    } catch {
        $errorDetails = Get-ErrorDetails $_.Exception
        Write-Host "Duplicate registration correctly blocked:"
        Write-Host "  Status: $($errorDetails.StatusCode)"
        Write-Host "  Error: $($errorDetails.Error)"
        Write-Host "  Message: $($errorDetails.Message)"
    }

} catch {
    $errorDetails = Get-ErrorDetails $_.Exception
    Write-Host "Error in registration test:"
    Write-Host "  Status: $($errorDetails.StatusCode)"
    Write-Host "  Error: $($errorDetails.Error)"
    Write-Host "  Message: $($errorDetails.Message)"
}

Write-Host "`n2. Testing login with invalid credentials..."
try {
    $invalidLoginBody = @{
        email = "nonexistent@example.com"
        password = "wrongpassword"
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method POST -ContentType "application/json" -Body $invalidLoginBody
    Write-Host "ERROR: Login with invalid credentials should have failed!"
} catch {
    $errorDetails = Get-ErrorDetails $_.Exception
    Write-Host "Invalid credentials correctly blocked:"
    Write-Host "  Status: $($errorDetails.StatusCode)"
    Write-Host "  Error: $($errorDetails.Error)"
    Write-Host "  Message: $($errorDetails.Message)"
}

Write-Host "`n3. Testing access to protected endpoint without authentication..."
try {
    $sessionResponse = Invoke-RestMethod -Uri "$baseUrl/api/auth/session" -Method GET
    Write-Host "ERROR: Access to protected endpoint should have failed!"
} catch {
    $errorDetails = Get-ErrorDetails $_.Exception
    Write-Host "Unauthorized access correctly blocked:"
    Write-Host "  Status: $($errorDetails.StatusCode)"
    Write-Host "  Error: $($errorDetails.Error)"
    Write-Host "  Message: $($errorDetails.Message)"
}

Write-Host "`n4. Testing validation errors..."
try {
    $invalidRegisterBody = @{
        firstName = ""
        lastName = ""
        email = "invalid-email"
        password = ""
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri "$baseUrl/api/auth/register" -Method POST -ContentType "application/json" -Body $invalidRegisterBody
    Write-Host "ERROR: Invalid registration data should have failed!"
} catch {
    $errorDetails = Get-ErrorDetails $_.Exception
    Write-Host "Validation errors correctly handled:"
    Write-Host "  Status: $($errorDetails.StatusCode)"
    Write-Host "  Error: $($errorDetails.Error)"
    Write-Host "  Message: $($errorDetails.Message)"
}

Write-Host "`nException handling tests completed."

# ========================================
# User Module Comprehensive Test Script
# ========================================
# This script tests all User CRUD endpoints with various scenarios
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
$script:CreatedUserIds = @()

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
        [hashtable]$Headers = $null,
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
        if ($Headers) { $params.Headers = $Headers }
        
        $response = Invoke-RestMethod @params
        
        Write-Success "$TestName - Status: $ExpectedStatusCode"
        return $response
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq $ExpectedStatusCode) {
            Write-Success "$TestName - Expected error status: $ExpectedStatusCode"
            return $null
        }
        else {
            $errorDetails = ""
            if ($_.ErrorDetails.Message) {
                try {
                    $errorObj = $_.ErrorDetails.Message | ConvertFrom-Json
                    $errorDetails = $errorObj.message
                }
                catch {
                    $errorDetails = $_.ErrorDetails.Message
                }
            }
            Write-Failure "$TestName - Unexpected status: $statusCode (expected $ExpectedStatusCode)" $errorDetails
            return $null
        }
    }
}

# ========================================
# Authentication
# ========================================

Write-TestHeader "1. AUTHENTICATION"

Write-TestCase "Login as Admin"
$loginBody = @{
    email = $AdminEmail
    password = $AdminPassword
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod `
        -Uri "$BaseUrl/api/auth/login" `
        -Method Post `
        -Body $loginBody `
        -ContentType "application/json" `
        -SessionVariable session
    
    if ($loginResponse.token) {
        Write-Success "Admin login successful"
        $adminToken = $loginResponse.token
        $adminHeaders = @{
            "Authorization" = "Bearer $adminToken"
        }
    }
    else {
        Write-Failure "Admin login failed - no token received"
        exit 1
    }
}
catch {
    Write-Failure "Admin login failed" $_.Exception.Message
    exit 1
}

# ========================================
# 2. CREATE USERS (Admin Only)
# ========================================

Write-TestHeader "2. CREATE USERS (ADMIN ONLY)"

Write-TestCase "Create customer user"
$createCustomerBody = @{
    firstName = "John"
    lastName = "Doe"
    email = "john.doe.test@example.com"
    password = "password123"
    role = "CUSTOMER"
} | ConvertTo-Json

$customer = Invoke-ApiRequest `
    -Method Post `
    -Uri "$BaseUrl/api/users" `
    -Body $createCustomerBody `
    -Headers $adminHeaders `
    -ExpectedStatusCode 201 `
    -TestName "Create customer user"

if ($customer) {
    $script:CreatedUserIds += $customer.id
    Write-Host "    Created user ID: $($customer.id)" -ForegroundColor Gray
}

Write-TestCase "Create admin user"
$createAdminBody = @{
    firstName = "Jane"
    lastName = "Admin"
    email = "jane.admin.test@example.com"
    password = "adminpass123"
    role = "ADMIN"
} | ConvertTo-Json

$admin = Invoke-ApiRequest `
    -Method Post `
    -Uri "$BaseUrl/api/users" `
    -Body $createAdminBody `
    -Headers $adminHeaders `
    -ExpectedStatusCode 201 `
    -TestName "Create admin user"

if ($admin) {
    $script:CreatedUserIds += $admin.id
    Write-Host "    Created user ID: $($admin.id)" -ForegroundColor Gray
}

Write-TestCase "Try to create duplicate user (should fail)"
Invoke-ApiRequest `
    -Method Post `
    -Uri "$BaseUrl/api/users" `
    -Body $createCustomerBody `
    -Headers $adminHeaders `
    -ExpectedStatusCode 409 `
    -TestName "Duplicate user creation prevention"

Write-TestCase "Try to create user with invalid email (should fail)"
$invalidEmailBody = @{
    firstName = "Invalid"
    lastName = "Email"
    email = "not-an-email"
    password = "password123"
    role = "CUSTOMER"
} | ConvertTo-Json

Invoke-ApiRequest `
    -Method Post `
    -Uri "$BaseUrl/api/users" `
    -Body $invalidEmailBody `
    -Headers $adminHeaders `
    -ExpectedStatusCode 400 `
    -TestName "Invalid email validation"

# ========================================
# 3. READ USERS
# ========================================

Write-TestHeader "3. READ USERS"

Write-TestCase "Get all users (admin only)"
$allUsers = Invoke-ApiRequest `
    -Method Get `
    -Uri "$BaseUrl/api/users" `
    -Headers $adminHeaders `
    -ExpectedStatusCode 200 `
    -TestName "Get all users"

if ($allUsers) {
    Write-Host "    Total users: $($allUsers.Count)" -ForegroundColor Gray
}

Write-TestCase "Get paginated users (admin only)"
$paginatedUsers = Invoke-ApiRequest `
    -Method Get `
    -Uri "$BaseUrl/api/users/paginated?page=0&size=10&sort=email,asc" `
    -Headers $adminHeaders `
    -ExpectedStatusCode 200 `
    -TestName "Get paginated users"

if ($paginatedUsers) {
    Write-Host "    Page size: $($paginatedUsers.size)" -ForegroundColor Gray
    Write-Host "    Total elements: $($paginatedUsers.totalElements)" -ForegroundColor Gray
    Write-Host "    Total pages: $($paginatedUsers.totalPages)" -ForegroundColor Gray
}

if ($customer) {
    Write-TestCase "Get user by ID (admin only)"
    $userById = Invoke-ApiRequest `
        -Method Get `
        -Uri "$BaseUrl/api/users/$($customer.id)" `
        -Headers $adminHeaders `
        -ExpectedStatusCode 200 `
        -TestName "Get user by ID"

    if ($userById) {
        Write-Host "    User email: $($userById.email)" -ForegroundColor Gray
        Write-Host "    User role: $($userById.role)" -ForegroundColor Gray
    }
}

Write-TestCase "Get current user profile (/me endpoint)"
$currentUser = Invoke-ApiRequest `
    -Method Get `
    -Uri "$BaseUrl/api/users/me" `
    -Headers $adminHeaders `
    -ExpectedStatusCode 200 `
    -TestName "Get current user profile"

if ($currentUser) {
    Write-Host "    Current user: $($currentUser.email)" -ForegroundColor Gray
}

Write-TestCase "Check if user exists by email (admin only)"
$exists = Invoke-ApiRequest `
    -Method Get `
    -Uri "$BaseUrl/api/users/exists?email=$([System.Web.HttpUtility]::UrlEncode($AdminEmail))" `
    -Headers $adminHeaders `
    -ExpectedStatusCode 200 `
    -TestName "Check user exists"

if ($null -ne $exists) {
    Write-Host "    User exists: $exists" -ForegroundColor Gray
}

# ========================================
# 4. UPDATE USERS
# ========================================

Write-TestHeader "4. UPDATE USERS"

if ($customer) {
    Write-TestCase "Update user (admin only)"
    $updateBody = @{
        firstName = "John Updated"
        lastName = "Doe Updated"
    } | ConvertTo-Json

    $updated = Invoke-ApiRequest `
        -Method Put `
        -Uri "$BaseUrl/api/users/$($customer.id)" `
        -Body $updateBody `
        -Headers $adminHeaders `
        -ExpectedStatusCode 200 `
        -TestName "Update user"

    if ($updated) {
        Write-Host "    Updated name: $($updated.firstName) $($updated.lastName)" -ForegroundColor Gray
    }
}

Write-TestCase "Update own profile (/me endpoint)"
$updateSelfBody = @{
    firstName = "Admin Updated"
    lastName = "User"
} | ConvertTo-Json

$updatedSelf = Invoke-ApiRequest `
    -Method Put `
    -Uri "$BaseUrl/api/users/me" `
    -Body $updateSelfBody `
    -Headers $adminHeaders `
    -ExpectedStatusCode 200 `
    -TestName "Update own profile"

if ($updatedSelf) {
    Write-Host "    Updated name: $($updatedSelf.firstName) $($updatedSelf.lastName)" -ForegroundColor Gray
}

if ($customer) {
    Write-TestCase "Update user password (admin only)"
    $passwordBody = @{
        password = "newpassword456"
    } | ConvertTo-Json

    Invoke-ApiRequest `
        -Method Put `
        -Uri "$BaseUrl/api/users/$($customer.id)" `
        -Body $passwordBody `
        -Headers $adminHeaders `
        -ExpectedStatusCode 200 `
        -TestName "Update user password"
}

# ========================================
# 5. DELETE USERS
# ========================================

Write-TestHeader "5. DELETE USERS (ADMIN ONLY)"

foreach ($userId in $script:CreatedUserIds) {
    Write-TestCase "Delete user: $userId"
    Invoke-ApiRequest `
        -Method Delete `
        -Uri "$BaseUrl/api/users/$userId" `
        -Headers $adminHeaders `
        -ExpectedStatusCode 204 `
        -TestName "Delete user $userId"
}

Write-TestCase "Try to get deleted user (should fail)"
if ($customer) {
    Invoke-ApiRequest `
        -Method Get `
        -Uri "$BaseUrl/api/users/$($customer.id)" `
        -Headers $adminHeaders `
        -ExpectedStatusCode 404 `
        -TestName "Get deleted user"
}

# ========================================
# 6. AUTHORIZATION TESTS
# ========================================

Write-TestHeader "6. AUTHORIZATION TESTS"

Write-TestCase "Try to access admin endpoints without authentication (should fail)"
try {
    Invoke-RestMethod -Uri "$BaseUrl/api/users" -Method Get
    Write-Failure "Unauthenticated access should be denied"
}
catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 401) {
        Write-Success "Unauthenticated access properly denied (401)"
    }
    else {
        Write-Failure "Unexpected status code: $statusCode"
    }
}

# ========================================
# SUMMARY
# ========================================

Write-TestHeader "TEST SUMMARY"

Write-Host "`nTotal Tests: $($script:PassedTests + $script:FailedTests)" -ForegroundColor White
Write-Host "Passed: $script:PassedTests" -ForegroundColor Green
Write-Host "Failed: $script:FailedTests" -ForegroundColor Red

if ($script:FailedTests -eq 0) {
    Write-Host "`n✓ All tests passed!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "`n✗ Some tests failed. See details above." -ForegroundColor Red
    Write-Host "`nFailed Tests:" -ForegroundColor Yellow
    $script:TestResults | Where-Object { $_.Result -eq "FAIL" } | ForEach-Object {
        Write-Host "  - $($_.Test)" -ForegroundColor Red
        if ($_.Details) {
            Write-Host "    $($_.Details)" -ForegroundColor DarkRed
        }
    }
    exit 1
}

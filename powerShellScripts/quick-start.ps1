# quick-start.ps1
# Purpose: Quick setup and test for E-Commerce API
# This script builds the app, starts it, and runs basic tests
# Usage: .\quick-start.ps1

param(
  [string]$BaseUrl = "http://localhost:8080",
  [switch]$SkipBuild = $false,
  [switch]$SkipTests = $false,
  [switch]$PopulateData = $false
)

$ErrorActionPreference = 'Continue'

Write-Host "`n============================================" -ForegroundColor Magenta
Write-Host " 🚀 E-Commerce Quick Start" -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta
Write-Host ""

# Step 1: Build
if (-not $SkipBuild) {
  Write-Host "📦 Building application..." -ForegroundColor Cyan
  try {
    & .\mvnw.cmd clean package -DskipTests
    Write-Host "  ✓ Build successful" -ForegroundColor Green
  } catch {
    Write-Host "  ✗ Build failed" -ForegroundColor Red
    exit 1
  }
} else {
  Write-Host "⏭️ Skipping build" -ForegroundColor Yellow
}

# Step 2: Check if already running
Write-Host "`n🔍 Checking if API is already running..." -ForegroundColor Cyan
try {
  $response = Invoke-RestMethod -Uri "$BaseUrl/api/auth/csrf" -Method GET -TimeoutSec 2
  Write-Host "  ✓ API is already running at $BaseUrl" -ForegroundColor Green
  $apiRunning = $true
} catch {
  Write-Host "  ℹ️ API is not running. Starting it now..." -ForegroundColor Yellow
  $apiRunning = $false
}

# Step 3: Start application if not running
if (-not $apiRunning) {
  Write-Host "`n🚀 Starting application..." -ForegroundColor Cyan
  
  # Start in new window
  $startCmd = "cd '$PWD'; .\mvnw.cmd spring-boot:run"
  Start-Process powershell -ArgumentList "-NoExit", "-Command", $startCmd
  
  Write-Host "  Waiting for application to start (30 seconds)..." -ForegroundColor Gray
  Start-Sleep -Seconds 5
  
  # Wait for API to be ready
  $maxAttempts = 25
  $attempt = 0
  $ready = $false
  
  while ($attempt -lt $maxAttempts -and -not $ready) {
    try {
      $null = Invoke-RestMethod -Uri "$BaseUrl/api/auth/csrf" -Method GET -TimeoutSec 2
      $ready = $true
      Write-Host "  ✓ Application started successfully!" -ForegroundColor Green
    } catch {
      $attempt++
      Start-Sleep -Seconds 1
      Write-Host "." -NoNewline -ForegroundColor Gray
    }
  }
  
  if (-not $ready) {
    Write-Host "`n  ✗ Application failed to start within timeout" -ForegroundColor Red
    exit 1
  }
  Write-Host ""
}

# Step 4: Register admin user
Write-Host "`n👤 Ensuring admin user exists..." -ForegroundColor Cyan
$adminBody = @{
  firstName = "Admin"
  lastName = "User"
  email = "sakibullah@gmail.com"
  password = "password123"
} | ConvertTo-Json

try {
  $response = Invoke-RestMethod -Uri "$BaseUrl/api/auth/register" -Method POST -ContentType 'application/json' -Body $adminBody
  Write-Host "  ✓ Admin user created: $($response.email)" -ForegroundColor Green
} catch {
  if ($_.Exception.Response.StatusCode.value__ -eq 400) {
    Write-Host "  ✓ Admin user already exists" -ForegroundColor Green
  } else {
    Write-Host "  ⚠ Could not verify admin user" -ForegroundColor Yellow
  }
}

# Step 5: Populate data (optional)
if ($PopulateData) {
  Write-Host "`n📊 Populating sample data..." -ForegroundColor Cyan
  try {
    & .\powerShellScripts\populate-data.ps1 -BaseUrl $BaseUrl
  } catch {
    Write-Host "  ⚠ Data population had some issues (this is usually OK)" -ForegroundColor Yellow
  }
}

# Step 6: Run tests (optional)
if (-not $SkipTests) {
  Write-Host "`n🧪 Running test suite..." -ForegroundColor Cyan
  Start-Sleep -Seconds 2
  try {
    & .\powerShellScripts\test-master.ps1 -BaseUrl $BaseUrl
  } catch {
    Write-Host "  ⚠ Some tests may have failed" -ForegroundColor Yellow
  }
}

# Summary
Write-Host "`n============================================" -ForegroundColor Magenta
Write-Host " ✅ Quick Start Complete!" -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta

Write-Host "`n📍 API is running at: $BaseUrl" -ForegroundColor Cyan
Write-Host "`n🔑 Admin credentials:" -ForegroundColor Cyan
Write-Host "   Email: sakibullah@gmail.com" -ForegroundColor White
Write-Host "   Password: password123" -ForegroundColor White

Write-Host "`n📚 Next steps:" -ForegroundColor Cyan
Write-Host "   • Test endpoints: .\powerShellScripts\test-master.ps1" -ForegroundColor White
Write-Host "   • Populate data: .\powerShellScripts\populate-data.ps1" -ForegroundColor White
Write-Host "   • View API docs: http://localhost:8080" -ForegroundColor White

Write-Host ""

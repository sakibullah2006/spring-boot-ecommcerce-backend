# PowerShell Scripts Documentation

This directory contains PowerShell scripts for testing and managing the E-Commerce API.

## 📋 Table of Contents

1. [Quick Start](#-quick-start)
2. [Available Scripts](#-available-scripts)
3. [Script Descriptions](#-script-descriptions)
4. [Usage Examples](#-usage-examples)
5. [Troubleshooting](#-troubleshooting)

---

## 🚀 Quick Start

**First time setup:**
```powershell
# Build, start, and test everything
.\powerShellScripts\quick-start.ps1

# With sample data
.\powerShellScripts\quick-start.ps1 -PopulateData
```

**Run tests:**
```powershell
# Comprehensive test suite
.\powerShellScripts\test-master.ps1
```

**Populate data:**
```powershell
# Add sample categories, attributes, and products
.\powerShellScripts\populate-data.ps1
```

---

## 📂 Available Scripts

### Main Scripts

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `quick-start.ps1` | Complete setup: build, start, test | First time setup or fresh start |
| `test-master.ps1` | Comprehensive test suite | Verify all endpoints working |
| `populate-data.ps1` | Load sample data | Need test data in database |

### Specialized Test Scripts

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `test-all-category-endpoints.ps1` | Test category CRUD | Testing category functionality |
| `test-all-product-endpoints.ps1` | Test product CRUD | Testing product functionality |
| `test-product-attributes.ps1` | Test product attributes | Testing attribute system |
| `test-exceptions.ps1` | Test error handling | Verify proper error responses |

---

## 📝 Script Descriptions

### `quick-start.ps1`

**Purpose:** One-command setup for the entire application.

**Features:**
- Builds the Maven project
- Starts the Spring Boot application
- Creates admin user
- Optionally populates sample data
- Optionally runs test suite

**Parameters:**
```powershell
-BaseUrl      # API URL (default: http://localhost:8080)
-SkipBuild    # Skip Maven build step
-SkipTests    # Skip running tests
-PopulateData # Load sample data after startup
```

**Example:**
```powershell
# Complete setup with sample data
.\powerShellScripts\quick-start.ps1 -PopulateData

# Just start without rebuilding
.\powerShellScripts\quick-start.ps1 -SkipBuild

# Start and populate data, skip tests
.\powerShellScripts\quick-start.ps1 -PopulateData -SkipTests
```

---

### `test-master.ps1`

**Purpose:** Comprehensive test suite covering all POST endpoints.

**What it tests:**
1. ✅ **Authentication**
   - User registration
   - Admin login
   - Session management
   - Logout

2. ✅ **Categories**
   - Create root category
   - Create subcategory with parent

3. ✅ **Attributes**
   - Create attributes
   - Create attribute options
   - Reference existing attributes

4. ✅ **Products**
   - Product without attributes
   - Product with NEW attributes (dynamic creation)
   - Product with EXISTING attributes (by ID)
   - Complex product (7+ attributes)

**Parameters:**
```powershell
-BaseUrl       # API URL (default: http://localhost:8080)
-AdminEmail    # Admin email (default: sakibullah@gmail.com)
-AdminPassword # Admin password (default: password123)
```

**Output:**
- Test results with pass/fail status
- Success rate percentage
- Created resource IDs
- Detailed error messages for failures

**Example:**
```powershell
# Run all tests
.\powerShellScripts\test-master.ps1

# Test against different endpoint
.\powerShellScripts\test-master.ps1 -BaseUrl "http://localhost:9090"

# Use different admin credentials
.\powerShellScripts\test-master.ps1 -AdminEmail "admin@test.com" -AdminPassword "admin123"
```

---

### `populate-data.ps1`

**Purpose:** Load sample data into the database via API.

**What it creates:**
1. **5 Main Categories:**
   - Electronics
   - Clothing
   - Books
   - Home & Garden
   - Sports & Outdoors

2. **5 Subcategories:**
   - Laptops (under Electronics)
   - Smartphones (under Electronics)
   - Tablets (under Electronics)
   - Men's Clothing (under Clothing)
   - Women's Clothing (under Clothing)

3. **5 Common Attributes:**
   - Brand
   - Color
   - Size
   - Material
   - Weight

4. **5 Sample Laptop Products:**
   - Dell XPS 13 (8 attributes)
   - MacBook Air M2 (8 attributes)
   - HP Spectre x360 14 (9 attributes)
   - Lenovo ThinkPad X1 Carbon Gen 11 (9 attributes)
   - ASUS ROG Zephyrus G14 (9 attributes)

**Parameters:**
```powershell
-BaseUrl       # API URL (default: http://localhost:8080)
-AdminEmail    # Admin email (default: sakibullah@gmail.com)
-AdminPassword # Admin password (default: password123)
```

**Example:**
```powershell
# Populate with defaults
.\powerShellScripts\populate-data.ps1

# Use custom credentials
.\powerShellScripts\populate-data.ps1 -AdminEmail "myAdmin@example.com" -AdminPassword "myPass"
```

**Note:** The script is idempotent - it will skip existing items, so it's safe to run multiple times.

---

### Specialized Test Scripts

#### `test-all-category-endpoints.ps1`
Tests all category operations (GET, POST, PUT, DELETE).

#### `test-all-product-endpoints.ps1`
Tests all product operations including attribute assignment.

#### `test-product-attributes.ps1`
Focuses on the attribute system - creating attributes, options, and assigning to products.

#### `test-exceptions.ps1`
Tests error handling for invalid requests.

---

## 💡 Usage Examples

### Scenario 1: First Time Setup
```powershell
# Clean build and start with sample data
.\powerShellScripts\quick-start.ps1 -PopulateData
```

### Scenario 2: After Code Changes
```powershell
# Rebuild and test
.\powerShellScripts\quick-start.ps1 -SkipTests
.\powerShellScripts\test-master.ps1
```

### Scenario 3: Test Specific Functionality
```powershell
# Just test products
.\powerShellScripts\test-all-product-endpoints.ps1

# Just test attributes
.\powerShellScripts\test-product-attributes.ps1
```

### Scenario 4: Development Workflow
```powershell
# 1. Start application (if not running)
.\mvnw.cmd spring-boot:run

# 2. Make code changes...

# 3. Run tests to verify
.\powerShellScripts\test-master.ps1

# 4. If needed, repopulate fresh data
.\powerShellScripts\populate-data.ps1
```

### Scenario 5: CI/CD Pipeline
```powershell
# Automated testing script
.\powerShellScripts\quick-start.ps1 -PopulateData
if ($LASTEXITCODE -ne 0) {
  Write-Error "Tests failed"
  exit 1
}
```

---

## 🔧 Troubleshooting

### Application Not Starting

**Problem:** `quick-start.ps1` says "API is not running" or times out.

**Solutions:**
1. Check if port 8080 is already in use:
   ```powershell
   netstat -ano | findstr :8080
   ```

2. Check MySQL is running:
   ```powershell
   Get-Process mysqld -ErrorAction SilentlyContinue
   ```

3. Verify database credentials in `application.yml`

4. Check application logs for errors

---

### Login Failed

**Problem:** Scripts fail with "Login failed" error.

**Solutions:**
1. Ensure admin user is registered:
   ```powershell
   # Register manually
   Invoke-RestMethod -Uri "http://localhost:8080/api/auth/register" -Method POST -ContentType 'application/json' -Body (@{
     firstName = "Admin"
     lastName = "User"
     email = "sakibullah@gmail.com"
     password = "password123"
   } | ConvertTo-Json)
   ```

2. Verify credentials match in both script and database

3. Check session cookie support in your environment

---

### Tests Failing

**Problem:** `test-master.ps1` shows failed tests.

**Solutions:**
1. Check which specific test failed - output shows details

2. Common issues:
   - **Category creation fails:** May already exist, check database
   - **Product creation fails:** Verify category ID is valid
   - **Attribute assignment fails:** Check cascade configuration

3. Run specific test scripts for more details:
   ```powershell
   .\powerShellScripts\test-all-product-endpoints.ps1
   ```

4. Check application logs for backend errors

---

### Data Population Issues

**Problem:** `populate-data.ps1` reports failures.

**Solutions:**
1. Check if items already exist (script skips duplicates):
   ```sql
   SELECT * FROM category WHERE name = 'Electronics';
   ```

2. Verify foreign key relationships:
   ```sql
   SELECT * FROM category WHERE parent_category_id IS NOT NULL;
   ```

3. Check attribute system is working:
   ```powershell
   .\powerShellScripts\test-product-attributes.ps1
   ```

---

## 📊 Understanding Test Output

### Success Output
```
[1] Testing: User Registration
    User registered: testuser@example.com
    ✓ PASSED

Total Tests Run: 12
Passed: 12
Failed: 0
Success Rate: 100%
```

### Failure Output
```
[5] Testing: Create Brand Attribute
    Response: {"error": "Unauthorized"}
    ✗ FAILED

Total Tests Run: 12
Passed: 4
Failed: 8
Success Rate: 33.33%
```

---

## 🎯 Key Features Tested

### 1. Attribute System (Reusable)
- ✅ Create attributes globally
- ✅ Create options for attributes
- ✅ Reference existing attributes in products
- ✅ Create new attributes dynamically during product creation
- ✅ Mix existing and new attributes in same product

### 2. Product Creation Patterns

**Pattern A: No Attributes**
```json
{
  "name": "Simple Product",
  "sku": "SKU-001",
  "price": 99.99,
  "stockQuantity": 10,
  "categoryId": "category-uuid-here",
  "attributes": []
}
```

**Pattern B: New Attributes (Dynamic)**
```json
{
  "name": "Product with New Attributes",
  "attributes": [
    {
      "attributeName": "Brand",
      "attributeDescription": "Manufacturer",
      "optionValue": "Apple"
    }
  ]
}
```

**Pattern C: Existing Attributes (By ID)**
```json
{
  "name": "Product with Existing Attributes",
  "attributes": [
    {
      "attributeId": "attr-uuid-here",
      "optionValue": "16GB"
    }
  ]
}
```

**Pattern D: Mixed**
```json
{
  "attributes": [
    {
      "attributeId": "existing-attr-uuid",
      "optionValue": "Dell"
    },
    {
      "attributeName": "New Attribute",
      "attributeDescription": "Description",
      "optionValue": "Value"
    }
  ]
}
```

---

## 📚 Additional Resources

- **API Documentation:** http://localhost:8080 (when running)
- **Source Code:** `src/main/java/com/saveitforlater/ecommerce/`
- **Database Schema:** `src/main/resources/db/migration/`

---

## 🔐 Default Credentials

**Admin User:**
- Email: `sakibullah@gmail.com`
- Password: `password123`

**Test User:**
- Email: `testuser@example.com`
- Password: `testpass123`

---

## 📝 Notes

1. All scripts use **session-based authentication** (cookies)
2. Product attributes support **dynamic creation** and **ID reference**
3. Scripts are **idempotent** - safe to run multiple times
4. All IDs are **UUIDs stored as Strings** (36-character format)
5. Categories support **hierarchical structure** (parent/child)

---

**Last Updated:** November 2024  
**Version:** 2.0 (Post String ID Migration)

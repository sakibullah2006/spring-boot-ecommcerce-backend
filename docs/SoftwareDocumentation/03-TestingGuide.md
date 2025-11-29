# Testing Guide

## Overview
This guide explains how to run the automated tests for the product, cart, and order modules using PowerShell scripts.

## Prerequisites
- Windows with PowerShell 7+
- Backend running on `http://localhost:8080`
- Database migrations applied

## Test Scripts
### Product Module
Run:
```powershell
.\powerShellScripts\test-product-module.ps1
```
Covers:
- Product CRUD
- Slug generation
- Validation (SKU, price, stock)
- Attributes and categories
- HTML sanitization

### Cart Module
Run:
```powershell
.\powerShellScripts\test-cart-module.ps1
```
Covers:
- Add/update/remove items
- Stock validation
- Total calculation

### Order Module
Run:
```powershell
.\powerShellScripts\test-order-module.ps1
```
Covers:
- Order creation
- Payments (Card, PayPal, COD)
- Invalid inputs and error handling
- My Orders and order retrieval

## Tips
- Ensure the backend server is running before executing tests.
- For fresh runs, clear the database or run migrations cleanly.
- Check the console output for summary and pass/fail counts.

## Troubleshooting Test Failures
- Cart empty errors: Ensure product IDs are resolved dynamically via `/products/paginated`.
- Authorization errors (403): Verify session login and `hasAuthority('ADMIN')` usage for admin endpoints.
- Migration errors: Confirm Flyway order (V4 creates description fields before sample data).

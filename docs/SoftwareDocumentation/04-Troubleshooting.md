# Troubleshooting

## Common Issues

### Cart is Empty When Creating Order
- Cause: No items in cart or product IDs invalid.
- Fix:
  - Ensure `Add-ItemToCart` succeeds.
  - Fetch product IDs from `/api/products/paginated` and use `content[i].id`.

### 403 Forbidden on Admin Endpoints
- Cause: Using role checks that expect `ROLE_ADMIN` but authorities are `ADMIN`.
- Fix: Use `@PreAuthorize("hasAuthority('ADMIN')")` for admin methods.

### Migration Failures (Unknown Column)
- Cause: Sample data using columns not yet created.
- Fix: Ensure migration order: V4 adds `short_description` and TEXT `description` before sample products in V5.

### File Upload Errors
- Cause: Invalid file type/size or missing multipart config.
- Fix:
  - Check `spring.servlet.multipart` settings in `application.yml`.
  - Ensure content type is one of JPEG/PNG/GIF/WebP.
  - Max 10MB per file.

### Login Fails
- Cause: Wrong credentials or server not running.
- Fix:
  - Verify server at `http://localhost:8080`.
  - Register a new user and try again.

### Payment Fails Unexpectedly
- Cause: Using a test card that triggers failure.
- Fix:
  - Use `4111111111111111` (VISA), `5111111111111111` (Mastercard), `3111111111111111` (AMEX).
  - Any card ending in `0000` triggers failure.

## Diagnostic Steps
1. Check server logs for exceptions.
2. Verify database connectivity.
3. Call health endpoints (if Actuator enabled).
4. Run module test scripts and read summary.
5. Validate session and cookies in API client.

## Getting Help
- Create a GitHub issue in the repository.
- Provide logs, exact steps, and environment details.

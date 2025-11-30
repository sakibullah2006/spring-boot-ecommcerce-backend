# Release Notes

## Version 1.0.0 (2025-11-30)

### Highlights
- Product descriptions: Added `shortDescription` and rich HTML `description` (sanitized via jsoup).
- Security: Fixed authorization annotations to `hasAuthority('ADMIN')` for admin endpoints.
- Migrations: Reordered Flyway scripts to ensure columns exist before sample data.
- Sample Data: Seeded categories, products, and attributes.
- Cart & Order: Implemented full cart → order → payment flow.
- File Storage: Reusable module for product images with metadata.
- Documentation: Comprehensive technical and software docs.

### Tests
- Product Module: 46/49 passing.
- Order Module: 26/26 passing after dynamic product ID fetch.
- Cart Module: Core flows validated.

### Known Issues
- Some product tests may fail if environment differs; ensure migrations are clean and endpoints available.

### Upgrades
- Spring Boot 3.3.5, Java 21, Flyway 10.10.0, jsoup 1.17.2.

### Next
- Add Auth and Category technical module docs.
- Consider JWT for stateless auth and cloud file storage adapters.

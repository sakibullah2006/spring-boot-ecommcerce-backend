# Features Overview

## Catalog
- Product browsing and search
- Category hierarchy (e.g., Electronics → Smartphones)
- Rich HTML product descriptions (sanitized)
- Product images with primary image selection
- Reusable attributes (Color, Size, Brand)

## Cart
- One cart per user
- Add, update, remove items
- Quantity validation and stock checks
- Cart total calculation

## Orders
- Create order from cart
- Two-step payment flow for card/PayPal
- COD flow with admin confirmation
- Order and payment status tracking
- My Orders view

## Files
- Upload product images (admin)
- Serve images publicly via secure endpoints
- Update image metadata (primary, order, alt text)

## Security
- Session-based authentication
- Role-based authorization (Admin, Customer)
- HTML sanitization for user-submitted content

## Admin Features
- Manage products and categories
- Manage attributes and options
- View all orders
- Update order and payment status

## Technology
- Spring Boot 3.3.5 (Java 21)
- MySQL/MariaDB with Flyway migrations
- Spring Security
- PowerShell test scripts for modules

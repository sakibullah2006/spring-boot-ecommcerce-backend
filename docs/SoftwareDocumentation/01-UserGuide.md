# User Guide

## Overview
This guide helps end users navigate the e-commerce system: browsing products, managing the cart, and placing orders.

## Getting Started
- Base URL: `http://localhost:8080`
- No login needed to browse products.
- Login required to manage cart and create orders.

## Browse Products
- Visit `/api/products/paginated?page=0&size=20` to list products.
- Use filters in your frontend (if available) for category, price, and search.

## Product Details
- View a single product by ID: `/api/products/{id}`
- Product pages show description, price, stock, attributes, and images.

## Account
### Register
Provide first name, last name, email, and password at `/api/auth/register` via the UI.

### Login
Use your email and password at `/api/auth/login`. You will stay signed in with a session.

### Logout
Click "Logout" in the UI (or call `/api/auth/logout`).

## Cart
- Add items from product pages.
- Update quantities in the cart view.
- Remove items or clear the cart.

## Checkout
1. Ensure cart has the right items and quantities.
2. Enter shipping and billing addresses.
3. Choose a payment method:
   - Credit/Debit Card
   - PayPal
   - Cash on Delivery (COD)
4. Submit the order.
5. If card/PayPal: complete payment step.

## Orders
- View your order history in "My Orders".
- Open an order to see status, items, and total.

## Statuses
- Order: `PENDING`, `CONFIRMED`, `SHIPPED`, `DELIVERED`, `CANCELLED`
- Payment: `PENDING`, `COMPLETED`, `FAILED`, `REFUNDED`

## Tips
- Keep your account secure; never share your password.
- If payment fails, retry with a different card or method.
- For COD, the admin confirms payment after delivery.

## Support
- If you encounter issues, see the Troubleshooting guide or contact support.

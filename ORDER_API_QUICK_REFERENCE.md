# Order API Quick Reference

## 🚀 Quick Start

### 1. Create Order (All Payment Methods)
```http
POST /api/orders
Content-Type: application/json

{
  "shippingAddress": {
    "addressLine1": "123 Main St",
    "city": "New York",
    "state": "NY",
    "postalCode": "10001",
    "country": "USA"
  },
  "billingAddress": {
    "addressLine1": "123 Main St",
    "city": "New York",
    "state": "NY",
    "postalCode": "10001",
    "country": "USA"
  },
  "customerEmail": "user@example.com",
  "customerPhone": "+1234567890",
  "paymentMethod": "CREDIT_CARD"
}
```

**Response:** Order with `PENDING` status and `orderId`

---

### 2A. Pay for Order (Credit/Debit Card)
```http
POST /api/orders/{orderId}/pay
Content-Type: application/json

{
  "paymentDetails": {
    "cardNumber": "4111111111111111",
    "cardHolderName": "John Doe",
    "expiryMonth": "12",
    "expiryYear": "2025",
    "cvv": "123"
  }
}
```

**Response:** Order with `CONFIRMED` status (success) or `PENDING` (failed)

---

### 2B. Confirm COD Payment (Admin Only)
```http
PATCH /api/orders/{orderId}/payment-status?paymentStatus=COMPLETED
```

**Response:** Order with `CONFIRMED` status

---

## 📋 All Endpoints

| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| POST | `/api/orders` | User | Create order from cart |
| POST | `/api/orders/{id}/pay` | Owner | Process card payment |
| GET | `/api/orders/{id}` | Owner/Admin | Get order details |
| GET | `/api/orders/my-orders` | User | Get my orders |
| GET | `/api/orders` | Admin | Get all orders |
| PATCH | `/api/orders/{id}/status` | Admin | Update order status |
| PATCH | `/api/orders/{id}/payment-status` | Admin | Update payment status |

---

## 💳 Payment Methods

- `CREDIT_CARD` → Use `/pay` endpoint
- `DEBIT_CARD` → Use `/pay` endpoint
- `PAYPAL` → Use `/pay` endpoint
- `BANK_TRANSFER` → Use `/pay` endpoint
- `CASH_ON_DELIVERY` → Admin uses `/payment-status` endpoint

---

## 📊 Status Values

### Order Status
- `PENDING` - Order created, payment pending
- `CONFIRMED` - Payment successful
- `SHIPPED` - Order shipped
- `DELIVERED` - Order delivered
- `CANCELLED` - Order cancelled

### Payment Status
- `PENDING` - Payment not processed
- `COMPLETED` - Payment successful
- `FAILED` - Payment failed
- `REFUNDED` - Payment refunded

---

## ⚡ Common Workflows

### Card Payment Flow
```
1. Add items to cart
2. POST /api/orders → Get orderId
3. POST /api/orders/{orderId}/pay → Payment processed
4. Order CONFIRMED ✅
```

### Cash on Delivery Flow
```
1. Add items to cart
2. POST /api/orders (paymentMethod: CASH_ON_DELIVERY)
3. Admin delivers & receives cash
4. Admin: PATCH /api/orders/{orderId}/payment-status?status=COMPLETED
5. Order CONFIRMED ✅
```

### Failed Payment Retry
```
1. POST /api/orders → orderId
2. POST /api/orders/{orderId}/pay → Payment FAILED
3. POST /api/orders/{orderId}/pay → Retry with different card
4. Payment COMPLETED ✅
```

---

## 🧪 Test Cards (Dummy Gateway)

| Card Number | Result |
|-------------|--------|
| `4111111111111111` | ✅ Success (VISA) |
| `5111111111111111` | ✅ Success (Mastercard) |
| `3111111111111111` | ✅ Success (AMEX) |
| `4111111111110000` | ❌ Failed (any card ending in 0000) |

---

## 🔒 Authorization

- **User**: Can create orders, pay for own orders, view own orders
- **Admin**: Full access including status updates and COD confirmation

---

## ⚠️ Important Notes

1. **Cart Clearing**: Cart is cleared immediately after order creation (Step 1)
2. **Stock Validation**: Happens twice - during order creation and before payment
3. **Stock Reduction**: Only happens after successful payment
4. **COD Orders**: Cannot use `/pay` endpoint
5. **Payment Retry**: Failed payments can be retried without recreating order

---

## 🐛 Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| 400 - Empty cart | No items in cart | Add items first |
| 400 - Insufficient stock | Not enough stock | Reduce quantity |
| 400 - Payment already processed | Trying to pay again | Order already paid |
| 400 - Wrong payment method | COD using /pay | Use admin endpoint |
| 404 - Order not found | Invalid orderId | Check orderId |
| 403 - Forbidden | Not order owner | Login as owner |

---

## 📝 Example: Complete Flow

```bash
# 1. Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password"}' \
  -c cookies.txt

# 2. Add to cart
curl -X POST http://localhost:8080/api/cart/items \
  -H "Content-Type: application/json" \
  -b cookies.txt \
  -d '{"productId":1,"quantity":2}'

# 3. Create order
curl -X POST http://localhost:8080/api/orders \
  -H "Content-Type: application/json" \
  -b cookies.txt \
  -d '{
    "shippingAddress": {...},
    "billingAddress": {...},
    "customerEmail": "user@example.com",
    "paymentMethod": "CREDIT_CARD"
  }' > order.json

# 4. Extract orderId and pay
ORDER_ID=$(cat order.json | jq -r '.publicId')
curl -X POST "http://localhost:8080/api/orders/$ORDER_ID/pay" \
  -H "Content-Type: application/json" \
  -b cookies.txt \
  -d '{
    "paymentDetails": {
      "cardNumber": "4111111111111111",
      "cardHolderName": "John Doe",
      "expiryMonth": "12",
      "expiryYear": "2025",
      "cvv": "123"
    }
  }'
```

---

## 🎯 PowerShell Testing

```powershell
# Run automated tests
cd powerShellScripts
.\test-order-module-two-step.ps1

# Expected: 10 test scenarios, ~30 assertions, 100% pass rate
```

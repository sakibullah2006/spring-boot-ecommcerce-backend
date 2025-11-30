# Order Module - Technical Documentation

## Overview

The Order Module converts a user's cart into an order, manages payment processing, and tracks order status lifecycle.

## Architecture

```
OrderController → OrderService → OrderRepository
                         ↓                ↓
                   PaymentService      OrderItemRepository
                         ↓
                      CartService (cart → order)
```

## Core Components

### Entities

#### Order
```java
@Entity
public class Order {
    @Id @GeneratedValue
    private Long id;
    private String publicId;
    private String orderNumber; // e.g. ORD-20251130-4020
    
    @ManyToOne private User user;
    
    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<OrderItem> items = new ArrayList<>();
    
    @OneToOne(cascade = CascadeType.ALL)
    private Payment payment;
    
    @Enumerated(EnumType.STRING) private OrderStatus status; // PENDING, CONFIRMED, ...
    private BigDecimal totalAmount;
    
    // Shipping & Billing (flattened fields for snapshotting)
    private String shippingAddressLine1; // ... (see DatabaseDesign)
    private String billingAddressLine1;  // ...
    private String customerEmail;
    private String customerPhone;
    private String notes;
}
```

#### OrderItem
```java
@Entity
public class OrderItem {
    @Id @GeneratedValue
    private Long id;
    private String publicId;
    
    @ManyToOne private Order order;
    @ManyToOne private Product product; // snapshot via fields below
    
    // Product snapshot
    private String productName;
    private String productSku;
    private BigDecimal unitPrice; // price at time of order
    private Integer quantity;
    private BigDecimal subtotal; // unitPrice * quantity
}
```

#### Payment
```java
@Entity
public class Payment {
    @Id @GeneratedValue
    private Long id;
    private String publicId;
    
    @ManyToOne private Order order;
    private BigDecimal amount;
    
    @Enumerated(EnumType.STRING) private PaymentMethod method; // CREDIT_CARD, COD, ...
    @Enumerated(EnumType.STRING) private PaymentStatus status; // PENDING, COMPLETED, FAILED, REFUNDED
    
    private String transactionId; // Synthetic in dev (e.g., TXN-22F261AD)
    private String maskedCard;    // **** **** **** 1111 (if applicable)
}
```

### Service Layer

#### OrderService
**Key Responsibilities**:
- Validate cart and user
- Create order from cart items (snapshot pricing)
- Generate unique order number
- Calculate totals
- Delegate to `PaymentService` for processing
- Update order/payment statuses
- Clear cart after successful order

**Key Methods**:
```java
OrderResponse createOrder(CreateOrderRequest request)
OrderResponse pay(String orderId, ProcessPaymentRequest request)
OrderResponse getOrderById(String orderId)
Page<OrderResponse> getMyOrders(Pageable pageable)
Page<OrderResponse> getAllOrders(Pageable pageable) // Admin
OrderResponse updateOrderStatus(String orderId, OrderStatus status) // Admin
OrderResponse updatePaymentStatus(String orderId, PaymentStatus status) // Admin
```

#### PaymentService
**Strategy**:
- Card payments: validate test card numbers; mark COMPLETED or FAILED
- PayPal/Bank Transfer: simulate success path
- COD: admin finalizes via payment status endpoint

```java
PaymentResult process(PaymentRequest request) // returns status + txn id
```

### Controllers
- `OrderController` exposes endpoints for create, pay, fetch, and admin updates.

## Workflows

### Card Payment (Two-Step)
```
1) POST /api/orders → Order (status=PENDING, payment=PENDING)
2) POST /api/orders/{id}/pay → Payment processed
   - success: order=CONFIRMED, payment=COMPLETED
   - failure: order remains PENDING, payment=FAILED
```

### Cash on Delivery (COD)
```
1) POST /api/orders (paymentMethod=CASH_ON_DELIVERY)
2) Admin: PATCH /api/orders/{id}/payment-status?paymentStatus=COMPLETED
3) Order moves to CONFIRMED
```

## Validation Rules

- Cart must not be empty
- Shipping/Billing addresses required for non-digital goods
- Email/phone format validation
- Quantity and pricing snapshot at time of order

## Status Lifecycle

### OrderStatus
- `PENDING` → created, awaiting payment
- `CONFIRMED` → payment completed
- `SHIPPED` → sent to customer
- `DELIVERED` → received by customer
- `CANCELLED` → cancelled

### PaymentStatus
- `PENDING` → not processed
- `COMPLETED` → success
- `FAILED` → declined
- `REFUNDED` → refunded

## API Endpoints

- `POST /api/orders` — Create from cart
- `POST /api/orders/{id}/pay` — Process payment
- `GET /api/orders/{id}` — Get order by ID (owner/admin)
- `GET /api/orders/my-orders` — List my orders
- `GET /api/orders` — List all (admin)
- `PATCH /api/orders/{id}/status?status=SHIPPED` — Update order status (admin)
- `PATCH /api/orders/{id}/payment-status?paymentStatus=COMPLETED` — Update payment status (admin)

## Database Schema

See `docs/technicalDocumentation/02-DatabaseDesign.md` for full DDL. Key points:
- Order stores flattened addresses and customer contact info
- OrderItem stores product snapshot (name, sku, unitPrice)
- Payment stores method, status, and transactionId

## Error Handling

- Empty cart → 400 `Cannot create order: cart is empty`
- Invalid payment → 400 with details
- Unauthorized access → 403 (owner-only access to orders)

## Testing

- PowerShell script: `powerShellScripts/test-order-module.ps1`
- Covers: creation, all payment methods, invalid inputs, admin flows

## Security

- Owner-only access enforced on order retrieval
- Admin-only endpoints for global listing and status updates
- Sensitive card data never stored (masked only)

---

**Related Documentation**:
- [Cart Module](./CartModule.md)
- [API Reference](../03-APIReference.md)
- [Security](../04-Security.md)

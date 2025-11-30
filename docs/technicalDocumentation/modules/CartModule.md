# Cart Module - Technical Documentation

## Overview

The Cart Module manages shopping cart functionality, allowing users to add products, update quantities, and prepare for checkout. Each user has exactly one active cart.

## Architecture

```
CartController → CartService → CartRepository
                     ↓              ↓
              ProductRepository   CartItemRepository
```

## Core Components

### Entities

#### Cart
```java
@Entity
public class Cart {
    @Id @GeneratedValue
    private Long id;
    
    private String publicId;
    
    @ManyToOne
    private User user;
    
    @OneToMany(mappedBy = "cart", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<CartItem> items = new ArrayList<>();
    
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
```

**Key Features**:
- One cart per user (enforced by UNIQUE constraint)
- Cascade delete of cart items
- Orphan removal for items

#### CartItem
```java
@Entity
public class CartItem {
    @Id @GeneratedValue
    private Long id;
    
    private String publicId;
    
    @ManyToOne
    private Cart cart;
    
    @ManyToOne
    private Product product;
    
    private Integer quantity;
    
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
```

**Key Features**:
- References product (not product snapshot)
- Quantity validation (must be > 0)
- Automatic timestamp tracking

### Service Layer

#### CartService
**Package**: `com.saveitforlater.ecommerce.domain.cart`

**Key Methods**:
```java
// Cart Operations
CartResponse getMyCart()
CartResponse getCartByUserId(String userId)
CartResponse addToCart(AddToCartRequest request)
CartResponse updateCartItem(String cartItemId, UpdateCartItemRequest request)
CartResponse removeCartItem(String cartItemId)
CartResponse clearCart()

// Helper Methods
Cart getOrCreateCartForCurrentUser()
BigDecimal calculateCartTotal(Cart cart)
void validateStock(Product product, int requestedQuantity)
```

**Business Logic**:

1. **Get or Create Cart**: Auto-creates cart if user doesn't have one
2. **Stock Validation**: Ensures requested quantity doesn't exceed stock
3. **Duplicate Prevention**: Updates quantity if product already in cart
4. **Total Calculation**: Sum of (unitPrice × quantity) for all items
5. **Authorization**: Users can only access their own cart

### Repository Layer

#### CartRepository
```java
@Repository
public interface CartRepository extends JpaRepository<Cart, Long> {
    Optional<Cart> findByPublicId(String publicId);
    Optional<Cart> findByUser_Id(Long userId);
    Optional<Cart> findByUser_PublicId(String userPublicId);
}
```

#### CartItemRepository
```java
@Repository
public interface CartItemRepository extends JpaRepository<CartItem, Long> {
    Optional<CartItem> findByPublicId(String publicId);
    Optional<CartItem> findByCart_IdAndProduct_Id(Long cartId, Long productId);
    List<CartItem> findByCart_Id(Long cartId);
    void deleteByCart_Id(Long cartId);
}
```

## API Endpoints

### Get My Cart
```http
GET /api/cart
Authorization: Required
```

**Response**: `200 OK`
```json
{
  "id": "cart-uuid",
  "items": [
    {
      "id": "item-uuid",
      "productId": "product-uuid",
      "productName": "iPhone 15 128GB",
      "productSku": "IPHONE15-128",
      "productSlug": "iphone-15-128gb-black",
      "unitPrice": 999.99,
      "quantity": 2,
      "subtotal": 1999.98,
      "productImage": "/api/files/images/image-uuid"
    }
  ],
  "totalItems": 2,
  "totalAmount": 1999.98,
  "createdAt": "2025-11-30T10:00:00Z",
  "updatedAt": "2025-11-30T10:05:00Z"
}
```

### Add Item to Cart
```http
POST /api/cart/items
Authorization: Required
Content-Type: application/json

{
  "productId": "product-uuid",
  "quantity": 2
}
```

**Response**: `201 Created` (returns updated cart)

**Validation**:
- Product must exist
- Product must be active
- Quantity must be > 0
- Sufficient stock must be available

**Behavior**:
- If product already in cart: increases quantity
- If new product: adds new cart item
- Auto-creates cart if user doesn't have one

### Update Cart Item Quantity
```http
PUT /api/cart/items/{cartItemId}
Authorization: Required
Content-Type: application/json

{
  "quantity": 5
}
```

**Response**: `200 OK` (returns updated cart)

**Validation**:
- Quantity must be > 0
- Cart item must belong to current user
- Sufficient stock must be available

### Remove Cart Item
```http
DELETE /api/cart/items/{cartItemId}
Authorization: Required
```

**Response**: `200 OK` (returns updated cart)

### Clear Cart
```http
DELETE /api/cart
Authorization: Required
```

**Response**: `200 OK` (returns empty cart)

### Get Cart by User ID (Admin Only)
```http
GET /api/cart/user/{userId}
Authorization: Admin
```

## Database Schema

```sql
CREATE TABLE cart (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    public_id VARCHAR(36) UNIQUE NOT NULL,
    user_id BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES appuser(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_cart (user_id)
);

CREATE TABLE cart_item (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    public_id VARCHAR(36) UNIQUE NOT NULL,
    cart_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (cart_id) REFERENCES cart(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES product(id),
    UNIQUE KEY unique_cart_product (cart_id, product_id)
);
```

**Constraints**:
- One cart per user
- One entry per product per cart
- Quantity must be positive
- Cascade delete on cart deletion

## Business Rules

### Stock Validation
```java
public void validateStock(Product product, int requestedQuantity) {
    if (product.getStockQuantity() < requestedQuantity) {
        throw new InsufficientStockException(
            "Insufficient stock. Available: " + product.getStockQuantity() +
            ", Requested: " + requestedQuantity
        );
    }
}
```

### Duplicate Item Handling
```java
// When adding existing product:
Optional<CartItem> existing = cartItemRepository
    .findByCart_IdAndProduct_Id(cart.getId(), product.getId());
    
if (existing.isPresent()) {
    CartItem item = existing.get();
    item.setQuantity(item.getQuantity() + request.quantity());
    cartItemRepository.save(item);
} else {
    // Create new cart item
}
```

### Total Calculation
```java
public BigDecimal calculateCartTotal(Cart cart) {
    return cart.getItems().stream()
        .map(item -> {
            BigDecimal price = item.getProduct().getSalePrice() != null
                ? item.getProduct().getSalePrice()
                : item.getProduct().getPrice();
            return price.multiply(BigDecimal.valueOf(item.getQuantity()));
        })
        .reduce(BigDecimal.ZERO, BigDecimal::add);
}
```

## Error Handling

### Common Errors

| Error | Status | Description |
|-------|--------|-------------|
| Product Not Found | 404 | Invalid product ID |
| Insufficient Stock | 400 | Not enough stock available |
| Invalid Quantity | 400 | Quantity must be > 0 |
| Unauthorized | 403 | Accessing another user's cart |
| Cart Item Not Found | 404 | Invalid cart item ID |

## Testing

### PowerShell Test Script
**File**: `powerShellScripts/test-cart-module.ps1`

**Run Tests**:
```powershell
.\powerShellScripts\test-cart-module.ps1
```

### Test Scenarios
1. Get empty cart → empty items array
2. Add item to cart → item appears in cart
3. Add existing item → quantity increases
4. Update quantity → cart total recalculated
5. Remove item → item removed from cart
6. Clear cart → all items removed
7. Add item with insufficient stock → 400 error
8. Add item with quantity 0 → 400 error

## Integration with Order Module

### Checkout Flow
```
1. User adds items to cart
2. User reviews cart
3. User clicks "Checkout"
4. Cart items → Order items
5. Cart cleared after successful order
```

### Implementation
```java
// In OrderService.createOrder()
Cart cart = cartService.getOrCreateCartForCurrentUser();

if (cart.getItems().isEmpty()) {
    throw new EmptyCartException("Cannot create order: cart is empty");
}

// Create order from cart items
Order order = new Order();
cart.getItems().forEach(cartItem -> {
    OrderItem orderItem = new OrderItem();
    orderItem.setProduct(cartItem.getProduct());
    orderItem.setQuantity(cartItem.getQuantity());
    orderItem.setUnitPrice(cartItem.getProduct().getPrice());
    order.addItem(orderItem);
});

// Clear cart after order creation
cartService.clearCart();
```

## Performance Considerations

### Eager vs Lazy Loading
```java
// Fetch cart with items in single query
@EntityGraph(attributePaths = {"items", "items.product"})
Optional<Cart> findByUser_Id(Long userId);
```

### Caching
Cart data changes frequently, so caching should be short-lived or disabled.

### Concurrency
For high-traffic scenarios, consider optimistic locking:
```java
@Version
private Long version;
```

## Security

### Authorization
- Users can only access their own cart
- Admins can view any user's cart
- Cart items validated to belong to requesting user

### Input Validation
```java
public record AddToCartRequest(
    @NotBlank String productId,
    @Min(1) @Max(999) Integer quantity
) {}
```

## Future Enhancements

- Cart expiration (clear after X days)
- Guest cart support (session-based)
- Save for later functionality
- Cart sharing (share cart URL)
- Coupon/discount application
- Stock reservation during checkout
- Cart abandonment tracking
- Persistent cart across devices

---

**Related Documentation**:
- [Product Module](./ProductModule.md)
- [Order Module](./OrderModule.md)
- [API Reference](../03-APIReference.md)

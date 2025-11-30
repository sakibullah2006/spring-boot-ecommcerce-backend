package com.saveitforlater.ecommerce.api.order;

import com.saveitforlater.ecommerce.api.order.dto.CreateOrderRequest;
import com.saveitforlater.ecommerce.api.order.dto.OrderResponse;
import com.saveitforlater.ecommerce.api.order.dto.ProcessPaymentRequest;
import com.saveitforlater.ecommerce.domain.order.OrderService;
import com.saveitforlater.ecommerce.persistence.entity.order.OrderStatus;
import com.saveitforlater.ecommerce.persistence.entity.order.PaymentStatus;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/orders")
@RequiredArgsConstructor
public class OrderController {

    private final OrderService orderService;

    /**
     * Create order from current user's cart - accessible to authenticated users
     * Order created with PENDING status. Payment must be processed separately.
     */
    @PostMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<OrderResponse> createOrder(@Valid @RequestBody CreateOrderRequest request) {
        log.info("POST /api/orders - Creating order");
        OrderResponse order = orderService.createOrder(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(order);
    }

    /**
     * Process payment for an order - accessible to order owner
     * Only for card-based payment methods (not COD)
     */
    @PostMapping("/{orderId}/pay")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<OrderResponse> processPayment(
            @PathVariable String orderId,
            @Valid @RequestBody ProcessPaymentRequest request) {
        log.info("POST /api/orders/{}/pay - Processing payment", orderId);
        OrderResponse order = orderService.processPayment(orderId, request.paymentDetails());
        return ResponseEntity.ok(order);
    }

    /**
     * Get order by ID - accessible to order owner or admin
     */
    @GetMapping("/{orderId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<OrderResponse> getOrderById(@PathVariable String orderId) {
        log.debug("GET /api/orders/{} - Fetching order", orderId);
        OrderResponse order = orderService.getOrderById(orderId);
        return ResponseEntity.ok(order);
    }

    /**
     * Get all orders for current user - accessible to authenticated users
     */
    @GetMapping("/my-orders")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<OrderResponse>> getMyOrders() {
        log.debug("GET /api/orders/my-orders - Fetching user's orders");
        List<OrderResponse> orders = orderService.getMyOrders();
        return ResponseEntity.ok(orders);
    }

    /**
     * Get paginated orders for current user - accessible to authenticated users
     */
    @GetMapping("/my-orders/paginated")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Page<OrderResponse>> getMyOrdersPaginated(
            @PageableDefault(size = 20, sort = "createdAt") Pageable pageable) {
        log.debug("GET /api/orders/my-orders/paginated - Fetching user's paginated orders");
        Page<OrderResponse> orders = orderService.getMyOrdersPaginated(pageable);
        return ResponseEntity.ok(orders);
    }

    /**
     * Get all orders - ADMIN ONLY
     */
    @GetMapping
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<List<OrderResponse>> getAllOrders() {
        log.debug("GET /api/orders - Fetching all orders (admin)");
        List<OrderResponse> orders = orderService.getAllOrders();
        return ResponseEntity.ok(orders);
    }

    /**
     * Get paginated orders - ADMIN ONLY
     */
    @GetMapping("/paginated")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<Page<OrderResponse>> getAllOrdersPaginated(
            @PageableDefault(size = 20, sort = "createdAt") Pageable pageable) {
        log.debug("GET /api/orders/paginated - Fetching all paginated orders (admin)");
        Page<OrderResponse> orders = orderService.getAllOrdersPaginated(pageable);
        return ResponseEntity.ok(orders);
    }

    /**
     * Get orders for a specific user - ADMIN ONLY
     */
    @GetMapping("/user/{userId}")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<List<OrderResponse>> getOrdersByUserId(@PathVariable String userId) {
        log.debug("GET /api/orders/user/{} - Fetching orders for user (admin)", userId);
        List<OrderResponse> orders = orderService.getOrdersByUserId(userId);
        return ResponseEntity.ok(orders);
    }

    /**
     * Get paginated orders for a specific user - ADMIN ONLY
     */
    @GetMapping("/user/{userId}/paginated")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<Page<OrderResponse>> getOrdersByUserIdPaginated(
            @PathVariable String userId,
            @PageableDefault(size = 20, sort = "createdAt") Pageable pageable) {
        log.debug("GET /api/orders/user/{}/paginated - Fetching paginated orders for user (admin)", userId);
        Page<OrderResponse> orders = orderService.getOrdersByUserIdPaginated(userId, pageable);
        return ResponseEntity.ok(orders);
    }

    /**
     * Update order status - ADMIN ONLY
     */
    @PatchMapping("/{orderId}/status")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<OrderResponse> updateOrderStatus(
            @PathVariable String orderId,
            @RequestParam OrderStatus status) {
        log.info("PATCH /api/orders/{}/status - Updating order status to: {}", orderId, status);
        OrderResponse order = orderService.updateOrderStatus(orderId, status);
        return ResponseEntity.ok(order);
    }

    /**
     * Update payment status - ADMIN ONLY (for COD orders)
     */
    @PatchMapping("/{orderId}/payment-status")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<OrderResponse> updatePaymentStatus(
            @PathVariable String orderId,
            @RequestParam PaymentStatus paymentStatus) {
        log.info("PATCH /api/orders/{}/payment-status - Updating payment status to: {}", orderId, paymentStatus);
        OrderResponse order = orderService.updatePaymentStatus(orderId, paymentStatus);
        return ResponseEntity.ok(order);
    }
}

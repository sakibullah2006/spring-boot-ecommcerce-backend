package com.saveitforlater.ecommerce.api.order;

import com.saveitforlater.ecommerce.api.order.dto.CreateOrderRequest;
import com.saveitforlater.ecommerce.api.order.dto.OrderResponse;
import com.saveitforlater.ecommerce.domain.order.OrderService;
import com.saveitforlater.ecommerce.persistence.entity.order.OrderStatus;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
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
     */
    @PostMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<OrderResponse> createOrder(@Valid @RequestBody CreateOrderRequest request) {
        log.info("POST /api/orders - Creating order");
        OrderResponse order = orderService.createOrder(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(order);
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
}

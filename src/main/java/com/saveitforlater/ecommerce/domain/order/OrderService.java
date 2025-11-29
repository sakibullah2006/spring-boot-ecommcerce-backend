package com.saveitforlater.ecommerce.domain.order;

import com.saveitforlater.ecommerce.api.order.dto.CreateOrderRequest;
import com.saveitforlater.ecommerce.api.order.dto.OrderResponse;
import com.saveitforlater.ecommerce.api.order.dto.PaymentDetailsRequest;
import com.saveitforlater.ecommerce.api.order.mapper.OrderMapper;
import com.saveitforlater.ecommerce.domain.order.exception.EmptyCartException;
import com.saveitforlater.ecommerce.domain.order.exception.InsufficientStockException;
import com.saveitforlater.ecommerce.domain.order.exception.OrderNotFoundException;
import com.saveitforlater.ecommerce.persistence.entity.cart.Cart;
import com.saveitforlater.ecommerce.persistence.entity.cart.CartItem;
import com.saveitforlater.ecommerce.persistence.entity.order.Order;
import com.saveitforlater.ecommerce.persistence.entity.order.OrderItem;
import com.saveitforlater.ecommerce.persistence.entity.order.OrderStatus;
import com.saveitforlater.ecommerce.persistence.entity.order.Payment;
import com.saveitforlater.ecommerce.persistence.entity.order.PaymentStatus;
import com.saveitforlater.ecommerce.persistence.entity.product.Product;
import com.saveitforlater.ecommerce.persistence.entity.user.User;
import com.saveitforlater.ecommerce.persistence.repository.cart.CartRepository;
import com.saveitforlater.ecommerce.persistence.repository.order.OrderRepository;
import com.saveitforlater.ecommerce.persistence.repository.product.ProductRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class OrderService {

    private final OrderRepository orderRepository;
    private final CartRepository cartRepository;
    private final ProductRepository productRepository;
    private final OrderMapper orderMapper;

    /**
     * Create order from current user's cart (Step 1: Order creation only, no payment)
     */
    @Transactional
    public OrderResponse createOrder(CreateOrderRequest request) {
        User currentUser = getCurrentUser();
        log.info("Creating order for user: {}", currentUser.getEmail());

        // Get user's cart
        Cart cart = cartRepository.findByUser(currentUser)
                .orElseThrow(() -> EmptyCartException.create());

        if (cart.getItems().isEmpty()) {
            throw EmptyCartException.create();
        }

        // Validate stock availability and calculate total
        BigDecimal totalAmount = validateStockAndCalculateTotal(cart);

        // Create order with PENDING status
        Order order = new Order();
        order.setUser(currentUser);
        order.setStatus(OrderStatus.PENDING);
        order.setTotalAmount(totalAmount);

        // Set shipping address
        order.setShippingAddressLine1(request.shippingAddress().addressLine1());
        order.setShippingAddressLine2(request.shippingAddress().addressLine2());
        order.setShippingCity(request.shippingAddress().city());
        order.setShippingState(request.shippingAddress().state());
        order.setShippingPostalCode(request.shippingAddress().postalCode());
        order.setShippingCountry(request.shippingAddress().country());

        // Set billing address
        order.setBillingAddressLine1(request.billingAddress().addressLine1());
        order.setBillingAddressLine2(request.billingAddress().addressLine2());
        order.setBillingCity(request.billingAddress().city());
        order.setBillingState(request.billingAddress().state());
        order.setBillingPostalCode(request.billingAddress().postalCode());
        order.setBillingCountry(request.billingAddress().country());

        // Set customer info
        order.setCustomerEmail(request.customerEmail());
        order.setCustomerPhone(request.customerPhone());
        order.setNotes(request.notes());

        // Convert cart items to order items
        for (CartItem cartItem : cart.getItems()) {
            OrderItem orderItem = new OrderItem();
            orderItem.setProduct(cartItem.getProduct());
            orderItem.setProductName(cartItem.getProduct().getName());
            orderItem.setProductSku(cartItem.getProduct().getSku());
            orderItem.setQuantity(cartItem.getQuantity());
            orderItem.setPrice(cartItem.getPriceAtAddition());
            
            order.addItem(orderItem);
        }

        // Create payment record with PENDING status
        Payment payment = new Payment();
        payment.setPaymentMethod(request.paymentMethod());
        payment.setAmount(totalAmount);
        payment.setPaymentStatus(PaymentStatus.PENDING);
        order.setPayment(payment);

        // Save order (status remains PENDING until payment)
        Order savedOrder = orderRepository.save(order);

        // Clear cart after order creation
        cart.getItems().clear();
        cartRepository.save(cart);

        log.info("Order created successfully with PENDING status: {}", savedOrder.getOrderNumber());
        return orderMapper.toOrderResponse(savedOrder);
    }

    /**
     * Process payment for an order (Step 2: Payment processing for card payments)
     */
    @Transactional
    public OrderResponse processPayment(String orderId, PaymentDetailsRequest paymentDetails) {
        User currentUser = getCurrentUser();
        log.info("Processing payment for order: {}", orderId);

        Order order = orderRepository.findByPublicId(orderId)
                .orElseThrow(() -> OrderNotFoundException.byId(orderId));

        // Authorization: only order owner can pay
        if (!order.getUser().getId().equals(currentUser.getId())) {
            throw OrderNotFoundException.byId(orderId);
        }

        // Validate order can be paid
        if (order.getStatus() != OrderStatus.PENDING) {
            throw new IllegalStateException("Order is not in PENDING status");
        }

        Payment payment = order.getPayment();
        if (payment.getPaymentStatus() != PaymentStatus.PENDING) {
            throw new IllegalStateException("Payment already processed");
        }

        // Only process payment for card-based methods
        if (payment.getPaymentMethod() == com.saveitforlater.ecommerce.persistence.entity.order.PaymentMethod.CASH_ON_DELIVERY) {
            throw new IllegalStateException("Cash on delivery orders cannot use this endpoint");
        }

        // Re-validate stock before payment
        validateStockForOrder(order);

        // Process payment using dummy gateway
        boolean paymentSuccess = processDummyPayment(payment, paymentDetails);

        if (paymentSuccess) {
            // Update order status to CONFIRMED
            order.setStatus(OrderStatus.CONFIRMED);
            
            // Reduce stock quantities
            reduceStockForOrder(order);
            
            log.info("Payment successful for order: {}", order.getOrderNumber());
        } else {
            log.warn("Payment failed for order: {}", order.getOrderNumber());
        }

        Order updatedOrder = orderRepository.save(order);
        return orderMapper.toOrderResponse(updatedOrder);
    }

    /**
     * Get order by ID (accessible to order owner or admin)
     */
    @Transactional(readOnly = true)
    public OrderResponse getOrderById(String orderId) {
        User currentUser = getCurrentUser();
        log.debug("Fetching order with ID: {} for user: {}", orderId, currentUser.getEmail());

        Order order = orderRepository.findByPublicId(orderId)
                .orElseThrow(() -> OrderNotFoundException.byId(orderId));

        // Authorization: user can only access their own orders unless they're admin
        if (!order.getUser().getId().equals(currentUser.getId()) && 
            !currentUser.getRole().name().equals("ADMIN")) {
            throw OrderNotFoundException.byId(orderId);
        }

        return orderMapper.toOrderResponse(order);
    }

    /**
     * Get all orders for current user
     */
    @Transactional(readOnly = true)
    public List<OrderResponse> getMyOrders() {
        User currentUser = getCurrentUser();
        log.debug("Fetching orders for user: {}", currentUser.getEmail());

        List<Order> orders = orderRepository.findByUserOrderByCreatedAtDesc(currentUser);
        return orders.stream()
                .map(orderMapper::toOrderResponse)
                .collect(Collectors.toList());
    }

    /**
     * Get all orders (admin only)
     */
    @Transactional(readOnly = true)
    public List<OrderResponse> getAllOrders() {
        log.debug("Fetching all orders (admin)");
        List<Order> orders = orderRepository.findAll();
        return orders.stream()
                .map(orderMapper::toOrderResponse)
                .collect(Collectors.toList());
    }

    /**
     * Update order status (admin only)
     */
    @Transactional
    public OrderResponse updateOrderStatus(String orderId, OrderStatus newStatus) {
        log.info("Updating order {} status to {}", orderId, newStatus);

        Order order = orderRepository.findByPublicId(orderId)
                .orElseThrow(() -> OrderNotFoundException.byId(orderId));

        order.setStatus(newStatus);
        Order updatedOrder = orderRepository.save(order);

        log.info("Order status updated successfully");
        return orderMapper.toOrderResponse(updatedOrder);
    }

    /**
     * Update payment status (admin only - for COD orders)
     */
    @Transactional
    public OrderResponse updatePaymentStatus(String orderId, PaymentStatus newPaymentStatus) {
        log.info("Updating payment status for order {} to {}", orderId, newPaymentStatus);

        Order order = orderRepository.findByPublicId(orderId)
                .orElseThrow(() -> OrderNotFoundException.byId(orderId));

        Payment payment = order.getPayment();
        PaymentStatus oldStatus = payment.getPaymentStatus();
        payment.setPaymentStatus(newPaymentStatus);

        // If payment confirmed for first time, reduce stock and update order status
        if (oldStatus != PaymentStatus.COMPLETED && newPaymentStatus == PaymentStatus.COMPLETED) {
            validateStockForOrder(order);
            reduceStockForOrder(order);
            order.setStatus(OrderStatus.CONFIRMED);
            payment.setPaymentDate(Instant.now());
            payment.setTransactionId("COD-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase());
        }

        Order updatedOrder = orderRepository.save(order);
        log.info("Payment status updated successfully");
        return orderMapper.toOrderResponse(updatedOrder);
    }

    /**
     * Validate stock availability and calculate total amount
     */
    private BigDecimal validateStockAndCalculateTotal(Cart cart) {
        BigDecimal total = BigDecimal.ZERO;

        for (CartItem cartItem : cart.getItems()) {
            Product product = cartItem.getProduct();
            
            // Check stock availability
            if (product.getStockQuantity() < cartItem.getQuantity()) {
                throw InsufficientStockException.forProduct(
                        product.getName(), 
                        cartItem.getQuantity(), 
                        product.getStockQuantity()
                );
            }

            // Calculate subtotal
            BigDecimal subtotal = cartItem.getPriceAtAddition()
                    .multiply(BigDecimal.valueOf(cartItem.getQuantity()));
            total = total.add(subtotal);
        }

        return total;
    }

    /**
     * Validate stock for an existing order
     */
    private void validateStockForOrder(Order order) {
        for (OrderItem orderItem : order.getItems()) {
            Product product = orderItem.getProduct();
            if (product.getStockQuantity() < orderItem.getQuantity()) {
                throw InsufficientStockException.forProduct(
                        product.getName(),
                        orderItem.getQuantity(),
                        product.getStockQuantity()
                );
            }
        }
    }

    /**
     * Reduce stock quantities for products in the order
     */
    private void reduceStockForOrder(Order order) {
        for (OrderItem orderItem : order.getItems()) {
            Product product = orderItem.getProduct();
            int newStock = product.getStockQuantity() - orderItem.getQuantity();
            product.setStockQuantity(newStock);
            productRepository.save(product);
        }
    }

    /**
     * Process payment using dummy gateway
     * Returns true if payment successful, false otherwise
     */
    private boolean processDummyPayment(Payment payment, PaymentDetailsRequest paymentDetails) {
        log.info("Processing payment using dummy gateway");

        payment.setPaymentGateway("DUMMY_GATEWAY");

        // Simulate payment processing with dummy credentials
        try {
            // Extract card details
            String cardNumber = paymentDetails.cardNumber();
            String cardBrand = determineCardBrand(cardNumber);
            String cardLastFour = cardNumber.substring(cardNumber.length() - 4);

            // Dummy validation - accept all cards except those ending in "0000"
            if (cardLastFour.equals("0000")) {
                payment.setPaymentStatus(PaymentStatus.FAILED);
                log.warn("Dummy payment failed: Card ending in 0000 is rejected");
                return false;
            } else {
                // Simulate successful payment
                payment.setPaymentStatus(PaymentStatus.COMPLETED);
                payment.setTransactionId("TXN-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase());
                payment.setPaymentDate(Instant.now());
                payment.setCardLastFour(cardLastFour);
                payment.setCardBrand(cardBrand);
                log.info("Dummy payment successful: Transaction ID: {}", payment.getTransactionId());
                return true;
            }

        } catch (Exception e) {
            log.error("Payment processing error: {}", e.getMessage());
            payment.setPaymentStatus(PaymentStatus.FAILED);
            return false;
        }
    }

    /**
     * Determine card brand from card number (dummy logic)
     */
    private String determineCardBrand(String cardNumber) {
        if (cardNumber.startsWith("4")) {
            return "VISA";
        } else if (cardNumber.startsWith("5")) {
            return "MASTERCARD";
        } else if (cardNumber.startsWith("3")) {
            return "AMEX";
        } else {
            return "UNKNOWN";
        }
    }

    /**
     * Get current authenticated user
     */
    private User getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return (User) authentication.getPrincipal();
    }
}

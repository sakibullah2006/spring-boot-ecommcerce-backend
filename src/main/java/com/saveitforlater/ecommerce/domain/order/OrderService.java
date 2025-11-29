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
     * Create order from current user's cart
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

        // Create order
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

        // Process payment
        Payment payment = processPayment(order, request.paymentMethod(), request.paymentDetails());
        order.setPayment(payment);

        // Update order status based on payment
        if (payment.getPaymentStatus() == PaymentStatus.COMPLETED) {
            order.setStatus(OrderStatus.CONFIRMED);
            
            // Reduce stock quantities
            reduceStock(cart);
        } else {
            order.setStatus(OrderStatus.PENDING);
        }

        // Save order
        Order savedOrder = orderRepository.save(order);

        // Clear cart after successful order
        if (payment.getPaymentStatus() == PaymentStatus.COMPLETED) {
            cart.getItems().clear();
            cartRepository.save(cart);
        }

        log.info("Order created successfully: {}", savedOrder.getOrderNumber());
        return orderMapper.toOrderResponse(savedOrder);
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
     * Reduce stock quantities for products in the order
     */
    private void reduceStock(Cart cart) {
        for (CartItem cartItem : cart.getItems()) {
            Product product = cartItem.getProduct();
            int newStock = product.getStockQuantity() - cartItem.getQuantity();
            product.setStockQuantity(newStock);
            productRepository.save(product);
        }
    }

    /**
     * Process payment using dummy gateway
     */
    private Payment processPayment(Order order, 
                                  com.saveitforlater.ecommerce.persistence.entity.order.PaymentMethod paymentMethod,
                                  PaymentDetailsRequest paymentDetails) {
        log.info("Processing payment for order using dummy gateway");

        Payment payment = new Payment();
        payment.setPaymentMethod(paymentMethod);
        payment.setAmount(order.getTotalAmount());
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
            } else {
                // Simulate successful payment
                payment.setPaymentStatus(PaymentStatus.COMPLETED);
                payment.setTransactionId("TXN-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase());
                payment.setPaymentDate(Instant.now());
                payment.setCardLastFour(cardLastFour);
                payment.setCardBrand(cardBrand);
                log.info("Dummy payment successful: Transaction ID: {}", payment.getTransactionId());
            }

        } catch (Exception e) {
            log.error("Payment processing error: {}", e.getMessage());
            payment.setPaymentStatus(PaymentStatus.FAILED);
        }

        return payment;
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

package com.saveitforlater.ecommerce.persistence.entity.order;

import com.saveitforlater.ecommerce.persistence.entity.user.User;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "orders")
@Getter
@Setter
@NoArgsConstructor
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, updatable = false, length = 36)
    private String publicId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, unique = true, length = 50)
    private String orderNumber;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private OrderStatus status;

    @Column(nullable = false, precision = 19, scale = 2)
    private BigDecimal totalAmount;

    // Shipping Address
    @Column(nullable = false)
    private String shippingAddressLine1;

    private String shippingAddressLine2;

    @Column(nullable = false, length = 100)
    private String shippingCity;

    @Column(nullable = false, length = 100)
    private String shippingState;

    @Column(nullable = false, length = 20)
    private String shippingPostalCode;

    @Column(nullable = false, length = 100)
    private String shippingCountry;

    // Billing Address
    @Column(nullable = false)
    private String billingAddressLine1;

    private String billingAddressLine2;

    @Column(nullable = false, length = 100)
    private String billingCity;

    @Column(nullable = false, length = 100)
    private String billingState;

    @Column(nullable = false, length = 20)
    private String billingPostalCode;

    @Column(nullable = false, length = 100)
    private String billingCountry;

    // Customer Contact Info
    @Column(nullable = false)
    private String customerEmail;

    @Column(length = 20)
    private String customerPhone;

    @Lob
    private String notes;

    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<OrderItem> items = new ArrayList<>();

    @OneToOne(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true)
    private Payment payment;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    public void prePersist() {
        if (this.publicId == null) {
            this.publicId = UUID.randomUUID().toString();
        }
        if (this.orderNumber == null) {
            this.orderNumber = generateOrderNumber();
        }
        if (this.status == null) {
            this.status = OrderStatus.PENDING;
        }
    }

    // Helper methods for managing order items
    public void addItem(OrderItem item) {
        items.add(item);
        item.setOrder(this);
    }

    public void removeItem(OrderItem item) {
        items.remove(item);
        item.setOrder(null);
    }

    public void setPayment(Payment payment) {
        this.payment = payment;
        if (payment != null) {
            payment.setOrder(this);
        }
    }

    private String generateOrderNumber() {
        // Format: ORD-YYYYMMDD-RANDOM (e.g., ORD-20250129-A3F9)
        String datePart = String.format("%tY%<tm%<td", System.currentTimeMillis());
        String randomPart = UUID.randomUUID().toString().substring(0, 4).toUpperCase();
        return String.format("ORD-%s-%s", datePart, randomPart);
    }
}

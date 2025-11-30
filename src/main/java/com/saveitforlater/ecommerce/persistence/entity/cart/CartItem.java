package com.saveitforlater.ecommerce.persistence.entity.cart;

import com.saveitforlater.ecommerce.persistence.entity.product.Product;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "cart_item", uniqueConstraints = {
        @UniqueConstraint(columnNames = {"cart_id", "product_id"})
})
@Getter
@Setter
@NoArgsConstructor
public class CartItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, updatable = false, length = 36)
    private String publicId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "cart_id", nullable = false)
    private Cart cart;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "product_id", nullable = false)
    private Product product;

    @Column(nullable = false)
    private Integer quantity;

    @Column(nullable = false, precision = 19, scale = 2)
    private BigDecimal priceAtAddition;

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
    }

    // Constructor for convenience
    public CartItem(Cart cart, Product product, Integer quantity, BigDecimal priceAtAddition) {
        this.cart = cart;
        this.product = product;
        this.quantity = quantity;
        this.priceAtAddition = priceAtAddition;
    }

    // Calculate subtotal
    public BigDecimal getSubtotal() {
        return priceAtAddition.multiply(BigDecimal.valueOf(quantity));
    }

    // Get current product price (might be different from priceAtAddition)
    public BigDecimal getCurrentPrice() {
        return product.getSalePrice().compareTo(BigDecimal.ZERO) > 0 
                ? product.getSalePrice() 
                : product.getPrice();
    }
}

package com.saveitforlater.ecommerce.persistence.entity.product;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;

/**
 * Junction entity that represents a specific attribute-value combination for a product.
 * This allows products to have different combinations of attributes and their values.
 * Examples: Product A has Color=Red, Size=Large; Product B has Color=Blue, Size=Medium
 */
@Entity
@Table(name = "product_attribute_value",
       uniqueConstraints = {
           @UniqueConstraint(columnNames = {"product_id", "attribute_id", "attribute_option_id"})
       })
@Getter
@Setter
@NoArgsConstructor
public class ProductAttributeValue {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id", nullable = false)
    private Product product;

    @ManyToOne(fetch = FetchType.LAZY, cascade = {CascadeType.PERSIST, CascadeType.MERGE})
    @JoinColumn(name = "attribute_id", nullable = false)
    private Attribute attribute;

    @ManyToOne(fetch = FetchType.LAZY, cascade = {CascadeType.PERSIST, CascadeType.MERGE})
    @JoinColumn(name = "attribute_option_id", nullable = false)
    private AttributeOption attributeOption;

    @Column(nullable = false)
    private boolean isActive = true; // Allow soft deletion

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    // Constructor for easy creation
    public ProductAttributeValue(Product product, Attribute attribute, AttributeOption attributeOption) {
        this.product = product;
        this.attribute = attribute;
        this.attributeOption = attributeOption;
    }
}
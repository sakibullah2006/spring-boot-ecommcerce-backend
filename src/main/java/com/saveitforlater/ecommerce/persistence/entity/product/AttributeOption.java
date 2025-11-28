package com.saveitforlater.ecommerce.persistence.entity.product;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.util.UUID;

/**
 * Represents a reusable attribute option that can be used with different attributes.
 * Examples: "Red", "Large", "Cotton", "Nike"
 */
@Entity
@Table(name = "attribute_option",
       uniqueConstraints = {
           @UniqueConstraint(columnNames = {"attribute_id", "name"}),
           @UniqueConstraint(columnNames = {"attribute_id", "slug"})
       })
@Getter
@Setter
@NoArgsConstructor
public class AttributeOption {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, updatable = false, length = 36)
    private String publicId;

    @Column(nullable = false, length = 100)
    private String name; // e.g., "Red", "Large", "Cotton", "Nike"

    @Column(nullable = false, length = 100)
    private String slug; // e.g., "red", "large", "cotton", "nike"

    @Column(length = 500)
    private String description; // Optional description for the option

    @Column(nullable = false)
    private boolean isActive = true; // Allow soft deletion

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "attribute_id", nullable = false)
    private Attribute attribute;

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
}


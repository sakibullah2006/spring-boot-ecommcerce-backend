package com.saveitforlater.ecommerce.persistence.entity.product;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Represents a reusable attribute definition that can be used across multiple products.
 * Examples: "Color", "Size", "Material", "Brand"
 */
@Entity
@Table(name = "attribute", 
       uniqueConstraints = {
           @UniqueConstraint(columnNames = {"name"}),
           @UniqueConstraint(columnNames = {"slug"})
       })
@Getter
@Setter
@NoArgsConstructor
public class Attribute {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, updatable = false, length = 36)
    private String publicId;

    @Column(nullable = false, unique = true, length = 100)
    private String name; // e.g., "Color", "Size", "Material"

    @Column(nullable = false, unique = true, length = 100)
    private String slug; // e.g., "color", "size", "material"

    @Column(length = 500)
    private String description; // Optional description for the attribute

    @Column(nullable = false)
    private boolean isActive = true; // Allow soft deletion

    @OneToMany(mappedBy = "attribute", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<AttributeOption> options = new ArrayList<>();

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    // Helper methods
    public void addOption(AttributeOption option) {
        if (!options.contains(option)) {
            options.add(option);
            option.setAttribute(this);
        }
    }

    public void removeOption(AttributeOption option) {
        options.remove(option);
        option.setAttribute(null);
    }

    @PrePersist
    public void prePersist() {
        if (this.publicId == null) {
            this.publicId = UUID.randomUUID().toString();
        }
    }
}
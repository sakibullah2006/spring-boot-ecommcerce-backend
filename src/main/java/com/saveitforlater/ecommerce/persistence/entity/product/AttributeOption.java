package com.saveitforlater.ecommerce.persistence.entity.product;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "attribute_option")
@Getter
@Setter
@NoArgsConstructor
public class AttributeOption {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name; // e.g., "S", "M", "L", "XL" or "Red", "Green", "Blue"

    @Column(nullable = false)
    private String slug; // e.g., "s", "m", "l", "xl" or "red", "green", "blue"

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "attribute_id", nullable = false)
    private ProductAttribute attribute;
}


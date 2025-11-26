package com.saveitforlater.ecommerce.persistence.entity.product;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "product_attribute")
@Getter
@Setter
@NoArgsConstructor
public class ProductAttribute {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name; // e.g., "size" or "color"

    @Column(nullable = false)
    private String slug; // e.g., "size" or "color"

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id", nullable = false)
    private Product product;

    @OneToMany(mappedBy = "attribute", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<AttributeOption> options = new ArrayList<>();

    public void addOption(AttributeOption option) {
        options.add(option);
        option.setAttribute(this);
    }

    public void removeOption(AttributeOption option) {
        options.remove(option);
        option.setAttribute(null);
    }
}



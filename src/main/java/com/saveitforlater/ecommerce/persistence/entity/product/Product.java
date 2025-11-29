package com.saveitforlater.ecommerce.persistence.entity.product;



import com.saveitforlater.ecommerce.persistence.entity.category.Category;
import com.saveitforlater.ecommerce.persistence.entity.file.ProductImage;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Entity
@Table(name = "product")
@Getter
@Setter
@NoArgsConstructor // Required by JPA
public class Product {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, updatable = false, length = 36)
    private String publicId;

    @Column(nullable = false, unique = true)
    private String sku;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false, unique = true)
    private String slug;

    @Column(length = 500)
    private String shortDescription;

    @Lob
    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(nullable = false, precision = 19, scale = 2)
    private BigDecimal price;

    @Column(nullable = false, precision = 19, scale = 2)
    private BigDecimal salePrice;

    @Column(nullable = false)
    private int stockQuantity = 0;

    // This is the "owning" side of the relationship.
    // Hibernate will automatically create the "product_category" join table.
    @ManyToMany(cascade = {CascadeType.PERSIST, CascadeType.MERGE})
    @JoinTable(
            name = "product_category",
            joinColumns = @JoinColumn(name = "product_id"),
            inverseJoinColumns = @JoinColumn(name = "category_id")
    )
    private Set<Category> categories = new HashSet<>();

    // Product attributes using the new reusable system
    @OneToMany(mappedBy = "product", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<ProductAttributeValue> attributeValues = new ArrayList<>();

    // Product images
    @OneToMany(mappedBy = "product", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<ProductImage> images = new ArrayList<>();

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

    // Helper methods for managing attribute values
    public void addAttributeValue(ProductAttributeValue attributeValue) {
        attributeValues.add(attributeValue);
        attributeValue.setProduct(this);
    }

    public void removeAttributeValue(ProductAttributeValue attributeValue) {
        attributeValues.remove(attributeValue);
        attributeValue.setProduct(null);
    }

    public void addAttributeValue(Attribute attribute, AttributeOption option) {
        ProductAttributeValue attributeValue = new ProductAttributeValue(this, attribute, option);
        addAttributeValue(attributeValue);
    }

    public void removeAttributeValue(Attribute attribute, AttributeOption option) {
        attributeValues.removeIf(av -> 
            av.getAttribute().equals(attribute) && av.getAttributeOption().equals(option));
    }
}

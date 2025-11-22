
package com.saveitforlater.ecommerce.persistence.entity.category;
import com.saveitforlater.ecommerce.persistence.entity.product.Product;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.util.Set;
import java.util.UUID;

@Entity
@Table(name = "category")
@Getter
@Setter
@NoArgsConstructor
public class Category {
    @Id
    private Long id;

    @Column(nullable = false, unique = true, updatable = false)
    private UUID publicId;

    @Column(unique = true)
    private String name;

    @ManyToMany(mappedBy = "categories")
    private Set<Product> products;

    @PrePersist
    public void prePersist() {
        if (this.publicId == null) {
            this.publicId = UUID.randomUUID();
        }
    }
}
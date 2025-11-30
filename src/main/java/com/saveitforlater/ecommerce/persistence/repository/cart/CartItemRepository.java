package com.saveitforlater.ecommerce.persistence.repository.cart;

import com.saveitforlater.ecommerce.persistence.entity.cart.Cart;
import com.saveitforlater.ecommerce.persistence.entity.cart.CartItem;
import com.saveitforlater.ecommerce.persistence.entity.product.Product;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CartItemRepository extends JpaRepository<CartItem, Long> {

    Optional<CartItem> findByPublicId(String publicId);
    
    Optional<CartItem> findByCartAndProduct(Cart cart, Product product);
    
    Page<CartItem> findByCart(Cart cart, Pageable pageable);
    
    void deleteByCart(Cart cart);
}

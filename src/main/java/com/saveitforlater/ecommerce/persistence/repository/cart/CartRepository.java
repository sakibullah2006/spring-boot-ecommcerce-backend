package com.saveitforlater.ecommerce.persistence.repository.cart;

import com.saveitforlater.ecommerce.persistence.entity.cart.Cart;
import com.saveitforlater.ecommerce.persistence.entity.user.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CartRepository extends JpaRepository<Cart, Long> {

    Optional<Cart> findByPublicId(String publicId);
    
    Optional<Cart> findByUser(User user);
    
    Optional<Cart> findByUserPublicId(String userPublicId);
}

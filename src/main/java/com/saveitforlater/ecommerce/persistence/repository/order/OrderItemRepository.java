package com.saveitforlater.ecommerce.persistence.repository.order;

import com.saveitforlater.ecommerce.persistence.entity.order.OrderItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface OrderItemRepository extends JpaRepository<OrderItem, Long> {

    Optional<OrderItem> findByPublicId(String publicId);
}

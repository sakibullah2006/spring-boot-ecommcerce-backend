package com.saveitforlater.ecommerce.persistence.repository.order;

import com.saveitforlater.ecommerce.persistence.entity.order.Order;
import com.saveitforlater.ecommerce.persistence.entity.user.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {

    Optional<Order> findByPublicId(String publicId);

    Optional<Order> findByOrderNumber(String orderNumber);

    List<Order> findByUser(User user);

    @Query("SELECT o FROM Order o WHERE o.user.publicId = :userPublicId ORDER BY o.createdAt DESC")
    List<Order> findByUserPublicId(@Param("userPublicId") String userPublicId);

    @Query("SELECT o FROM Order o WHERE o.user.publicId = :userPublicId ORDER BY o.createdAt DESC")
    Page<Order> findByUserPublicIdPaginated(@Param("userPublicId") String userPublicId, Pageable pageable);

    @Query("SELECT o FROM Order o WHERE o.user = :user ORDER BY o.createdAt DESC")
    List<Order> findByUserOrderByCreatedAtDesc(@Param("user") User user);
    
    @Query("SELECT o FROM Order o WHERE o.user = :user ORDER BY o.createdAt DESC")
    Page<Order> findByUserOrderByCreatedAtDesc(@Param("user") User user, Pageable pageable);
    
    @Query("SELECT o FROM Order o ORDER BY o.createdAt DESC")
    Page<Order> findAllByOrderByCreatedAtDesc(Pageable pageable);
}

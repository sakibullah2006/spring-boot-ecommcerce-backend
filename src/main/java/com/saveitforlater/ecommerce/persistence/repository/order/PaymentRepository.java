package com.saveitforlater.ecommerce.persistence.repository.order;

import com.saveitforlater.ecommerce.persistence.entity.order.Payment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface PaymentRepository extends JpaRepository<Payment, Long> {

    Optional<Payment> findByPublicId(String publicId);

    Optional<Payment> findByTransactionId(String transactionId);
}

package com.saveitforlater.ecommerce.persistence.repository.user;

import com.saveitforlater.ecommerce.persistence.entity.user.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    // This is the method Spring Security will use to load the user
    Optional<User> findByEmail(String email);

    Optional<User> findByPublicId(String publicId);
}
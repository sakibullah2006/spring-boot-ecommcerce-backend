package com.saveitforlater.ecommerce.domain.auth;

import com.saveitforlater.ecommerce.api.auth.dto.RegistrationRequest;
import com.saveitforlater.ecommerce.api.auth.dto.UserResponse;
import com.saveitforlater.ecommerce.api.auth.mapper.UserMapper;
import com.saveitforlater.ecommerce.domain.auth.exception.UserAlreadyExistsException;
import com.saveitforlater.ecommerce.persistence.entity.user.User;
import com.saveitforlater.ecommerce.persistence.repository.user.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final UserMapper userMapper;

    @Transactional
    public UserResponse register(RegistrationRequest request) {
        log.info("Attempting to register user with email: {}", request.email());

        if (userRepository.findByEmail(request.email()).isPresent()) {
            log.warn("Registration failed - user already exists with email: {}", request.email());
            throw new UserAlreadyExistsException(request.email());
        }

        try {
            User user = User.builder()
                    .firstName(request.firstName())
                    .lastName(request.lastName())
                    .email(request.email())
                    .password(passwordEncoder.encode(request.password()))
                    .role(User.Role.CUSTOMER) // Default to CUSTOMER role
                    .build();

            // publicId is generated automatically by the entity
            user = userRepository.save(user);

            log.info("User registered successfully with email: {} and publicId: {}",
                    user.getEmail(), user.getPublicId());

            return userMapper.toUserResponse(user);

        } catch (Exception e) {
            log.error("Error occurred during user registration for email: {}", request.email(), e);
            throw new RuntimeException("Registration failed due to an unexpected error", e);
        }
    }

    public boolean userExists(String email) {
        try {
            return userRepository.findByEmail(email).isPresent();
        } catch (Exception e) {
            log.error("Error checking if user exists for email: {}", email, e);
            return false;
        }
    }
}
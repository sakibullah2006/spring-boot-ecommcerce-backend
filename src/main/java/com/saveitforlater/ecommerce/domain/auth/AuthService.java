package com.saveitforlater.ecommerce.domain.auth;

import com.saveitforlater.ecommerce.api.auth.dto.RegistrationRequest;
import com.saveitforlater.ecommerce.api.auth.dto.UserResponse;
import com.saveitforlater.ecommerce.api.auth.mapper.UserMapper;
import com.saveitforlater.ecommerce.persistence.entity.user.User;
import com.saveitforlater.ecommerce.persistence.repository.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final UserMapper userMapper;

    @Transactional
    public UserResponse register(RegistrationRequest request) {

        if (userRepository.findByEmail(request.email()).isPresent()) {
            // This should be a more specific, handled exception
            throw new IllegalArgumentException("User with this email already exists");
        }

        User user = User.builder()
                .firstName(request.firstName())
                .lastName(request.lastName())
                .email(request.email())
                .password(passwordEncoder.encode(request.password()))
                .role(User.Role.CUSTOMER) // Default to USER role
                .build();

        // publicId is generated automatically by the entity
        user = userRepository.save(user);

        return userMapper.toUserResponse(user);
    }
}
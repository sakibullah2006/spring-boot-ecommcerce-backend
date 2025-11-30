package com.saveitforlater.ecommerce.domain.user;

import com.saveitforlater.ecommerce.api.auth.dto.UserResponse;
import com.saveitforlater.ecommerce.api.auth.mapper.UserMapper;
import com.saveitforlater.ecommerce.api.user.dto.CreateUserRequest;
import com.saveitforlater.ecommerce.api.user.dto.UpdateUserRequest;
import com.saveitforlater.ecommerce.api.user.dto.UserDetailResponse;
import com.saveitforlater.ecommerce.domain.auth.exception.UserAlreadyExistsException;
import com.saveitforlater.ecommerce.domain.user.exception.UserNotFoundException;
import com.saveitforlater.ecommerce.persistence.entity.user.User;
import com.saveitforlater.ecommerce.persistence.repository.user.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserService {

    private final UserRepository userRepository;
    private final UserMapper userMapper;
    private final PasswordEncoder passwordEncoder;

    /**
     * Get all users - ADMIN ONLY
     */
    public List<UserDetailResponse> getAllUsers() {
        log.debug("Fetching all users");
        return userRepository.findAll()
                .stream()
                .map(userMapper::toUserDetailResponse)
                .collect(Collectors.toList());
    }

    /**
     * Get paginated users - ADMIN ONLY
     */
    public Page<UserDetailResponse> getUsers(Pageable pageable) {
        log.debug("Fetching users with pagination: {}", pageable);
        return userRepository.findAll(pageable)
                .map(userMapper::toUserDetailResponse);
    }

    /**
     * Get user by public ID - ADMIN or SELF
     */
    public UserDetailResponse getUserById(String publicId) {
        log.debug("Fetching user by ID: {}", publicId);
        User user = userRepository.findByPublicId(publicId)
                .orElseThrow(() -> UserNotFoundException.byPublicId(publicId));
        return userMapper.toUserDetailResponse(user);
    }

    /**
     * Get user by email - ADMIN ONLY (for internal use)
     */
    public UserDetailResponse getUserByEmail(String email) {
        log.debug("Fetching user by email: {}", email);
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> UserNotFoundException.byEmail(email));
        return userMapper.toUserDetailResponse(user);
    }

    /**
     * Create a new user - ADMIN ONLY
     */
    @Transactional
    public UserDetailResponse createUser(CreateUserRequest request) {
        log.info("Creating new user with email: {}", request.email());

        // Check if user already exists
        if (userRepository.findByEmail(request.email()).isPresent()) {
            throw new UserAlreadyExistsException(request.email());
        }

        // Build user entity
        User user = User.builder()
                .firstName(request.firstName().trim())
                .lastName(request.lastName().trim())
                .email(request.email().toLowerCase().trim())
                .password(passwordEncoder.encode(request.password()))
                .role(request.role() != null ? User.Role.valueOf(request.role()) : User.Role.CUSTOMER)
                .build();

        user = userRepository.save(user);
        log.info("Successfully created user: {} (ID: {})", user.getEmail(), user.getPublicId());

        return userMapper.toUserDetailResponse(user);
    }

    /**
     * Update user - ADMIN or SELF
     */
    @Transactional
    public UserDetailResponse updateUser(String publicId, UpdateUserRequest request) {
        log.info("Updating user: {}", publicId);

        User user = userRepository.findByPublicId(publicId)
                .orElseThrow(() -> UserNotFoundException.byPublicId(publicId));

        // Update fields only if provided
        if (StringUtils.hasText(request.firstName())) {
            user.setFirstName(request.firstName().trim());
        }
        if (StringUtils.hasText(request.lastName())) {
            user.setLastName(request.lastName().trim());
        }
        if (StringUtils.hasText(request.email())) {
            String newEmail = request.email().toLowerCase().trim();
            // Check if email is already taken by another user
            if (!user.getEmail().equals(newEmail) && userRepository.findByEmail(newEmail).isPresent()) {
                throw new UserAlreadyExistsException(newEmail);
            }
            user.setEmail(newEmail);
        }
        if (StringUtils.hasText(request.password())) {
            user.setPassword(passwordEncoder.encode(request.password()));
            log.debug("Password updated for user: {}", publicId);
        }
        if (StringUtils.hasText(request.role())) {
            user.setRole(User.Role.valueOf(request.role()));
            log.debug("Role updated for user: {} to {}", publicId, request.role());
        }

        user = userRepository.save(user);
        log.info("Successfully updated user: {}", publicId);

        return userMapper.toUserDetailResponse(user);
    }

    /**
     * Delete user - ADMIN ONLY
     */
    @Transactional
    public void deleteUser(String publicId) {
        log.info("Deleting user: {}", publicId);

        User user = userRepository.findByPublicId(publicId)
                .orElseThrow(() -> UserNotFoundException.byPublicId(publicId));

        userRepository.delete(user);
        log.info("Successfully deleted user: {}", publicId);
    }

    /**
     * Get current authenticated user's profile
     */
    public UserResponse getCurrentUser(String email) {
        log.debug("Fetching current user profile: {}", email);
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> UserNotFoundException.byEmail(email));
        return userMapper.toUserResponse(user);
    }

    /**
     * Check if user exists by email
     */
    public boolean existsByEmail(String email) {
        return userRepository.findByEmail(email).isPresent();
    }

    /**
     * Check if user exists by public ID
     */
    public boolean existsByPublicId(String publicId) {
        return userRepository.findByPublicId(publicId).isPresent();
    }
}

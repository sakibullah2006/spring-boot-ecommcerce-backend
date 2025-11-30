package com.saveitforlater.ecommerce.api.user;

import com.saveitforlater.ecommerce.api.auth.dto.UserResponse;
import com.saveitforlater.ecommerce.api.user.dto.CreateUserRequest;
import com.saveitforlater.ecommerce.api.user.dto.UpdateUserRequest;
import com.saveitforlater.ecommerce.api.user.dto.UserDetailResponse;
import com.saveitforlater.ecommerce.domain.user.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Controller for user management operations
 * Provides CRUD endpoints for user administration and profile management
 */
@Slf4j
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    /**
     * Get all users - ADMIN ONLY
     */
    @GetMapping
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<List<UserDetailResponse>> getAllUsers() {
        log.debug("GET /api/users - Fetching all users");
        List<UserDetailResponse> users = userService.getAllUsers();
        return ResponseEntity.ok(users);
    }

    /**
     * Get paginated users - ADMIN ONLY
     */
    @GetMapping("/paginated")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<Page<UserDetailResponse>> getUsers(
            @PageableDefault(size = 20, sort = "createdAt") Pageable pageable) {
        log.debug("GET /api/users/paginated - Fetching users with pagination: {}", pageable);
        Page<UserDetailResponse> users = userService.getUsers(pageable);
        return ResponseEntity.ok(users);
    }

    /**
     * Get current authenticated user's profile
     */
    @GetMapping("/me")
    public ResponseEntity<UserResponse> getCurrentUser(@AuthenticationPrincipal UserDetails userDetails) {
        log.debug("GET /api/users/me - Fetching current user profile");
        String email = userDetails.getUsername();
        UserResponse user = userService.getCurrentUser(email);
        return ResponseEntity.ok(user);
    }

    /**
     * Get user by ID - ADMIN ONLY (for now, could be extended to allow users to view their own profile)
     */
    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<UserDetailResponse> getUserById(@PathVariable String id) {
        log.debug("GET /api/users/{} - Fetching user by ID", id);
        UserDetailResponse user = userService.getUserById(id);
        return ResponseEntity.ok(user);
    }

    /**
     * Create a new user - ADMIN ONLY
     */
    @PostMapping
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<UserDetailResponse> createUser(@Valid @RequestBody CreateUserRequest request) {
        log.info("POST /api/users - Creating new user: {}", request.email());
        UserDetailResponse createdUser = userService.createUser(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(createdUser);
    }

    /**
     * Update user - ADMIN ONLY (for now, could be extended to allow users to update their own profile)
     */
    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<UserDetailResponse> updateUser(
            @PathVariable String id,
            @Valid @RequestBody UpdateUserRequest request) {
        log.info("PUT /api/users/{} - Updating user", id);
        UserDetailResponse updatedUser = userService.updateUser(id, request);
        return ResponseEntity.ok(updatedUser);
    }

    /**
     * Update current user's profile (self-update)
     * Users can update their own firstName, lastName, and password
     * Email and role changes require admin privileges
     */
    @PutMapping("/me")
    public ResponseEntity<UserResponse> updateCurrentUser(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody UpdateSelfRequest request) {
        log.info("PUT /api/users/me - User updating own profile");
        
        String email = userDetails.getUsername();
        
        // Create UpdateUserRequest with limited fields (no email or role changes)
        UpdateUserRequest updateRequest = new UpdateUserRequest(
                request.firstName(),
                request.lastName(),
                null, // Email cannot be changed by user
                request.password(),
                null  // Role cannot be changed by user
        );
        
        // Find user by email to get their publicId
        UserDetailResponse currentUser = userService.getUserByEmail(email);
        UserDetailResponse updatedUser = userService.updateUser(currentUser.id(), updateRequest);
        
        // Return simplified response
        UserResponse response = new UserResponse(
                updatedUser.id(),
                updatedUser.firstName(),
                updatedUser.lastName(),
                updatedUser.email(),
                updatedUser.role()
        );
        
        return ResponseEntity.ok(response);
    }

    /**
     * Delete user - ADMIN ONLY
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<Void> deleteUser(@PathVariable String id) {
        log.info("DELETE /api/users/{} - Deleting user", id);
        userService.deleteUser(id);
        return ResponseEntity.noContent().build();
    }

    /**
     * Check if user exists by email - ADMIN ONLY
     */
    @GetMapping("/exists")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<Boolean> userExists(@RequestParam String email) {
        log.debug("GET /api/users/exists - Checking if user exists: {}", email);
        boolean exists = userService.existsByEmail(email);
        return ResponseEntity.ok(exists);
    }

    // DTO for self-update (limited fields)
    public record UpdateSelfRequest(
            String firstName,
            String lastName,
            String password // Optional - only if changing password
    ) {}
}

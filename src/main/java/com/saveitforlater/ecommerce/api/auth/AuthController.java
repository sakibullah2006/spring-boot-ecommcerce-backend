package com.saveitforlater.ecommerce.api.auth;

import com.saveitforlater.ecommerce.api.auth.dto.LoginRequest;
import com.saveitforlater.ecommerce.api.auth.dto.RegistrationRequest;
import com.saveitforlater.ecommerce.api.auth.dto.UserResponse;
import com.saveitforlater.ecommerce.api.auth.mapper.UserMapper;
import com.saveitforlater.ecommerce.domain.auth.AuthService;
import com.saveitforlater.ecommerce.domain.auth.exception.InvalidCredentialsException;
import com.saveitforlater.ecommerce.persistence.entity.user.User;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.session.SessionInformation;
import org.springframework.security.core.session.SessionRegistry;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.web.context.HttpSessionSecurityContextRepository;
import org.springframework.security.web.context.SecurityContextRepository;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.web.authentication.logout.SecurityContextLogoutHandler;

@Slf4j
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final AuthenticationManager authenticationManager;
    private final UserMapper userMapper;
    private final SessionRegistry sessionRegistry;

    private final SecurityContextRepository securityContextRepository =
            new HttpSessionSecurityContextRepository();

    @PostMapping("/register")
    public ResponseEntity<UserResponse> register(@Valid @RequestBody RegistrationRequest request) {
        log.info("Registration attempt for email: {}", request.email());

        UserResponse userResponse = authService.register(request);

        log.info("User registered successfully: {}", userResponse.email());
        return ResponseEntity.status(HttpStatus.CREATED).body(userResponse);
    }

    @PostMapping("/login")
    public ResponseEntity<UserResponse> login(@Valid @RequestBody LoginRequest request,
                                              HttpServletRequest httpServletRequest,
                                              HttpServletResponse response) {
        log.info("Login attempt for email: {}", request.email());

        try {
            // 1. Authenticate the user
            Authentication authentication = authenticationManager.authenticate(
                    UsernamePasswordAuthenticationToken.unauthenticated(request.email(), request.password())
            );

            // 2. Set the authentication in the security context
            SecurityContext context = SecurityContextHolder.createEmptyContext();
            context.setAuthentication(authentication);
            SecurityContextHolder.setContext(context);

            // This is what persists the authentication between requests.
            securityContextRepository.saveContext(context, httpServletRequest, response);

            // 3. Return the user details
            User user = (User) authentication.getPrincipal();

            log.info("User logged in successfully: {}", user.getEmail());
            return ResponseEntity.ok(userMapper.toUserResponse(user));

        } catch (BadCredentialsException ex) {
            log.warn("Login failed for email: {} - Invalid credentials", request.email());
            throw new InvalidCredentialsException();

        } catch (UsernameNotFoundException ex) {
            log.warn("Login failed for email: {} - User not found", request.email());
            throw new InvalidCredentialsException();

        } catch (AuthenticationException ex) {
            log.warn("Authentication failed for email: {} - {}", request.email(), ex.getMessage());
            throw new InvalidCredentialsException();

        } catch (Exception ex) {
            log.error("Unexpected error during login for email: {}", request.email(), ex);
            throw new RuntimeException("Login failed due to an unexpected error", ex);
        }
    }

    @PostMapping("/logout")
    public ResponseEntity<String> logout(HttpServletRequest request, HttpServletResponse response) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();

        try {
            if (auth != null && auth.getPrincipal() instanceof User user) {
                log.info("Logout attempt for user: {}", user.getEmail());

                // Remove all sessions for this user from the session registry
                for (SessionInformation sessionInfo : sessionRegistry.getAllSessions(user, false)) {
                    sessionInfo.expireNow();
                }

                log.info("User logged out successfully: {}", user.getEmail());
            }

            // Use Spring Security's logout handler to clear the session
            SecurityContextLogoutHandler logoutHandler = new SecurityContextLogoutHandler();
            logoutHandler.logout(request, response, auth);

            // Clear all relevant cookies
            clearCookie(response, "JSESSIONID", "/", request.isSecure());
            clearCookie(response, "XSRF-TOKEN", "/", false);
            clearCookie(response, "SPRING_SECURITY_REMEMBER_ME_COOKIE", "/", request.isSecure());

            // Also invalidate the session if it exists
            if (request.getSession(false) != null) {
                request.getSession().invalidate();
            }

            // Clear the security context
            SecurityContextHolder.clearContext();

            return ResponseEntity.ok("Logged out successfully");

        } catch (Exception ex) {
            log.error("Error during logout", ex);
            // Even if there's an error, we should try to clear the context
            SecurityContextHolder.clearContext();
            return ResponseEntity.ok("Logged out successfully");
        }
    }

    private void clearCookie(HttpServletResponse response, String cookieName, String path, boolean secure) {
        try {
            jakarta.servlet.http.Cookie cookie = new jakarta.servlet.http.Cookie(cookieName, null);
            cookie.setPath(path);
            cookie.setHttpOnly(true);
            cookie.setMaxAge(0); // This deletes the cookie
            cookie.setSecure(secure);
            response.addCookie(cookie);
        } catch (Exception ex) {
            log.warn("Failed to clear cookie: {}", cookieName, ex);
        }
    }

    /**
     * "Who Am I" endpoint.
     * Returns the currently authenticated user or 401 if no session.
     */
    @GetMapping("/session")
    public ResponseEntity<UserResponse> getSession(Authentication authentication) {
        try {
            if (authentication == null || !authentication.isAuthenticated()) {
                log.warn("Session check failed - no authentication");
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
            }

            User user = (User) authentication.getPrincipal();
            log.info("Session check successful for user: {}", user.getEmail());

            return ResponseEntity.ok(userMapper.toUserResponse(user));

        } catch (Exception ex) {
            log.error("Error during session check", ex);
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
    }

    /**
     * Debug endpoint to check if user exists (remove in production)
     */
    @GetMapping("/debug/user-exists")
    public ResponseEntity<String> checkUserExists(@RequestParam String email) {
        try {
            boolean exists = authService.userExists(email);
            log.info("User exists check for email: {} - {}", email, exists);
            return ResponseEntity.ok("User exists: " + exists);
        } catch (Exception ex) {
            log.error("Error checking if user exists for email: {}", email, ex);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Error checking user existence");
        }
    }
}
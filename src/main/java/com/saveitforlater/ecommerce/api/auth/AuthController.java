package com.saveitforlater.ecommerce.api.auth;

import com.saveitforlater.ecommerce.api.auth.dto.LoginRequest;
import com.saveitforlater.ecommerce.api.auth.dto.RegistrationRequest;
import com.saveitforlater.ecommerce.api.auth.dto.UserResponse;
import com.saveitforlater.ecommerce.api.auth.mapper.UserMapper;
import com.saveitforlater.ecommerce.domain.auth.AuthService;
import com.saveitforlater.ecommerce.persistence.entity.user.User;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.session.SessionInformation;
import org.springframework.security.core.session.SessionRegistry;
import org.springframework.security.web.context.HttpSessionSecurityContextRepository;
import org.springframework.security.web.context.SecurityContextRepository;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.web.authentication.logout.SecurityContextLogoutHandler;


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
        UserResponse userResponse = authService.register(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(userResponse);
    }

    @PostMapping("/login")
    public ResponseEntity<UserResponse> login(@Valid @RequestBody LoginRequest request,
                                              HttpServletRequest httpServletRequest, HttpServletResponse response) {
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
            return ResponseEntity.ok(userMapper.toUserResponse(user));

        } catch (Exception e) {
            // Log the actual error for debugging
            System.err.println("Login failed for email: " + request.email() + ". Error: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(null);
        }
    }

    @PostMapping("/logout")
    public ResponseEntity<String> logout(HttpServletRequest request, HttpServletResponse response) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();

        if (auth != null) {
            // Get the current user
            User user = (User) auth.getPrincipal();

            // Remove all sessions for this user from the session registry
            for (SessionInformation sessionInfo : sessionRegistry.getAllSessions(user, false)) {
                sessionInfo.expireNow();
            }
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
    }

    private void clearCookie(HttpServletResponse response, String cookieName, String path, boolean secure) {
        jakarta.servlet.http.Cookie cookie = new jakarta.servlet.http.Cookie(cookieName, null);
        cookie.setPath(path);
        cookie.setHttpOnly(true);
        cookie.setMaxAge(0); // This deletes the cookie
        cookie.setSecure(secure);
        response.addCookie(cookie);
    }

    /**
     * "Who Am I" endpoint.
     * Returns the currently authenticated user or 401 if no session.
     */
    @GetMapping("/session")
    public ResponseEntity<UserResponse> getSession(Authentication authentication) {
        User user = (User) authentication.getPrincipal();
        return ResponseEntity.ok(userMapper.toUserResponse(user));
    }

    /**
     * Debug endpoint to check if user exists (remove in production)
     */
    @GetMapping("/debug/user-exists")
    public ResponseEntity<String> checkUserExists(@RequestParam String email) {
        boolean exists = authService.userExists(email);
        return ResponseEntity.ok("User exists: " + exists);
    }
}
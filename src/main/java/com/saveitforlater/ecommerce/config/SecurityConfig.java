package com.saveitforlater.ecommerce.config; // Your package

import com.saveitforlater.ecommerce.domain.user.UserDetailsServiceImpl;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.ProviderManager;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.session.SessionRegistry;
import org.springframework.security.core.session.SessionRegistryImpl;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;
import java.util.List;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final UserDetailsServiceImpl userDetailsService;

    @Value("${app.frontend.origin}")
    private String frontendOrigin;

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SessionRegistry sessionRegistry() {
        return new SessionRegistryImpl();
    }

    @Bean
    public AuthenticationManager authenticationManager(UserDetailsServiceImpl userDetailsService, PasswordEncoder passwordEncoder) {
        DaoAuthenticationProvider authenticationProvider = new DaoAuthenticationProvider();
        authenticationProvider.setUserDetailsService(userDetailsService);
        authenticationProvider.setPasswordEncoder(passwordEncoder);

        return new ProviderManager(authenticationProvider);
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {

        // 1. Configure CORS
        http.cors(cors -> cors.configurationSource(corsConfigurationSource()));

        // 2. Configure CSRF Protection
//        http.csrf(csrf -> csrf
//                .csrfTokenRepository(CookieCsrfTokenRepository.withHttpOnlyFalse())
//                .csrfTokenRequestHandler(new CsrfTokenRequestAttributeHandler())
//                // *** THIS IS THE FIX ***
//                // We MUST ignore the login and register endpoints.
//                // A user doesn't have a CSRF token before they log in.
//                .ignoringRequestMatchers("*" )
//
//        );
        http.csrf(AbstractHttpConfigurer::disable);

        // 3. Disable Spring Security's default login/logout pages
        http.formLogin(AbstractHttpConfigurer::disable);

        // Configure session management
        http.sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.IF_REQUIRED)
                .sessionFixation().migrateSession() // Protect against session fixation attacks
                .maximumSessions(1)
                .maxSessionsPreventsLogin(false)
                .sessionRegistry(sessionRegistry())
        );

        // 4. Configure Authorization Rules
        http.authorizeHttpRequests(authz -> authz
                // Public endpoints - allow anonymous access
                .requestMatchers("/api/auth/register", "/api/auth/login", "/api/auth/logout").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/products/**", "/api/categories/**", "/api/attributes/**").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/files/**").permitAll()
                .requestMatchers("/api/auth/debug/**").permitAll() // Debug endpoints (remove in production)
                .requestMatchers("/error").permitAll() // Spring Boot error endpoint
                .requestMatchers("/actuator/health").permitAll() // Health check endpoint

                // User management endpoints
                .requestMatchers(HttpMethod.GET, "/api/users/me").authenticated() // Get own profile
                .requestMatchers(HttpMethod.PUT, "/api/users/me").authenticated() // Update own profile
                .requestMatchers("/api/users/**").hasAuthority("ADMIN") // All other user endpoints require admin

                // Secure all other endpoints
                .requestMatchers("/api/orders/**", "/api/cart/**").authenticated()
                .requestMatchers("/api/auth/session").authenticated()
                .requestMatchers("/actuator/**").hasRole("ADMIN") // Admin-only actuator endpoints
                .anyRequest().authenticated()
        );

        // 5. Set our custom UserDetailsService
        http.userDetailsService(userDetailsService);

        // 6. Add custom exception handling for REST API
        http.exceptionHandling(ex -> ex
                // This is called when an unauthenticated user tries to access a protected route.
                .authenticationEntryPoint((request, response, authException) -> {
                    response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                    response.setContentType("application/json");
                    response.setCharacterEncoding("UTF-8");

                    String jsonResponse = String.format(
                        "{\"error\":\"AUTHENTICATION_REQUIRED\",\"message\":\"%s\",\"status\":401,\"timestamp\":\"%s\",\"path\":\"%s\"}",
                        "Authentication required to access this resource",
                        java.time.LocalDateTime.now().toString(),
                        request.getRequestURI()
                    );

                    response.getWriter().write(jsonResponse);
                })
                // This is called when an authenticated user tries to access a route they don't have permission for.
                .accessDeniedHandler((request, response, accessDeniedException) -> {
                    response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                    response.setContentType("application/json");
                    response.setCharacterEncoding("UTF-8");

                    String jsonResponse = String.format(
                        "{\"error\":\"ACCESS_DENIED\",\"message\":\"%s\",\"status\":403,\"timestamp\":\"%s\",\"path\":\"%s\"}",
                        "Access denied - insufficient privileges",
                        java.time.LocalDateTime.now().toString(),
                        request.getRequestURI()
                    );

                    response.getWriter().write(jsonResponse);
                })
        );

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowCredentials(true);
        configuration.setAllowedOrigins(List.of(frontendOrigin));
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(Arrays.asList("Authorization", "Cache-Control", "Content-Type", "X-XSRF-TOKEN"));

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}
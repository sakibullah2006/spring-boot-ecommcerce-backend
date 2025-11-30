package com.saveitforlater.ecommerce.api.cart;

import com.saveitforlater.ecommerce.api.cart.dto.AddToCartRequest;
import com.saveitforlater.ecommerce.api.cart.dto.CartItemResponse;
import com.saveitforlater.ecommerce.api.cart.dto.CartResponse;
import com.saveitforlater.ecommerce.api.cart.dto.UpdateCartItemRequest;
import com.saveitforlater.ecommerce.domain.cart.CartService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@Slf4j
@RestController
@RequestMapping("/api/cart")
@RequiredArgsConstructor
public class CartController {

    private final CartService cartService;

    /**
     * Get current user's cart - accessible to authenticated users
     */
    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<CartResponse> getMyCart() {
        log.debug("GET /api/cart - Fetching current user's cart");
        CartResponse cart = cartService.getMyCart();
        return ResponseEntity.ok(cart);
    }

    /**
     * Get cart by user ID - ADMIN ONLY
     */
    @GetMapping("/user/{userId}")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<CartResponse> getCartByUserId(@PathVariable String userId) {
        log.debug("GET /api/cart/user/{} - Fetching cart by user ID", userId);
        CartResponse cart = cartService.getCartByUserId(userId);
        return ResponseEntity.ok(cart);
    }

    /**
     * Get paginated cart items - accessible to authenticated users
     */
    @GetMapping("/items/paginated")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Page<CartItemResponse>> getMyCartItems(
            @PageableDefault(size = 20, sort = "id") Pageable pageable) {
        log.debug("GET /api/cart/items/paginated - Fetching paginated cart items");
        Page<CartItemResponse> cartItems = cartService.getMyCartItems(pageable);
        return ResponseEntity.ok(cartItems);
    }

    /**
     * Add item to cart - accessible to authenticated users
     */
    @PostMapping("/items")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<CartResponse> addToCart(@Valid @RequestBody AddToCartRequest request) {
        log.info("POST /api/cart/items - Adding item to cart: productId={}, quantity={}", 
                request.productId(), request.quantity());
        CartResponse cart = cartService.addToCart(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(cart);
    }

    /**
     * Update cart item quantity - accessible to authenticated users
     */
    @PutMapping("/items/{cartItemId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<CartResponse> updateCartItem(
            @PathVariable String cartItemId,
            @Valid @RequestBody UpdateCartItemRequest request) {
        log.info("PUT /api/cart/items/{} - Updating cart item quantity to: {}", 
                cartItemId, request.quantity());
        CartResponse cart = cartService.updateCartItem(cartItemId, request);
        return ResponseEntity.ok(cart);
    }

    /**
     * Remove item from cart - accessible to authenticated users
     */
    @DeleteMapping("/items/{cartItemId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<CartResponse> removeCartItem(@PathVariable String cartItemId) {
        log.info("DELETE /api/cart/items/{} - Removing cart item", cartItemId);
        CartResponse cart = cartService.removeCartItem(cartItemId);
        return ResponseEntity.ok(cart);
    }

    /**
     * Clear all items from cart - accessible to authenticated users
     */
    @DeleteMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<CartResponse> clearCart() {
        log.info("DELETE /api/cart - Clearing cart");
        CartResponse cart = cartService.clearCart();
        return ResponseEntity.ok(cart);
    }
}

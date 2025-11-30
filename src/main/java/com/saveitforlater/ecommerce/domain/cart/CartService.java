package com.saveitforlater.ecommerce.domain.cart;

import com.saveitforlater.ecommerce.api.cart.dto.AddToCartRequest;
import com.saveitforlater.ecommerce.api.cart.dto.CartItemResponse;
import com.saveitforlater.ecommerce.api.cart.dto.CartResponse;
import com.saveitforlater.ecommerce.api.cart.dto.UpdateCartItemRequest;
import com.saveitforlater.ecommerce.api.cart.mapper.CartMapper;
import com.saveitforlater.ecommerce.domain.cart.exception.CartItemNotFoundException;
import com.saveitforlater.ecommerce.domain.cart.exception.CartNotFoundException;
import com.saveitforlater.ecommerce.domain.cart.exception.InsufficientStockException;
import com.saveitforlater.ecommerce.domain.product.exception.ProductNotFoundException;
import com.saveitforlater.ecommerce.persistence.entity.cart.Cart;
import com.saveitforlater.ecommerce.persistence.entity.cart.CartItem;
import com.saveitforlater.ecommerce.persistence.entity.product.Product;
import com.saveitforlater.ecommerce.persistence.entity.user.User;
import com.saveitforlater.ecommerce.persistence.repository.cart.CartItemRepository;
import com.saveitforlater.ecommerce.persistence.repository.cart.CartRepository;
import com.saveitforlater.ecommerce.persistence.repository.product.ProductRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;

@Slf4j
@Service
@RequiredArgsConstructor
public class CartService {

    private final CartRepository cartRepository;
    private final CartItemRepository cartItemRepository;
    private final ProductRepository productRepository;
    private final CartMapper cartMapper;

    /**
     * Get the current authenticated user's cart
     */
    @Transactional
    public CartResponse getMyCart() {
        User currentUser = getCurrentUser();
        log.debug("Fetching cart for user: {}", currentUser.getEmail());
        
        Cart cart = cartRepository.findByUser(currentUser)
                .orElseGet(() -> createCartForUser(currentUser));

        return cartMapper.toCartResponse(cart);
    }

    /**
     * Get cart by user public ID (accessible to the user or admin)
     */
    @Transactional(readOnly = true)
    public CartResponse getCartByUserId(String userPublicId) {
        log.debug("Fetching cart for user ID: {}", userPublicId);
        
        // Note: Authorization is handled at controller level with @PreAuthorize("hasAuthority('ADMIN')")
        // This method is only called by admins, so we can safely proceed
        Cart cart = cartRepository.findByUserPublicId(userPublicId)
                .orElseThrow(() -> CartNotFoundException.byUserId(userPublicId));

        return cartMapper.toCartResponse(cart);
    }

    /**
     * Get paginated cart items for current user
     */
    @Transactional(readOnly = true)
    public Page<CartItemResponse> getMyCartItems(Pageable pageable) {
        User currentUser = getCurrentUser();
        log.debug("Fetching paginated cart items for user: {}", currentUser.getEmail());
        
        Cart cart = cartRepository.findByUser(currentUser)
                .orElseGet(() -> createCartForUser(currentUser));

        return cartItemRepository.findByCart(cart, pageable)
                .map(cartMapper::toCartItemResponse);
    }

    /**
     * Add item to cart or update quantity if already exists
     */
    @Transactional
    public CartResponse addToCart(AddToCartRequest request) {
        User currentUser = getCurrentUser();
        log.info("Adding item to cart for user: {} - Product ID: {}, Quantity: {}", 
                currentUser.getEmail(), request.productId(), request.quantity());

        // Get or create cart
        Cart cart = cartRepository.findByUser(currentUser)
                .orElseGet(() -> createCartForUser(currentUser));

        // Get product
        Product product = productRepository.findByPublicId(request.productId())
                .orElseThrow(() -> ProductNotFoundException.byPublicId(request.productId()));

        // Check stock availability
        if (product.getStockQuantity() < request.quantity()) {
            throw InsufficientStockException.forProduct(
                    product.getName(), 
                    request.quantity(), 
                    product.getStockQuantity());
        }

        // Check if item already exists in cart
        CartItem existingItem = cartItemRepository.findByCartAndProduct(cart, product)
                .orElse(null);

        if (existingItem != null) {
            // Update quantity
            int newQuantity = existingItem.getQuantity() + request.quantity();
            
            // Check stock for new quantity
            if (product.getStockQuantity() < newQuantity) {
                throw InsufficientStockException.forProduct(
                        product.getName(), 
                        newQuantity, 
                        product.getStockQuantity());
            }
            
            existingItem.setQuantity(newQuantity);
            cartItemRepository.save(existingItem);
            log.debug("Updated cart item quantity to: {}", newQuantity);
        } else {
            // Create new cart item
            BigDecimal currentPrice = product.getSalePrice().compareTo(BigDecimal.ZERO) > 0 
                    ? product.getSalePrice() 
                    : product.getPrice();
            
            CartItem newItem = new CartItem(cart, product, request.quantity(), currentPrice);
            cart.addItem(newItem);
            cartItemRepository.save(newItem);
            log.debug("Added new item to cart");
        }

        cart = cartRepository.save(cart);
        return cartMapper.toCartResponse(cart);
    }

    /**
     * Update cart item quantity
     */
    @Transactional
    public CartResponse updateCartItem(String cartItemId, UpdateCartItemRequest request) {
        User currentUser = getCurrentUser();
        log.info("Updating cart item: {} - New quantity: {}", cartItemId, request.quantity());

        CartItem cartItem = cartItemRepository.findByPublicId(cartItemId)
                .orElseThrow(() -> CartItemNotFoundException.byPublicId(cartItemId));

        // Verify cart belongs to current user
        if (!cartItem.getCart().getUser().getId().equals(currentUser.getId())) {
            throw new IllegalStateException("Cannot modify another user's cart");
        }

        // Check stock availability
        Product product = cartItem.getProduct();
        if (product.getStockQuantity() < request.quantity()) {
            throw InsufficientStockException.forProduct(
                    product.getName(), 
                    request.quantity(), 
                    product.getStockQuantity());
        }

        cartItem.setQuantity(request.quantity());
        cartItemRepository.save(cartItem);

        Cart cart = cartItem.getCart();
        return cartMapper.toCartResponse(cart);
    }

    /**
     * Remove item from cart
     */
    @Transactional
    public CartResponse removeCartItem(String cartItemId) {
        User currentUser = getCurrentUser();
        log.info("Removing cart item: {}", cartItemId);

        CartItem cartItem = cartItemRepository.findByPublicId(cartItemId)
                .orElseThrow(() -> CartItemNotFoundException.byPublicId(cartItemId));

        // Verify cart belongs to current user
        Cart cart = cartItem.getCart();
        if (!cart.getUser().getId().equals(currentUser.getId())) {
            throw new IllegalStateException("Cannot modify another user's cart");
        }

        cart.removeItem(cartItem);
        cartItemRepository.delete(cartItem);

        return cartMapper.toCartResponse(cart);
    }

    /**
     * Clear all items from cart
     */
    @Transactional
    public CartResponse clearCart() {
        User currentUser = getCurrentUser();
        log.info("Clearing cart for user: {}", currentUser.getEmail());

        Cart cart = cartRepository.findByUser(currentUser)
                .orElseThrow(() -> CartNotFoundException.byUserId(currentUser.getPublicId()));

        cart.clearItems();
        cartItemRepository.deleteByCart(cart);
        cart = cartRepository.save(cart);

        return cartMapper.toCartResponse(cart);
    }

    /**
     * Create a new cart for a user
     */
    @Transactional
    private Cart createCartForUser(User user) {
        log.info("Creating new cart for user: {}", user.getEmail());
        Cart cart = new Cart();
        cart.setUser(user);
        return cartRepository.save(cart);
    }

    /**
     * Get current authenticated user
     */
    private User getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            throw new IllegalStateException("No authenticated user found");
        }
        return (User) authentication.getPrincipal();
    }
}

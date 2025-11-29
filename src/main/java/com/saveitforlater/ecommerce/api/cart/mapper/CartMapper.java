package com.saveitforlater.ecommerce.api.cart.mapper;

import com.saveitforlater.ecommerce.api.cart.dto.CartItemResponse;
import com.saveitforlater.ecommerce.api.cart.dto.CartResponse;
import com.saveitforlater.ecommerce.persistence.entity.cart.Cart;
import com.saveitforlater.ecommerce.persistence.entity.cart.CartItem;
import com.saveitforlater.ecommerce.persistence.entity.product.Product;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper
public interface CartMapper {

    @Mapping(source = "publicId", target = "id")
    @Mapping(source = "user.publicId", target = "userId")
    @Mapping(source = "items", target = "items")
    CartResponse toCartResponse(Cart cart);

    @Mapping(source = "publicId", target = "id")
    @Mapping(source = "product", target = "product")
    CartItemResponse toCartItemResponse(CartItem cartItem);

    @Mapping(source = "publicId", target = "id")
    CartItemResponse.ProductSummary toProductSummary(Product product);
}

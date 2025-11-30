package com.saveitforlater.ecommerce.api.order.mapper;

import com.saveitforlater.ecommerce.api.order.dto.*;
import com.saveitforlater.ecommerce.persistence.entity.order.Order;
import com.saveitforlater.ecommerce.persistence.entity.order.OrderItem;
import com.saveitforlater.ecommerce.persistence.entity.order.Payment;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper
public interface OrderMapper {

    @Mapping(source = "publicId", target = "id")
    @Mapping(source = "user.publicId", target = "userId")
    @Mapping(target = "shippingAddress", expression = "java(mapShippingAddress(order))")
    @Mapping(target = "billingAddress", expression = "java(mapBillingAddress(order))")
    OrderResponse toOrderResponse(Order order);

    @Mapping(source = "publicId", target = "id")
    @Mapping(source = "product.publicId", target = "productId")
    OrderItemResponse toOrderItemResponse(OrderItem orderItem);

    @Mapping(source = "publicId", target = "id")
    PaymentResponse toPaymentResponse(Payment payment);

    default AddressResponse mapShippingAddress(Order order) {
        return new AddressResponse(
                order.getShippingAddressLine1(),
                order.getShippingAddressLine2(),
                order.getShippingCity(),
                order.getShippingState(),
                order.getShippingPostalCode(),
                order.getShippingCountry()
        );
    }

    default AddressResponse mapBillingAddress(Order order) {
        return new AddressResponse(
                order.getBillingAddressLine1(),
                order.getBillingAddressLine2(),
                order.getBillingCity(),
                order.getBillingState(),
                order.getBillingPostalCode(),
                order.getBillingCountry()
        );
    }
}

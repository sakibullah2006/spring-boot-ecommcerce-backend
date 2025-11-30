package com.saveitforlater.ecommerce.api.auth.mapper;

import com.saveitforlater.ecommerce.api.auth.dto.UserResponse;
import com.saveitforlater.ecommerce.api.user.dto.UserDetailResponse;
import com.saveitforlater.ecommerce.persistence.entity.user.User;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface UserMapper {

    @Mapping(source = "publicId", target = "id")
    @Mapping(source = "role", target = "role") // Map enum to String
    UserResponse toUserResponse(User user);

    @Mapping(source = "publicId", target = "id")
    @Mapping(source = "role", target = "role") // Map enum to String
    UserDetailResponse toUserDetailResponse(User user);
}

package com.saveitforlater.ecommerce.persistence.specification;

import com.saveitforlater.ecommerce.api.product.dto.ProductFilterRequest;
import com.saveitforlater.ecommerce.persistence.entity.category.Category;
import com.saveitforlater.ecommerce.persistence.entity.product.Attribute;
import com.saveitforlater.ecommerce.persistence.entity.product.AttributeOption;
import com.saveitforlater.ecommerce.persistence.entity.product.Product;
import com.saveitforlater.ecommerce.persistence.entity.product.ProductAttributeValue;
import jakarta.persistence.criteria.*;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

public class ProductSpecification {

    /**
     * Build a composite specification based on filter criteria
     */
    public static Specification<Product> withFilters(ProductFilterRequest filter) {
        return (root, query, criteriaBuilder) -> {
            List<Predicate> predicates = new ArrayList<>();

            // Search term (name, shortDescription, SKU)
            if (StringUtils.hasText(filter.searchTerm())) {
                String searchPattern = "%" + filter.searchTerm().toLowerCase() + "%";
                Predicate namePredicate = criteriaBuilder.like(
                        criteriaBuilder.lower(root.get("name")), searchPattern);
                Predicate shortDescPredicate = criteriaBuilder.like(
                        criteriaBuilder.lower(root.get("shortDescription")), searchPattern);
                Predicate skuPredicate = criteriaBuilder.like(
                        criteriaBuilder.lower(root.get("sku")), searchPattern);
                
                predicates.add(criteriaBuilder.or(namePredicate, shortDescPredicate, skuPredicate));
            }

            // Category filter
            if (filter.categoryIds() != null && !filter.categoryIds().isEmpty()) {
                Join<Product, Category> categoryJoin = root.join("categories", JoinType.INNER);
                predicates.add(categoryJoin.get("publicId").in(filter.categoryIds()));
            }

            // Price range filters
            if (filter.minPrice() != null) {
                // Check both price and salePrice
                Predicate priceMin = criteriaBuilder.greaterThanOrEqualTo(
                        root.get("price"), filter.minPrice());
                Predicate salePriceMin = criteriaBuilder.and(
                        criteriaBuilder.isNotNull(root.get("salePrice")),
                        criteriaBuilder.greaterThan(root.get("salePrice"), BigDecimal.ZERO),
                        criteriaBuilder.greaterThanOrEqualTo(root.get("salePrice"), filter.minPrice())
                );
                predicates.add(criteriaBuilder.or(priceMin, salePriceMin));
            }

            if (filter.maxPrice() != null) {
                // Check both price and salePrice
                Predicate priceMax = criteriaBuilder.lessThanOrEqualTo(
                        root.get("price"), filter.maxPrice());
                Predicate salePriceMax = criteriaBuilder.and(
                        criteriaBuilder.isNotNull(root.get("salePrice")),
                        criteriaBuilder.greaterThan(root.get("salePrice"), BigDecimal.ZERO),
                        criteriaBuilder.lessThanOrEqualTo(root.get("salePrice"), filter.maxPrice())
                );
                predicates.add(criteriaBuilder.or(priceMax, salePriceMax));
            }

            // Stock filter
            if (filter.inStock() != null) {
                if (filter.inStock()) {
                    predicates.add(criteriaBuilder.greaterThan(root.get("stockQuantity"), 0));
                } else {
                    predicates.add(criteriaBuilder.lessThanOrEqualTo(root.get("stockQuantity"), 0));
                }
            }

            // Attribute filters
            if (filter.attributes() != null && !filter.attributes().isEmpty()) {
                for (ProductFilterRequest.AttributeFilter attrFilter : filter.attributes()) {
                    if (StringUtils.hasText(attrFilter.attributeName()) 
                            && attrFilter.optionNames() != null 
                            && !attrFilter.optionNames().isEmpty()) {
                        
                        Subquery<Long> subquery = query.subquery(Long.class);
                        Root<ProductAttributeValue> pavRoot = subquery.from(ProductAttributeValue.class);
                        Join<ProductAttributeValue, Attribute> attrJoin = pavRoot.join("attribute");
                        Join<ProductAttributeValue, AttributeOption> optionJoin = pavRoot.join("attributeOption");
                        
                        subquery.select(pavRoot.get("product").get("id"))
                                .where(
                                    criteriaBuilder.and(
                                        criteriaBuilder.equal(pavRoot.get("product").get("id"), root.get("id")),
                                        criteriaBuilder.equal(
                                                criteriaBuilder.lower(attrJoin.get("name")), 
                                                attrFilter.attributeName().toLowerCase()),
                                        criteriaBuilder.lower(optionJoin.get("name")).in(
                                                attrFilter.optionNames().stream()
                                                        .map(String::toLowerCase)
                                                        .toList()
                                        ),
                                        criteriaBuilder.isTrue(pavRoot.get("isActive"))
                                    )
                                );
                        
                        predicates.add(criteriaBuilder.exists(subquery));
                    }
                }
            }

            // Ensure distinct results when joining with categories
            if (filter.categoryIds() != null && !filter.categoryIds().isEmpty()) {
                query.distinct(true);
            }

            return criteriaBuilder.and(predicates.toArray(new Predicate[0]));
        };
    }
}

package com.saveitforlater.ecommerce.domain.product;

import com.saveitforlater.ecommerce.persistence.entity.product.*;
import com.saveitforlater.ecommerce.persistence.repository.product.ProductAttributeValueRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Transactional
public class ProductAttributeValueService {

    private final ProductAttributeValueRepository productAttributeValueRepository;

    public List<ProductAttributeValue> getActiveAttributeValuesByProduct(Product product) {
        return productAttributeValueRepository.findByProductAndIsActiveTrue(product);
    }

    public List<ProductAttributeValue> getActiveAttributeValuesByProductId(String productPublicId) {
        return productAttributeValueRepository.findActiveAttributeValuesByProductPublicId(productPublicId);
    }

    public List<Attribute> getDistinctAttributesByProduct(Product product) {
        return productAttributeValueRepository.findDistinctAttributesByProduct(product);
    }

    public Optional<ProductAttributeValue> findByProductAndAttribute(Product product, Attribute attribute) {
        return productAttributeValueRepository.findByProductAndAttributeAndIsActiveTrue(product, attribute);
    }

    public ProductAttributeValue addAttributeValueToProduct(Product product, Attribute attribute, AttributeOption option) {
        if (product == null || attribute == null || option == null) {
            throw new IllegalArgumentException("Product, attribute, and option cannot be null");
        }

        // Check if this exact combination already exists
        Optional<ProductAttributeValue> existingValue = productAttributeValueRepository
                .findByProductAndAttributeAndOption(product, attribute, option);

        if (existingValue.isPresent()) {
            ProductAttributeValue value = existingValue.get();
            value.setActive(true); // Reactivate if it was soft deleted
            return productAttributeValueRepository.save(value);
        }

        // Check if product already has a value for this attribute
        Optional<ProductAttributeValue> existingAttributeValue = productAttributeValueRepository
                .findByProductAndAttributeAndIsActiveTrue(product, attribute);

        if (existingAttributeValue.isPresent()) {
            // Update existing attribute value with new option
            ProductAttributeValue value = existingAttributeValue.get();
            value.setAttributeOption(option);
            return productAttributeValueRepository.save(value);
        }

        // Create new attribute value
        ProductAttributeValue newValue = new ProductAttributeValue(product, attribute, option);
        return productAttributeValueRepository.save(newValue);
    }

    public void removeAttributeValueFromProduct(Product product, Attribute attribute, AttributeOption option) {
        Optional<ProductAttributeValue> value = productAttributeValueRepository
                .findByProductAndAttributeAndOption(product, attribute, option);

        if (value.isPresent()) {
            productAttributeValueRepository.delete(value.get());
        }
    }

    public void removeAllAttributeValuesFromProduct(Product product, Attribute attribute) {
        productAttributeValueRepository.deleteByProductAndAttribute(product, attribute);
    }

    public void softDeleteAttributeValue(Product product, Attribute attribute, AttributeOption option) {
        Optional<ProductAttributeValue> value = productAttributeValueRepository
                .findByProductAndAttributeAndOption(product, attribute, option);

        if (value.isPresent()) {
            ProductAttributeValue attributeValue = value.get();
            attributeValue.setActive(false);
            productAttributeValueRepository.save(attributeValue);
        }
    }

    public void clearAllAttributeValuesForProduct(Product product) {
        List<ProductAttributeValue> values = productAttributeValueRepository.findByProduct(product);
        productAttributeValueRepository.deleteAll(values);
    }
}
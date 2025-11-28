package com.saveitforlater.ecommerce.domain.product;

import com.saveitforlater.ecommerce.persistence.entity.product.Attribute;
import com.saveitforlater.ecommerce.persistence.entity.product.AttributeOption;
import com.saveitforlater.ecommerce.persistence.repository.product.AttributeOptionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Transactional
public class AttributeOptionService {

    private final AttributeOptionRepository attributeOptionRepository;

    public List<AttributeOption> getActiveOptionsByAttribute(Attribute attribute) {
        return attributeOptionRepository.findByAttributeAndIsActiveTrue(attribute);
    }

    public List<AttributeOption> getActiveOptionsByAttributeId(String attributePublicId) {
        return attributeOptionRepository.findActiveOptionsByAttributePublicId(attributePublicId);
    }

    public Optional<AttributeOption> findByPublicId(String publicId) {
        return attributeOptionRepository.findByPublicId(publicId);
    }

    public Optional<AttributeOption> findByAttributeAndName(Attribute attribute, String name) {
        return attributeOptionRepository.findByAttributeAndNameIgnoreCase(attribute, name);
    }

    public Optional<AttributeOption> findByAttributeAndSlug(Attribute attribute, String slug) {
        return attributeOptionRepository.findByAttributeAndSlugIgnoreCase(attribute, slug);
    }

    public AttributeOption createOrGetOption(Attribute attribute, String name, String description) {
        if (!StringUtils.hasText(name)) {
            throw new IllegalArgumentException("Option name cannot be empty");
        }

        if (attribute == null) {
            throw new IllegalArgumentException("Attribute cannot be null");
        }

        String normalizedName = name.trim();
        String slug = generateSlug(normalizedName);

        // Try to find existing option by name (case-insensitive)
        Optional<AttributeOption> existingOption = attributeOptionRepository
                .findByAttributeAndNameIgnoreCase(attribute, normalizedName);
        if (existingOption.isPresent()) {
            return existingOption.get();
        }

        // Try to find existing option by slug (case-insensitive)
        Optional<AttributeOption> existingOptionBySlug = attributeOptionRepository
                .findByAttributeAndSlugIgnoreCase(attribute, slug);
        if (existingOptionBySlug.isPresent()) {
            return existingOptionBySlug.get();
        }

        // Create new option
        AttributeOption newOption = new AttributeOption();
        newOption.setName(normalizedName);
        newOption.setSlug(slug);
        newOption.setDescription(description);
        newOption.setActive(true);
        newOption.setAttribute(attribute);

        AttributeOption savedOption = attributeOptionRepository.save(newOption);
        
        // Add to attribute's options list
        attribute.addOption(savedOption);
        
        return savedOption;
    }

    public AttributeOption updateOption(String publicId, String name, String description, boolean isActive) {
        AttributeOption option = attributeOptionRepository.findByPublicId(publicId)
                .orElseThrow(() -> new IllegalArgumentException("Attribute option not found with ID: " + publicId));

        if (StringUtils.hasText(name)) {
            String normalizedName = name.trim();
            
            // Check if name is already used by another option in the same attribute
            if (attributeOptionRepository.existsByAttributeAndNameAndIdNot(
                    option.getAttribute(), normalizedName, option.getId())) {
                throw new IllegalArgumentException("Option name already exists for this attribute: " + normalizedName);
            }
            
            option.setName(normalizedName);
            option.setSlug(generateSlug(normalizedName));
        }

        if (description != null) {
            option.setDescription(description);
        }

        option.setActive(isActive);

        return attributeOptionRepository.save(option);
    }

    public void deactivateOption(String publicId) {
        AttributeOption option = attributeOptionRepository.findByPublicId(publicId)
                .orElseThrow(() -> new IllegalArgumentException("Attribute option not found with ID: " + publicId));
        
        option.setActive(false);
        attributeOptionRepository.save(option);
    }

    private String generateSlug(String name) {
        return name.toLowerCase()
                .replaceAll("[^a-z0-9\\s-]", "") // Remove special characters
                .replaceAll("\\s+", "-") // Replace spaces with hyphens
                .replaceAll("-+", "-") // Replace multiple hyphens with single hyphen
                .replaceAll("^-|-$", ""); // Remove leading/trailing hyphens
    }
}
package com.saveitforlater.ecommerce.domain.product;

import com.saveitforlater.ecommerce.persistence.entity.product.Attribute;
import com.saveitforlater.ecommerce.persistence.repository.product.AttributeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Transactional
public class AttributeService {

    private final AttributeRepository attributeRepository;

    public List<Attribute> getAllActiveAttributes() {
        return attributeRepository.findAllActiveOrderByName();
    }

    public Optional<Attribute> findByPublicId(String publicId) {
        return attributeRepository.findByPublicId(publicId);
    }

    public Optional<Attribute> findByName(String name) {
        return attributeRepository.findByNameIgnoreCase(name);
    }

    public Optional<Attribute> findBySlug(String slug) {
        return attributeRepository.findBySlugIgnoreCase(slug);
    }

    public Attribute createOrGetAttribute(String name, String description) {
        if (!StringUtils.hasText(name)) {
            throw new IllegalArgumentException("Attribute name cannot be empty");
        }

        String normalizedName = name.trim();
        String slug = generateSlug(normalizedName);

        // Try to find existing attribute by name (case-insensitive)
        Optional<Attribute> existingAttribute = attributeRepository.findByNameIgnoreCase(normalizedName);
        if (existingAttribute.isPresent()) {
            return existingAttribute.get();
        }

        // Try to find existing attribute by slug (case-insensitive)
        Optional<Attribute> existingAttributeBySlug = attributeRepository.findBySlugIgnoreCase(slug);
        if (existingAttributeBySlug.isPresent()) {
            return existingAttributeBySlug.get();
        }

        // Create new attribute
        Attribute newAttribute = new Attribute();
        newAttribute.setName(normalizedName);
        newAttribute.setSlug(slug);
        newAttribute.setDescription(description);
        newAttribute.setActive(true);

        return attributeRepository.save(newAttribute);
    }

    public Attribute updateAttribute(String publicId, String name, String description, boolean isActive) {
        Attribute attribute = attributeRepository.findByPublicId(publicId)
                .orElseThrow(() -> new IllegalArgumentException("Attribute not found with ID: " + publicId));

        if (StringUtils.hasText(name)) {
            String normalizedName = name.trim();
            
            // Check if name is already used by another attribute
            if (attributeRepository.existsByNameAndIdNot(normalizedName, attribute.getId())) {
                throw new IllegalArgumentException("Attribute name already exists: " + normalizedName);
            }
            
            attribute.setName(normalizedName);
            attribute.setSlug(generateSlug(normalizedName));
        }

        if (description != null) {
            attribute.setDescription(description);
        }

        attribute.setActive(isActive);

        return attributeRepository.save(attribute);
    }

    public void deactivateAttribute(String publicId) {
        Attribute attribute = attributeRepository.findByPublicId(publicId)
                .orElseThrow(() -> new IllegalArgumentException("Attribute not found with ID: " + publicId));
        
        attribute.setActive(false);
        attributeRepository.save(attribute);
    }

    private String generateSlug(String name) {
        return name.toLowerCase()
                .replaceAll("[^a-z0-9\\s-]", "") // Remove special characters
                .replaceAll("\\s+", "-") // Replace spaces with hyphens
                .replaceAll("-+", "-") // Replace multiple hyphens with single hyphen
                .replaceAll("^-|-$", ""); // Remove leading/trailing hyphens
    }
}
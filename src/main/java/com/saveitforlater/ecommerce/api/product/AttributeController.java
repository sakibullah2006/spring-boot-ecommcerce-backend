package com.saveitforlater.ecommerce.api.product;

import com.saveitforlater.ecommerce.api.product.dto.AttributeDto;
import com.saveitforlater.ecommerce.api.product.dto.AttributeOptionDto;
import com.saveitforlater.ecommerce.api.product.mapper.ProductMapper;
import com.saveitforlater.ecommerce.domain.product.AttributeOptionService;
import com.saveitforlater.ecommerce.domain.product.AttributeService;
import com.saveitforlater.ecommerce.persistence.entity.product.Attribute;
import com.saveitforlater.ecommerce.persistence.entity.product.AttributeOption;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/attributes")
@RequiredArgsConstructor
public class AttributeController {

    private final AttributeService attributeService;
    private final AttributeOptionService attributeOptionService;
    private final ProductMapper productMapper;

    /**
     * Get all attributes (accessible to everyone)
     */
    @GetMapping
    public ResponseEntity<List<AttributeDto>> getAllAttributes() {
        List<Attribute> attributes = attributeService.getAllActiveAttributes();
        List<AttributeDto> response = attributes.stream()
                .map(productMapper::toAttributeDto)
                .collect(Collectors.toList());
        return ResponseEntity.ok(response);
    }

    /**
     * Get attribute by ID (accessible to everyone)
     */
    @GetMapping("/{attributeId}")
    public ResponseEntity<AttributeDto> getAttributeById(@PathVariable String attributeId) {
        Attribute attribute = attributeService.findByPublicId(attributeId)
                .orElseThrow(() -> new IllegalArgumentException("Attribute not found with ID: " + attributeId));
        
        AttributeDto response = productMapper.toAttributeDto(attribute);
        return ResponseEntity.ok(response);
    }

    /**
     * Create a new attribute (ADMIN ONLY)
     */
    @PostMapping
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<AttributeDto> createAttribute(@Valid @RequestBody CreateAttributeRequest request) {
        Attribute attribute = attributeService.createOrGetAttribute(request.name(), request.description());
        AttributeDto response = productMapper.toAttributeDto(attribute);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * Update an attribute (ADMIN ONLY)
     */
    @PutMapping("/{attributeId}")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<AttributeDto> updateAttribute(@PathVariable String attributeId,
                                                       @Valid @RequestBody UpdateAttributeRequest request) {
        Attribute attribute = attributeService.updateAttribute(
                attributeId, request.name(), request.description(), 
                request.isActive() != null ? request.isActive() : true);
        AttributeDto response = productMapper.toAttributeDto(attribute);
        return ResponseEntity.ok(response);
    }

    /**
     * Deactivate an attribute (ADMIN ONLY)
     */
    @DeleteMapping("/{attributeId}")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<Void> deactivateAttribute(@PathVariable String attributeId) {
        attributeService.deactivateAttribute(attributeId);
        return ResponseEntity.noContent().build();
    }

    /**
     * Get options for a specific attribute (accessible to everyone)
     */
    @GetMapping("/{attributeId}/options")
    public ResponseEntity<List<AttributeOptionDto>> getAttributeOptions(@PathVariable String attributeId) {
        List<AttributeOption> options = attributeOptionService.getActiveOptionsByAttributeId(attributeId);
        List<AttributeOptionDto> response = options.stream()
                .map(productMapper::toAttributeOptionDto)
                .collect(Collectors.toList());
        return ResponseEntity.ok(response);
    }

    /**
     * Create a new option for an attribute (ADMIN ONLY)
     */
    @PostMapping("/{attributeId}/options")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<AttributeOptionDto> createAttributeOption(@PathVariable String attributeId,
                                                                    @Valid @RequestBody CreateAttributeOptionRequest request) {
        Attribute attribute = attributeService.findByPublicId(attributeId)
                .orElseThrow(() -> new IllegalArgumentException("Attribute not found with ID: " + attributeId));
        
        AttributeOption option = attributeOptionService.createOrGetOption(
                attribute, request.name(), request.description());
        AttributeOptionDto response = productMapper.toAttributeOptionDto(option);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * Update an attribute option (ADMIN ONLY)
     */
    @PutMapping("/options/{optionId}")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<AttributeOptionDto> updateAttributeOption(@PathVariable String optionId,
                                                                    @Valid @RequestBody UpdateAttributeOptionRequest request) {
        AttributeOption option = attributeOptionService.updateOption(
                optionId, request.name(), request.description(), request.isActive());
        AttributeOptionDto response = productMapper.toAttributeOptionDto(option);
        return ResponseEntity.ok(response);
    }

    /**
     * Deactivate an attribute option (ADMIN ONLY)
     */
    @DeleteMapping("/options/{optionId}")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<Void> deactivateAttributeOption(@PathVariable String optionId) {
        attributeOptionService.deactivateOption(optionId);
        return ResponseEntity.noContent().build();
    }

    // Request DTOs
    public record CreateAttributeRequest(
            String name,
            String description
    ) {}

    public record UpdateAttributeRequest(
            @NotBlank(message = "Name is required")
            String name,
            String description,
            Boolean isActive
    ) {}

    public record CreateAttributeOptionRequest(
            String name,
            String description
    ) {}

    public record UpdateAttributeOptionRequest(
            String name,
            String description,
            boolean isActive
    ) {}
}
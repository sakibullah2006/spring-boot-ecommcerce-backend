package com.saveitforlater.ecommerce.persistence.entity.file;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "file_metadata")
@Getter
@Setter
@NoArgsConstructor
public class FileMetadata {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, updatable = false, length = 36)
    private String publicId;

    @Column(nullable = false)
    private String fileName;

    @Column(nullable = false)
    private String originalFileName;

    @Column(nullable = false, length = 500)
    private String filePath;

    @Column(nullable = false)
    private Long fileSize;

    @Column(nullable = false, length = 100)
    private String contentType;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private FileType fileType = FileType.OTHER;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    public void prePersist() {
        if (this.publicId == null) {
            this.publicId = UUID.randomUUID().toString();
        }
    }

    public enum FileType {
        IMAGE,
        DOCUMENT,
        VIDEO,
        OTHER
    }
}

package com.saveitforlater.ecommerce.persistence.repository.file;

import com.saveitforlater.ecommerce.persistence.entity.file.FileMetadata;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface FileMetadataRepository extends JpaRepository<FileMetadata, Long> {
    
    Optional<FileMetadata> findByPublicId(String publicId);
    
    Optional<FileMetadata> findByFileName(String fileName);
    
    void deleteByPublicId(String publicId);
}

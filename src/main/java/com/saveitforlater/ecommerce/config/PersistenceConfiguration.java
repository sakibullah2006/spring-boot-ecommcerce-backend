package com.saveitforlater.ecommerce.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

@Configuration(proxyBeanMethods = false)
@EnableJpaRepositories(basePackages = "com.saveitforlater.ecommerce.persistence.repository") // Adjust package if needed
@EnableJpaAuditing
public class PersistenceConfiguration {
    // You can also move @EntityScan here if you were using it
}
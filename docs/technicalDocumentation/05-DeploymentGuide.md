# Deployment Guide

## Prerequisites

### System Requirements
- **Java**: JDK 21 or higher
- **Database**: MySQL 5.7+ or MariaDB 10.3+
- **Build Tool**: Maven 3.9+
- **OS**: Windows, Linux, or macOS

### Development Tools
- IntelliJ IDEA / VS Code
- MySQL Workbench / DBeaver
- Postman / PowerShell (for API testing)
- Git

## Local Development Setup

### 1. Clone Repository
```bash
git clone https://github.com/sakibullah2006/spring-boot-ecommcerce-backend.git
cd spring-boot-ecommcerce-backend
```

### 2. Database Setup

**Create Database**:
```sql
CREATE DATABASE ecommerce_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'ecommerce_user'@'localhost' IDENTIFIED BY 'SecurePassword123!';
GRANT ALL PRIVILEGES ON ecommerce_db.* TO 'ecommerce_user'@'localhost';
FLUSH PRIVILEGES;
```

**Configure Connection**:
Edit `src/main/resources/application.yml`:

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/ecommerce_db?useSSL=false&serverTimezone=UTC
    username: ecommerce_user
    password: SecurePassword123!
    driver-class-name: com.mysql.cj.jdbc.Driver
```

### 3. Build Project
```bash
mvn clean install
```

### 4. Run Application
```bash
mvn spring-boot:run
```

Or run the generated JAR:
```bash
java -jar target/ecommerce-0.0.1-SNAPSHOT.jar
```

### 5. Verify Deployment
```bash
curl http://localhost:8080/api/products/paginated
```

Application should be running on `http://localhost:8080`.

## Database Migrations

### Flyway Configuration
Migrations run automatically on application startup.

**Migration Files**: `src/main/resources/db/migration/`

**Naming Convention**: `V{version}__{description}.sql`

Example:
- `V1__Initial_Schema.sql`
- `V2__Create_Reusable_Attribute_System.sql`

### Manual Migration
```bash
mvn flyway:migrate
```

### Rollback (use with caution)
```bash
mvn flyway:clean  # Drops all objects
mvn flyway:migrate  # Recreate schema
```

### Check Migration Status
```bash
mvn flyway:info
```

## Environment Configuration

### application.yml Structure
```yaml
server:
  port: 8080

spring:
  profiles:
    active: dev  # dev, staging, prod
  
  datasource:
    url: ${DB_URL}
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
  
  jpa:
    hibernate:
      ddl-auto: validate  # Never use 'update' in production
    show-sql: false
  
  servlet:
    multipart:
      max-file-size: 10MB
      max-request-size: 10MB

app:
  file:
    upload-dir: ${UPLOAD_DIR:uploads}
    max-file-size: 10485760

logging:
  level:
    root: INFO
    com.saveitforlater.ecommerce: DEBUG
```

### Environment Variables
```bash
# Database
export DB_URL=jdbc:mysql://localhost:3306/ecommerce_db
export DB_USERNAME=ecommerce_user
export DB_PASSWORD=SecurePassword123!

# File Storage
export UPLOAD_DIR=/var/app/uploads

# Server
export SERVER_PORT=8080
```

## Production Deployment

### Docker Deployment

**Dockerfile**:
```dockerfile
FROM eclipse-temurin:21-jdk-alpine
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
```

**Build and Run**:
```bash
mvn clean package -DskipTests
docker build -t ecommerce-backend .
docker run -p 8080:8080 \
  -e DB_URL=jdbc:mysql://db:3306/ecommerce_db \
  -e DB_USERNAME=ecommerce_user \
  -e DB_PASSWORD=SecurePassword123! \
  -v /data/uploads:/app/uploads \
  ecommerce-backend
```

**Docker Compose**:
```yaml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      DB_URL: jdbc:mysql://db:3306/ecommerce_db
      DB_USERNAME: ecommerce_user
      DB_PASSWORD: SecurePassword123!
    volumes:
      - uploads:/app/uploads
    depends_on:
      - db
  
  db:
    image: mysql:8.0
    environment:
      MYSQL_DATABASE: ecommerce_db
      MYSQL_USER: ecommerce_user
      MYSQL_PASSWORD: SecurePassword123!
      MYSQL_ROOT_PASSWORD: RootPassword123!
    volumes:
      - mysql_data:/var/lib/mysql
    ports:
      - "3306:3306"

volumes:
  uploads:
  mysql_data:
```

### AWS Deployment

**Elastic Beanstalk**:
1. Package application: `mvn clean package`
2. Create Beanstalk application
3. Configure environment variables
4. Deploy JAR file
5. Configure RDS MySQL database
6. Set up S3 for file storage (replace local storage)

**ECS (Docker)**:
1. Push Docker image to ECR
2. Create ECS task definition
3. Configure ECS service
4. Set up RDS and EFS
5. Configure ALB for load balancing

### Server Configuration

**JVM Options** (production):
```bash
java -Xms512m -Xmx2048m \
     -XX:+UseG1GC \
     -XX:MaxGCPauseMillis=200 \
     -jar app.jar
```

**systemd Service** (Linux):
```ini
[Unit]
Description=E-Commerce Backend
After=syslog.target

[Service]
User=ecommerce
ExecStart=/usr/bin/java -jar /opt/ecommerce/app.jar
SuccessExitStatus=143
Environment="DB_URL=jdbc:mysql://localhost:3306/ecommerce_db"
Environment="DB_USERNAME=ecommerce_user"
Environment="DB_PASSWORD=SecurePassword123!"

[Install]
WantedBy=multi-user.target
```

## SSL/TLS Configuration

### application.yml (HTTPS)
```yaml
server:
  port: 8443
  ssl:
    enabled: true
    key-store: classpath:keystore.p12
    key-store-password: ${KEYSTORE_PASSWORD}
    key-store-type: PKCS12
    key-alias: tomcat
```

### Generate Self-Signed Certificate (Development)
```bash
keytool -genkeypair -alias tomcat \
  -keyalg RSA -keysize 2048 \
  -storetype PKCS12 \
  -keystore keystore.p12 \
  -validity 365
```

### Production: Use Let's Encrypt or AWS Certificate Manager

## Monitoring and Health Checks

### Spring Boot Actuator
Add to `pom.xml`:
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

**Endpoints**:
- `/actuator/health` - Application health
- `/actuator/info` - Application info
- `/actuator/metrics` - Application metrics

## Backup Strategy

### Database Backups
```bash
# Daily backup
mysqldump -u ecommerce_user -p ecommerce_db > backup_$(date +%Y%m%d).sql

# Automated backup (cron)
0 2 * * * /usr/bin/mysqldump -u ecommerce_user -p$DB_PASSWORD ecommerce_db > /backups/ecommerce_$(date +\%Y\%m\%d).sql
```

### File Storage Backups
```bash
# Sync uploads to S3
aws s3 sync /var/app/uploads s3://ecommerce-uploads/
```

## Performance Tuning

### Database Connection Pool
```yaml
spring:
  datasource:
    hikari:
      maximum-pool-size: 20
      minimum-idle: 5
      connection-timeout: 30000
      idle-timeout: 600000
      max-lifetime: 1800000
```

### JPA Performance
```yaml
spring:
  jpa:
    properties:
      hibernate:
        jdbc:
          batch_size: 20
        order_inserts: true
        order_updates: true
        query:
          in_clause_parameter_padding: true
```

## Troubleshooting

### Application Won't Start
1. Check database connectivity
2. Verify Flyway migrations
3. Check port availability (8080)
4. Review logs in `logs/application.log`

### Database Connection Errors
```bash
# Test connection
mysql -u ecommerce_user -p -h localhost ecommerce_db

# Check MySQL status
systemctl status mysql
```

### File Upload Issues
1. Check upload directory exists and has write permissions
2. Verify file size limits in configuration
3. Check disk space

## Scaling Considerations

### Horizontal Scaling
- Use external session storage (Redis)
- Use cloud file storage (S3, Azure Blob)
- Configure database read replicas
- Implement caching (Redis, Memcached)

### Load Balancing
```nginx
upstream backend {
    server backend1:8080;
    server backend2:8080;
    server backend3:8080;
}

server {
    listen 80;
    location /api {
        proxy_pass http://backend;
    }
}
```

---

**Related Documentation**:
- [System Architecture](./01-SystemArchitecture.md)
- [Security](./04-Security.md)
- [Database Design](./02-DatabaseDesign.md)

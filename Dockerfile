# Stage 1: Build
FROM mcr.microsoft.com/openjdk/jdk:17-azurelinux AS builder

WORKDIR /app

# Install tar (required for Maven on Azure Linux)
RUN tdnf install -y tar gzip && tdnf clean all

# Copy Maven wrapper and pom.xml first for dependency caching
COPY mvnw ./
COPY .mvn .mvn
COPY pom.xml ./

# Make Maven wrapper executable
RUN chmod +x mvnw

# Download dependencies (cached layer)
RUN ./mvnw dependency:go-offline -B

# Copy source code
COPY src ./src

# Build the application (skip tests for faster build)
RUN ./mvnw package -DskipTests -B

# Stage 2: Runtime
FROM mcr.microsoft.com/openjdk/jdk:17-distroless

WORKDIR /app

# Copy the built JAR from builder stage
COPY --from=builder /app/target/*.jar app.jar

# Expose application port
EXPOSE 8080

# Run as non-root user (distroless images run as non-root by default)
ENTRYPOINT ["java", "-jar", "app.jar"]

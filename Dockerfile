# Stage 1: Build
FROM mcr.microsoft.com/openjdk/jdk:17-azurelinux AS builder

WORKDIR /app

# Install tar (needed for Maven on Azure Linux)
RUN tdnf install -y tar gzip && tdnf clean all

# Copy Maven wrapper and pom.xml first for dependency caching
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./

# Download dependencies (cached layer)
RUN chmod +x mvnw && ./mvnw dependency:go-offline -B

# Copy source code
COPY src/ src/

# Build the application
RUN ./mvnw package -DskipTests -B && \
    mv target/*.jar target/app.jar

# Stage 2: Runtime
FROM mcr.microsoft.com/openjdk/jdk:17-distroless

WORKDIR /app

# Copy the built artifact from the builder stage
COPY --from=builder /app/target/app.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]

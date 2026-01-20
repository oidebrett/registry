# Multi-stage Dockerfile for MCP Registry with localhost support
FROM golang:1.24-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git make

# Set working directory
WORKDIR /build

# Copy go mod files first for better caching
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the registry with version info
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags="-X main.Version=$(git describe --tags --always --dirty) -X main.GitCommit=$(git rev-parse HEAD) -X main.BuildTime=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    -a -installsuffix cgo \
    -o /registry \
    ./cmd/registry

# Final stage
FROM alpine:latest

# Install ca-certificates for HTTPS
RUN apk --no-cache add ca-certificates

WORKDIR /app

# Copy binary from builder
COPY --from=builder /registry /app/registry

# Copy seed data
COPY --from=builder /build/data ./data

# Expose port
EXPOSE 8080

# Run the registry
ENTRYPOINT ["/app/registry"]

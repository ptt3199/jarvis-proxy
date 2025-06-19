# System Patterns: jarvis-proxy

## Architecture Overview

### Core Components

```
Internet → Cloudflare → Cloudflared Tunnel → Traefik → Application Containers
```

#### Component Responsibilities
- **Cloudflare**: DNS management, DDoS protection, caching
- **Cloudflared**: Secure tunnel (no exposed ports)
- **Traefik**: Reverse proxy, load balancing, SSL termination, service discovery
- **Docker Compose**: Container orchestration and networking

### Network Architecture

```
┌─────────────────┐
│   Cloudflare    │
│  (DNS + CDN)    │
└─────────┬───────┘
          │ HTTPS
          ▼
┌─────────────────┐
│  Cloudflared    │
│    Tunnel       │
└─────────┬───────┘
          │ Local Network
          ▼
┌─────────────────┐
│     Traefik     │
│ (Reverse Proxy) │
└─────────┬───────┘
          │ Docker Network
    ┌─────┼─────┬─────────┐
    ▼     ▼     ▼         ▼
  ┌───┐ ┌───┐ ┌─────┐ ┌──────┐
  │App│ │App│ │Dash │ │Future│
  │ 1 │ │ 2 │ │board│ │ Apps │
  └───┘ └───┘ └─────┘ └──────┘
```

## Design Patterns

### Service Discovery Pattern
**Pattern**: Label-based automatic registration
**Implementation**: Docker containers declare routing rules via labels

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.app.rule=Host(`app.jarvis.thanhpt.xyz`)"
  - "traefik.http.services.app.loadbalancer.server.port=3000"
```

**Benefits**:
- Zero manual configuration
- Self-documenting services
- Automatic cleanup when containers stop

### SSL Certificate Management Pattern
**Pattern**: Automatic certificate provisioning with DNS challenge
**Implementation**: Let's Encrypt + Cloudflare DNS API

```yaml
certificatesResolvers:
  cloudflare:
    acme:
      email: admin@example.com
      storage: /acme.json
      dnsChallenge:
        provider: cloudflare
```

**Benefits**:
- Wildcard certificate support
- No port 80 requirement
- Works with private networks

### Middleware Chain Pattern
**Pattern**: Composable request/response middleware
**Implementation**: Stackable Traefik middlewares

```yaml
middlewares:
  - "auth"           # Authentication
  - "ratelimit"      # Rate limiting  
  - "compress"       # Response compression
  - "headers"        # Security headers
```

**Benefits**:
- Reusable security policies
- Fine-grained request control
- Easy A/B testing

## Key Technical Decisions

### Routing Strategy
**Decision**: Subdomain-based routing as primary pattern
**Rationale**: 
- Cleaner URLs
- Better application isolation
- Easier wildcard SSL management
- No base path configuration required

**Alternative**: Path-based routing for specific use cases

### Container Networking
**Decision**: Docker Compose with custom network
**Rationale**:
- Service isolation
- Name-based service resolution
- Easy inter-service communication

```yaml
networks:
  jarvis-proxy:
    external: true
```

### Configuration Management
**Decision**: File-based configuration with dynamic discovery
**Rationale**:
- Version controlled static config
- Runtime container discovery
- Clear separation of concerns

```
traefik/
├── traefik.yml        # Static configuration
├── dynamic_conf.yml   # File provider config
└── acme.json         # Certificate storage
```

## Component Relationships

### Traefik ↔ Docker Integration
- Traefik polls Docker API for container changes
- Containers register via labels
- Automatic service mesh creation

### SSL Certificate Lifecycle
1. New domain detected in container labels
2. Traefik requests certificate from Let's Encrypt
3. DNS challenge completed via Cloudflare API
4. Certificate stored in acme.json
5. Automatic renewal before expiration

### Middleware Processing Pipeline
```
Request → [Auth] → [Rate Limit] → [Headers] → [Compress] → Application
Response ← [Compress] ← [Headers] ← [Auth Headers] ← Application
```

## Scalability Patterns

### Horizontal Scaling
- Multiple container replicas behind single service
- Traefik automatic load balancing
- Health check based routing

### Service Mesh Readiness
- Service discovery foundation
- Middleware-based policies
- Observability integration points

## Security Patterns

### Zero-Trust Network
- No public port exposure
- Cloudflare Tunnel as single entry point
- Application-level authentication

### Defense in Depth
1. **Cloudflare**: DDoS protection, WAF
2. **Traefik**: Rate limiting, basic auth
3. **Applications**: Application-specific security

This architecture provides a solid foundation for a microservices ecosystem while maintaining simplicity for single-developer use cases. 
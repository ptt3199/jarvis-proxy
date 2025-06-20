# jarvis-proxy

A simplified reverse proxy & gateway stack for routing web services using Traefik and Docker with Cloudflare Tunnel integration.

## Overview

jarvis-proxy provides **HTTP-only local routing** with **path-based service organization** on a single domain. SSL is handled entirely by Cloudflare, eliminating local certificate complexity while maintaining enterprise-grade security.

## 🎯 Current Working Features

- **✅ Path-Based Routing**: Single domain with `/path` routing to different services  
- **✅ HTTP-Only Local**: Cloudflare handles all SSL termination
- **✅ Service Discovery**: Auto-detection via Docker labels  
- **✅ Zero Port Exposure**: Cloudflare Tunnel integration
- **✅ Live Dashboard**: Real-time service monitoring
- **✅ Strip Prefix Middleware**: Clean URLs to backend services

## 🏗️ Architecture

```
Internet (HTTPS) → Cloudflare → Tunnel (HTTP) → Traefik (Port 80) → Services
```

**Key Benefits:**
- **Simplified**: No local SSL certificates or HTTPS redirects
- **Secure**: Cloudflare handles SSL/TLS termination  
- **Fast**: HTTP-only local routing with minimal overhead
- **Scalable**: Easy to add new services with Docker labels

## 🌐 Current Routes

| Path | Service | Description |
|------|---------|-------------|
| `gw.thanhpt.xyz/` | Whoami | Test service & fallback |
| `gw.thanhpt.xyz/dashboard` | Traefik | Admin dashboard |
| `gw.thanhpt.xyz/homecam` | HomeCam | USB webcam stream |

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose
- Cloudflare Tunnel configured to point to `http://localhost:80`

### Start Services
```bash
# Clone and start
git clone <repo-url>
cd jarvis-proxy

# Create network (if not exists)
docker network create jarvis-proxy

# Start all services
docker compose up -d

# Verify services
docker ps
curl http://localhost:80/ -H "Host: gw.thanhpt.xyz"
```

### Test Routes
```bash
# Test root service
curl http://localhost:80/ -H "Host: gw.thanhpt.xyz"

# Test dashboard
curl http://localhost:80/dashboard/ -H "Host: gw.thanhpt.xyz"

# Test homecam
curl http://localhost:80/homecam/ -H "Host: gw.thanhpt.xyz"

# Or use debug dashboard
curl http://localhost:8080/dashboard/
```

## 📦 Add New Services

Use this template to add new services:

```yaml
# Add to docker-compose.yml
new-service:
  image: your-service:latest
  container_name: your-service
  restart: unless-stopped
  labels:
    - "traefik.enable=true"
    # Route: gw.thanhpt.xyz/yourpath
    - "traefik.http.routers.yourservice.rule=Host(`gw.thanhpt.xyz`) && PathPrefix(`/yourpath`)"
    - "traefik.http.routers.yourservice.service=yourservice"
    # Strip /yourpath before forwarding (if needed)
    - "traefik.http.routers.yourservice.middlewares=yourservice-stripprefix"
    - "traefik.http.middlewares.yourservice-stripprefix.stripprefix.prefixes=/yourpath"
    # Backend configuration
    - "traefik.http.services.yourservice.loadbalancer.server.port=8080"
  networks:
    - jarvis-proxy
```

## 🔧 Configuration

### Docker Compose Structure
```yaml
networks:
  jarvis-proxy:
    external: true

services:
  traefik:
    image: traefik:v3.1.4
    ports:
      - "80:80"      # Main HTTP entry point
      - "8080:8080"  # Debug dashboard
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./traefik:/etc/traefik:ro
```

### Traefik Configuration (traefik.yml)
```yaml
# HTTP-only entry point
entryPoints:
  web:
    address: ":80"

# Docker provider for service discovery
providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
    network: jarvis-proxy

# Dashboard (insecure mode for debugging)
api:
  dashboard: true
  insecure: true
```

### Cloudflare Tunnel Setup
```bash
# Your tunnel should point to:
http://localhost:80

# NOT https://localhost:443 (no local SSL needed)
```

## 📊 Monitoring

### Traefik Dashboard
- **Secure**: `gw.thanhpt.xyz/dashboard` (via tunnel)
- **Debug**: `http://localhost:8080/dashboard` (local only)

### Service Status
```bash
# Check running containers
docker ps

# Check Traefik logs
docker logs traefik

# Check API status
curl http://localhost:8080/api/http/routers
```

## 🔐 Security

### Current Security Layers
1. **Cloudflare**: DDoS protection, WAF, SSL termination
2. **Tunnel**: Encrypted connection, no exposed ports  
3. **Traefik**: HTTP routing, optional authentication
4. **Docker**: Network isolation via jarvis-proxy network

### Enable Dashboard Authentication (Optional)
```yaml
# Uncomment in docker-compose.yml
labels:
  - "traefik.http.routers.dashboard.middlewares=auth"
  - "traefik.http.middlewares.auth.basicauth.users=admin:$2y$05$hashedpassword"
```

## 🐛 Troubleshooting

### Common Issues

**502 Bad Gateway from tunnel:**
- Ensure tunnel points to `http://localhost:80` (not HTTPS)
- Check containers are running: `docker ps`
- Verify Traefik logs: `docker logs traefik`

**404 Not Found:**
- Check routing rules: `curl http://localhost:8080/api/http/routers`
- Verify Host header: `curl -H "Host: gw.thanhpt.xyz" http://localhost:80/path`
- Recreate containers to pick up label changes: `docker compose down && docker compose up -d`

**Service not accessible:**
- Check container is in jarvis-proxy network
- Verify traefik.enable=true label
- Check service port configuration

### Debug Commands
```bash
# Check network
docker network ls | grep jarvis-proxy

# Inspect Traefik configuration
curl http://localhost:8080/api/rawdata

# Test local routing
curl -v http://localhost:80/dashboard/ -H "Host: gw.thanhpt.xyz"
```

## 📁 Project Structure

```
jarvis-proxy/
├── docker-compose.yml    # Service definitions
├── traefik/
│   ├── traefik.yml      # HTTP-only static config
│   └── acme.json        # Empty (no SSL certs needed)
├── memory-bank/         # Project documentation
│   ├── activeContext.md
│   ├── progress.md
│   ├── systemPatterns.md
│   └── ...
└── README.md           # This file
```

## 🎯 What Makes This Simple

- **No SSL complexity**: Cloudflare handles certificates
- **No environment variables**: No API keys needed
- **No HTTPS redirects**: HTTP-only local routing
- **No dynamic config files**: All config via Docker labels
- **Single domain**: All services on `gw.thanhpt.xyz/path`

## 📚 Documentation

See `memory-bank/` directory for detailed:
- Architecture patterns and decisions
- Implementation progress and status  
- Technical context and setup guides

## 🔄 Status

**✅ Production Ready**: Core infrastructure complete and tested
- All routing paths functional
- Tunnel integration confirmed
- Service discovery working
- Dashboard monitoring available

For detailed implementation status, see `memory-bank/progress.md`.
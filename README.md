# jarvis-proxy

A modern reverse proxy & gateway stack for routing web services using Traefik and Docker.

## Overview

jarvis-proxy provides automated routing, SSL management, and service discovery for containerized applications. Built with Traefik and Docker Compose, it offers zero-configuration deployments with enterprise-grade features.

## Key Features

- **Automatic Routing**: Add Docker labels to containers for instant HTTP routing
- **SSL Certificates**: Automatic Let's Encrypt certificates with DNS challenge
- **Service Discovery**: Auto-detection of new services with zero downtime
- **Secure Access**: Cloudflare Tunnel integration (no exposed ports)
- **Web Dashboard**: Real-time monitoring and service management
- **Middleware**: Built-in authentication, rate limiting, and compression

## Architecture

```
Internet → Cloudflare → Cloudflared Tunnel → Traefik → Your Apps
```

### Routing Examples

**Subdomain routing** (recommended):
- `homecam.jarvis.thanhpt.xyz` → app1
- `flashcard.jarvis.thanhpt.xyz` → app2

**Path-based routing**:
- `jarvis.thanhpt.xyz/homecam` → app1
- `jarvis.thanhpt.xyz/flashcard` → app2

## Quick Start

### Prerequisites
- Docker & Docker Compose
- Cloudflare account with domain
- Ubuntu Server (recommended)

### Setup
```bash
# Clone repository
git clone <repo-url>
cd jarvis-proxy

# Configure environment
cp .env.example .env
# Edit .env with your Cloudflare credentials

# Create Docker network
docker network create jarvis-proxy

# Start services
docker-compose up -d
```

### Deploy Your First App
```yaml
# Add to docker-compose.yml
your-app:
  image: your-app:latest
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.yourapp.rule=Host(`yourapp.jarvis.thanhpt.xyz`)"
    - "traefik.http.services.yourapp.loadbalancer.server.port=3000"
  networks:
    - jarvis-proxy
```

## Configuration

### Environment Variables
```bash
CLOUDFLARE_EMAIL=your-email@example.com
CLOUDFLARE_DNS_API_TOKEN=your-api-token
TRAEFIK_DASHBOARD_USER=admin
TRAEFIK_DASHBOARD_PASSWORD_HASH=your-hash
```

### File Structure
```
jarvis-proxy/
├── docker-compose.yml
├── .env
├── traefik/
│   ├── traefik.yml
│   ├── dynamic_conf.yml
│   └── acme.json
└── cloudflared/
    └── config.yml
```

## Monitoring

Access the Traefik dashboard at `https://dashboard.jarvis.thanhpt.xyz` to monitor:
- Service health and status
- SSL certificate management
- Real-time traffic metrics
- Route configurations

## Security Features

- **Zero exposed ports**: All traffic via Cloudflare Tunnel
- **Automatic HTTPS**: Let's Encrypt certificates with auto-renewal
- **Rate limiting**: Configurable per-service rate limits
- **Authentication**: Basic auth and custom middleware support

## Contributing

See [development-roadmap.md](development-roadmap.md) for detailed implementation guides and learning materials.

## License

MIT License
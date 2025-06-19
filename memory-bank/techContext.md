# Tech Context: jarvis-proxy

## Technology Stack

### Core Technologies

| Component | Technology | Version | Purpose |
|-----------|------------|---------|---------|
| Reverse Proxy | Traefik | 2.x | HTTP routing, SSL, load balancing |
| Container Runtime | Docker | 24+ | Application containerization |
| Orchestration | Docker Compose | 2.x | Multi-container management |
| SSL Provider | Let's Encrypt | ACME v2 | Automatic SSL certificates |
| Tunnel | Cloudflared | Latest | Secure external access |
| DNS Provider | Cloudflare | API v4 | DNS management, tunnel |

### Development Environment

#### Host Requirements
- **OS**: Ubuntu Server 20.04+ (recommended)
- **RAM**: 2GB minimum, 4GB recommended
- **Storage**: 20GB minimum for containers and logs
- **Network**: Stable internet for certificate challenges

#### Required Software
```bash
# Docker & Docker Compose
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Cloudflared
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -o cloudflared.deb
sudo dpkg -i cloudflared.deb
```

### Configuration Dependencies

#### Environment Variables
```bash
# Cloudflare API credentials (for DNS challenge)
CLOUDFLARE_EMAIL=your-email@example.com
CLOUDFLARE_API_KEY=your-global-api-key

# Or use API Token (recommended)
CLOUDFLARE_DNS_API_TOKEN=your-dns-api-token

# Traefik Dashboard Authentication
TRAEFIK_DASHBOARD_USER=admin
TRAEFIK_DASHBOARD_PASSWORD_HASH=$2y$05$...
```

#### File Structure
```
jarvis-proxy/
├── docker-compose.yml          # Service definitions
├── .env                        # Environment variables
├── traefik/
│   ├── traefik.yml            # Static configuration
│   ├── dynamic_conf.yml       # Dynamic configuration
│   └── acme.json             # SSL certificates (created by Traefik)
├── cloudflared/
│   └── config.yml            # Tunnel configuration
└── logs/                     # Application logs
    ├── traefik/
    └── cloudflared/
```

## Development Setup

### Initial Setup Process
1. **Clone and configure**
   ```bash
   git clone <repo>
   cd jarvis-proxy
   cp .env.example .env
   # Edit .env with your credentials
   ```

2. **Create Docker network**
   ```bash
   docker network create jarvis-proxy
   ```

3. **Start core services**
   ```bash
   docker-compose up -d traefik cloudflared
   ```

4. **Verify setup**
   - Check Traefik dashboard: `https://dashboard.jarvis.thanhpt.xyz`
   - Verify tunnel status: `cloudflared tunnel info`

### Local Development

#### Testing New Applications
```yaml
# docker-compose.override.yml
version: '3.8'
services:
  test-app:
    image: nginx:alpine
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.test.rule=Host(`test.jarvis.thanhpt.xyz`)"
      - "traefik.http.services.test.loadbalancer.server.port=80"
    networks:
      - jarvis-proxy
```

#### Debug Mode
```yaml
# Enable debug logging in traefik.yml
log:
  level: DEBUG
  filePath: "/logs/traefik.log"
```

## Technical Constraints

### Cloudflare Integration
- **DNS Challenge Only**: Required for wildcard certificates
- **API Rate Limits**: 1200 requests per 5 minutes
- **Tunnel Limitations**: Single tunnel per account (free tier)

### Docker Compose Limitations
- **Single Host**: No built-in clustering
- **Network Scope**: Services must be in same Docker network
- **Storage**: Local volumes only (no distributed storage)

### Security Considerations
- **acme.json permissions**: Must be 600 (Traefik requirement)
- **Cloudflare API keys**: Full account access (use API tokens when possible)
- **Container isolation**: All services share same Docker network

## Monitoring & Observability

### Built-in Monitoring
- **Traefik Dashboard**: Real-time service status and metrics
- **Docker Logs**: Centralized logging via Docker
- **Healthchecks**: Container-level health monitoring

### Log Management
```yaml
# Centralized logging configuration
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

### Metrics Collection
- Traefik metrics endpoint: `/metrics`
- Prometheus-compatible format
- Custom metrics via middleware

## Performance Characteristics

### Expected Performance
- **SSL Handshake**: <100ms (cached certificates)
- **Routing Overhead**: <10ms per request
- **Memory Usage**: ~100MB base (Traefik + Cloudflared)
- **CPU Usage**: <5% on idle, scales with request volume

### Scaling Considerations
- **Horizontal**: Multiple app replicas behind Traefik
- **Vertical**: Increase container resources as needed
- **Database**: External database for session storage
- **CDN**: Cloudflare handles static asset caching

## Deployment Pipeline

### Current State
- Manual deployment via `docker-compose up`
- Configuration changes require service restart

### Future Automation
- GitHub Actions for automated deployment
- Blue-green deployments for zero downtime
- Automated backup and disaster recovery
- Infrastructure as Code (Terraform) 
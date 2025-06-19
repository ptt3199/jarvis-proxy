# Product Context: jarvis-proxy

## Why This Project Exists

### Problem Statement
Managing multiple web applications and services in a personal/small-scale environment typically involves:
- Manual configuration of reverse proxies (nginx/Apache)
- Complex SSL certificate management
- Port management and firewall configuration
- No service discovery or auto-scaling
- Difficult debugging and monitoring

### Solution Vision
jarvis-proxy provides a **modern, automated gateway solution** that eliminates manual configuration overhead while providing enterprise-grade features for personal and small-scale deployments.

## How It Should Work

### User Experience Goals

#### For Developers
- **Deploy once, route automatically**: Add Docker labels to any container and it's immediately accessible
- **Zero-config SSL**: HTTPS works automatically without manual certificate management
- **Real-time monitoring**: Visual dashboard shows all services, their health, and traffic patterns
- **Security by default**: Built-in rate limiting, authentication, and secure tunnel access

#### For DevOps Learning
- **Production patterns**: Learn industry-standard tools (Traefik, Docker, Let's Encrypt)
- **Infrastructure as Code**: All configuration in version-controlled files
- **Monitoring & Observability**: Dashboard and logging for troubleshooting
- **CI/CD Integration**: GitHub Actions pipeline for automated deployments

### Key Workflows

#### Adding a New Service
1. Developer creates Docker container with Traefik labels
2. Container starts and registers automatically with Traefik
3. SSL certificate is provisioned within seconds
4. Service is immediately accessible via configured domain/subdomain
5. Dashboard reflects new service status

#### Service Management
- Monitor service health and response times
- View real-time traffic routing
- Manage SSL certificates
- Configure rate limiting and authentication per service

## Problems This Solves

### Infrastructure Complexity
- **Before**: Manual nginx configs, manual SSL, port conflicts
- **After**: Label-based configuration, automatic SSL, service discovery

### Security Overhead
- **Before**: Exposed ports, manual firewall rules, DIY authentication
- **After**: Cloudflare Tunnel, integrated auth middleware, zero public ports

### Monitoring Blind Spots
- **Before**: No visibility into service health or traffic patterns
- **After**: Comprehensive dashboard with real-time metrics

### Deployment Friction
- **Before**: Complex deployment scripts, downtime during changes
- **After**: Zero-downtime deployments, automatic service registration

## Target Use Cases

1. **Personal Projects**: Host multiple web apps under one domain
2. **Development Environment**: Local development with production-like routing
3. **Learning Platform**: Hands-on experience with modern DevOps tools
4. **Small Team Infrastructure**: Shared development/staging environments
5. **Portfolio Hosting**: Professional presentation of multiple projects

## Success Metrics
- Time to deploy new service: < 2 minutes
- SSL certificate provisioning: < 30 seconds
- Zero unplanned downtime during service updates
- Dashboard provides 100% visibility into service health 
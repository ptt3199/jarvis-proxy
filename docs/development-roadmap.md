# Lộ trình phát triển jarvis-proxy

Ghi chú cá nhân về cách triển khai hệ thống jarvis-proxy từng bước, để không quên và có thể tham khảo lại sau này.

## 🎯 Mục tiêu cá nhân

Dùng jarvis-proxy để thực hành các kỹ năng DevOps, từ setup cơ bản đến automation.

### 📊 Kế hoạch thực hiện

| Phase | Nội dung | Công nghệ | Dự kiến |
|-------|----------|-----------|---------|
| 🌱 **Phase 1** | Setup cơ bản, làm cho nó chạy được | Traefik + Docker | 1-2 tuần |
| 🔧 **Phase 2** | Bảo mật và monitoring | SSL + Auth + Dashboard | 1 tuần |
| ⚙️ **Phase 3** | Scale và load balancing | Replica + Health check | 2 tuần |
| 🧠 **Phase 4** | Automation và CI/CD | GitHub Actions | 2-3 tuần |

## 🏗️ Kiến trúc chi tiết hệ thống

### Sơ đồ tổng quan

```
                     INTERNET
                        │
                        ▼
    ┌─────────────────────────────────────────┐
    │            CLOUDFLARE                   │
    │  • DNS Management (*.jarvis.thanhpt.xyz)│
    │  • DDoS Protection & WAF                │
    │  • CDN & Caching                        │
    │  • SSL/TLS Termination (Edge)           │
    └─────────────────┬───────────────────────┘
                      │ HTTPS (443)
                      │ Cloudflare Tunnel
                      ▼
    ┌─────────────────────────────────────────┐
    │         UBUNTU SERVER (VPS)             │
    │                                         │
    │  ┌───────────────────────────────────┐  │
    │  │        CLOUDFLARED                │  │
    │  │    • Tunnel Client                │  │
    │  │    • Zero Trust Access            │  │
    │  │    • No Exposed Ports             │  │
    │  └─────────────┬─────────────────────┘  │
    │                │ Internal Network       │
    │                ▼                        │
    │  ┌───────────────────────────────────┐  │
    │  │           TRAEFIK                 │  │
    │  │    • Reverse Proxy & LB           │  │
    │  │    • Service Discovery            │  │
    │  │    • SSL Cert Management          │  │
    │  │    • Middleware Processing        │  │
    │  │    • Metrics & Monitoring         │  │
    │  └─────────────┬─────────────────────┘  │
    │                │ Docker Network         │
    │                ▼                        │
    │  ┌─────────────────────────────────────┐│
    │  │       APPLICATION LAYER             ││
    │  │                                     ││
    │  │ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────────┐ ││
    │  │ │App1 │ │App2 │ │App3 │ │Dashboard│ ││
    │  │ │:3000│ │:3001│ │:3002│ │  :8080  │ ││
    │  │ └─────┘ └─────┘ └─────┘ └─────────┘ ││
    │  └─────────────────────────────────────┘│
    └─────────────────────────────────────────┘
```

### Luồng xử lý request

```
    [User Request]
         │
         ▼
    [Cloudflare CDN]
         │ DNS Resolution
         │ DDoS Protection
         │ WAF Rules
         ▼
    [Cloudflare Tunnel]
         │ Encrypted Tunnel
         │ Zero Trust Check
         ▼
    [Cloudflared Client]
         │ Local Network
         │ Port Forward
         ▼
    [Traefik Router]
         │ Route Matching
         │ Middleware Chain
         ▼
    ┌─────────────────────┐
    │   MIDDLEWARE CHAIN  │
    │                     │
    │ 1. [Rate Limiting]  │
    │ 2. [Authentication] │
    │ 3. [CORS Headers]   │
    │ 4. [Compression]    │
    │ 5. [Security Headers]│
    └─────────┬───────────┘
              ▼
    [Load Balancer]
         │ Health Check
         │ Round Robin
         ▼
    [Application Container]
         │ Process Request
         ▼
    [Response] → [Reverse Chain] → [User]
```

## 📚 Phase 1: Setup cơ bản (🌱)

### Mục tiêu
- Làm cho Traefik chạy được
- Routing đầu tiên hoạt động
- SSL tự động
- Deploy được 1 app test

### Bước 1: Chuẩn bị môi trường

#### 1.1 Cài đặt Docker & Docker Compose
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Install Docker Compose (nếu chưa có)
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version
```

#### 1.2 Setup Cloudflare Domain
1. **Mua domain hoặc sử dụng domain có sẵn**
2. **Chuyển DNS về Cloudflare**
3. **Tạo A record trỏ về IP server**
4. **Setup wildcard DNS**: `*.jarvis.thanhpt.xyz`

#### 1.3 Tạo Cloudflare API Token
```bash
# Vào Cloudflare Dashboard
# My Profile → API Tokens → Create Token
# Template: Custom token
# Permissions:
#   - Zone:Zone:Read
#   - Zone:DNS:Edit
# Zone Resources:
#   - Include → Specific zone → jarvis.thanhpt.xyz
```

### Bước 2: Tạo cấu trúc project

```bash
# Tạo thư mục project
mkdir jarvis-proxy && cd jarvis-proxy

# Tạo cấu trúc thư mục
mkdir -p traefik cloudflared logs/{traefik,cloudflared}

# Tạo file cấu hình
touch .env docker-compose.yml
touch traefik/traefik.yml traefik/dynamic_conf.yml
touch cloudflared/config.yml
```

### Bước 3: Cấu hình cơ bản

> **Test local vs Server**: Có thể test basic trên local trước, nhưng SSL và domain thật cần server. Xem phần "Test Local" bên dưới.

#### 3.1 File `.env`
```bash
# Cloudflare Configuration
CLOUDFLARE_DNS_API_TOKEN=your_cloudflare_api_token_here
CLOUDFLARE_EMAIL=your_email@example.com

# Domain Configuration
DOMAIN=jarvis.thanhpt.xyz

# Traefik Dashboard Auth (generate with: htpasswd -nbB admin yourpassword)
TRAEFIK_DASHBOARD_USER=admin
TRAEFIK_DASHBOARD_PASSWORD_HASH='$2y$05$...' # Thay bằng hash thật

# SSL Email
ACME_EMAIL=your_email@example.com
```

#### 3.2 File `docker-compose.yml` cơ bản
```yaml
version: '3.8'

networks:
  jarvis-proxy:
    external: true  # Network phải tạo trước: docker network create jarvis-proxy

services:
  traefik:
    image: traefik:v2.10
    container_name: traefik
    restart: unless-stopped
    ports:
      - "80:80"    # HTTP port - redirect to HTTPS
      - "443:443"  # HTTPS port - main traffic
    volumes:
      # Docker socket - để Traefik detect containers
      - /var/run/docker.sock:/var/run/docker.sock:ro
      # Config files - mount read-only
      - ./traefik:/etc/traefik:ro
      # Logs - để troubleshoot
      - ./logs/traefik:/var/log/traefik
    environment:
      # Cloudflare credentials cho DNS challenge
      - CLOUDFLARE_DNS_API_TOKEN=${CLOUDFLARE_DNS_API_TOKEN}
      - CLOUDFLARE_EMAIL=${CLOUDFLARE_EMAIL}
    labels:
      - "traefik.enable=true"
      # Dashboard routing
      - "traefik.http.routers.dashboard.rule=Host(`dashboard.${DOMAIN}`)"
      - "traefik.http.routers.dashboard.service=api@internal"  # Internal API service
      - "traefik.http.routers.dashboard.middlewares=auth"      # Protect with auth
      - "traefik.http.routers.dashboard.tls.certresolver=cloudflare"  # Auto SSL
      # Basic auth middleware definition
      - "traefik.http.middlewares.auth.basicauth.users=${TRAEFIK_DASHBOARD_USER}:${TRAEFIK_DASHBOARD_PASSWORD_HASH}"
    networks:
      - jarvis-proxy

  # Test app - để verify routing hoạt động
  whoami:
    image: traefik/whoami  # Simple app trả về container info
    container_name: whoami
    restart: unless-stopped
    labels:
      - "traefik.enable=true"  # Bật Traefik discovery
      - "traefik.http.routers.whoami.rule=Host(`whoami.${DOMAIN}`)"  # Route rule
      - "traefik.http.routers.whoami.tls.certresolver=cloudflare"    # Auto SSL
      - "traefik.http.services.whoami.loadbalancer.server.port=80"   # Container port
    networks:
      - jarvis-proxy
```

**Giải thích cấu hình:**
- **external network**: Dùng chung network cho tất cả services
- **volumes**: Mount Docker socket để auto-detect containers
- **labels**: Khai báo routing rules cho chính Traefik
- **environment**: Credentials cho SSL DNS challenge
- **whoami**: App test đơn giản để verify setup

#### 3.3 File `traefik/traefik.yml`
```yaml
# Static configuration - chỉ load khi start Traefik
global:
  checkNewVersion: false      # Tắt check update tự động
  sendAnonymousUsage: false   # Tắt gửi usage data

# Entry points - định nghĩa ports Traefik listen
entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entrypoint:
          to: websecure     # Tự động redirect HTTP → HTTPS
          scheme: https
  websecure:
    address: ":443"         # Main HTTPS traffic

# Providers - nơi Traefik lấy config
providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"  # Connect to Docker
    exposedByDefault: false                  # Chỉ expose containers có label enable=true
    network: jarvis-proxy                    # Default network cho services
  file:
    filename: /etc/traefik/dynamic_conf.yml  # Load middleware từ file
    watch: true                              # Auto reload khi file thay đổi

# Certificate resolvers - tự động cấp SSL
certificatesResolvers:
  cloudflare:
    acme:
      email: admin@jarvis.thanhpt.xyz        # Email đăng ký Let's Encrypt
      storage: /etc/traefik/acme.json        # File lưu certificates
      dnsChallenge:                          # DNS challenge cho wildcard certs
        provider: cloudflare                 # Dùng Cloudflare DNS API
        resolvers:
          - "1.1.1.1:53"                    # DNS servers để verify
          - "8.8.8.8:53"

# API and Dashboard
api:
  dashboard: true          # Bật dashboard
  insecure: false         # Tắt insecure mode (cần auth)

# Logging
log:
  level: INFO                                    # Log level
  filePath: /var/log/traefik/traefik.log        # Traefik logs

accessLog:
  filePath: /var/log/traefik/access.log         # HTTP access logs

# Metrics - để monitor với Prometheus
metrics:
  prometheus:
    addEntryPointsLabels: true    # Thêm labels cho ports
    addServicesLabels: true       # Thêm labels cho services
```

**Giải thích từng section:**
- **entryPoints**: HTTP redirect HTTPS, HTTPS là main traffic
- **providers**: Docker auto-discovery + file config cho middleware
- **certificatesResolvers**: DNS challenge để get wildcard SSL
- **api**: Dashboard cho monitoring (có auth)
- **logging**: Debug và monitor traffic
- **metrics**: Export metrics cho Prometheus

#### 3.4 File `traefik/dynamic_conf.yml`
```yaml
# Dynamic configuration - có thể reload without restart
http:
  middlewares:
    # Security headers - bảo vệ web security
    secure-headers:
      headers:
        accessControlAllowMethods:
          - GET
          - OPTIONS  
          - PUT
        accessControlMaxAge: 100           # Cache preflight requests
        hostsProxyHeaders:
          - "X-Forwarded-Host"            # Forward original host
        referrerPolicy: "same-origin"      # Referrer policy
        customRequestHeaders:
          X-Forwarded-Proto: "https"      # Tell app we're using HTTPS

    # Rate limiting - chống DDoS/abuse
    rate-limit:
      rateLimit:
        average: 100     # 100 requests/second average
        burst: 20        # Allow bursts up to 120 req/sec

    # Compression - tiết kiệm bandwidth
    gzip:
      compress: {}       # Enable gzip compression
```

**Tại sao cần middleware:**
- **secure-headers**: Bảo vệ XSS, clickjacking, content sniffing
- **rate-limit**: Tránh DDoS và abuse API endpoints  
- **gzip**: Giảm bandwidth, faster loading
- **Dynamic**: Có thể update middleware mà không restart Traefik

### Bước 4: Khởi chạy hệ thống

```bash
# Tạo Docker network
docker network create jarvis-proxy

# Set permissions cho acme.json
touch traefik/acme.json
chmod 600 traefik/acme.json

# Start services
docker-compose up -d

# Check logs
docker-compose logs -f traefik
```

### Bước 5: Test Local vs Deploy Server

#### 🏠 Test Local (Recommended first)

**Ưu điểm**: Test nhanh, không cần domain thật, không risk server
**Nhược điểm**: Không test được SSL thật, Cloudflare tunnel

```bash
# Local setup - không cần SSL và Cloudflare
# File docker-compose.local.yml
version: '3.8'
networks:
  jarvis-proxy:
    external: true

services:
  traefik:
    image: traefik:v2.10
    container_name: traefik-local
    ports:
      - "80:80"     # No HTTPS for local
      - "8080:8080" # Dashboard on :8080
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik-local.yml:/etc/traefik/traefik.yml:ro
    networks:
      - jarvis-proxy

  whoami:
    image: traefik/whoami
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.whoami.rule=Host(`whoami.local`)"
    networks:
      - jarvis-proxy
```

```yaml
# traefik-local.yml - simplified config
entryPoints:
  web:
    address: ":80"
  dashboard:
    address: ":8080"

providers:
  docker:
    exposedByDefault: false

api:
  dashboard: true
  insecure: true  # OK for local testing
```

**Test local:**
```bash
# Add to /etc/hosts
echo "127.0.0.1 whoami.local" | sudo tee -a /etc/hosts

# Start local stack
docker network create jarvis-proxy
docker-compose -f docker-compose.local.yml up -d

# Test
curl http://whoami.local          # Should work
curl http://localhost:8080        # Dashboard
```

#### 🚀 Deploy Server (Production)

**Khi nào**: Sau khi test local OK
**Ưu điểm**: Test full SSL, domain thật, Cloudflare
**Nhược điểm**: Cần server, domain setup

```bash
# On server - full production setup
git clone your-repo
cd jarvis-proxy

# Setup domain first
# 1. Point *.jarvis.thanhpt.xyz to server IP
# 2. Get Cloudflare API token  
# 3. Configure .env file

# Deploy
docker network create jarvis-proxy
docker-compose up -d

# Test real domain
curl https://dashboard.jarvis.thanhpt.xyz
curl https://whoami.jarvis.thanhpt.xyz
```

#### 📊 Comparison

| Feature | Local Test | Server Deploy |
|---------|------------|---------------|
| SSL Certificates | ❌ Mock/none | ✅ Real Let's Encrypt |
| Domain routing | ❌ /etc/hosts | ✅ Real DNS |
| Cloudflare integration | ❌ No | ✅ Full tunnel |
| Speed | ✅ Fast | ⏳ Slower |
| Risk | ✅ Safe | ⚠️ Production |
| Debugging | ✅ Easy | ⏳ SSH required |

**Recommended workflow:**
1. **Local first**: Test basic routing, labels, middleware
2. **Server deploy**: Test SSL, real domains, performance
3. **Iterate**: Use local for development, server for validation

### Bước 6: Troubleshooting cơ bản

```bash
# Check container status
docker ps

# Check Traefik logs
docker logs traefik -f

# Check if services are discovered
curl http://localhost:8080/api/http/services

# Test internal connectivity
docker exec traefik ping whoami
```

## 📚 Phase 2: Bảo mật và monitoring (🔧)

### Mục tiêu
- Middleware cho bảo mật
- Dashboard để monitor
- Hardening security
- Tối ưu performance

### Bước 1: Advanced Middleware

#### 1.1 Cập nhật `traefik/dynamic_conf.yml`
```yaml
http:
  middlewares:
    # Advanced security headers
    security-headers:
      headers:
        frameDeny: true
        sslRedirect: true
        browserXssFilter: true
        contentTypeNosniff: true
        forceSTSHeader: true
        stsIncludeSubdomains: true
        stsPreload: true
        stsSeconds: 31536000
        customFrameOptionsValue: "SAMEORIGIN"
        customRequestHeaders:
          X-Forwarded-Proto: "https"
        customResponseHeaders:
          X-Robots-Tag: "none"
          server: "jarvis-proxy"

    # IP whitelist cho admin
    admin-whitelist:
      ipWhiteList:
        sourceRange:
          - "192.168.1.0/24"    # Local network
          - "10.0.0.0/8"        # Private network
          - "YOUR_IP_HERE/32"   # Your public IP

    # Rate limiting tiers
    rate-limit-api:
      rateLimit:
        average: 50
        burst: 10

    rate-limit-web:
      rateLimit:
        average: 200
        burst: 50

    # Error handling
    error-pages:
      errors:
        status:
          - "404"
          - "500"
          - "503"
        service: error-handler
        query: "/{status}.html"

    # Path stripping
    strip-prefix:
      stripPrefix:
        prefixes:
          - "/api/v1"

    # CORS
    cors:
      headers:
        accessControlAllowOriginList:
          - "https://jarvis.thanhpt.xyz"
          - "https://*.jarvis.thanhpt.xyz"
        accessControlAllowMethods:
          - "GET"
          - "POST"
          - "PUT"
          - "DELETE"
          - "OPTIONS"
        accessControlAllowHeaders:
          - "Content-Type"
          - "Authorization"
          - "X-Requested-With"

  # Services
  services:
    error-handler:
      loadBalancer:
        servers:
          - url: "http://error-pages:8080"
```

### Bước 2: Monitoring Stack

#### 2.1 Thêm Prometheus + Grafana
```yaml
# Thêm vào docker-compose.yml
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.prometheus.rule=Host(`prometheus.${DOMAIN}`)"
      - "traefik.http.routers.prometheus.middlewares=auth,secure-headers"
      - "traefik.http.routers.prometheus.tls.certresolver=cloudflare"
    networks:
      - jarvis-proxy

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=your_secure_password
    volumes:
      - grafana_data:/var/lib/grafana
      - ./monitoring/grafana/provisioning:/etc/grafana/provisioning:ro
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.grafana.rule=Host(`grafana.${DOMAIN}`)"
      - "traefik.http.routers.grafana.middlewares=secure-headers"
      - "traefik.http.routers.grafana.tls.certresolver=cloudflare"
    networks:
      - jarvis-proxy

volumes:
  prometheus_data:
  grafana_data:
```

#### 2.2 File `monitoring/prometheus.yml`
```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'traefik'
    static_configs:
      - targets: ['traefik:8080']
    metrics_path: /metrics

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
```

### Bước 3: Security Hardening

#### 3.1 Fail2ban cho Traefik
```bash
# Cài đặt fail2ban
sudo apt install fail2ban

# Tạo config cho Traefik
sudo nano /etc/fail2ban/jail.d/traefik.conf
```

```ini
[traefik-auth]
enabled = true
port = http,https
filter = traefik-auth
logpath = /var/log/traefik/access.log
maxretry = 3
bantime = 86400
findtime = 43200
```

#### 3.2 Docker security
```yaml
# Thêm vào traefik service trong docker-compose.yml
security_opt:
  - no-new-privileges:true
read_only: true
tmpfs:
  - /tmp
user: "1000:1000"  # Non-root user
```

## 📚 Phase 3: Scale và HA (⚙️)

### Mục tiêu
- Load balancing nhiều instances
- Health checks
- Failover
- Performance tuning

### Bước 1: Load Balancing Setup

#### 1.1 Multiple app instances
```yaml
# Ví dụ với app có multiple replicas
services:
  web-app:
    image: your-app:latest
    deploy:
      replicas: 3
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.webapp.rule=Host(`app.${DOMAIN}`)"
      - "traefik.http.services.webapp.loadbalancer.server.port=3000"
      # Health check
      - "traefik.http.services.webapp.loadbalancer.healthcheck.path=/health"
      - "traefik.http.services.webapp.loadbalancer.healthcheck.interval=30s"
      - "traefik.http.services.webapp.loadbalancer.healthcheck.timeout=5s"
      # Sticky sessions
      - "traefik.http.services.webapp.loadbalancer.sticky.cookie=true"
      - "traefik.http.services.webapp.loadbalancer.sticky.cookie.name=server"
    networks:
      - jarvis-proxy
```

### Bước 2: Database và Cache Layer

#### 2.1 Redis cho session storage
```yaml
  redis:
    image: redis:7-alpine
    container_name: redis
    restart: unless-stopped
    command: redis-server --requirepass your_redis_password
    volumes:
      - redis_data:/data
    labels:
      - "traefik.enable=true"
      - "traefik.tcp.routers.redis.rule=HostSNI(`*`)"
      - "traefik.tcp.routers.redis.entrypoints=redis"
      - "traefik.tcp.services.redis.loadbalancer.server.port=6379"
    networks:
      - jarvis-proxy

volumes:
  redis_data:
```

## 📚 Phase 4: Automation (🧠)

### Mục tiêu
- CI/CD với GitHub Actions
- Automated backup
- Disaster recovery
- Production monitoring

### Bước 1: GitHub Actions CI/CD

#### 1.1 File `.github/workflows/deploy.yml`
```yaml
name: Deploy to Production

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup SSH
      uses: webfactory/ssh-agent@v0.7.0
      with:
        ssh-private-key: ${{ secrets.SSH_PRIVATE_KEY }}
    
    - name: Deploy to server
      run: |
        ssh -o StrictHostKeyChecking=no ${{ secrets.SSH_USER }}@${{ secrets.SSH_HOST }} '
          cd /opt/jarvis-proxy
          git pull origin main
          docker-compose down
          docker-compose pull
          docker-compose up -d
          docker system prune -f
        '
    
    - name: Health check
      run: |
        sleep 30
        curl -f https://dashboard.jarvis.thanhpt.xyz/ping || exit 1
```

### Bước 2: Backup Strategy

#### 2.1 Script backup tự động
```bash
#!/bin/bash
# backup.sh

BACKUP_DIR="/backup/jarvis-proxy"
DATE=$(date +%Y%m%d_%H%M%S)

# Backup configurations
tar -czf "$BACKUP_DIR/config_$DATE.tar.gz" \
  traefik/ cloudflared/ docker-compose.yml .env

# Backup SSL certificates
cp traefik/acme.json "$BACKUP_DIR/acme_$DATE.json"

# Backup to S3 (optional)
aws s3 cp "$BACKUP_DIR/config_$DATE.tar.gz" \
  s3://your-backup-bucket/jarvis-proxy/

# Cleanup old backups (keep last 30 days)
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 -delete
```

## 🔧 Troubleshooting

### Common Issues

#### SSL Certificate Issues
```bash
# Check certificate status
docker exec traefik cat /etc/traefik/acme.json | jq

# Force certificate renewal
docker exec traefik traefik-cert-renew

# Check DNS propagation
dig TXT _acme-challenge.jarvis.thanhpt.xyz
```

#### Routing Issues
```bash
# Check Traefik logs
docker logs traefik -f

# Verify container labels
docker inspect container_name | jq '.[0].Config.Labels'

# Test internal connectivity
docker exec traefik ping app_container
```

#### Performance Issues
```bash
# Monitor resource usage
docker stats

# Check Traefik metrics
curl http://localhost:8080/metrics

# Analyze access logs
tail -f logs/traefik/access.log | grep "response_time"
```

## 📈 Performance Tuning

### Traefik Optimization
```yaml
# traefik.yml performance settings
providers:
  docker:
    exposedByDefault: false
    pollInterval: "10s"

entryPoints:
  websecure:
    address: ":443"
    http:
      tls:
        options: default
        
# TLS configuration
tls:
  options:
    default:
      sslProtocols:
        - "TLSv1.2"
        - "TLSv1.3"
      cipherSuites:
        - "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
        - "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305"
```

Đó là plan cá nhân của mình để setup jarvis-proxy từ cơ bản đến đủ xài production. 
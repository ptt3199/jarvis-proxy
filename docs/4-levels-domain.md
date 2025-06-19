## 🌐 Domain 4 cấp với Cloudflared

### Câu hỏi: Có setup được `api.v1.homecam.jarvis.thanhpt.xyz` không?

**Trả lời: Có!** Cloudflare + Traefik hỗ trợ nhiều tầng subdomain.

### Setup:

#### 1. Cloudflare DNS
```bash
# Wildcard cho tất cả subdomain levels
*.jarvis.thanhpt.xyz      A    YOUR_SERVER_IP
*.*.jarvis.thanhpt.xyz    A    YOUR_SERVER_IP  # 4+ levels
```

#### 2. Cloudflared Config
```yaml
# cloudflared/config.yml
tunnel: your-tunnel-id
credentials-file: /etc/cloudflared/credentials.json

ingress:
  - hostname: "*.jarvis.thanhpt.xyz"
    service: http://traefik:80
  - hostname: "*.*.jarvis.thanhpt.xyz"  # 4+ levels
    service: http://traefik:80
  - service: http_status:404
```

#### 3. Traefik Labels
```yaml
# Ví dụ routing 4 cấp
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.api-v1.rule=Host(`api.v1.homecam.jarvis.thanhpt.xyz`)"
  - "traefik.http.services.api-v1.loadbalancer.server.port=3000"
```

### Kết quả có thể có:
- `api.v1.homecam.jarvis.thanhpt.xyz` → API version 1
- `api.v2.homecam.jarvis.thanhpt.xyz` → API version 2  
- `admin.dashboard.jarvis.thanhpt.xyz` → Admin panel
- `grafana.monitoring.jarvis.thanhpt.xyz` → Grafana

**Lưu ý**: Cloudflared chỉ tunnel traffic về server, Traefik sẽ route dựa trên hostname.
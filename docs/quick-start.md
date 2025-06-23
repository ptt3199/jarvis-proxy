# Quick Start Guide

Hướng dẫn nhanh sử dụng Traefik Service Management System.

## 🚀 Thêm Service Mới

### Backend API
```bash
./cli/generate-service.sh -n chat -t api -p 3001
```
- Tạo: `11-backend-chat.yml`
- Domain: `chat-api.thanhpt.xyz`

### Frontend Only
```bash  
./cli/generate-service.sh -n blog -t frontend -u https://blog.vercel.app
```
- Append vào: `90-frontend-routes.yml`
- Domain: `blog.thanhpt.xyz`

### Full Stack
```bash
./cli/generate-service.sh -n admin -t both -p 4000 -u https://admin.vercel.app
```
- API: `admin-api.thanhpt.xyz`  
- Frontend: `admin.thanhpt.xyz`

## 📋 Commands

| Command | Action |
|---------|--------|
| `./cli/generate-service.sh -h` | Show help |
| `docker logs traefik --tail 20` | Check logs |
| `docker network inspect jarvis-proxy` | Check network |
| `curl -H 'Host: service.thanhpt.xyz' http://localhost` | Test route |

## 📁 File Structure

```
traefik/dynamic/
├── 00-middlewares.yml        # Shared configs
├── 10-backend-{name}.yml     # Individual backends  
└── 90-frontend-routes.yml    # All frontends
```

## 🔧 Debug 502 Errors

1. Check container running: `docker ps | grep service-name`
2. Check network: `docker network inspect jarvis-proxy`
3. Test connectivity: `docker exec traefik curl http://service:port`
4. Check logs: `docker logs traefik --tail 50`

## 📊 Domain Patterns

- **Frontend**: `service.thanhpt.xyz`
- **Backend API**: `service-api.thanhpt.xyz`  
- **Dashboard**: `dashboard.thanhpt.xyz`

---

📖 **Full Documentation**: [traefik-service-management.md](./traefik-service-management.md) 
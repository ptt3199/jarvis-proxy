# Jarvis Proxy

Mô hình Self-managed Platform as a Service (PaaS)

## 1. Kiến trúc

```bash
Cloudflare DNS (*.thanhpt.xyz)
           ↓
        Traefik (reverse proxy, SSL, routing)
           ↓
  ┌───────────────────────┐
  │   Docker host server  │
  └───────────────────────┘
      ↓                 ↓
  Portainer          App Container (backend)
      ↓                 
Khởi động app, gán vào network của Traefik
```

### Quy trình triển khai app mới
1. Traefik container chạy sẵn với network riêng (`traefik-net`)
2. Portainer chạy để quản lí app container qua web UI
3. App containers được tạo mới qua Portainer:
  - Gắn vào `traefik-net`
  - Có label `traefik.enable=true` và các label định tuyến

## 2. Nhiệm vụ 

- [x] Chạy Traefik container, cài đặt tunnel cloudflare, kiểm tra connection
  - [x] Cấu hình tunnel `*.thanhpt.xyz` trỏ vào `localhost:80` của traefik 
  - [x] Thêm DND wildcard CNAME `*`
  - [x] Kiểm tra từ trình duyệt, có thể truy cập vào `dashboard.thanhpt.xyz` -> traefik dashboard 8080 và `whoami.thanhpt.xyz` -> traefik whoami

- [ ] Cấu hình truy cập động cho app container
  - [x] Thử với homecam-api (một backend service đang chạy sẵn)
    - [x] Thêm `homecam-api` vào network `jarvis-proxy`: `docker network connect jarvis-proxy homecam-api`
    - [x] Cấu hình cho `cam.thanhpt.xyz` trỏ vào container `homecam-api` trong file `traefik/dynamic_conf.yml` -> Kiểm tra xem có truy cập được không (traefik không khởi động lại)
  - [x] Viết script để tự động thêm service mới
    - [x] Thêm service vào network `jarvis-proxy`
    - [x] Thêm service vào file `traefik/dynamic_conf.yml`
    
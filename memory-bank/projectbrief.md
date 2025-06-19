# Project Brief: jarvis-proxy

## Overview
**jarvis-proxy** is a reverse proxy & gateway stack designed for routing web services in the Jarvis system ecosystem. Built on Traefik and Docker, it provides a modern, automated infrastructure for managing microservices routing, SSL certificates, and service discovery.

## Core Requirements

### Primary Objectives
- **Automated Routing**: Route incoming requests to appropriate backend services
- **SSL Management**: Automatic SSL certificate provisioning and renewal via Let's Encrypt
- **Service Discovery**: Auto-discovery of Docker containers with zero-downtime deployments
- **Security**: Built-in protection via Cloudflare Tunnel integration and middleware
- **Scalability**: Support for multiple applications with load balancing capabilities

### Technical Stack
- **Reverse Proxy**: Traefik v2.x
- **Container Orchestration**: Docker Compose
- **SSL Provider**: Let's Encrypt (DNS Challenge)
- **Tunnel**: Cloudflared for secure external access
- **Platform**: Ubuntu Server

### Routing Strategies
1. **Subdomain Routing** (Recommended)
   - `homecam.jarvis.thanhpt.xyz` → app1:8001
   - `flashcard.jarvis.thanhpt.xyz` → app2:8002
   
2. **Path-based Routing** (Alternative)
   - `jarvis.thanhpt.xyz/homecam` → app1
   - `jarvis.thanhpt.xyz/flashcard` → app2

### Security Requirements
- No public port exposure (Cloudflare Tunnel only)
- Basic authentication for admin interfaces
- Rate limiting for API endpoints
- Automatic HTTPS enforcement

### Success Criteria
- Zero-downtime service additions/removals
- Sub-second SSL certificate provisioning
- Dashboard monitoring for all services
- Automated deployment pipeline integration

## Project Scope
This project serves as the foundational infrastructure for the Jarvis ecosystem, enabling:
- Easy microservice deployment
- Centralized traffic management  
- DevOps learning platform
- Production-ready service mesh 
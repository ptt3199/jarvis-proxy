#!/bin/bash
# Generate new service configuration

show_help() {
    echo "🚀 Service Generator for Traefik"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
echo "  -n, --name        Service name (e.g., chat, blog, admin)"
echo "  -t, --type        Service type: api (frontends use Vercel+Cloudflare direct)"
echo "  -p, --port        Backend port (for API services)"
    echo "  -h, --help        Show this help"
    echo ""
    echo "Examples:"
echo "  $0 -n chat -t api -p 3001"
echo ""
echo "Note: Frontends connect directly via Vercel+Cloudflare DNS"
echo "      No need to route through Traefik"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            SERVICE_NAME="$2"
            shift 2
            ;;
        -t|--type)
            SERVICE_TYPE="$2"
            shift 2
            ;;
        -p|--port)
            SERVICE_PORT="$2"
            shift 2
            ;;
        -u|--url)
            FRONTEND_URL="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate inputs
if [ -z "$SERVICE_NAME" ] || [ -z "$SERVICE_TYPE" ]; then
    echo "❌ Service name and type are required!"
    show_help
    exit 1
fi

if [[ "$SERVICE_TYPE" != "api" ]]; then
    echo "❌ Service type must be: api"
    echo "💡 Frontends connect directly via Vercel+Cloudflare DNS"
    exit 1
fi

if [ -z "$SERVICE_PORT" ]; then
    echo "❌ Port is required for API services"
    exit 1
fi

# Go to project root
cd "$(dirname "$0")/.."

# Generate config file based on service type
if [[ "$SERVICE_TYPE" =~ ^(api|both)$ ]]; then
    # Backend services: 10-19 range
    NEXT_NUM=$((10 + $(ls traefik/dynamic/1*-*.yml 2>/dev/null | wc -l)))
    CONFIG_FILE="traefik/dynamic/$(printf "%02d" $NEXT_NUM)-backend-${SERVICE_NAME}.yml"
else
    # Frontend-only services: Add to existing frontend routes file
    CONFIG_FILE="traefik/dynamic/90-frontend-routes.yml"
fi

echo "📝 Generating config: $CONFIG_FILE"

# Handle frontend-only services (append to existing file)
if [[ "$SERVICE_TYPE" == "frontend" ]]; then
    echo "📝 Adding frontend route to existing file..."
    
    # Add frontend service to services section
    sed -i '/^    # Future: Chat Frontend/i\
    # '"${SERVICE_NAME^}"' Frontend\
    '"${SERVICE_NAME}"'-frontend:\
      loadBalancer:\
        servers:\
          - url: "'"${FRONTEND_URL}"'"\
\
' "$CONFIG_FILE"
    
    # Add frontend router to routers section
    sed -i '/^    # Future routers/i\
    # '"${SERVICE_NAME^}"' Frontend Router\
    '"${SERVICE_NAME}"'-frontend:\
      rule: "Host(\`'"${SERVICE_NAME}"'.thanhpt.xyz\`)"\
      service: '"${SERVICE_NAME}"'-frontend\
      entryPoints:\
        - web\
      middlewares:\
        - securityHeaders\
        - gzip\
\
' "$CONFIG_FILE"
    
else
    # Create new file for backend services
    cat > "$CONFIG_FILE" << EOF
# ${SERVICE_NAME^} Service Configuration
# Generated on $(date)

http:
EOF

    # Add services section
    echo "  services:" >> "$CONFIG_FILE"
fi

# Add API service if needed
if [[ "$SERVICE_TYPE" =~ ^(api|both)$ ]]; then
    cat >> "$CONFIG_FILE" << EOF
    # ${SERVICE_NAME^} API Backend
    ${SERVICE_NAME}-api:
      loadBalancer:
        servers:
          - url: "http://${SERVICE_NAME}-api:${SERVICE_PORT}"

EOF
fi

# Add frontend service if needed
if [[ "$SERVICE_TYPE" =~ ^(frontend|both)$ ]]; then
    cat >> "$CONFIG_FILE" << EOF
    # ${SERVICE_NAME^} Frontend
    ${SERVICE_NAME}-frontend:
      loadBalancer:
        servers:
          - url: "${FRONTEND_URL}"

EOF
fi

# Add routers section
echo "  routers:" >> "$CONFIG_FILE"

# Add API router if needed
if [[ "$SERVICE_TYPE" =~ ^(api|both)$ ]]; then
    cat >> "$CONFIG_FILE" << EOF
    # ${SERVICE_NAME^} API Router
    ${SERVICE_NAME}-api:
      rule: "Host(\`${SERVICE_NAME}-api.thanhpt.xyz\`)"
      service: ${SERVICE_NAME}-api
      entryPoints:
        - web
      middlewares:
        - corsApi
        - securityHeaders
        - rateLimit
        - gzip

EOF
fi

# Add frontend router if needed
if [[ "$SERVICE_TYPE" =~ ^(frontend|both)$ ]]; then
    cat >> "$CONFIG_FILE" << EOF
    # ${SERVICE_NAME^} Frontend Router
    ${SERVICE_NAME}-frontend:
      rule: "Host(\`${SERVICE_NAME}.thanhpt.xyz\`)"
      service: ${SERVICE_NAME}-frontend
      entryPoints:
        - web
      middlewares:
        - securityHeaders
        - gzip

EOF
fi

echo "✅ Generated configuration for $SERVICE_NAME ($SERVICE_TYPE)"

# Connect to network if API service
if [[ "$SERVICE_TYPE" =~ ^(api|both)$ ]]; then
    echo "🔗 Connecting ${SERVICE_NAME}-api to jarvis-proxy network..."
    docker network connect jarvis-proxy "${SERVICE_NAME}-api" 2>/dev/null || echo "⚠️  Container not found or already connected"
fi

# Skip file creation for frontend-only services (already handled above)
if [[ "$SERVICE_TYPE" == "frontend" ]]; then
    echo ""
    echo "📋 Summary:"
    echo "  🌐 Frontend: https://${SERVICE_NAME}.thanhpt.xyz → ${FRONTEND_URL}"
    echo ""
    echo "🔄 Traefik will auto-reload the configuration"
    echo "📊 Check dashboard: https://dashboard.thanhpt.xyz"
    exit 0
fi

echo ""
echo "📋 Summary:"
if [[ "$SERVICE_TYPE" =~ ^(api|both)$ ]]; then
    echo "  🔧 API: https://${SERVICE_NAME}-api.thanhpt.xyz → ${SERVICE_NAME}-api:${SERVICE_PORT}"
fi
if [[ "$SERVICE_TYPE" =~ ^(frontend|both)$ ]]; then
    echo "  🌐 Frontend: https://${SERVICE_NAME}.thanhpt.xyz → ${FRONTEND_URL}"
fi
echo ""
echo "🔄 Traefik will auto-reload the configuration"
echo "📊 Check dashboard: https://dashboard.thanhpt.xyz" 
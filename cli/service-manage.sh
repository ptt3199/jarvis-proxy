#!/bin/bash
# Add service to traefik

# Function to list services in table format
list_services() {
    echo "📋 Current services in Traefik:"
    echo ""
    
    cd "$(dirname "$0")/.."
    
    if [ ! -f "traefik/dynamic_conf.yml" ]; then
        echo "❌ traefik/dynamic_conf.yml not found!"
        exit 1
    fi
    
    # Header
    printf "%-20s %-30s %-20s %-10s\n" "SERVICE" "DOMAIN" "URL" "STATUS"
    printf "%-20s %-30s %-20s %-10s\n" "--------------------" "------------------------------" "--------------------" "----------"
    
    # Extract services and routers info
    temp_file=$(mktemp)
    
    # Get services
    awk '/^  services:/,/^  # Routers configuration/ {
        if ($0 ~ /^    [a-zA-Z0-9-]+:$/) {
            service = $1
            gsub(/:/, "", service)
        }
        if ($0 ~ /- url:/) {
            gsub(/.*"/, "", $0)
            gsub(/".*/, "", $0)
            print service ":" $0
        }
    }' traefik/dynamic_conf.yml > "$temp_file.services"
    
    # Get routers
    awk '/^  routers:/,EOF {
        if ($0 ~ /^    [a-zA-Z0-9-]+:$/) {
            router = $1
            gsub(/:/, "", router)
        }
        if ($0 ~ /rule: "Host/) {
            gsub(/.*Host\(`/, "", $0)
            gsub(/`\).*/, "", $0)
            print router ":" $0
        }
    }' traefik/dynamic_conf.yml > "$temp_file.routers"
    
    # Combine and display
    while IFS=: read -r service url; do
        domain=$(grep "^$service:" "$temp_file.routers" | cut -d: -f2)
        if [ -z "$domain" ]; then
            domain="N/A"
        fi
        
        # Check if service is running
        if docker ps --format "table {{.Names}}" | grep -q "^$service$"; then
            status="🟢 UP"
        else
            status="🔴 DOWN"
        fi
        
        printf "%-20s %-30s %-20s %-10s\n" "$service" "$domain" "$url" "$status"
    done < "$temp_file.services"
    
    rm -f "$temp_file.services" "$temp_file.routers"
    echo ""
}

# Function to remove service
remove_service() {
    echo "🗑️  Remove service from Traefik"
    echo ""
    
    # List current services first
    list_services
    
    read -p "Enter service name to remove: " service_name
    
    if [ -z "$service_name" ]; then
        echo "❌ Service name is required!"
        exit 1
    fi
    
    cd "$(dirname "$0")/.."
    
    # Check if service exists in config
    if ! grep -q "^    $service_name:" traefik/dynamic_conf.yml; then
        echo "❌ Service '$service_name' not found in configuration!"
        exit 1
    fi
    
    # Confirm removal
    read -p "⚠️  Remove service '$service_name'? This will disconnect it from network too. (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "❌ Removal cancelled"
        exit 0
    fi
    
    echo "💾 Backing up dynamic_conf.yml..."
    cp traefik/dynamic_conf.yml traefik/dynamic_conf.yml.backup
    
    # Remove service from services section
    echo "🔄 Removing service from configuration..."
    sed -i "/^    # Service for $service_name$/,/^    [a-zA-Z]/{ /^    [a-zA-Z]/!d; }" traefik/dynamic_conf.yml
    sed -i "/^    $service_name:$/,/^$/d" traefik/dynamic_conf.yml
    
    # Remove router from routers section  
    echo "🔄 Removing router from configuration..."
    sed -i "/^    # Router for $service_name$/,/^$/d" traefik/dynamic_conf.yml
    
    # Disconnect from network
    echo "🔌 Disconnecting $service_name from jarvis-proxy network..."
    docker network disconnect jarvis-proxy $service_name 2>/dev/null || echo "⚠️  Service not connected to network"
    
    echo "✅ Service '$service_name' removed successfully!"
    echo "🔄 Traefik will auto-reload the configuration"
    echo "💡 To rollback: ./cli/add-service.sh --rollback"
}

# Check for flags
case "$1" in
    "--list"|"-l")
        list_services
        exit 0
        ;;
    "--remove"|"-rm")
        remove_service
        exit 0
        ;;
    "--rollback"|"-r")
        echo "🔄 Rolling back traefik configuration..."
        
        cd "$(dirname "$0")/.."
        
        if [ ! -f "traefik/dynamic_conf.yml.backup" ]; then
            echo "❌ No backup file found! Cannot rollback."
            echo "💡 Backup file should be at: traefik/dynamic_conf.yml.backup"
            exit 1
        fi
        
        read -p "⚠️  This will overwrite current config. Continue? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "❌ Rollback cancelled"
            exit 0
        fi
        
        echo "🔄 Restoring configuration from backup..."
        cp traefik/dynamic_conf.yml.backup traefik/dynamic_conf.yml
        
        echo "✅ Configuration restored successfully!"
        echo "🔄 Traefik will auto-reload the configuration"
        exit 0
        ;;
    "--help"|"-h")
        echo "🚀 Traefik Service Manager"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  -l,  --list       List all current services"
        echo "  -rm, --remove     Remove a service"
        echo "  -r,  --rollback   Rollback to backup configuration"  
        echo "  -h,  --help       Show this help message"
        echo ""
        echo "Without options: Add new service interactively"
        echo ""
        echo "Examples:"
        echo "  $0                    # Add new service"
        echo "  $0 --list            # List services"
        echo "  $0 --remove          # Remove service"
        echo "  $0 --rollback        # Rollback changes"
        exit 0
        ;;
esac

# Add new service (default behavior)
echo "➕ Add new service to Traefik"
echo ""

# Prompt service name, port, sub domain
read -p "Service name: " service_name

# Check if service exist in docker, if not, exit
if [ -z "$(docker ps --format "table {{.Names}}" | grep -q "^$service_name$")" ]; then
  echo "❌ Service $service_name not found"
  exit 1
fi

# Check if service already exist in dynamic_conf.yml, if so, exit
if grep -q "^    $service_name:" traefik/dynamic_conf.yml; then
  echo "❌ Service $service_name already exists"
  exit 1
fi

read -p "Port: " port  
read -p "Sub Domain: " sub_domain

# Validate sub domain
if [[ ! "$sub_domain" =~ ^[a-z0-9]+$ ]]; then
  echo "❌ Sub domain must be lowercase letters and numbers"
  exit 1
fi

domain="$sub_domain.thanhpt.xyz"

# Validate inputs
if [ -z "$service_name" ] || [ -z "$port" ] || [ -z "$sub_domain" ]; then
  echo "❌ All fields are required!"
  exit 1
fi

# Add service to Docker Network `jarvis-proxy`
echo "🔗 Connecting $service_name to jarvis-proxy network..."
docker network connect jarvis-proxy $service_name 2>/dev/null || echo "⚠️  Service already connected to network"

echo "🔗 Adding service $service_name to $domain"

# Go to project root (parent of cli directory)
cd "$(dirname "$0")/.."

echo "💾 Backing up dynamic_conf.yml..."
cp traefik/dynamic_conf.yml traefik/dynamic_conf.yml.backup

echo "🔄 Adding service to dynamic_conf.yml..."
sed -i '/^  # Routers configuration/i\
\
    # Service for '"$service_name"'\
    '"$service_name"':\
      loadBalancer:\
        servers:\
          - url: "http://'"$service_name"':'"$port"'"\
' traefik/dynamic_conf.yml

echo "🔄 Adding router to dynamic_conf.yml..."
cat >> traefik/dynamic_conf.yml << EOF

    # Router for $service_name
    $service_name:
      rule: "Host(\`$domain\`)"
      service: $service_name
      entryPoints:
        - web
      middlewares:
        - securityHeaders
        - rateLimit
        - gzip
EOF

echo "✅ Added service '$service_name' with domain '$domain' pointing to port $port"
echo "🔄 Traefik will auto-reload the configuration"
echo "🌐 Test: curl -H 'Host: $domain' http://localhost"
echo "📊 Check dashboard: http://dashboard.thanhpt.xyz"
echo ""
echo "💡 Management commands:"
echo "   List services: ./cli/add-service.sh --list"
echo "   Remove service: ./cli/add-service.sh --remove" 
echo "   Rollback: ./cli/add-service.sh --rollback"

# Validate YAML syntax
if command -v yq &> /dev/null; then
    if yq eval traefik/dynamic_conf.yml > /dev/null 2>&1; then
        echo "✅ YAML syntax is valid"
    else
        echo "❌ YAML syntax error! Restoring backup..."
        cp traefik/dynamic_conf.yml.backup traefik/dynamic_conf.yml
        exit 1
    fi
else
    echo "⚠️  yq not found - couldn't validate YAML syntax"
fi
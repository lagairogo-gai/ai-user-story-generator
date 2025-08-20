#!/bin/bash
set -e

echo "🔧 Fixing nginx configuration error..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_step() {
    echo -e "${YELLOW}[STEP]${NC} $1"
}

log_step "Creating corrected nginx configuration..."

# Create corrected nginx.conf without the problematic gzip_proxied line
cat > frontend/nginx.conf << 'EOF'
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # Gzip compression (fixed configuration)
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "strict-origin-when-cross-origin";

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    # Handle React routing
    location / {
        try_files $uri $uri/ /index.html;
    }

    # API proxy to backend
    location /api/ {
        proxy_pass http://backend:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
}
EOF

log_info "✅ Created corrected nginx configuration"

log_step "Stopping the problematic frontend container..."

# Stop the current frontend container
docker-compose stop frontend

log_step "Rebuilding frontend with fixed configuration..."

# Rebuild the frontend image
docker-compose build frontend

log_step "Starting frontend service..."

# Start the frontend service
docker-compose up -d frontend

log_step "Waiting for frontend to start..."

# Wait for the service to start
sleep 10

log_step "Checking frontend status..."

# Check the status
echo "=== Frontend Container Status ==="
docker ps | grep frontend

echo ""
echo "=== Recent Frontend Logs ==="
docker-compose logs --tail=10 frontend

echo ""
echo "=== Testing Frontend Health Check ==="

# Test the health check
for i in {1..5}; do
    echo "Attempt $i/5..."
    if curl -f -s http://localhost:3000/health > /dev/null; then
        log_info "✅ Frontend health check: WORKING"
        break
    else
        echo "❌ Frontend health check: Not ready yet, waiting..."
        sleep 5
    fi
done

echo ""
echo "=== Testing Frontend Main Page ==="

# Test the main page
if curl -f -s http://localhost:3000/ > /dev/null; then
    log_info "✅ Frontend main page: WORKING"
else
    echo "❌ Frontend main page: Not ready yet"
fi

echo ""
echo "=== All Service Status ==="
docker-compose ps

echo ""
echo "================================================"
log_info "🎉 Frontend Fix Applied!"
echo "================================================"
echo ""

# Check if any services are still restarting
if docker ps | grep -q "Restarting"; then
    echo "⚠️  Some services may still be starting up..."
    echo "   Run this command in 1-2 minutes to check: docker-compose ps"
else
    log_info "✅ All services appear stable!"
fi

echo ""
echo "🌐 Access your application:"
echo "  Frontend:    http://localhost:3000"
echo "  Backend API: http://localhost:8000/api/health"
echo "  Grafana:     http://localhost:3001 (admin/admin)"
echo "  Prometheus:  http://localhost:9090"
echo ""
echo "🔧 Useful commands:"
echo "  docker-compose ps                    # Check service status"
echo "  docker-compose logs frontend        # View frontend logs"
echo "  curl http://localhost:3000/health   # Test frontend health"
echo "  curl http://localhost:8000/api/health # Test backend API"

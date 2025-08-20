#!/bin/bash
set -e

echo "🌐 Configuring external network access..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_step() {
    echo -e "${YELLOW}[STEP]${NC} $1"
}

log_note() {
    echo -e "${BLUE}[NOTE]${NC} $1"
}

log_step "Checking current network configuration..."

echo "Current Docker port bindings:"
docker-compose ps

echo ""
echo "Current network interfaces:"
ip addr show | grep -E "inet.*scope global"

log_step "Updating Docker Compose for external access..."

# Update docker-compose.yml to bind to all interfaces (0.0.0.0)
cat > docker-compose.yml << 'EOF'
services:
  # React Frontend - accessible from external IP
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
      target: production
    ports:
      - "0.0.0.0:3000:80"  # Bind to all interfaces
    environment:
      - NODE_ENV=production
    depends_on:
      - backend
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
    networks:
      - app-network

  # FastAPI Backend - accessible from external IP
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
      target: production
    ports:
      - "0.0.0.0:8000:8000"  # Bind to all interfaces
    environment:
      - DATABASE_URL=postgresql://postgres:${POSTGRES_PASSWORD:-password}@db:5432/${POSTGRES_DB:-userstories}
      - REDIS_URL=redis://redis:6379
      - ENVIRONMENT=production
      - LOG_LEVEL=info
      - OPENAI_API_KEY=${OPENAI_API_KEY:-}
    volumes:
      - backend_uploads:/app/uploads
      - backend_chroma:/app/chroma_db
      - backend_logs:/app/logs
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    networks:
      - app-network

  # PostgreSQL Database
  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=${POSTGRES_DB:-userstories}
      - POSTGRES_USER=${POSTGRES_USER:-postgres}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-password}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "0.0.0.0:5432:5432"  # Accessible from external IP
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-postgres}"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - app-network

  # Redis Cache
  redis:
    image: redis:7-alpine
    ports:
      - "0.0.0.0:6379:6379"  # Accessible from external IP
    volumes:
      - redis_data:/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    command: redis-server --appendonly yes --maxmemory 512mb --maxmemory-policy allkeys-lru
    networks:
      - app-network

  # ChromaDB Vector Database
  chromadb:
    image: chromadb/chroma:latest
    ports:
      - "0.0.0.0:8001:8000"  # Accessible from external IP
    volumes:
      - chroma_data:/chroma/chroma
    environment:
      - CHROMA_SERVER_HOST=0.0.0.0
      - CHROMA_SERVER_HTTP_PORT=8000
    restart: unless-stopped
    networks:
      - app-network

  # Prometheus Monitoring
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "0.0.0.0:9090:9090"  # Accessible from external IP
    volumes:
      - ./monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
    restart: unless-stopped
    networks:
      - app-network

  # Grafana Dashboard
  grafana:
    image: grafana/grafana:latest
    ports:
      - "0.0.0.0:3001:3000"  # Accessible from external IP
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD:-admin}
      - GF_SECURITY_ADMIN_USER=${GRAFANA_USER:-admin}
    volumes:
      - grafana_data:/var/lib/grafana
    depends_on:
      - prometheus
    restart: unless-stopped
    networks:
      - app-network

volumes:
  postgres_data:
  redis_data:
  chroma_data:
  prometheus_data:
  grafana_data:
  backend_uploads:
  backend_chroma:
  backend_logs:

networks:
  app-network:
    driver: bridge
EOF

log_info "✅ Updated Docker Compose for external access"

log_step "Checking firewall status..."

# Check if ufw is active and blocking ports
if command -v ufw >/dev/null 2>&1; then
    echo "UFW Status:"
    sudo ufw status
    
    log_step "Opening required ports in firewall..."
    
    # Open ports in firewall
    sudo ufw allow 3000/tcp comment "AI User Story Generator Frontend"
    sudo ufw allow 8000/tcp comment "AI User Story Generator Backend"
    sudo ufw allow 3001/tcp comment "Grafana Dashboard"
    sudo ufw allow 9090/tcp comment "Prometheus"
    
    log_info "✅ Firewall ports opened"
else
    log_note "UFW not found, skipping firewall configuration"
fi

log_step "Restarting services with new configuration..."

# Restart services with new port bindings
docker-compose down
docker-compose up -d

log_step "Waiting for services to start..."
sleep 30

log_step "Testing external access..."

# Get the external IP
EXTERNAL_IP=$(ip route get 8.8.8.8 | awk '{print $7}' | head -n1)
log_info "Detected external IP: $EXTERNAL_IP"

echo ""
echo "=== Testing Local Access ==="
# Test local access first
if curl -f -s http://localhost:3000/health > /dev/null; then
    log_info "✅ Local frontend: Working"
else
    echo "❌ Local frontend: Not responding"
fi

if curl -f -s http://localhost:8000/api/health > /dev/null; then
    log_info "✅ Local backend: Working"
else
    echo "❌ Local backend: Not responding"
fi

echo ""
echo "=== Testing External Access ==="
# Test external access
if curl -f -s http://$EXTERNAL_IP:3000/health > /dev/null; then
    log_info "✅ External frontend: Working"
else
    echo "❌ External frontend: Not responding yet (may need a moment)"
fi

if curl -f -s http://$EXTERNAL_IP:8000/api/health > /dev/null; then
    log_info "✅ External backend: Working"
else
    echo "❌ External backend: Not responding yet (may need a moment)"
fi

echo ""
echo "=== Port Binding Check ==="
echo "Current port bindings:"
netstat -tlnp | grep -E ":3000|:8000|:3001|:9090" | head -10

echo ""
echo "================================================"
log_info "🌐 External Access Configuration Complete!"
echo "================================================"
echo ""
echo "🔗 Access URLs:"
echo "  External Frontend:  http://$EXTERNAL_IP:3000"
echo "  External Backend:   http://$EXTERNAL_IP:8000/api/health"
echo "  External Grafana:   http://$EXTERNAL_IP:3001 (admin/admin)"
echo "  External Prometheus: http://$EXTERNAL_IP:9090"
echo ""
echo "  Local Frontend:     http://localhost:3000"
echo "  Local Backend:      http://localhost:8000/api/health"
echo ""
echo "🔧 Troubleshooting:"
echo "  1. If still not accessible, check cloud provider security groups"
echo "  2. Ensure ports 3000, 8000, 3001, 9090 are open in your cloud firewall"
echo "  3. Wait 1-2 minutes for services to fully start"
echo ""
echo "📊 Service Status:"
docker-compose ps

# Final check
echo ""
log_step "Final verification in 10 seconds..."
sleep 10

echo "Testing external URL: http://$EXTERNAL_IP:3000/"
if curl -f -s http://$EXTERNAL_IP:3000/ > /dev/null; then
    log_info "🎉 SUCCESS! Application is accessible at http://$EXTERNAL_IP:3000/"
else
    echo "⚠️  External access not ready yet. Try these steps:"
    echo "   1. Wait 2-3 minutes for full startup"
    echo "   2. Check cloud firewall/security groups"
    echo "   3. Verify with: curl http://$EXTERNAL_IP:3000/health"
fi

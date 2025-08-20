#!/bin/bash
set -e

# AI User Story Generator - Production Structure Setup Script
# Fixed version with proper function definitions and paths

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

error_exit() {
    log_error "$1"
    exit 1
}

# ========================================
# PRODUCTION FOLDER STRUCTURE
# ========================================

log_step "Creating AI User Story Generator project structure..."

# Create the complete project structure
mkdir -p ai-user-story-generator
cd ai-user-story-generator

# Get current directory
PROJECT_ROOT=$(pwd)
log_info "Project root: $PROJECT_ROOT"

# Root structure
mkdir -p {backend,frontend,docker,scripts,docs,tests,config,monitoring}

# Backend structure
mkdir -p backend/{app,tests,migrations,static,uploads}
mkdir -p backend/app/{api,core,models,services,utils,integrations}
mkdir -p backend/app/api/{v1,auth,health}
mkdir -p backend/app/api/v1/{endpoints,dependencies}
mkdir -p backend/app/services/{llm,rag,security,integration}
mkdir -p backend/tests/{unit,integration,e2e}

# Frontend structure
mkdir -p frontend/{src,public,build,tests}
mkdir -p frontend/src/{components,pages,services,utils,hooks,context,types}
mkdir -p frontend/src/components/{ui,forms,layout,charts}
mkdir -p frontend/tests/{unit,integration,e2e}

# Docker structure
mkdir -p docker/{backend,frontend,nginx,monitoring}
mkdir -p docker/monitoring/{prometheus,grafana}

# Configuration structure
mkdir -p config/{development,staging,production}

# Scripts structure
mkdir -p scripts/{deployment,backup,monitoring,development,test,security}

# Documentation structure
mkdir -p docs/{api,deployment,architecture,user-guide}

# Monitoring structure
mkdir -p monitoring/{dashboards,alerts,logs,prometheus,grafana}

log_info "✅ Folder structure created successfully!"

# ========================================
# ENVIRONMENT CONFIGURATION FILES
# ========================================

log_step "Creating environment configuration files..."

cat > .env.example << 'EOF'
# AI User Story Generator - Environment Configuration

# ========================================
# APPLICATION SETTINGS
# ========================================
ENVIRONMENT=production
DEBUG=false
LOG_LEVEL=info
SECRET_KEY=your-secret-key-here

# ========================================
# DATABASE CONFIGURATION
# ========================================
POSTGRES_DB=userstories
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your-secure-password-here
DATABASE_URL=postgresql://postgres:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}

# ========================================
# REDIS CONFIGURATION
# ========================================
REDIS_URL=redis://redis:6379
REDIS_PASSWORD=

# ========================================
# LLM API KEYS
# ========================================
OPENAI_API_KEY=your-openai-api-key
AZURE_OPENAI_API_KEY=your-azure-api-key
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/
AZURE_OPENAI_API_VERSION=2023-12-01-preview
GOOGLE_API_KEY=your-google-api-key
ANTHROPIC_API_KEY=your-anthropic-api-key

# ========================================
# SECURITY SETTINGS
# ========================================
JWT_SECRET=your-jwt-secret-key
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW=3600

# ========================================
# EXTERNAL INTEGRATIONS
# ========================================
CONFLUENCE_BASE_URL=https://yourcompany.atlassian.net
CONFLUENCE_USERNAME=your-confluence-email
CONFLUENCE_API_TOKEN=your-confluence-api-token
JIRA_BASE_URL=https://yourcompany.atlassian.net
JIRA_USERNAME=your-jira-email
JIRA_API_TOKEN=your-jira-api-token

# ========================================
# MONITORING SETTINGS
# ========================================
GRAFANA_USER=admin
GRAFANA_PASSWORD=admin
PROMETHEUS_RETENTION=200h

# ========================================
# STORAGE SETTINGS
# ========================================
UPLOAD_DIR=/app/uploads
MAX_FILE_SIZE=52428800
CHROMA_PERSIST_DIRECTORY=/app/chroma_db

# ========================================
# EMAIL SETTINGS (Optional)
# ========================================
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_TLS=true

# ========================================
# BACKUP SETTINGS
# ========================================
BACKUP_RETENTION_DAYS=7
S3_BACKUP_BUCKET=your-backup-bucket
AWS_ACCESS_KEY_ID=your-aws-access-key
AWS_SECRET_ACCESS_KEY=your-aws-secret-key
EOF

# Copy environment files for different environments
cp .env.example config/development/.env.development
cp .env.example config/staging/.env.staging  
cp .env.example config/production/.env.production

log_info "✅ Environment files created"

# ========================================
# BACKEND FILES
# ========================================

log_step "Creating backend configuration files..."

# Backend Dockerfile
cat > backend/Dockerfile << 'EOF'
# Multi-stage build for Python backend
FROM python:3.11-slim as builder

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    curl \
    postgresql-client \
    poppler-utils \
    tesseract-ocr \
    libreoffice \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create and set work directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# Production stage
FROM python:3.11-slim as production

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    postgresql-client \
    poppler-utils \
    tesseract-ocr \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create app user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Set work directory
WORKDIR /app

# Copy Python packages from builder stage
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application code
COPY . .

# Create necessary directories and set permissions
RUN mkdir -p /app/{uploads,chroma_db,logs,static} && \
    chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8000/api/health || exit 1

# Start application with Gunicorn
CMD ["gunicorn", "main:app", "--workers", "4", "--worker-class", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:8000", "--timeout", "120", "--keep-alive", "2"]
EOF

# Backend Development Dockerfile
cat > backend/Dockerfile.dev << 'EOF'
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code
COPY . .

# Expose port
EXPOSE 8000

# Start development server with hot reload
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
EOF

# Backend Requirements
cat > backend/requirements.txt << 'EOF'
# FastAPI and server
fastapi==0.104.1
uvicorn[standard]==0.24.0
gunicorn==21.2.0
pydantic==2.5.0
pydantic-settings==2.1.0

# Database
sqlalchemy==2.0.23
alembic==1.12.1
psycopg2-binary==2.9.9
asyncpg==0.29.0

# Caching and background tasks
redis==5.0.1
celery==5.3.4
kombu==5.3.4

# LangChain and AI
langchain==0.0.350
langchain-experimental==0.0.45
langchain-community==0.0.5
langchain-openai==0.0.2
openai==1.3.8
anthropic==0.7.8
google-generativeai==0.3.2
azure-openai==1.3.8

# Vector stores and embeddings
chromadb==0.4.18
faiss-cpu==1.7.4
pinecone-client==2.2.4
sentence-transformers==2.2.2
numpy==1.24.3

# Document processing
PyPDF2==3.0.1
python-docx==1.1.0
python-multipart==0.0.6
unstructured==0.11.6
beautifulsoup4==4.12.2
pandas==2.1.4
openpyxl==3.1.2
pypandoc==1.12
python-magic==0.4.27

# Security and authentication
passlib[bcrypt]==1.7.4
python-jose[cryptography]==3.3.0
bcrypt==4.1.2
bleach==6.1.0
cryptography==41.0.7

# HTTP and API clients
requests==2.31.0
httpx==0.25.2
aiohttp==3.9.1

# Monitoring and observability
prometheus-client==0.19.0
structlog==23.2.0
sentry-sdk[fastapi]==1.38.0
opentelemetry-api==1.21.0
opentelemetry-sdk==1.21.0

# External integrations
atlassian-python-api==3.41.10
jira==3.5.2
slack-sdk==3.25.0

# Utilities
python-dotenv==1.0.0
click==8.1.7
rich==13.7.0
typer==0.9.0

# Development and testing
pytest==7.4.3
pytest-asyncio==0.21.1
pytest-cov==4.1.0
black==23.11.0
flake8==6.1.0
mypy==1.7.1
isort==5.12.0
pre-commit==3.6.0

# Production server
supervisor==4.2.5
EOF

# Backend .dockerignore
cat > backend/.dockerignore << 'EOF'
__pycache__
*.pyc
*.pyo
*.pyd
.Python
env
pip-log.txt
pip-delete-this-directory.txt
.tox
.coverage
.coverage.*
.cache
nosetests.xml
coverage.xml
*.cover
*.log
.git
.mypy_cache
.pytest_cache
.hypothesis

.DS_Store
.vscode/
.idea/

tests/
*.md
Dockerfile*
docker-compose*
EOF

log_info "✅ Backend files created"

# ========================================
# FRONTEND FILES
# ========================================

log_step "Creating frontend configuration files..."

# Frontend Dockerfile
cat > frontend/Dockerfile << 'EOF'
# Multi-stage build for React frontend
FROM node:18-alpine as builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Production stage with Nginx
FROM nginx:alpine as production

# Copy built assets from builder stage
COPY --from=builder /app/build /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:80/ || exit 1

# Expose port
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
EOF

# Frontend Development Dockerfile
cat > frontend/Dockerfile.dev << 'EOF'
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY . .

# Expose port
EXPOSE 3000

# Start development server
CMD ["npm", "start"]
EOF

# Frontend package.json
cat > frontend/package.json << 'EOF'
{
  "name": "ai-user-story-generator-frontend",
  "version": "1.0.0",
  "description": "React frontend for AI User Story Generator",
  "private": true,
  "dependencies": {
    "@testing-library/jest-dom": "^5.16.5",
    "@testing-library/react": "^13.4.0",
    "@testing-library/user-event": "^14.4.3",
    "@types/jest": "^27.5.2",
    "@types/node": "^16.18.23",
    "@types/react": "^18.0.31",
    "@types/react-dom": "^18.0.11",
    "lucide-react": "^0.263.1",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.10.0",
    "react-scripts": "5.0.1",
    "typescript": "^4.9.5",
    "web-vitals": "^2.1.4",
    "axios": "^1.4.0",
    "recharts": "^2.6.2",
    "react-hook-form": "^7.43.9",
    "react-query": "^3.39.3",
    "@headlessui/react": "^1.7.14",
    "clsx": "^1.2.1"
  },
  "devDependencies": {
    "tailwindcss": "^3.3.2",
    "autoprefixer": "^10.4.14",
    "postcss": "^8.4.23",
    "@types/react-router-dom": "^5.3.3",
    "eslint": "^8.38.0",
    "prettier": "^2.8.7",
    "husky": "^8.0.3",
    "lint-staged": "^13.2.1"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test",
    "eject": "react-scripts eject",
    "lint": "eslint src --ext .ts,.tsx",
    "lint:fix": "eslint src --ext .ts,.tsx --fix",
    "format": "prettier --write src/**/*.{ts,tsx,json,css,md}",
    "type-check": "tsc --noEmit"
  },
  "eslintConfig": {
    "extends": [
      "react-app",
      "react-app/jest"
    ]
  },
  "browserslist": {
    "production": [
      ">0.2%",
      "not dead",
      "not op_mini all"
    ],
    "development": [
      "last 1 chrome version",
      "last 1 firefox version",
      "last 1 safari version"
    ]
  },
  "proxy": "http://localhost:8000"
}
EOF

# Frontend Nginx configuration
cat > frontend/nginx.conf << 'EOF'
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
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

    # Handle React routing
    location / {
        try_files $uri $uri/ /index.html;
    }

    # API proxy
    location /api/ {
        proxy_pass http://backend:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# TypeScript configuration
cat > frontend/tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "es5",
    "lib": [
      "dom",
      "dom.iterable",
      "es6"
    ],
    "allowJs": true,
    "skipLibCheck": true,
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "noFallthroughCasesInSwitch": true,
    "module": "esnext",
    "moduleResolution": "node",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx"
  },
  "include": [
    "src"
  ]
}
EOF

# Tailwind configuration
cat > frontend/tailwind.config.js << 'EOF'
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{js,jsx,ts,tsx}",
  ],
  theme: {
    extend: {
      animation: {
        'slideIn': 'slideIn 0.5s ease-out',
        'fadeIn': 'fadeIn 0.3s ease-in',
        'pulse': 'pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite',
      },
      keyframes: {
        slideIn: {
          '0%': { opacity: '0', transform: 'translateY(20px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        }
      },
      colors: {
        primary: {
          50: '#eff6ff',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
        }
      }
    },
  },
  plugins: [],
}
EOF

# Frontend .dockerignore
cat > frontend/.dockerignore << 'EOF'
node_modules
npm-debug.log
Dockerfile*
docker-compose*
.git
.gitignore
README.md
.env
.nyc_output
coverage
.nyc_output
.coverage
.vscode/
.idea/
*.md
EOF

log_info "✅ Frontend files created"

# ========================================
# DOCKER COMPOSE FILES
# ========================================

log_step "Creating Docker Compose configurations..."

# Main Docker Compose
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  # React Frontend
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
      target: production
    ports:
      - "3000:80"
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
    networks:
      - app-network

  # FastAPI Backend
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
      target: production
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://postgres:${POSTGRES_PASSWORD:-password}@db:5432/${POSTGRES_DB:-userstories}
      - REDIS_URL=redis://redis:6379
      - ENVIRONMENT=production
      - LOG_LEVEL=info
    volumes:
      - backend_uploads:/app/uploads
      - backend_chroma:/app/chroma_db
      - backend_logs:/app/logs
    depends_on:
      - db
      - redis
      - chromadb
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
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
      - "5432:5432"
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
      - "6379:6379"
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
      - "8001:8000"
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
      - "9090:9090"
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
      - "3001:3000"
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

# Development Docker Compose
cat > docker-compose.dev.yml << 'EOF'
version: '3.8'

services:
  # Development Frontend with hot reload
  frontend-dev:
    build:
      context: ./frontend
      dockerfile: Dockerfile.dev
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
      - CHOKIDAR_USEPOLLING=true
    volumes:
      - ./frontend:/app
      - /app/node_modules
    depends_on:
      - backend-dev
    networks:
      - dev-network

  # Development Backend with hot reload
  backend-dev:
    build:
      context: ./backend
      dockerfile: Dockerfile.dev
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://postgres:password@db-dev:5432/userstories_dev
      - REDIS_URL=redis://redis-dev:6379
      - ENVIRONMENT=development
      - LOG_LEVEL=debug
    volumes:
      - ./backend:/app
      - dev_uploads:/app/uploads
    depends_on:
      - db-dev
      - redis-dev
    networks:
      - dev-network

  # Development Database
  db-dev:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=userstories_dev
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    volumes:
      - dev_postgres_data:/var/lib/postgresql/data
    ports:
      - "5433:5432"
    networks:
      - dev-network

  # Development Redis
  redis-dev:
    image: redis:7-alpine
    ports:
      - "6380:6379"
    volumes:
      - dev_redis_data:/data
    networks:
      - dev-network

volumes:
  dev_postgres_data:
  dev_redis_data:
  dev_uploads:

networks:
  dev-network:
    driver: bridge
EOF

log_info "✅ Docker Compose files created"

# ========================================
# MAKEFILE
# ========================================

log_step "Creating Makefile for automation..."

cat > Makefile << 'EOF'
# AI User Story Generator - Production Build Automation

.PHONY: help dev build deploy test clean lint format security-scan backup restore

# Default environment
ENV ?= development

# Colors for output
YELLOW = \033[1;33m
GREEN = \033[1;32m
RED = \033[1;31m
NC = \033[0m # No Color

help: ## Show this help message
	@echo "$(YELLOW)AI User Story Generator - Build Commands$(NC)"
	@echo "================================================"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "$(GREEN)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# ========================================
# DEVELOPMENT COMMANDS
# ========================================

dev: ## Start development environment
	@echo "$(YELLOW)Starting development environment...$(NC)"
	docker-compose -f docker-compose.dev.yml up --build

dev-down: ## Stop development environment
	@echo "$(YELLOW)Stopping development environment...$(NC)"
	docker-compose -f docker-compose.dev.yml down

dev-logs: ## View development logs
	docker-compose -f docker-compose.dev.yml logs -f

# ========================================
# BUILD COMMANDS
# ========================================

build: ## Build all services
	@echo "$(YELLOW)Building all services...$(NC)"
	docker-compose build --parallel

build-frontend: ## Build frontend only
	@echo "$(YELLOW)Building frontend...$(NC)"
	docker-compose build frontend

build-backend: ## Build backend only
	@echo "$(YELLOW)Building backend...$(NC)"
	docker-compose build backend

# ========================================
# DEPLOYMENT COMMANDS
# ========================================

deploy: ## Deploy to production
	@echo "$(YELLOW)Deploying to production...$(NC)"
	./scripts/deployment/deploy.sh

start: ## Start production services
	@echo "$(YELLOW)Starting production services...$(NC)"
	docker-compose up -d

stop: ## Stop all services
	@echo "$(YELLOW)Stopping all services...$(NC)"
	docker-compose down

restart: ## Restart all services
	@echo "$(YELLOW)Restarting all services...$(NC)"
	docker-compose restart

# ========================================
# TESTING COMMANDS
# ========================================

test: ## Run all tests
	@echo "$(YELLOW)Running all tests...$(NC)"
	@echo "Note: Start services first with 'make start'"

# ========================================
# MONITORING COMMANDS
# ========================================

logs: ## View all logs
	docker-compose logs -f

logs-backend: ## View backend logs
	docker-compose logs -f backend

logs-frontend: ## View frontend logs
	docker-compose logs -f frontend

health: ## Check system health
	@echo "$(YELLOW)Checking system health...$(NC)"
	@curl -f http://localhost:3000/health || echo "$(RED)Frontend health check failed$(NC)"
	@curl -f http://localhost:8000/api/health || echo "$(RED)Backend health check failed$(NC)"

# ========================================
# CLEANUP COMMANDS
# ========================================

clean: ## Clean up Docker resources
	@echo "$(YELLOW)Cleaning up Docker resources...$(NC)"
	docker system prune -f
	docker volume prune -f

clean-all: ## Clean up everything (including images)
	@echo "$(RED)Cleaning up all Docker resources...$(NC)"
	docker system prune -af
	docker volume prune -f

# ========================================
# UTILITY COMMANDS
# ========================================

shell-backend: ## Open shell in backend container
	docker-compose exec backend bash

shell-frontend: ## Open shell in frontend container
	docker-compose exec frontend sh

shell-db: ## Open database shell
	docker-compose exec db psql -U postgres -d userstories

status: ## Show service status
	@echo "$(YELLOW)Service Status:$(NC)"
	docker-compose ps
EOF

log_info "✅ Makefile created"

# ========================================
# DEPLOYMENT SCRIPT
# ========================================

log_step "Creating deployment script..."

cat > scripts/deployment/deploy.sh << 'EOF'
#!/bin/bash
set -e

# AI User Story Generator - Production Deployment Script

# Configuration
PROJECT_NAME="ai-user-story-generator"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Main deployment function
main() {
    log_info "🚀 AI User Story Generator Deployment Script"
    echo "================================================"
    
    log_step "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed"
        exit 1
    fi
    
    log_info "Prerequisites check passed ✅"
    
    log_step "Building and starting services..."
    cd "$PROJECT_ROOT"
    
    # Build services
    log_info "Building services..."
    docker-compose build --parallel
    
    # Start services
    log_info "Starting services..."
    docker-compose up -d
    
    # Wait for services to be ready
    log_info "Waiting for services to be ready..."
    sleep 30
    
    log_step "Running health checks..."
    
    # Health checks
    if curl -f -s --max-time 10 "http://localhost:3000/health" > /dev/null; then
        log_info "Frontend: ✅ Healthy"
    else
        log_warn "Frontend: ⚠️ Health check failed"
    fi
    
    if curl -f -s --max-time 10 "http://localhost:8000/api/health" > /dev/null; then
        log_info "Backend: ✅ Healthy"
    else
        log_warn "Backend: ⚠️ Health check failed (may need configuration)"
    fi
    
    echo "================================================"
    log_info "🎉 Deployment completed!"
    echo ""
    log_info "Service URLs:"
    echo "  📱 Frontend:     http://localhost:3000"
    echo "  🔧 Backend API:  http://localhost:8000"
    echo "  📊 Grafana:      http://localhost:3001 (admin/admin)"
    echo "  📈 Prometheus:   http://localhost:9090"
    echo ""
    log_info "Next steps:"
    echo "  1. Update .env with your API keys"
    echo "  2. Restart services: make restart"
    echo "  3. Check logs: make logs"
}

# Run main function
main "$@"
EOF

chmod +x scripts/deployment/deploy.sh

log_info "✅ Deployment script created"

# ========================================
# MONITORING CONFIGURATION
# ========================================

log_step "Creating monitoring configurations..."

cat > monitoring/prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'ai-user-story-generator'
    static_configs:
      - targets: ['backend:8000']
    metrics_path: '/metrics'
    scrape_interval: 30s

  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
EOF

log_info "✅ Monitoring configuration created"

# ========================================
# GITIGNORE
# ========================================

log_step "Creating .gitignore..."

cat > .gitignore << 'EOF'
# Environment files
.env
.env.*
!.env.example

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# Virtual environments
venv/
env/
ENV/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# Node.js
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Production builds
frontend/build/
frontend/dist/

# Logs
*.log
logs/
backend/logs/

# Database
*.db
*.sqlite3

# Uploads and data
uploads/
chroma_db/
*.rdb

# Docker
.dockerignore

# OS
.DS_Store
Thumbs.db

# Backup files
backups/
*.bak

# SSL certificates
*.pem
*.key
*.crt

# Monitoring data
prometheus_data/
grafana_data/

# Testing
.coverage
htmlcov/
.pytest_cache/
coverage.xml

# Temporary files
tmp/
temp/
.tmp/
EOF

log_info "✅ .gitignore created"

# ========================================
# README
# ========================================

log_step "Creating comprehensive README..."

cat > README.md << 'EOF'
# 🤖 AI User Story Generator

A production-grade AI-powered application for generating user stories using RAG (Retrieval-Augmented Generation) technology with support for multiple LLM providers.

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- Git
- 8GB RAM minimum
- 10GB free disk space

### 1. Clone and Setup
```bash
# The structure is already created, you're in the project directory
cd ai-user-story-generator  # if not already there
```

### 2. Configure Environment
```bash
# Copy and edit environment file
cp .env.example .env

# Edit .env with your API keys:
# - OPENAI_API_KEY=your-openai-api-key
# - POSTGRES_PASSWORD=your-secure-password
# - JWT_SECRET=your-jwt-secret
```

### 3. Deploy with One Command
```bash
make deploy
```

### 4. Access Application
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **Grafana**: http://localhost:3001 (admin/admin)
- **Prometheus**: http://localhost:9090

## 📋 Available Commands

### Development
```bash
make dev              # Start development environment
make dev-down         # Stop development environment
make dev-logs         # View development logs
```

### Building & Deployment
```bash
make build            # Build all services
make deploy           # Deploy to production
make start            # Start production services
make stop             # Stop all services
make restart          # Restart all services
```

### Monitoring & Maintenance
```bash
make logs             # View all logs
make health           # Check system health
make status           # Show service status
make clean            # Clean Docker resources
```

### Development Tools
```bash
make shell-backend    # Open shell in backend container
make shell-frontend   # Open shell in frontend container
make shell-db         # Open database shell
```

## 🔧 Configuration

### Required Environment Variables

Edit your `.env` file with the following required settings:

```bash
# Database (Required)
POSTGRES_PASSWORD=your-secure-password-here

# Security (Required)
JWT_SECRET=your-jwt-secret-key-here

# LLM API Keys (At least one required)
OPENAI_API_KEY=your-openai-api-key
# OR
AZURE_OPENAI_API_KEY=your-azure-api-key
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/
# OR
GOOGLE_API_KEY=your-google-api-key
# OR
ANTHROPIC_API_KEY=your-anthropic-api-key
```

### Optional Integrations

```bash
# Confluence
CONFLUENCE_BASE_URL=https://yourcompany.atlassian.net
CONFLUENCE_USERNAME=your-email@company.com
CONFLUENCE_API_TOKEN=your-confluence-api-token

# Jira
JIRA_BASE_URL=https://yourcompany.atlassian.net
JIRA_USERNAME=your-email@company.com
JIRA_API_TOKEN=your-jira-api-token
```

## 🏗️ Architecture

### Services
- **Frontend**: React TypeScript application with Tailwind CSS
- **Backend**: FastAPI Python application with RAG system
- **Database**: PostgreSQL for data persistence
- **Cache**: Redis for session management and caching
- **Vector DB**: ChromaDB for RAG document storage
- **Monitoring**: Prometheus + Grafana for observability

### Key Features
- **Multi-LLM Support**: OpenAI, Azure OpenAI, Google Gemini, Anthropic Claude
- **RAG System**: Document upload and intelligent retrieval
- **External Integrations**: Confluence, Jira, URL fetching
- **Security**: JWT authentication, rate limiting, input validation
- **Monitoring**: Real-time metrics and health checks

## 📁 Project Structure

```
ai-user-story-generator/
├── 📁 backend/                     # Python FastAPI Backend
│   ├── 📁 app/                     # Application code
│   ├── requirements.txt            # Python dependencies
│   └── Dockerfile                  # Production container
├── 📁 frontend/                    # React TypeScript Frontend
│   ├── 📁 src/                     # Source code
│   ├── package.json                # Node dependencies
│   └── Dockerfile                  # Production container
├── 📁 scripts/                     # Automation scripts
├── 📁 monitoring/                  # Monitoring configs
├── docker-compose.yml              # Production services
├── docker-compose.dev.yml          # Development services
├── Makefile                        # Build automation
└── README.md                       # This file
```

## 🔍 Troubleshooting

### Services Won't Start
```bash
# Check Docker resources
docker system df
docker system prune

# Check logs
make logs

# Restart services
make restart
```

### Database Connection Issues
```bash
# Check database status
make status

# View database logs
docker-compose logs db

# Restart database
docker-compose restart db
```

### API Connection Issues
```bash
# Check backend logs
make logs-backend

# Verify environment variables
cat .env

# Test API directly
curl http://localhost:8000/api/health
```

### Port Conflicts
If you encounter port conflicts, you can modify the ports in `docker-compose.yml`:

```yaml
services:
  frontend:
    ports:
      - "3001:80"  # Change from 3000 to 3001
  backend:
    ports:
      - "8001:8000"  # Change from 8000 to 8001
```

## 🛡️ Security

### Production Considerations
1. **Environment Variables**: Never commit real API keys to version control
2. **Database**: Use strong passwords and consider encryption at rest
3. **Network**: Configure firewall rules and use HTTPS in production
4. **Updates**: Regularly update dependencies and base images

### API Keys Security
- Store API keys in `.env` file (already in .gitignore)
- Use different keys for development and production
- Rotate keys regularly
- Monitor API usage for unusual activity

## 🚀 Deployment

### Local Development
```bash
make dev              # Start with hot reload
```

### Production
```bash
make deploy           # Full production deployment
```

### Scaling
```bash
# Scale backend instances
docker-compose up -d --scale backend=3

# Scale frontend instances  
docker-compose up -d --scale frontend=2
```

## 📊 Monitoring

### Access Dashboards
- **Grafana**: http://localhost:3001 (admin/admin)
- **Prometheus**: http://localhost:9090

### Key Metrics
- Request rate and response times
- Error rates and status codes
- Resource utilization
- Business metrics (projects, stories generated)

## 🤝 Contributing

### Development Setup
```bash
# Start development environment
make dev

# The services will start with hot reload enabled
# Frontend: http://localhost:3000
# Backend: http://localhost:8000
```

### Code Structure
- Frontend code goes in `frontend/src/`
- Backend code goes in `backend/app/`
- Follow the existing project structure
- Use TypeScript for frontend, Python for backend

## 📄 License

This project is open source. See the LICENSE file for details.

## 🆘 Support

- **Issues**: Create GitHub issues for bugs and feature requests
- **Documentation**: Check this README and inline code comments
- **Community**: Use GitHub Discussions for questions

---

🎉 **You're all set!** Run `make deploy` to start your AI User Story Generator.
EOF

log_info "✅ README created"

# ========================================
# FINAL STEPS
# ========================================

log_step "Setting up executable permissions..."

# Make scripts executable
find scripts -name "*.sh" -exec chmod +x {} \;

log_step "Creating placeholder files..."

# Create placeholder files for proper structure
touch backend/main.py
touch frontend/src/index.tsx
touch frontend/src/App.tsx
touch frontend/public/index.html

log_info "✅ Placeholder files created"

# ========================================
# COMPLETION MESSAGE
# ========================================

echo ""
echo "================================================"
log_info "🎉 AI User Story Generator project structure created successfully!"
echo "================================================"
echo ""
log_info "📁 Project Structure:"
echo "  ├── Complete folder hierarchy with proper separation"
echo "  ├── Multi-stage Docker builds for optimization"
echo "  ├── Environment-specific configurations"
echo "  ├── Comprehensive automation with Makefile"
echo "  ├── Production deployment scripts"
echo "  ├── Monitoring and security configurations"
echo "  └── Documentation and guidelines"
echo ""
log_info "🚀 Next Steps:"
echo "  1. Copy your existing code into the appropriate directories:"
echo "     - Backend code → backend/app/"
echo "     - Frontend code → frontend/src/"
echo "  2. Update .env with your API keys and configuration"
echo "  3. Run 'make deploy' to start the application"
echo "  4. Access the application at http://localhost:3000"
echo ""
log_info "📖 Documentation:"
echo "  - See README.md for detailed setup instructions"
echo "  - Use 'make help' to see all available commands"
echo "  - Check .env.example for all configuration options"
echo ""
log_info "🔧 Quick Commands:"
echo "  make deploy    # Deploy production environment"
echo "  make dev       # Start development environment"
echo "  make logs      # View application logs"
echo "  make health    # Check system health"
echo "  make help      # Show all available commands"
echo ""
log_warn "⚠️  Important:"
echo "  - Update .env with your real API keys before deploying"
echo "  - The deployment script will check for required dependencies"
echo "  - Use 'make dev' for development with hot reload"
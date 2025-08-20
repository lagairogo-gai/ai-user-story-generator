# PRODUCTION FOLDER STRUCTURE
# ========================================

# Create the complete project structure
mkdir -p ai-user-story-generator
cd ai-user-story-generator

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
mkdir -p scripts/{deployment,backup,monitoring,development}

# Documentation structure
mkdir -p docs/{api,deployment,architecture,user-guide}

# Monitoring structure
mkdir -p monitoring/{dashboards,alerts,logs}

echo "✅ Project structure created successfully!"

# ========================================
# PROJECT STRUCTURE TREE
# ========================================

cat > project-structure.md << 'EOF'
# AI User Story Generator - Production Structure

```
ai-user-story-generator/
├── 📁 backend/                     # Python FastAPI Backend
│   ├── 📁 app/
│   │   ├── 📁 api/
│   │   │   ├── 📁 auth/            # Authentication endpoints
│   │   │   ├── 📁 health/          # Health check endpoints
│   │   │   └── 📁 v1/
│   │   │       ├── 📁 endpoints/   # API route handlers
│   │   │       └── 📁 dependencies/# FastAPI dependencies
│   │   ├── 📁 core/               # Core configuration
│   │   ├── 📁 models/             # Database models
│   │   ├── 📁 services/           # Business logic
│   │   │   ├── 📁 llm/            # LLM integrations
│   │   │   ├── 📁 rag/            # RAG system
│   │   │   ├── 📁 security/       # Security services
│   │   │   └── 📁 integration/    # External integrations
│   │   ├── 📁 utils/              # Utility functions
│   │   └── 📁 integrations/       # External API clients
│   ├── 📁 migrations/             # Database migrations
│   ├── 📁 static/                 # Static files
│   ├── 📁 tests/                  # Backend tests
│   ├── 📁 uploads/                # File uploads
│   ├── main.py                    # FastAPI application
│   ├── requirements.txt           # Python dependencies
│   └── Dockerfile                 # Backend Docker config
│
├── 📁 frontend/                    # React Frontend
│   ├── 📁 public/                 # Public assets
│   ├── 📁 src/
│   │   ├── 📁 components/         # Reusable components
│   │   │   ├── 📁 ui/             # UI components
│   │   │   ├── 📁 forms/          # Form components
│   │   │   ├── 📁 layout/         # Layout components
│   │   │   └── 📁 charts/         # Chart components
│   │   ├── 📁 pages/              # Page components
│   │   ├── 📁 services/           # API services
│   │   ├── 📁 hooks/              # Custom React hooks
│   │   ├── 📁 context/            # React context
│   │   ├── 📁 utils/              # Utility functions
│   │   ├── 📁 types/              # TypeScript types
│   │   ├── App.tsx                # Main App component
│   │   └── index.tsx              # Entry point
│   ├── 📁 tests/                  # Frontend tests
│   ├── package.json               # Node dependencies
│   ├── tsconfig.json              # TypeScript config
│   ├── tailwind.config.js         # Tailwind CSS config
│   └── Dockerfile                 # Frontend Docker config
│
├── 📁 docker/                     # Docker configurations
│   ├── 📁 backend/                # Backend Docker files
│   ├── 📁 frontend/               # Frontend Docker files
│   ├── 📁 nginx/                  # Nginx configuration
│   ├── 📁 monitoring/             # Monitoring stack
│   └── docker-compose.yml         # Main compose file
│
├── 📁 config/                     # Configuration files
│   ├── 📁 development/            # Dev environment config
│   ├── 📁 staging/                # Staging environment config
│   └── 📁 production/             # Production environment config
│
├── 📁 scripts/                    # Deployment & utility scripts
│   ├── 📁 deployment/             # Deployment scripts
│   ├── 📁 backup/                 # Backup scripts
│   ├── 📁 monitoring/             # Monitoring scripts
│   └── 📁 development/            # Development scripts
│
├── 📁 monitoring/                 # Monitoring configurations
│   ├── 📁 dashboards/             # Grafana dashboards
│   ├── 📁 alerts/                 # Alert configurations
│   └── 📁 logs/                   # Log configurations
│
├── 📁 tests/                      # Integration & E2E tests
├── 📁 docs/                       # Documentation
├── .env.example                   # Environment variables template
├── .gitignore                     # Git ignore rules
├── docker-compose.yml             # Main docker compose
├── docker-compose.dev.yml         # Development compose
├── docker-compose.prod.yml        # Production compose
├── Makefile                       # Build automation
└── README.md                      # Project documentation
```
EOF

# ========================================
# BACKEND DOCKERFILE (Production)
# ========================================

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

# ========================================
# FRONTEND DOCKERFILE (Production)
# ========================================

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

# ========================================
# FRONTEND NGINX CONFIGURATION
# ========================================

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

# ========================================
# PACKAGE.JSON FOR FRONTEND
# ========================================

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

# ========================================
# TAILWIND CONFIG
# ========================================

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

# ========================================
# BACKEND REQUIREMENTS.TXT (Updated)
# ========================================

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

# ========================================
# DOCKER COMPOSE (Production)
# ========================================

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
      - DATABASE_URL=postgresql://postgres:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}
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
      - ./scripts/init.sql:/docker-entrypoint-initdb.d/init.sql
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

  # Nginx Reverse Proxy
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./docker/nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./docker/nginx/ssl:/etc/nginx/ssl
      - nginx_logs:/var/log/nginx
    depends_on:
      - frontend
      - backend
    restart: unless-stopped
    networks:
      - app-network

  # Celery Worker for Background Tasks
  celery-worker:
    build:
      context: ./backend
      dockerfile: Dockerfile
      target: production
    command: celery -A app.core.celery worker --loglevel=info --concurrency=4
    environment:
      - DATABASE_URL=postgresql://postgres:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}
      - REDIS_URL=redis://redis:6379
      - ENVIRONMENT=production
    volumes:
      - backend_uploads:/app/uploads
      - backend_chroma:/app/chroma_db
      - backend_logs:/app/logs
    depends_on:
      - db
      - redis
    restart: unless-stopped
    networks:
      - app-network

  # Celery Beat Scheduler
  celery-beat:
    build:
      context: ./backend
      dockerfile: Dockerfile
      target: production
    command: celery -A app.core.celery beat --loglevel=info
    environment:
      - DATABASE_URL=postgresql://postgres:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}
      - REDIS_URL=redis://redis:6379
      - ENVIRONMENT=production
    volumes:
      - backend_logs:/app/logs
    depends_on:
      - db
      - redis
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
      - ./monitoring/grafana:/etc/grafana/provisioning
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
  nginx_logs:

networks:
  app-network:
    driver: bridge
EOF

# ========================================
# DOCKER COMPOSE (Development)
# ========================================

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

# ========================================
# DEVELOPMENT DOCKERFILES
# ========================================

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

# ========================================
# NGINX CONFIGURATION (Production)
# ========================================

mkdir -p docker/nginx
cat > docker/nginx/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream frontend {
        server frontend:80;
    }

    upstream backend {
        server backend:8000;
    }

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=upload:10m rate=1r/s;

    # Security headers
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    server {
        listen 80;
        server_name _;

        # Redirect HTTP to HTTPS in production
        # return 301 https://$server_name$request_uri;

        # File upload limits
        client_max_body_size 100M;
        client_body_timeout 300s;
        proxy_read_timeout 300s;
        proxy_connect_timeout 300s;

        # Frontend static files
        location / {
            proxy_pass http://frontend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # API endpoints with rate limiting
        location /api/ {
            limit_req zone=api burst=20 nodelay;
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # File upload endpoint with strict rate limiting
        location /api/upload {
            limit_req zone=upload burst=5 nodelay;
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_read_timeout 600s;
        }

        # WebSocket support
        location /ws/ {
            proxy_pass http://backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Health checks
        location /health {
            access_log off;
            proxy_pass http://backend/api/health;
        }
    }
}
EOF

# ========================================
# MAKEFILE FOR BUILD AUTOMATION
# ========================================

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
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "$(GREEN)%-20s$(NC) %s\n", $1, $2}' $(MAKEFILE_LIST)

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

deploy-staging: ## Deploy to staging
	@echo "$(YELLOW)Deploying to staging...$(NC)"
	ENV=staging ./scripts/deployment/deploy.sh

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
# DATABASE COMMANDS
# ========================================

db-migrate: ## Run database migrations
	@echo "$(YELLOW)Running database migrations...$(NC)"
	docker-compose exec backend alembic upgrade head

db-reset: ## Reset database (WARNING: This will delete all data)
	@echo "$(RED)Resetting database - This will delete all data!$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	if [[ $REPLY =~ ^[Yy]$ ]]; then \
		docker-compose exec backend alembic downgrade base && \
		docker-compose exec backend alembic upgrade head; \
	fi

db-backup: ## Backup database
	@echo "$(YELLOW)Creating database backup...$(NC)"
	./scripts/backup/backup-database.sh

# ========================================
# TESTING COMMANDS
# ========================================

test: ## Run all tests
	@echo "$(YELLOW)Running all tests...$(NC)"
	docker-compose exec backend pytest tests/
	docker-compose exec frontend npm test -- --coverage --watchAll=false

test-backend: ## Run backend tests
	@echo "$(YELLOW)Running backend tests...$(NC)"
	docker-compose exec backend pytest tests/ -v

test-frontend: ## Run frontend tests
	@echo "$(YELLOW)Running frontend tests...$(NC)"
	docker-compose exec frontend npm test -- --coverage --watchAll=false

test-e2e: ## Run end-to-end tests
	@echo "$(YELLOW)Running E2E tests...$(NC)"
	./scripts/test/run-e2e-tests.sh

# ========================================
# CODE QUALITY COMMANDS
# ========================================

lint: ## Run linters
	@echo "$(YELLOW)Running linters...$(NC)"
	docker-compose exec backend black --check app/
	docker-compose exec backend flake8 app/
	docker-compose exec backend mypy app/
	docker-compose exec frontend npm run lint

lint-fix: ## Fix linting issues
	@echo "$(YELLOW)Fixing linting issues...$(NC)"
	docker-compose exec backend black app/
	docker-compose exec backend isort app/
	docker-compose exec frontend npm run lint:fix

format: ## Format code
	@echo "$(YELLOW)Formatting code...$(NC)"
	docker-compose exec backend black app/
	docker-compose exec backend isort app/
	docker-compose exec frontend npm run format

# ========================================
# SECURITY COMMANDS
# ========================================

security-scan: ## Run security scans
	@echo "$(YELLOW)Running security scans...$(NC)"
	./scripts/security/security-scan.sh

vulnerability-check: ## Check for vulnerabilities
	@echo "$(YELLOW)Checking for vulnerabilities...$(NC)"
	docker-compose exec backend safety check
	docker-compose exec frontend npm audit

# ========================================
# MONITORING COMMANDS
# ========================================

logs: ## View all logs
	docker-compose logs -f

logs-backend: ## View backend logs
	docker-compose logs -f backend

logs-frontend: ## View frontend logs
	docker-compose logs -f frontend

metrics: ## Open metrics dashboard
	@echo "$(GREEN)Opening Grafana dashboard at http://localhost:3001$(NC)"
	@echo "$(GREEN)Opening Prometheus at http://localhost:9090$(NC)"

health: ## Check system health
	@echo "$(YELLOW)Checking system health...$(NC)"
	curl -f http://localhost:80/health || echo "$(RED)Frontend health check failed$(NC)"
	curl -f http://localhost:8000/api/health || echo "$(RED)Backend health check failed$(NC)"

# ========================================
# BACKUP & RESTORE COMMANDS
# ========================================

backup: ## Create full system backup
	@echo "$(YELLOW)Creating full system backup...$(NC)"
	./scripts/backup/full-backup.sh

restore: ## Restore from backup
	@echo "$(YELLOW)Restoring from backup...$(NC)"
	./scripts/backup/restore.sh

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

install-dev: ## Install development dependencies
	@echo "$(YELLOW)Installing development dependencies...$(NC)"
	cd frontend && npm install
	cd backend && pip install -r requirements.txt

update-deps: ## Update dependencies
	@echo "$(YELLOW)Updating dependencies...$(NC)"
	cd frontend && npm update
	cd backend && pip-compile requirements.in --upgrade

generate-docs: ## Generate API documentation
	@echo "$(YELLOW)Generating API documentation...$(NC)"
	docker-compose exec backend python -m app.core.docs

setup-hooks: ## Setup git hooks
	@echo "$(YELLOW)Setting up git hooks...$(NC)"
	pre-commit install

status: ## Show service status
	@echo "$(YELLOW)Service Status:$(NC)"
	docker-compose ps
EOF

# ========================================
# DEPLOYMENT SCRIPT (Updated)
# ========================================

mkdir -p scripts/deployment
cat > scripts/deployment/deploy.sh << 'EOF'
#!/bin/bash
set -e

# AI User Story Generator - Production Deployment Script
# This script handles the complete deployment process

# Configuration
PROJECT_NAME="ai-user-story-generator"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEPLOY_DIR="/opt/${PROJECT_NAME}"
BACKUP_DIR="/opt/backups/${PROJECT_NAME}"
ENV="${ENV:-production}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "\033[0;32m[INFO]\033[0m $1"
}
log_warn() {
    echo -e "\033[1;33m[WARN]\033[0m $1"
}
log_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1"
}
log_step() {
    echo -e "\033[0;34m[STEP]\033[0m $1"
}

# Error handling
error_exit() {
    log_error "$1"
    exit 1
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   error_exit "This script should not be run as root for security reasons"
fi

# Help function
show_help() {
    cat << EOF
AI User Story Generator - Deployment Script

Usage: $0 [OPTIONS]

Options:
    -h, --help          Show this help message
    -e, --env ENV       Environment (development|staging|production) [default: production]
    -f, --force         Force deployment without confirmations
    -b, --backup-only   Only create backup, don't deploy
    -r, --rollback      Rollback to previous version
    --no-backup         Skip backup creation
    --health-check      Run health checks only

Examples:
    $0                          # Deploy to production
    $0 -e staging              # Deploy to staging
    $0 --backup-only           # Create backup only
    $0 --rollback              # Rollback deployment
EOF


# Parse command line arguments
FORCE=false
BACKUP_ONLY=false
ROLLBACK=false
NO_BACKUP=false
HEALTH_CHECK_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -e|--env)
            ENV="$2"
            shift 2
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -b|--backup-only)
            BACKUP_ONLY=true
            shift
            ;;
        -r|--rollback)
            ROLLBACK=true
            shift
            ;;
        --no-backup)
            NO_BACKUP=true
            shift
            ;;
        --health-check)
            HEALTH_CHECK_ONLY=true
            shift
            ;;
        *)
            error_exit "Unknown option: $1"
            ;;
    esac
done

# Validate environment
case $ENV in
    development|staging|production)
        log_info "Deploying to: $ENV"
        ;;
    *)
        error_exit "Invalid environment: $ENV. Must be development, staging, or production"
        ;;
esac

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        error_exit "Docker is not installed"
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        error_exit "Docker Compose is not installed"
    fi
    
    # Check if user is in docker group
    if ! groups | grep -q docker; then
        error_exit "Current user is not in the docker group"
    fi
    
    # Check available disk space (minimum 5GB)
    available_space=$(df / | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 5242880 ]]; then
        error_exit "Insufficient disk space. At least 5GB required"
    fi
    
    # Check if ports are available
    for port in 80 443 8000 3000 5432 6379; do
        if netstat -tuln | grep -q ":$port "; then
            log_warn "Port $port is already in use"
        fi
    done
    
    log_info "Prerequisites check passed ✅"
}

# Environment validation
validate_environment() {
    log_step "Validating environment configuration..."
    
    # Check environment file
    ENV_FILE="$PROJECT_ROOT/.env.$ENV"
    if [[ ! -f "$ENV_FILE" ]]; then
        log_warn "Environment file $ENV_FILE not found, creating from template..."
        cp "$PROJECT_ROOT/.env.example" "$ENV_FILE"
        log_warn "Please update $ENV_FILE with proper values before continuing"
        if [[ "$FORCE" != "true" ]]; then
            read -p "Continue anyway? [y/N] " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    fi
    
    # Source environment variables
    source "$ENV_FILE"
    
    # Validate required variables
    required_vars=("POSTGRES_PASSWORD" "JWT_SECRET" "OPENAI_API_KEY")
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            error_exit "Required environment variable $var is not set"
        fi
    done
    
    log_info "Environment validation passed ✅"
}

# Create backup
create_backup() {
    if [[ "$NO_BACKUP" == "true" ]]; then
        log_info "Skipping backup as requested"
        return
    fi
    
    log_step "Creating backup..."
    
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    BACKUP_PATH="$BACKUP_DIR/backup-$TIMESTAMP"
    
    sudo mkdir -p "$BACKUP_PATH"
    
    # Backup application files
    if [[ -d "$DEPLOY_DIR" ]]; then
        log_info "Backing up application files..."
        sudo cp -r "$DEPLOY_DIR" "$BACKUP_PATH/app"
    fi
    
    # Backup databases if services are running
    if docker-compose ps | grep -q "Up"; then
        log_info "Backing up databases..."
        
        # PostgreSQL backup
        docker-compose exec -T db pg_dump -U postgres userstories > "$BACKUP_PATH/postgres.sql" || log_warn "PostgreSQL backup failed"
        
        # Redis backup
        docker-compose exec -T redis redis-cli --rdb - > "$BACKUP_PATH/redis.rdb" || log_warn "Redis backup failed"
        
        # ChromaDB backup
        sudo tar -czf "$BACKUP_PATH/chromadb.tar.gz" -C "$DEPLOY_DIR" chroma_db/ || log_warn "ChromaDB backup failed"
    fi
    
    # Clean old backups (keep last 7 days)
    find "$BACKUP_DIR" -name "backup-*" -mtime +7 -exec sudo rm -rf {} \; 2>/dev/null || true
    
    log_info "Backup created at: $BACKUP_PATH ✅"
    echo "$BACKUP_PATH" > "$BACKUP_DIR/latest-backup.txt"
}

# Setup deployment directory
setup_deployment_directory() {
    log_step "Setting up deployment directory..."
    
    sudo mkdir -p "$DEPLOY_DIR"
    sudo mkdir -p "$DEPLOY_DIR"/{config,ssl,logs}
    
    # Copy application files
    sudo cp -r "$PROJECT_ROOT"/* "$DEPLOY_DIR/"
    
    # Set up configuration
    sudo cp "$PROJECT_ROOT/.env.$ENV" "$DEPLOY_DIR/.env"
    
    # Set permissions
    sudo chown -R $USER:$USER "$DEPLOY_DIR"
    chmod +x "$DEPLOY_DIR"/scripts/deployment/*.sh
    chmod +x "$DEPLOY_DIR"/scripts/backup/*.sh
    
    log_info "Deployment directory setup complete ✅"
}

# Generate SSL certificates
setup_ssl() {
    log_step "Setting up SSL certificates..."
    
    SSL_DIR="$DEPLOY_DIR/docker/nginx/ssl"
    sudo mkdir -p "$SSL_DIR"
    
    if [[ ! -f "$SSL_DIR/cert.pem" ]]; then
        log_info "Generating self-signed SSL certificates..."
        sudo openssl req -x509 -newkey rsa:4096 -keyout "$SSL_DIR/key.pem" \
            -out "$SSL_DIR/cert.pem" -days 365 -nodes \
            -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
        
        sudo chmod 600 "$SSL_DIR/key.pem"
        sudo chmod 644 "$SSL_DIR/cert.pem"
        
        log_info "SSL certificates generated ✅"
    else
        log_info "SSL certificates already exist, skipping generation"
    fi
}

# Build and deploy services
deploy_services() {
    log_step "Building and deploying services..."
    
    cd "$DEPLOY_DIR"
    
    # Select appropriate compose file
    COMPOSE_FILE="docker-compose.yml"
    if [[ "$ENV" == "development" ]]; then
        COMPOSE_FILE="docker-compose.dev.yml"
    fi
    
    # Pull base images
    log_info "Pulling base images..."
    docker-compose -f "$COMPOSE_FILE" pull --ignore-pull-failures
    
    # Build services
    log_info "Building services..."
    docker-compose -f "$COMPOSE_FILE" build --parallel
    
    # Start services
    log_info "Starting services..."
    docker-compose -f "$COMPOSE_FILE" up -d
    
    # Wait for services to be ready
    log_info "Waiting for services to be ready..."
    sleep 30
    
    # Run database migrations
    log_info "Running database migrations..."
    docker-compose -f "$COMPOSE_FILE" exec -T backend alembic upgrade head || log_warn "Migration failed"
    
    log_info "Services deployed successfully ✅"
}

# Health checks
run_health_checks() {
    log_step "Running health checks..."
    
    # Define endpoints to check
    endpoints=(
        "http://localhost:80/health:Frontend"
        "http://localhost:8000/api/health:Backend API"
        "http://localhost:9090/-/healthy:Prometheus"
        "http://localhost:3001/api/health:Grafana"
    )
    
    failed_checks=0
    
    for endpoint in "${endpoints[@]}"; do
        url="${endpoint%%:*}"
        name="${endpoint##*:}"
        
        log_info "Checking $name ($url)..."
        
        if curl -f -s --max-time 10 "$url" > /dev/null; then
            log_info "$name: ✅ Healthy"
        else
            log_error "$name: ❌ Failed"
            ((failed_checks++))
        fi
    done
    
    # Check Docker services
    log_info "Checking Docker services..."
    if docker-compose ps | grep -v "Up" | grep -q "Exit\|Dead"; then
        log_error "Some Docker services are not running properly"
        docker-compose ps
        ((failed_checks++))
    else
        log_info "All Docker services are running ✅"
    fi
    
    if [[ $failed_checks -gt 0 ]]; then
        error_exit "$failed_checks health check(s) failed"
    else
        log_info "All health checks passed ✅"
    fi
}

# Rollback function
rollback_deployment() {
    log_step "Rolling back deployment..."
    
    if [[ ! -f "$BACKUP_DIR/latest-backup.txt" ]]; then
        error_exit "No backup found for rollback"
    fi
    
    LATEST_BACKUP=$(cat "$BACKUP_DIR/latest-backup.txt")
    
    if [[ ! -d "$LATEST_BACKUP" ]]; then
        error_exit "Backup directory not found: $LATEST_BACKUP"
    fi
    
    log_info "Rolling back to: $LATEST_BACKUP"
    
    # Stop current services
    cd "$DEPLOY_DIR" && docker-compose down
    
    # Restore application files
    sudo rm -rf "$DEPLOY_DIR"
    sudo cp -r "$LATEST_BACKUP/app" "$DEPLOY_DIR"
    sudo chown -R $USER:$USER "$DEPLOY_DIR"
    
    # Restore databases
    if [[ -f "$LATEST_BACKUP/postgres.sql" ]]; then
        log_info "Restoring PostgreSQL database..."
        cd "$DEPLOY_DIR"
        docker-compose up -d db
        sleep 10
        cat "$LATEST_BACKUP/postgres.sql" | docker-compose exec -T db psql -U postgres userstories
    fi
    
    # Start services
    cd "$DEPLOY_DIR" && docker-compose up -d
    
    log_info "Rollback completed ✅"
}

# Cleanup function
cleanup() {
    log_step "Cleaning up..."
    
    # Remove unused Docker images
    docker image prune -f
    
    # Remove unused volumes
    docker volume prune -f
    
    log_info "Cleanup completed ✅"
}

# Main deployment function
main() {
    log_info "🚀 AI User Story Generator Deployment Script"
    log_info "Environment: $ENV"
    echo "================================================"
    
    # Handle special modes
    if [[ "$HEALTH_CHECK_ONLY" == "true" ]]; then
        run_health_checks
        exit 0
    fi
    
    if [[ "$ROLLBACK" == "true" ]]; then
        rollback_deployment
        run_health_checks
        exit 0
    fi
    
    if [[ "$BACKUP_ONLY" == "true" ]]; then
        create_backup
        exit 0
    fi
    
    # Full deployment process
    check_prerequisites
    validate_environment
    
    # Confirmation for production
    if [[ "$ENV" == "production" && "$FORCE" != "true" ]]; then
        echo
        log_warn "You are about to deploy to PRODUCTION environment!"
        read -p "Are you sure you want to continue? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Deployment cancelled"
            exit 0
        fi
    fi
    
    create_backup
    setup_deployment_directory
    setup_ssl
    deploy_services
    run_health_checks
    cleanup
    
    echo "================================================"
    log_info "🎉 Deployment completed successfully!"
    echo ""
    log_info "Service URLs:"
    echo "  📱 Frontend:     http://localhost:3000"
    echo "  🔧 Backend API:  http://localhost:8000"
    echo "  📊 Grafana:      http://localhost:3001"
    echo "  📈 Prometheus:   http://localhost:9090"
    echo ""
    log_info "Useful commands:"
    echo "  View logs:       cd $DEPLOY_DIR && docker-compose logs -f"
    echo "  Check status:    cd $DEPLOY_DIR && docker-compose ps"
    echo "  Stop services:   cd $DEPLOY_DIR && docker-compose down"
    echo "  Rollback:        $0 --rollback"
}

# Run main function
main "$@"
EOF

# ========================================
# ENVIRONMENT CONFIGURATION FILES
# ========================================

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

# ========================================
# BACKUP SCRIPTS
# ========================================

mkdir -p scripts/backup
cat > scripts/backup/full-backup.sh << 'EOF'
#!/bin/bash
set -e

# Full System Backup Script
PROJECT_NAME="ai-user-story-generator"
BACKUP_DIR="/opt/backups/${PROJECT_NAME}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_PATH="${BACKUP_DIR}/full-backup-${TIMESTAMP}"

echo "🔄 Starting full system backup..."

# Create backup directory
mkdir -p "$BACKUP_PATH"

# Backup Docker volumes
echo "📦 Backing up Docker volumes..."
docker run --rm -v ai-user-story-generator_postgres_data:/data -v "$BACKUP_PATH":/backup alpine tar czf /backup/postgres_data.tar.gz -C /data .
docker run --rm -v ai-user-story-generator_redis_data:/data -v "$BACKUP_PATH":/backup alpine tar czf /backup/redis_data.tar.gz -C /data .
docker run --rm -v ai-user-story-generator_chroma_data:/data -v "$BACKUP_PATH":/backup alpine tar czf /backup/chroma_data.tar.gz -C /data .

# Backup application data
echo "📁 Backing up application data..."
cd "/opt/${PROJECT_NAME}"
tar czf "$BACKUP_PATH/app_data.tar.gz" uploads/ logs/ config/

# Backup database dump
echo "🗃️ Creating database dump..."
docker-compose exec -T db pg_dump -U postgres userstories > "$BACKUP_PATH/database.sql"

# Create backup manifest
cat > "$BACKUP_PATH/manifest.json" << JSON
{
  "timestamp": "$TIMESTAMP",
  "type": "full_backup",
  "files": [
    "postgres_data.tar.gz",
    "redis_data.tar.gz", 
    "chroma_data.tar.gz",
    "app_data.tar.gz",
    "database.sql"
  ],
  "version": "1.0.0"
}
JSON

echo "✅ Full backup completed: $BACKUP_PATH"
EOF

chmod +x scripts/backup/full-backup.sh

# ========================================
# MONITORING CONFIGURATIONS
# ========================================

mkdir -p monitoring/prometheus
cat > monitoring/prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alert_rules.yml"

scrape_configs:
  - job_name: 'ai-user-story-generator'
    static_configs:
      - targets: ['backend:8000']
    metrics_path: '/metrics'
    scrape_interval: 30s

  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres-exporter:9187']

  - job_name: 'redis'
    static_configs:
      - targets: ['redis-exporter:9121']

  - job_name: 'nginx'
    static_configs:
      - targets: ['nginx-exporter:9113']
EOF

# ========================================
# GITIGNORE
# ========================================

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

# ========================================
# COMPREHENSIVE README
# ========================================

cat > README.md << 'EOF'
# 🤖 AI User Story Generator

A production-grade AI-powered application for generating user stories using RAG (Retrieval-Augmented Generation) technology with support for multiple LLM providers.

## 🚀 Features

### 🎯 Core Capabilities
- **Multi-LLM Support**: OpenAI, Azure OpenAI, Google Gemini, Anthropic Claude
- **RAG-Enhanced Generation**: ChromaDB vector database with intelligent document retrieval
- **Multiple Data Sources**: Direct upload, Confluence, Jira, URL fetching
- **Real-time Processing**: Async document processing with progress tracking
- **Export Functionality**: CSV export with comprehensive story details

### 🛡️ Enterprise Security
- JWT authentication with role-based access control
- Rate limiting and DDoS protection
- Input validation and output sanitization
- PII detection and redaction
- Comprehensive audit logging
- SSL/TLS encryption

### 📊 Monitoring & Observability
- Prometheus metrics collection
- Grafana dashboards
- Real-time health monitoring
- Performance tracking
- Error tracking and alerting

### 🔧 Production Infrastructure
- Docker containerization
- Multi-stage builds for optimization
- Nginx reverse proxy with load balancing
- Database migrations and backups
- Zero-downtime deployments
- Horizontal scaling support

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   React Frontend │    │  FastAPI Backend │    │  Vector Database │
│                 │    │                 │    │    (ChromaDB)   │
│  • LLM Config   │◄──►│  • RAG System   │◄──►│                 │
│  • File Upload  │    │  • LLM Clients  │    │  • Embeddings   │
│  • Story Display│    │  • Security     │    │  • Similarity   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │              ┌─────────────────┐             │
         │              │   PostgreSQL    │             │
         └──────────────┤   • Projects    │─────────────┘
                        │   • Documents   │
                        │   • User Stories│
                        └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- Git
- 8GB RAM minimum
- 20GB free disk space

### 1. Clone Repository
```bash
git clone <repository-url>
cd ai-user-story-generator
```

### 2. Configure Environment
```bash
cp .env.example .env
# Edit .env with your API keys and configuration
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

### Building
```bash
make build            # Build all services
make build-frontend   # Build frontend only
make build-backend    # Build backend only
```

### Deployment
```bash
make deploy           # Deploy to production
make deploy-staging   # Deploy to staging
make start            # Start production services
make stop             # Stop all services
make restart          # Restart all services
```

### Testing
```bash
make test             # Run all tests
make test-backend     # Run backend tests
make test-frontend    # Run frontend tests
make test-e2e         # Run end-to-end tests
```

### Maintenance
```bash
make backup           # Create full system backup
make restore          # Restore from backup
make clean            # Clean Docker resources
make health           # Check system health
```

## 🔧 Configuration

### LLM Providers
Configure your preferred LLM provider in the frontend:

#### OpenAI
```bash
export OPENAI_API_KEY="sk-..."
```

#### Azure OpenAI
```bash
export AZURE_OPENAI_API_KEY="..."
export AZURE_OPENAI_ENDPOINT="https://your-resource.openai.azure.com/"
export AZURE_OPENAI_API_VERSION="2023-12-01-preview"
```

#### Google Gemini
```bash
export GOOGLE_API_KEY="..."
```

#### Anthropic Claude
```bash
export ANTHROPIC_API_KEY="..."
```

### External Integrations

#### Confluence
```bash
export CONFLUENCE_BASE_URL="https://yourcompany.atlassian.net"
export CONFLUENCE_USERNAME="your-email@company.com"
export CONFLUENCE_API_TOKEN="your-api-token"
```

#### Jira
```bash
export JIRA_BASE_URL="https://yourcompany.atlassian.net"
export JIRA_USERNAME="your-email@company.com"
export JIRA_API_TOKEN="your-api-token"
```

## 📁 Project Structure

```
ai-user-story-generator/
├── 📁 backend/                     # Python FastAPI Backend
│   ├── 📁 app/                     # Application code
│   │   ├── 📁 api/                 # API routes
│   │   ├── 📁 core/                # Core configuration
│   │   ├── 📁 models/              # Database models
│   │   ├── 📁 services/            # Business logic
│   │   └── 📁 utils/               # Utilities
│   ├── main.py                     # FastAPI app
│   ├── requirements.txt            # Dependencies
│   └── Dockerfile                  # Container config
├── 📁 frontend/                    # React Frontend
│   ├── 📁 src/                     # Source code
│   │   ├── 📁 components/          # React components
│   │   ├── 📁 services/            # API services
│   │   └── 📁 utils/               # Utilities
│   ├── package.json                # Dependencies
│   └── Dockerfile                  # Container config
├── 📁 docker/                      # Docker configs
├── 📁 scripts/                     # Automation scripts
├── 📁 monitoring/                  # Monitoring configs
├── docker-compose.yml              # Main compose file
├── Makefile                        # Build automation
└── README.md                       # Documentation
```

## 🔍 API Documentation

### Authentication
All API requests require a JWT token in the Authorization header:
```bash
Authorization: Bearer <your-jwt-token>
```

### Core Endpoints

#### Projects
```bash
GET    /api/projects              # List projects
POST   /api/projects              # Create project
GET    /api/projects/{id}         # Get project
PUT    /api/projects/{id}         # Update project
DELETE /api/projects/{id}         # Delete project
```

#### Document Upload
```bash
POST   /api/projects/{id}/upload  # Upload documents
GET    /api/projects/{id}/documents # List documents
```

#### User Story Generation
```bash
POST   /api/projects/{id}/generate-stories  # Generate stories
GET    /api/projects/{id}/stories           # List stories
```

#### Configuration
```bash
PUT    /api/config/llm            # Update LLM config
GET    /api/config                # Get configuration
```

#### Health & Monitoring
```bash
GET    /api/health                # Health check
GET    /metrics                   # Prometheus metrics
```

## 🔐 Security

### Authentication & Authorization
- JWT-based authentication
- Role-based access control
- Session management
- Password hashing with bcrypt

### Data Protection
- Input validation and sanitization
- Output filtering
- PII detection and redaction
- Secure file upload validation

### Infrastructure Security
- TLS 1.3 encryption
- Rate limiting
- DDoS protection
- Security headers
- Container security scanning

## 📊 Monitoring

### Metrics
- Request rate and response times
- Error rates and status codes
- Resource utilization
- Business metrics (projects, stories, documents)

### Alerts
- Service health checks
- High error rates
- Resource exhaustion
- Security incidents

### Dashboards
- System overview
- Application metrics
- Infrastructure monitoring
- Business analytics

## 🚀 Deployment

### Environments
- **Development**: Local development with hot reload
- **Staging**: Pre-production testing environment
- **Production**: Full production deployment

### Deployment Strategies
- Blue-green deployments
- Rolling updates
- Canary releases
- Feature flags

### Scaling
- Horizontal pod autoscaling
- Database read replicas
- Redis clustering
- CDN integration

## 🔧 Troubleshooting

### Common Issues

#### Services Won't Start
```bash
# Check Docker resources
docker system df
docker system prune

# Check logs
make logs
```

#### Database Connection Issues
```bash
# Reset database
make db-reset

# Check database logs
docker-compose logs db
```

#### Performance Issues
```bash
# Check metrics
make metrics

# Scale services
docker-compose up -d --scale backend=3
```

### Debug Mode
```bash
# Enable debug logging
export LOG_LEVEL=debug
make restart
```

## 🤝 Contributing

### Development Setup
```bash
# Install development dependencies
make install-dev

# Set up git hooks
make setup-hooks

# Run tests
make test
```

### Code Quality
```bash
# Lint code
make lint

# Format code
make format

# Type checking
make type-check
```

### Pull Request Process
1. Fork the repository
2. Create feature branch
3. Make changes with tests
4. Run quality checks
5. Submit pull request

## 📚 Documentation

- [API Documentation](docs/api/README.md)
- [Deployment Guide](docs/deployment/README.md)
- [Architecture Overview](docs/architecture/README.md)
- [User Guide](docs/user-guide/README.md)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Issues**: Create GitHub issues for bugs and feature requests
- **Discussions**: Use GitHub Discussions for questions and ideas
- **Email**: support@yourcompany.com
- **Documentation**: Check the docs/ folder for detailed guides

## 🗺️ Roadmap

### Version 2.0
- [ ] Multi-tenant support
- [ ] Advanced analytics dashboard
- [ ] Integration with more LLM providers
- [ ] Mobile application
- [ ] Advanced workflow automation

### Version 2.1
- [ ] AI-powered testing generation
- [ ] Advanced export formats
- [ ] Team collaboration features
- [ ] API rate limiting dashboard
- [ ] Advanced security features

---

Built with ❤️ by the AI User Story Generator Team
EOF

# ========================================
# TYPESCRIPT CONFIGURATION
# ========================================

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

# ========================================
# TESTING CONFIGURATION
# ========================================

mkdir -p scripts/test
cat > scripts/test/run-e2e-tests.sh << 'EOF'
#!/bin/bash
set -e

echo "🧪 Running End-to-End Tests"

# Start test environment
docker-compose -f docker-compose.test.yml up -d

# Wait for services
sleep 30

# Run E2E tests
docker-compose -f docker-compose.test.yml exec -T frontend npm run test:e2e

# Cleanup
docker-compose -f docker-compose.test.yml down

echo "✅ E2E tests completed"
EOF

chmod +x scripts/test/run-e2e-tests.sh

# ========================================
# SECURITY SCAN SCRIPT
# ========================================

mkdir -p scripts/security
cat > scripts/security/security-scan.sh << 'EOF'
#!/bin/bash
set -e

echo "🔒 Running Security Scans"

# Backend security scan
echo "Scanning backend for vulnerabilities..."
docker-compose exec backend safety check --json > security-report-backend.json || true

# Frontend security scan
echo "Scanning frontend for vulnerabilities..."
docker-compose exec frontend npm audit --audit-level=moderate --json > security-report-frontend.json || true

# Docker image security scan
echo "Scanning Docker images..."
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image ai-user-story-generator_backend:latest > security-report-docker-backend.txt || true

docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image ai-user-story-generator_frontend:latest > security-report-docker-frontend.txt || true

echo "✅ Security scans completed. Check security-report-*.json files for results."
EOF

chmod +x scripts/security/security-scan.sh

# ========================================
# PRE-COMMIT CONFIGURATION
# ========================================

cat > .pre-commit-config.yaml << 'EOF'
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
      - id: check-merge-conflict

  - repo: https://github.com/psf/black
    rev: 23.3.0
    hooks:
      - id: black
        language_version: python3
        files: ^backend/

  - repo: https://github.com/pycqa/isort
    rev: 5.12.0
    hooks:
      - id: isort
        files: ^backend/

  - repo: https://github.com/pycqa/flake8
    rev: 6.0.0
    hooks:
      - id: flake8
        files: ^backend/

  - repo: https://github.com/pre-commit/mirrors-prettier
    rev: v3.0.0-alpha.9-for-vscode
    hooks:
      - id: prettier
        files: ^frontend/
EOF

# ========================================
# DOCKER IGNORE FILES
# ========================================

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

echo "✅ Production-grade project structure created successfully!"
echo ""
echo "📁 Project Structure:"
echo "  ├── Complete folder hierarchy with proper separation"
echo "  ├── Multi-stage Docker builds for optimization"
echo "  ├── Environment-specific configurations"
echo "  ├── Comprehensive automation with Makefile"
echo "  ├── Production deployment scripts"
echo "  ├── Monitoring and security configurations"
echo "  ├── Testing infrastructure"
echo "  └── Documentation and guidelines"
echo ""
echo "🚀 Next Steps:"
echo "  1. Copy your code into the appropriate directories"
echo "  2. Update .env files with your configuration"
echo "  3. Run 'make deploy' to start the application"
echo "  4. Access the application at http://localhost:3000"
echo ""
echo "📖 See README.md for detailed documentation"
# ========================================
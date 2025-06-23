#!/bin/bash

# Ubuntu生产环境快速启动脚本（适用于已构建项目）
# 八卦运势AI小程序 - Docker环境优先
# 部署顺序: 前端 -> 后端
# 作者: AI助手
# 日期: 2025-01-17

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示横幅
echo -e "${CYAN}"
echo "=================================================="
echo "    八卦运势AI小程序 - Ubuntu快速启动"
echo "    前端->后端部署顺序 | Docker环境"
echo "=================================================="
echo -e "${NC}"

# 检查Docker环境
log_info "🔍 检查Docker环境..."
if ! docker info > /dev/null 2>&1; then
    log_error "❌ Docker未运行，请先启动Docker服务"
    echo "启动命令: sudo systemctl start docker"
    exit 1
fi
log_success "✅ Docker环境检查通过"

# 检查必要文件
log_info "🔍 检查必要文件..."
if [ ! -f "docker-compose.public.yml" ]; then
    log_error "❌ 找不到docker-compose.public.yml文件"
    exit 1
fi

if [ ! -f "config/prod.env" ]; then
    log_error "❌ 找不到config/prod.env配置文件"
    exit 1
fi

if [ ! -f "backend/target/fortune-mini-app-1.0.0.jar" ]; then
    log_error "❌ 找不到后端JAR文件，请先构建后端"
    echo "构建命令: cd backend && mvn clean package -DskipTests"
    exit 1
fi

log_success "✅ 必要文件检查通过"

# 创建必要目录
log_info "📁 创建必要目录..."
mkdir -p logs uploads nginx/ssl
chmod 755 logs uploads

# 停止现有服务
log_info "🛑 停止现有服务..."
docker-compose -f docker-compose.public.yml down --remove-orphans > /dev/null 2>&1 || true

# 步骤1: 部署前端（如果有构建好的前端）
if [ -d "frontend/dist" ] || [ -d "frontend/build" ]; then
    log_info "🎨 部署前端服务..."
    
    # 创建前端Nginx配置
    cat > nginx/frontend.conf << 'EOF'
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    # 启用gzip压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_comp_level 6;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # API代理到后端
    location /api/ {
        proxy_pass http://host.docker.internal:8080/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # SPA路由支持
    location / {
        try_files $uri $uri/ @fallback;
    }

    location @fallback {
        try_files /index.html =404;
    }

    # 健康检查
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

    # 启动前端容器
    FRONTEND_DIR="frontend/dist"
    if [ -d "frontend/dist/build/h5" ]; then
        FRONTEND_DIR="frontend/dist/build/h5"
    elif [ -d "frontend/build" ]; then
        FRONTEND_DIR="frontend/build"
    fi

    docker run -d \
        --name bagua-frontend-prod \
        --restart unless-stopped \
        -p 80:80 \
        -v "$(pwd)/$FRONTEND_DIR:/usr/share/nginx/html:ro" \
        -v "$(pwd)/nginx/frontend.conf:/etc/nginx/conf.d/default.conf:ro" \
        nginx:alpine

    # 等待前端启动
    log_info "⏳ 等待前端服务启动..."
    for i in {1..30}; do
        if curl -s http://localhost/health > /dev/null 2>&1; then
            log_success "✅ 前端服务启动成功"
            break
        fi
        if [ $i -eq 30 ]; then
            log_error "❌ 前端服务启动超时"
            docker logs bagua-frontend-prod
            exit 1
        fi
        echo -n "."
        sleep 2
    done
else
    log_info "⏭️ 跳过前端部署（未找到构建文件）"
fi

# 步骤2: 部署后端服务
log_info "⚙️ 部署后端服务..."

# 启动数据库和缓存服务
log_info "🗄️ 启动数据库和缓存服务..."
docker-compose -f docker-compose.public.yml --env-file config/prod.env up -d mysql redis

# 等待数据库启动
log_info "⏳ 等待数据库启动..."
for i in {1..30}; do
    if docker-compose -f docker-compose.public.yml exec -T mysql mysqladmin ping -h localhost -u root -pFortune2025!Root > /dev/null 2>&1; then
        log_success "✅ 数据库启动成功"
        break
    fi
    if [ $i -eq 30 ]; then
        log_error "❌ 数据库启动超时"
        exit 1
    fi
    echo -n "."
    sleep 2
done

# 启动后端服务
log_info "🚀 启动后端服务..."
docker-compose -f docker-compose.public.yml --env-file config/prod.env up -d backend

# 等待后端启动
log_info "⏳ 等待后端服务启动..."
for i in {1..60}; do
    if curl -s http://localhost:8080/api/actuator/health > /dev/null 2>&1; then
        log_success "✅ 后端服务启动成功"
        break
    fi
    if [ $i -eq 60 ]; then
        log_error "❌ 后端服务启动超时"
        docker-compose -f docker-compose.public.yml logs backend
        exit 1
    fi
    echo -n "."
    sleep 2
done

# 验证部署结果
log_info "🔍 验证部署结果..."

# 检查前端
if docker ps | grep -q bagua-frontend-prod; then
    if curl -s http://localhost/health | grep -q "healthy"; then
        log_success "✅ 前端服务验证通过"
    else
        log_error "❌ 前端服务验证失败"
    fi
else
    log_info "ℹ️ 前端服务未部署"
fi

# 检查后端
if curl -s http://localhost:8080/api/actuator/health | grep -q "UP"; then
    log_success "✅ 后端服务验证通过"
else
    log_error "❌ 后端服务验证失败"
fi

# 显示服务状态
log_info "📊 服务状态:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# 显示部署结果
log_success "🎉 Ubuntu生产环境启动完成！"
echo ""
echo -e "${CYAN}📋 服务访问地址:${NC}"
if docker ps | grep -q bagua-frontend-prod; then
    echo "- 前端Web应用: http://localhost"
fi
echo "- 后端API接口: http://localhost:8080"
echo "- 数据库: localhost:3306"
echo "- Redis缓存: localhost:6379"
echo ""
echo -e "${CYAN}🔧 管理命令:${NC}"
echo "- 查看所有容器: docker ps"
if docker ps | grep -q bagua-frontend-prod; then
    echo "- 查看前端日志: docker logs bagua-frontend-prod"
fi
echo "- 查看后端日志: docker-compose -f docker-compose.public.yml logs -f"
echo "- 停止所有服务: docker-compose -f docker-compose.public.yml down"
if docker ps | grep -q bagua-frontend-prod; then
    echo "                    docker stop bagua-frontend-prod && docker rm bagua-frontend-prod"
fi
echo "- 重新启动: ./ubuntu-quick-start.sh"
echo ""
echo -e "${CYAN}🧪 测试命令:${NC}"
if docker ps | grep -q bagua-frontend-prod; then
    echo "- 前端健康检查: curl http://localhost/health"
fi
echo "- 后端健康检查: curl http://localhost:8080/api/actuator/health"
echo "- 测试运势API: curl -X POST http://localhost:8080/api/fortune/calculate -H 'Content-Type: application/json' -d '{\"name\":\"测试\",\"birthDate\":\"1990-01-01\",\"birthTime\":\"子时\",\"gender\":\"male\"}'"
echo ""
if docker ps | grep -q bagua-frontend-prod; then
    echo -e "${GREEN}部署完成！请访问 http://localhost 查看前端应用${NC}"
else
    echo -e "${GREEN}后端部署完成！请访问 http://localhost:8080 查看API接口${NC}"
fi 
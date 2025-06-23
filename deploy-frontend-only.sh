#!/bin/bash

# 八卦运势AI小程序 - 只部署前端脚本
# Ubuntu生产环境
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

# 通用容器清理函数
cleanup_container() {
    local container_name=$1
    local service_name=$2
    
    if docker ps | grep -q "$container_name"; then
        log_info "停止运行中的${service_name}容器..."
        docker stop "$container_name" > /dev/null 2>&1
    fi
    
    if docker ps -a | grep -q "$container_name"; then
        log_info "删除已存在的${service_name}容器..."
        docker rm "$container_name" > /dev/null 2>&1
    fi
}

echo -e "${CYAN}"
echo "=================================================="
echo "    八卦运势AI小程序 - 前端部署"
echo "    Ubuntu生产环境 | Docker环境"
echo "=================================================="
echo -e "${NC}"

# 检查Docker环境
log_info "🔍 检查Docker环境..."
if ! docker info > /dev/null 2>&1; then
    log_error "❌ Docker未运行，请先启动Docker服务"
    exit 1
fi
log_success "✅ Docker环境检查通过"

# 清理已存在的前端容器
log_info "🧹 清理前端容器..."
cleanup_container "bagua-frontend-prod" "前端"

# 检查前端构建文件
if [ ! -d "frontend/dist" ] && [ ! -d "frontend/build" ]; then
    log_error "❌ 找不到前端构建文件"
    log_info "请先构建前端："
    log_info "cd frontend && npm install && npm run build:h5"
    exit 1
fi

# 创建前端Nginx配置（不包含API代理）
log_info "📝 创建前端Nginx配置..."
mkdir -p nginx
cat > nginx/frontend-only.conf << 'EOF'
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

    # HTML文件不缓存
    location ~* \.html$ {
        expires -1;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
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

    # API提示页面（当后端未启动时）
    location /api/ {
        return 503 '{"error": "Backend service not available", "message": "Please start backend service first"}';
        add_header Content-Type application/json;
    }
}
EOF

# 确定前端目录
FRONTEND_DIR="frontend/dist"
if [ -d "frontend/dist/build/h5" ]; then
    FRONTEND_DIR="frontend/dist/build/h5"
elif [ -d "frontend/build" ]; then
    FRONTEND_DIR="frontend/build"
fi

log_info "📁 使用前端目录: $FRONTEND_DIR"

# 启动前端容器
log_info "🚀 启动前端服务..."
docker run -d \
    --name bagua-frontend-prod \
    --restart unless-stopped \
    -p 80:80 \
    -v "$(pwd)/$FRONTEND_DIR:/usr/share/nginx/html:ro" \
    -v "$(pwd)/nginx/frontend-only.conf:/etc/nginx/conf.d/default.conf:ro" \
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

# 显示结果
log_success "🎉 前端部署完成！"
echo ""
echo -e "${CYAN}📋 访问地址:${NC}"
echo "- 前端Web应用: http://localhost"
echo "- 健康检查: http://localhost/health"
echo ""
echo -e "${CYAN}🔧 管理命令:${NC}"
echo "- 查看容器状态: docker ps"
echo "- 查看前端日志: docker logs bagua-frontend-prod"
echo "- 停止前端: docker stop bagua-frontend-prod && docker rm bagua-frontend-prod"
echo ""
echo -e "${YELLOW}⚠️ 注意:${NC}"
echo "- 前端已启动，但API接口需要单独启动后端服务"
echo "- 启动后端: ./deploy-backend-only.sh"
echo "- 或使用完整部署: ./ubuntu-quick-start.sh" 
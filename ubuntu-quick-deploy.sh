#!/bin/bash

# Ubuntu生产环境快速部署脚本
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
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

log_deploy() {
    echo -e "${CYAN}[DEPLOY]${NC} $1"
}

# 显示横幅
show_banner() {
    echo -e "${CYAN}"
    echo "=================================================="
    echo "      八卦运势AI小程序 - Ubuntu生产环境部署"
    echo "      Docker环境优先 | 前端->后端部署顺序"
    echo "=================================================="
    echo -e "${NC}"
}

# 检查系统环境
check_system() {
    log_step "🔍 检查系统环境..."
    
    # 检查是否为Ubuntu
    if ! grep -q "Ubuntu" /etc/os-release; then
        log_warning "当前系统不是Ubuntu，脚本可能需要调整"
    else
        log_success "✅ Ubuntu系统检查通过"
    fi
    
    # 检查是否为root或有sudo权限
    if [[ $EUID -eq 0 ]]; then
        log_success "✅ Root权限检查通过"
    elif sudo -n true 2>/dev/null; then
        log_success "✅ Sudo权限检查通过"
    else
        log_error "❌ 需要root权限或sudo权限"
        exit 1
    fi
}

# 安装Docker环境
install_docker() {
    log_step "🐳 检查并安装Docker环境..."
    
    if command -v docker &> /dev/null; then
        log_success "✅ Docker已安装"
        docker --version
    else
        log_info "安装Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh
        log_success "✅ Docker安装完成"
    fi
    
    if command -v docker-compose &> /dev/null; then
        log_success "✅ Docker Compose已安装"
        docker-compose --version
    else
        log_info "安装Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        log_success "✅ Docker Compose安装完成"
    fi
    
    # 启动Docker服务
    sudo systemctl enable docker
    sudo systemctl start docker
    
    # 检查Docker是否运行
    if ! docker info > /dev/null 2>&1; then
        log_error "❌ Docker未正常运行"
        exit 1
    fi
    
    log_success "✅ Docker环境准备完成"
}

# 安装Node.js环境（用于前端构建）
install_nodejs() {
    log_step "📦 检查并安装Node.js环境..."
    
    if command -v node &> /dev/null; then
        log_success "✅ Node.js已安装: $(node --version)"
    else
        log_info "安装Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs
        log_success "✅ Node.js安装完成: $(node --version)"
    fi
    
    # 检查npm
    if command -v npm &> /dev/null; then
        log_success "✅ NPM已安装: $(npm --version)"
    else
        log_error "❌ NPM未安装"
        exit 1
    fi
}

# 安装Java环境（用于后端构建）
install_java() {
    log_step "☕ 检查并安装Java环境..."
    
    if command -v java &> /dev/null; then
        log_success "✅ Java已安装: $(java --version 2>&1 | head -n1)"
    else
        log_info "安装OpenJDK 17..."
        sudo apt-get update
        sudo apt-get install -y openjdk-17-jdk
        log_success "✅ Java安装完成"
    fi
    
    # 检查Maven
    if command -v mvn &> /dev/null; then
        log_success "✅ Maven已安装: $(mvn --version | head -n1)"
    else
        log_info "安装Maven..."
        sudo apt-get install -y maven
        log_success "✅ Maven安装完成"
    fi
}

# 创建必要目录和配置
setup_directories() {
    log_step "📁 创建必要目录和配置..."
    
    # 创建目录
    mkdir -p logs uploads nginx/ssl config
    
    # 设置权限
    chmod 755 logs uploads
    
    # 检查配置文件
    if [ ! -f "config/prod.env" ]; then
        log_warning "⚠️ 生产环境配置文件不存在，创建默认配置..."
        cp env.prod.template config/prod.env 2>/dev/null || {
            log_error "❌ 找不到配置模板文件"
            exit 1
        }
    fi
    
    log_success "✅ 目录和配置准备完成"
}

# 构建前端应用
build_frontend() {
    log_deploy "🎨 开始构建前端应用..."
    
    cd frontend
    
    # 检查package.json
    if [ ! -f "package.json" ]; then
        log_error "❌ 前端项目配置文件不存在"
        exit 1
    fi
    
    # 安装依赖
    log_info "安装前端依赖..."
    npm install --production=false
    
    # 构建H5版本（用于Web部署）
    log_info "构建H5版本..."
    npm run build:h5
    
    # 构建微信小程序版本
    log_info "构建微信小程序版本..."
    npm run build:mp-weixin
    
    cd ..
    
    log_success "✅ 前端构建完成"
}

# 创建前端Docker镜像
build_frontend_docker() {
    log_deploy "🐳 创建前端Docker镜像..."
    
    # 创建前端Dockerfile
    cat > frontend/Dockerfile << 'EOF'
FROM nginx:alpine

# 复制构建好的前端文件
COPY dist/build/h5/ /usr/share/nginx/html/
COPY dist/build/mp-weixin/ /usr/share/nginx/html/mp-weixin/

# 复制Nginx配置
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 暴露端口
EXPOSE 80

# 启动Nginx
CMD ["nginx", "-g", "daemon off;"]
EOF

    # 创建前端Nginx配置
    cat > frontend/nginx.conf << 'EOF'
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
}
EOF

    # 构建前端Docker镜像
    cd frontend
    docker build -t bagua-frontend:latest .
    cd ..
    
    log_success "✅ 前端Docker镜像创建完成"
}

# 构建后端应用
build_backend() {
    log_deploy "⚙️ 开始构建后端应用..."
    
    cd backend
    
    # 检查pom.xml
    if [ ! -f "pom.xml" ]; then
        log_error "❌ 后端项目配置文件不存在"
        exit 1
    fi
    
    # 清理并构建
    log_info "构建后端应用..."
    mvn clean package -DskipTests
    
    # 检查JAR文件
    if [ ! -f "target/fortune-mini-app-1.0.0.jar" ]; then
        log_error "❌ 后端JAR文件构建失败"
        exit 1
    fi
    
    cd ..
    
    log_success "✅ 后端构建完成"
}

# 部署前端服务
deploy_frontend() {
    log_deploy "🚀 部署前端服务..."
    
    # 停止现有前端容器（更安全的清理方式）
    log_info "清理现有前端容器..."
    if docker ps | grep -q bagua-frontend-prod; then
        log_info "停止运行中的前端容器..."
        docker stop bagua-frontend-prod
    fi
    if docker ps -a | grep -q bagua-frontend-prod; then
        log_info "删除已存在的前端容器..."
        docker rm bagua-frontend-prod
    fi
    
    # 启动前端容器
    docker run -d \
        --name bagua-frontend-prod \
        --restart unless-stopped \
        -p 80:80 \
        -p 443:443 \
        bagua-frontend:latest
    
    # 等待前端启动
    log_info "等待前端服务启动..."
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
    
    log_success "✅ 前端部署完成"
}

# 部署后端服务
deploy_backend() {
    log_deploy "🚀 部署后端服务..."
    
    # 停止现有服务
    log_info "停止现有后端服务..."
    docker-compose -f docker-compose.public.yml down --remove-orphans > /dev/null 2>&1 || true
    
    # 启动数据库和缓存服务
    log_info "启动数据库和缓存服务..."
    docker-compose -f docker-compose.public.yml --env-file config/prod.env up -d mysql redis
    
    # 等待数据库启动
    log_info "等待数据库启动..."
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
    log_info "启动后端服务..."
    docker-compose -f docker-compose.public.yml --env-file config/prod.env up -d backend
    
    # 等待后端启动
    log_info "等待后端服务启动..."
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
    
    log_success "✅ 后端部署完成"
}

# 验证部署结果
verify_deployment() {
    log_step "🔍 验证部署结果..."
    
    # 检查前端
    if curl -s http://localhost/health | grep -q "healthy"; then
        log_success "✅ 前端服务验证通过"
    else
        log_warning "⚠️ 前端服务可能有问题"
    fi
    
    # 检查后端
    if curl -s http://localhost:8080/api/actuator/health | grep -q "UP"; then
        log_success "✅ 后端服务验证通过"
    else
        log_warning "⚠️ 后端服务可能有问题"
    fi
    
    # 显示服务状态
    log_info "服务状态:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    log_success "✅ 部署验证完成"
}

# 显示部署结果
show_deployment_info() {
    log_success "🎉 Ubuntu生产环境部署完成！"
    echo ""
    echo -e "${CYAN}📋 服务访问地址:${NC}"
    echo "- 前端Web应用: http://localhost"
    echo "- 后端API接口: http://localhost:8080"
    echo "- 数据库: localhost:3306"
    echo "- Redis缓存: localhost:6379"
    echo ""
    echo -e "${CYAN}🔧 管理命令:${NC}"
    echo "- 查看所有容器: docker ps"
    echo "- 查看前端日志: docker logs bagua-frontend-prod"
    echo "- 查看后端日志: docker-compose -f docker-compose.public.yml logs -f"
    echo "- 停止所有服务: docker-compose -f docker-compose.public.yml down && docker stop bagua-frontend-prod"
    echo "- 重新部署: ./ubuntu-quick-deploy.sh"
    echo ""
    echo -e "${CYAN}🧪 测试命令:${NC}"
    echo "- 前端健康检查: curl http://localhost/health"
    echo "- 后端健康检查: curl http://localhost:8080/api/actuator/health"
    echo "- 测试运势API: curl -X POST http://localhost:8080/api/fortune/calculate -H 'Content-Type: application/json' -d '{\"name\":\"测试\",\"birthDate\":\"1990-01-01\",\"birthTime\":\"子时\",\"gender\":\"male\"}'"
    echo ""
    echo -e "${GREEN}部署完成！请访问 http://localhost 查看前端应用${NC}"
}

# 主函数
main() {
    show_banner
    
    # 检查参数
    SKIP_BUILD=false
    SKIP_FRONTEND=false
    SKIP_BACKEND=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-build)
                SKIP_BUILD=true
                shift
                ;;
            --skip-frontend)
                SKIP_FRONTEND=true
                shift
                ;;
            --skip-backend)
                SKIP_BACKEND=true
                shift
                ;;
            --help)
                echo "用法: $0 [选项]"
                echo "选项:"
                echo "  --skip-build      跳过构建步骤"
                echo "  --skip-frontend   跳过前端部署"
                echo "  --skip-backend    跳过后端部署"
                echo "  --help           显示帮助信息"
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                exit 1
                ;;
        esac
    done
    
    # 执行部署步骤
    check_system
    install_docker
    
    if [ "$SKIP_BUILD" = false ]; then
        install_nodejs
        install_java
    fi
    
    setup_directories
    
    if [ "$SKIP_FRONTEND" = false ]; then
        if [ "$SKIP_BUILD" = false ]; then
            build_frontend
            build_frontend_docker
        fi
        deploy_frontend
    fi
    
    if [ "$SKIP_BACKEND" = false ]; then
        if [ "$SKIP_BUILD" = false ]; then
            build_backend
        fi
        deploy_backend
    fi
    
    verify_deployment
    show_deployment_info
}

# 错误处理
trap 'log_error "部署过程中发生错误，请检查日志"; exit 1' ERR

# 运行主函数
main "$@" 
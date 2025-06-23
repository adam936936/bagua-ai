#!/bin/bash

# 八卦运势AI - 公网HTTP部署脚本
# 适用于跳过SSL配置，直接使用HTTP访问的场景

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 检查环境
check_environment() {
    log_info "检查部署环境..."
    
    # 检查Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装，请先安装Docker"
        exit 1
    fi
    
    # 检查Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose未安装，请先安装Docker Compose"
        exit 1
    fi
    
    # 检查必要文件
    if [[ ! -f "docker-compose.public.yml" ]]; then
        log_error "docker-compose.public.yml文件不存在"
        exit 1
    fi
    
    if [[ ! -f "nginx/nginx.public-http.conf" ]]; then
        log_error "nginx/nginx.public-http.conf文件不存在"
        exit 1
    fi
    
    log_success "环境检查通过"
}

# 构建前端
build_frontend() {
    log_info "构建前端项目..."
    
    if [[ ! -d "frontend" ]]; then
        log_error "frontend目录不存在"
        exit 1
    fi
    
    cd frontend
    
    # 检查是否有package.json
    if [[ ! -f "package.json" ]]; then
        log_error "frontend/package.json不存在"
        exit 1
    fi
    
    # 安装依赖并构建
    log_info "安装前端依赖..."
    npm install
    
    log_info "构建前端..."
    npm run build
    
    if [[ ! -d "dist" ]]; then
        log_error "前端构建失败，dist目录不存在"
        exit 1
    fi
    
    cd ..
    log_success "前端构建完成"
}

# 构建后端
build_backend() {
    log_info "构建后端项目..."
    
    if [[ ! -d "backend" ]]; then
        log_error "backend目录不存在"
        exit 1
    fi
    
    cd backend
    
    # 检查Maven
    if ! command -v mvn &> /dev/null; then
        log_error "Maven未安装，请先安装Maven"
        exit 1
    fi
    
    # 清理并构建
    log_info "清理旧的构建文件..."
    mvn clean
    
    log_info "编译并打包后端..."
    mvn package -DskipTests
    
    if [[ ! -f "target/*.jar" ]]; then
        log_error "后端构建失败，JAR文件不存在"
        exit 1
    fi
    
    cd ..
    log_success "后端构建完成"
}

# 准备部署环境
prepare_deployment() {
    log_info "准备部署环境..."
    
    # 创建必要的目录
    mkdir -p logs/nginx
    mkdir -p uploads
    
    # 设置目录权限
    sudo chown -R $USER:$USER logs uploads
    chmod -R 755 logs uploads
    
    # 检查环境变量文件
    if [[ ! -f ".env" ]]; then
        log_warning ".env文件不存在，将使用默认配置"
        # 创建基本的.env文件
        cat > .env << EOF
# 数据库配置
MYSQL_ROOT_PASSWORD=Fortune2025!Root
MYSQL_DATABASE=bagua_ai
MYSQL_USERNAME=bagua_user
MYSQL_PASSWORD=Fortune2025!User

# Redis配置
REDIS_PASSWORD=Fortune2025!Redis

# AI服务配置（请填入实际值）
DEEPSEEK_API_KEY=your_deepseek_api_key
DEEPSEEK_API_URL=https://api.deepseek.com/v1/chat/completions
DEEPSEEK_MODEL=deepseek-chat

# 微信配置（请填入实际值）
WECHAT_APP_ID=your_wechat_app_id
WECHAT_APP_SECRET=your_wechat_app_secret

# JWT配置
JWT_SECRET=BaguaAI2025SecretKey
ENCRYPTION_KEY=BaguaAI2025EncryptionKey

# 域名配置
DOMAIN_NAME=122.51.104.128
EOF
        log_warning "已创建默认.env文件，请根据实际情况修改配置"
    fi
    
    log_success "部署环境准备完成"
}

# 清理旧容器
cleanup_containers() {
    log_info "清理旧的容器..."
    
    # 停止并删除旧容器
    docker-compose -f docker-compose.public.yml down --remove-orphans 2>/dev/null || true
    
    # 清理未使用的镜像和网络
    docker system prune -f 2>/dev/null || true
    
    log_success "容器清理完成"
}

# 启动服务
start_services() {
    log_info "启动服务..."
    
    # 启动所有服务
    docker-compose -f docker-compose.public.yml up -d
    
    log_success "服务启动完成"
}

# 等待服务就绪
wait_for_services() {
    log_info "等待服务启动..."
    
    # 等待MySQL就绪
    log_info "等待MySQL启动..."
    for i in {1..30}; do
        if docker-compose -f docker-compose.public.yml exec -T mysql mysqladmin ping -h localhost -u root -pFortune2025!Root 2>/dev/null; then
            log_success "MySQL已就绪"
            break
        fi
        if [[ $i -eq 30 ]]; then
            log_error "MySQL启动超时"
            exit 1
        fi
        sleep 10
    done
    
    # 等待Redis就绪
    log_info "等待Redis启动..."
    for i in {1..20}; do
        if docker-compose -f docker-compose.public.yml exec -T redis redis-cli -a Fortune2025!Redis ping 2>/dev/null | grep -q PONG; then
            log_success "Redis已就绪"
            break
        fi
        if [[ $i -eq 20 ]]; then
            log_error "Redis启动超时"
            exit 1
        fi
        sleep 5
    done
    
    # 等待后端服务就绪
    log_info "等待后端服务启动..."
    for i in {1..60}; do
        if curl -f http://localhost:8081/actuator/health 2>/dev/null; then
            log_success "后端服务已就绪"
            break
        fi
        if [[ $i -eq 60 ]]; then
            log_error "后端服务启动超时"
            exit 1
        fi
        sleep 10
    done
    
    # 等待Nginx就绪
    log_info "等待Nginx启动..."
    for i in {1..20}; do
        if curl -f http://localhost/health 2>/dev/null; then
            log_success "Nginx已就绪"
            break
        fi
        if [[ $i -eq 20 ]]; then
            log_error "Nginx启动超时"
            exit 1
        fi
        sleep 5
    done
}

# 验证部署
verify_deployment() {
    log_info "验证部署状态..."
    
    # 检查容器状态
    log_info "检查容器状态..."
    docker-compose -f docker-compose.public.yml ps
    
    # 测试各个服务
    log_info "测试服务连通性..."
    
    # 测试前端
    if curl -f http://localhost/ >/dev/null 2>&1; then
        log_success "✓ 前端服务正常 (http://localhost/)"
    else
        log_error "✗ 前端服务异常"
    fi
    
    # 测试后端API
    if curl -f http://localhost/api/health >/dev/null 2>&1; then
        log_success "✓ 后端API正常 (http://localhost/api/health)"
    else
        log_warning "✗ 后端API可能异常 (http://localhost/api/health)"
    fi
    
    # 测试健康检查端点
    if curl -f http://localhost:8081/actuator/health >/dev/null 2>&1; then
        log_success "✓ 健康检查端点正常 (http://localhost:8081/actuator/health)"
    else
        log_error "✗ 健康检查端点异常"
    fi
    
    # 测试外网访问
    local_ip=$(hostname -I | awk '{print $1}')
    log_info "本机IP: $local_ip"
    log_info "外网访问地址："
    echo "  - 前端: http://122.51.104.128/"
    echo "  - API: http://122.51.104.128/api/"
    echo "  - 健康检查: http://122.51.104.128:8081/actuator/health"
    echo "  - 管理端点: http://122.51.104.128/actuator/health"
}

# 显示部署信息
show_deployment_info() {
    log_success "=== 部署完成 ==="
    echo
    echo "🎉 八卦运势AI已成功部署到公网！"
    echo
    echo "📋 服务信息："
    echo "  - 前端地址: http://122.51.104.128/"
    echo "  - API地址: http://122.51.104.128/api/"
    echo "  - 健康检查: http://122.51.104.128:8081/actuator/health"
    echo "  - 管理端点: http://122.51.104.128/actuator/"
    echo
    echo "🔧 管理命令："
    echo "  - 查看日志: docker-compose -f docker-compose.public.yml logs -f"
    echo "  - 停止服务: docker-compose -f docker-compose.public.yml down"
    echo "  - 重启服务: docker-compose -f docker-compose.public.yml restart"
    echo "  - 查看状态: docker-compose -f docker-compose.public.yml ps"
    echo
    echo "📁 重要目录："
    echo "  - 应用日志: ./logs/"
    echo "  - 上传文件: ./uploads/"
    echo "  - Nginx日志: ./logs/nginx/"
    echo
    echo "⚠️  注意事项："
    echo "  - 请确保服务器防火墙已开放80和8081端口"
    echo "  - 请根据实际情况修改.env文件中的配置"
    echo "  - 建议定期备份数据库和上传文件"
    echo
}

# 主函数
main() {
    log_info "开始八卦运势AI公网HTTP部署..."
    
    check_environment
    prepare_deployment
    build_frontend
    build_backend
    cleanup_containers
    start_services
    wait_for_services
    verify_deployment
    show_deployment_info
    
    log_success "部署完成！"
}

# 执行主函数
main "$@" 
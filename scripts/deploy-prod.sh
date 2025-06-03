#!/bin/bash

# AI八卦运势小程序 - 生产环境部署脚本
# 作者：八卦AI团队
# 时间：$(date)

set -e  # 遇到错误立即退出

# 颜色定义
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

# 检查必需的环境变量
check_env_vars() {
    log_info "检查必需的环境变量..."
    
    required_vars=(
        "MYSQL_PASSWORD"
        "MYSQL_ROOT_PASSWORD"
        "REDIS_PASSWORD"
        "JWT_SECRET"
        "DEEPSEEK_API_KEY"
        "WECHAT_APP_ID"
        "WECHAT_APP_SECRET"
    )
    
    missing_vars=()
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "缺少必需的环境变量："
        for var in "${missing_vars[@]}"; do
            echo "  - $var"
        done
        echo ""
        echo "请在.env.prod文件中设置这些变量，或通过export命令设置"
        echo "示例：export MYSQL_PASSWORD='your_secure_password'"
        exit 1
    fi
    
    log_success "环境变量检查通过"
}

# 检查Docker和Docker Compose
check_docker() {
    log_info "检查Docker环境..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装，请先安装Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose未安装，请先安装Docker Compose"
        exit 1
    fi
    
    # 检查Docker是否运行
    if ! docker info &> /dev/null; then
        log_error "Docker服务未运行，请启动Docker服务"
        exit 1
    fi
    
    log_success "Docker环境检查通过"
}

# 创建必要的目录
create_directories() {
    log_info "创建必要的目录..."
    
    directories=(
        "logs"
        "uploads"
        "mysql/conf.d"
        "mysql/logs"
        "redis/logs"
        "nginx/ssl"
        "nginx/logs"
        "static"
    )
    
    for dir in "${directories[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_info "创建目录: $dir"
        fi
    done
    
    # 设置目录权限
    chmod 755 logs uploads mysql/logs redis/logs nginx/logs static
    
    log_success "目录创建完成"
}

# 生成SSL证书（自签名，生产环境建议使用真实证书）
generate_ssl_cert() {
    log_info "检查SSL证书..."
    
    if [[ ! -f "nginx/ssl/server.crt" ]] || [[ ! -f "nginx/ssl/server.key" ]]; then
        log_warning "SSL证书不存在，生成自签名证书..."
        
        openssl req -x509 -newkey rsa:4096 -keyout nginx/ssl/server.key -out nginx/ssl/server.crt -days 365 -nodes \
            -subj "/C=CN/ST=Beijing/L=Beijing/O=Fortune AI/OU=IT Department/CN=fortune-ai.com"
        
        chmod 600 nginx/ssl/server.key
        chmod 644 nginx/ssl/server.crt
        
        log_warning "已生成自签名SSL证书，生产环境请使用真实证书"
    else
        log_success "SSL证书已存在"
    fi
}

# 构建应用
build_application() {
    log_info "构建Spring Boot应用..."
    
    cd backend
    
    # 清理并打包
    if ./mvnw clean package -DskipTests -Pprod; then
        log_success "应用构建成功"
    else
        log_error "应用构建失败"
        exit 1
    fi
    
    cd ..
}

# 停止现有服务
stop_existing_services() {
    log_info "停止现有服务..."
    
    if docker-compose -f docker-compose.prod.yml ps -q 2>/dev/null | grep -q .; then
        docker-compose -f docker-compose.prod.yml down
        log_success "已停止现有服务"
    else
        log_info "没有运行中的服务"
    fi
}

# 启动服务
start_services() {
    log_info "启动生产环境服务..."
    
    # 拉取最新镜像
    docker-compose -f docker-compose.prod.yml pull
    
    # 启动服务
    if docker-compose -f docker-compose.prod.yml up -d; then
        log_success "服务启动成功"
    else
        log_error "服务启动失败"
        exit 1
    fi
}

# 等待服务启动
wait_for_services() {
    log_info "等待服务启动..."
    
    # 等待MySQL启动
    log_info "等待MySQL启动..."
    max_attempts=30
    attempt=0
    while [[ $attempt -lt $max_attempts ]]; do
        if docker-compose -f docker-compose.prod.yml exec -T mysql-prod mysqladmin ping -h localhost -uroot -p"$MYSQL_ROOT_PASSWORD" 2>/dev/null; then
            log_success "MySQL已启动"
            break
        fi
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done
    
    if [[ $attempt -eq $max_attempts ]]; then
        log_error "MySQL启动超时"
        exit 1
    fi
    
    # 等待Redis启动
    log_info "等待Redis启动..."
    attempt=0
    while [[ $attempt -lt $max_attempts ]]; do
        if docker-compose -f docker-compose.prod.yml exec -T redis-prod redis-cli -a "$REDIS_PASSWORD" ping 2>/dev/null | grep -q "PONG"; then
            log_success "Redis已启动"
            break
        fi
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done
    
    if [[ $attempt -eq $max_attempts ]]; then
        log_error "Redis启动超时"
        exit 1
    fi
    
    # 等待应用启动
    log_info "等待应用启动..."
    attempt=0
    max_attempts=60  # 应用启动需要更长时间
    while [[ $attempt -lt $max_attempts ]]; do
        if curl -f -s http://localhost:8080/api/actuator/health >/dev/null 2>&1; then
            log_success "应用已启动"
            break
        fi
        attempt=$((attempt + 1))
        echo -n "."
        sleep 5
    done
    
    if [[ $attempt -eq $max_attempts ]]; then
        log_error "应用启动超时"
        exit 1
    fi
}

# 验证部署
verify_deployment() {
    log_info "验证部署..."
    
    # 检查健康状态
    health_status=$(curl -s http://localhost:8080/api/actuator/health | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    if [[ "$health_status" == "UP" ]]; then
        log_success "应用健康检查通过"
    else
        log_error "应用健康检查失败"
        exit 1
    fi
    
    # 检查Nginx
    if curl -f -s http://localhost/health >/dev/null 2>&1; then
        log_success "Nginx健康检查通过"
    else
        log_error "Nginx健康检查失败"
        exit 1
    fi
    
    # 显示服务状态
    echo ""
    log_info "服务状态："
    docker-compose -f docker-compose.prod.yml ps
    
    echo ""
    log_success "🎉 生产环境部署成功！"
    echo ""
    echo "访问地址："
    echo "  - 主页: http://localhost"
    echo "  - API健康检查: http://localhost:8080/api/actuator/health"
    echo "  - Nginx状态: http://localhost/health"
    echo ""
    echo "管理命令："
    echo "  - 查看日志: docker-compose -f docker-compose.prod.yml logs -f [service_name]"
    echo "  - 停止服务: docker-compose -f docker-compose.prod.yml down"
    echo "  - 重启服务: docker-compose -f docker-compose.prod.yml restart [service_name]"
}

# 主函数
main() {
    echo "=========================================="
    echo "   AI八卦运势小程序 - 生产环境部署"
    echo "=========================================="
    echo ""
    
    check_docker
    check_env_vars
    create_directories
    generate_ssl_cert
    build_application
    stop_existing_services
    start_services
    wait_for_services
    verify_deployment
    
    log_success "部署完成！🚀"
}

# 错误处理
trap 'log_error "部署过程中发生错误，请检查日志"; exit 1' ERR

# 执行主函数
main "$@" 
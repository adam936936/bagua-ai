#!/bin/bash

# 八卦AI后端生产构建脚本
# 作者: AI助手
# 日期: 2025-01-17
# 用途: 构建后端Docker镜像用于生产环境

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

# 检查是否在项目根目录
if [ ! -f "pom.xml" ] && [ ! -d "backend" ]; then
    log_error "请在项目根目录运行此脚本"
    exit 1
fi

# 获取项目根目录
PROJECT_ROOT=$(pwd)
BACKEND_DIR="$PROJECT_ROOT/backend"

log_info "开始构建八卦AI后端生产镜像..."
log_info "项目根目录: $PROJECT_ROOT"
log_info "后端目录: $BACKEND_DIR"

# 检查backend目录
if [ ! -d "$BACKEND_DIR" ]; then
    log_error "backend目录不存在: $BACKEND_DIR"
    exit 1
fi

# 进入backend目录
cd "$BACKEND_DIR"

# 检查必要文件
if [ ! -f "pom.xml" ]; then
    log_error "pom.xml文件不存在"
    exit 1
fi

if [ ! -f "Dockerfile" ]; then
    log_error "Dockerfile文件不存在"
    exit 1
fi

# 清理旧的构建文件
log_info "清理旧的构建文件..."
if [ -d "target" ]; then
    rm -rf target
    log_success "已清理target目录"
fi

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    log_error "Docker未运行，请先启动Docker"
    exit 1
fi

# 构建Docker镜像（使用多阶段构建）
log_info "开始构建Docker镜像..."
log_info "使用多阶段构建，这可能需要几分钟时间..."

if docker build -t bagua-backend:prod -t bagua-backend:latest .; then
    log_success "Docker镜像构建成功"
else
    log_error "Docker镜像构建失败"
    exit 1
fi

# 检查镜像是否创建成功
if docker images | grep -q "bagua-backend"; then
    log_success "镜像创建成功"
    docker images | grep bagua-backend
else
    log_error "镜像创建失败"
    exit 1
fi

# 测试镜像
log_info "测试镜像是否可以正常启动..."
CONTAINER_ID=$(docker run -d --name bagua-backend-test -p 8082:8080 bagua-backend:prod)

if [ $? -eq 0 ]; then
    log_info "容器启动成功，等待应用启动..."
    sleep 10
    
    # 检查容器状态
    if docker ps | grep -q "bagua-backend-test"; then
        log_success "容器运行正常"
        
        # 尝试健康检查
        if docker exec bagua-backend-test curl -f http://localhost:8080/api/actuator/health > /dev/null 2>&1; then
            log_success "应用健康检查通过"
        else
            log_warning "应用可能还在启动中，请稍后手动检查"
        fi
    else
        log_error "容器启动失败"
        docker logs bagua-backend-test
    fi
    
    # 清理测试容器
    log_info "清理测试容器..."
    docker stop bagua-backend-test > /dev/null 2>&1
    docker rm bagua-backend-test > /dev/null 2>&1
else
    log_error "容器启动失败"
    exit 1
fi

# 显示镜像信息
log_info "构建完成的镜像信息:"
docker images | grep bagua-backend

# 显示使用说明
log_success "🎉 后端镜像构建完成！"
echo ""
echo "使用方法:"
echo "1. 开发环境启动:"
echo "   docker run -d --name bagua-backend -p 8081:8080 bagua-backend:prod"
echo ""
echo "2. 生产环境部署:"
echo "   docker-compose -f docker-compose.prod.2025.yml up -d"
echo ""
echo "3. 健康检查:"
echo "   curl http://localhost:8081/api/actuator/health"
echo ""

log_success "构建脚本执行完成！" 
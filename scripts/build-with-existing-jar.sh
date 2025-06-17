#!/bin/bash

# 八卦AI后端构建脚本 - 使用现有JAR文件
# 作者: AI助手
# 日期: 2025-01-17
# 用途: 基于已构建的JAR文件创建Docker镜像

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

# 获取项目根目录
PROJECT_ROOT=$(pwd)
BACKEND_DIR="$PROJECT_ROOT/backend"

log_info "🚀 开始构建八卦AI后端镜像..."
log_info "项目根目录: $PROJECT_ROOT"
log_info "后端目录: $BACKEND_DIR"

# 检查backend目录
if [ ! -d "$BACKEND_DIR" ]; then
    log_error "backend目录不存在: $BACKEND_DIR"
    exit 1
fi

# 进入backend目录
cd "$BACKEND_DIR"

# 检查JAR文件是否存在
if [ ! -f "target/fortune-mini-app-1.0.0.jar" ]; then
    log_warning "JAR文件不存在，开始Maven构建..."
    
    # 检查是否有Maven
    if ! command -v mvn &> /dev/null; then
        log_error "Maven未安装，请先安装Maven或使用Docker构建"
        exit 1
    fi
    
    # Maven构建
    log_info "执行Maven构建..."
    mvn clean package -DskipTests
    
    if [ $? -eq 0 ]; then
        log_success "Maven构建完成"
    else
        log_error "Maven构建失败"
        exit 1
    fi
else
    log_success "发现已存在的JAR文件: target/fortune-mini-app-1.0.0.jar"
fi

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    log_error "Docker未运行，请先启动Docker"
    exit 1
fi

# 选择Dockerfile
DOCKERFILE="Dockerfile.simple"
if [ ! -f "$DOCKERFILE" ]; then
    log_warning "$DOCKERFILE 不存在，使用默认Dockerfile"
    DOCKERFILE="Dockerfile"
fi

# 构建Docker镜像
log_info "开始构建Docker镜像..."
log_info "使用Dockerfile: $DOCKERFILE"

if docker build -f "$DOCKERFILE" -t bagua-backend:prod -t bagua-backend:latest .; then
    log_success "Docker镜像构建成功"
else
    log_error "Docker镜像构建失败"
    
    # 显示详细错误信息
    log_info "尝试显示构建日志..."
    docker build -f "$DOCKERFILE" -t bagua-backend:debug . || true
    exit 1
fi

# 检查镜像
log_info "检查构建的镜像..."
docker images | grep bagua-backend

# 快速测试镜像
log_info "快速测试镜像..."
TEST_CONTAINER="bagua-backend-test-$$"

if docker run -d --name "$TEST_CONTAINER" -p 8082:8080 bagua-backend:prod; then
    log_info "容器启动成功，等待应用启动..."
    sleep 15
    
    # 检查容器状态
    if docker ps | grep -q "$TEST_CONTAINER"; then
        log_success "容器运行正常"
        
        # 检查应用日志
        log_info "应用启动日志:"
        docker logs "$TEST_CONTAINER" | tail -10
        
        # 尝试健康检查
        if docker exec "$TEST_CONTAINER" curl -f http://localhost:8080/api/actuator/health > /dev/null 2>&1; then
            log_success "✅ 应用健康检查通过"
        else
            log_warning "⚠️ 健康检查失败，应用可能还在启动中"
        fi
    else
        log_error "容器启动失败"
        docker logs "$TEST_CONTAINER"
    fi
    
    # 清理测试容器
    log_info "清理测试容器..."
    docker stop "$TEST_CONTAINER" > /dev/null 2>&1 || true
    docker rm "$TEST_CONTAINER" > /dev/null 2>&1 || true
else
    log_error "容器启动失败"
    exit 1
fi

# 显示最终结果
log_success "🎉 后端镜像构建完成！"
echo ""
echo "📋 镜像信息:"
docker images | grep bagua-backend | head -3
echo ""
echo "🚀 使用方法:"
echo "1. 直接运行:"
echo "   docker run -d --name bagua-backend -p 8081:8080 bagua-backend:prod"
echo ""
echo "2. 使用docker-compose:"
echo "   docker-compose up -d backend"
echo ""
echo "3. 健康检查:"
echo "   curl http://localhost:8081/api/actuator/health"
echo ""

log_success "✨ 构建脚本执行完成！" 
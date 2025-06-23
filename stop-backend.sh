#!/bin/bash

# 停止后端服务脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

log_info "🛑 停止后端服务..."

# 停止JAR进程
if [ -f "backend.pid" ]; then
    PID=$(cat backend.pid)
    if kill -0 $PID 2>/dev/null; then
        log_info "停止后端进程 (PID: $PID)..."
        kill $PID
        
        # 等待进程停止
        for i in {1..10}; do
            if ! kill -0 $PID 2>/dev/null; then
                log_success "后端进程已停止"
                break
            fi
            if [ $i -eq 10 ]; then
                log_warning "强制停止进程..."
                kill -9 $PID 2>/dev/null || true
            fi
            sleep 1
        done
    else
        log_warning "后端进程不存在 (PID: $PID)"
    fi
    rm -f backend.pid
else
    log_warning "未找到PID文件"
fi

# 停止Docker容器中的后端服务
if docker ps | grep -q "bagua-backend-public"; then
    log_info "停止Docker后端容器..."
    docker stop bagua-backend-public > /dev/null 2>&1 || true
    docker rm bagua-backend-public > /dev/null 2>&1 || true
    log_success "Docker后端容器已停止"
fi

# 检查端口是否还被占用
if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1; then
    log_warning "端口8080仍被占用，尝试强制停止..."
    PIDS=$(lsof -Pi :8080 -sTCP:LISTEN -t)
    for pid in $PIDS; do
        log_info "强制停止进程 $pid"
        kill -9 $pid 2>/dev/null || true
    done
fi

log_success "✅ 后端服务已停止" 
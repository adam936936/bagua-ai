#!/bin/bash

echo "=== 停止所有服务 ==="

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 停止后端
if [ -f "logs/backend.pid" ]; then
    BACKEND_PID=$(cat logs/backend.pid)
    if kill -0 $BACKEND_PID 2>/dev/null; then
        echo -e "${YELLOW}正在停止后端服务 (PID: $BACKEND_PID)...${NC}"
        kill $BACKEND_PID
        sleep 2
        if kill -0 $BACKEND_PID 2>/dev/null; then
            echo "强制停止后端服务..."
            kill -9 $BACKEND_PID
        fi
        echo -e "${GREEN}✅ 后端服务已停止${NC}"
    else
        echo "后端服务未运行"
    fi
    rm -f logs/backend.pid
fi

# 停止前端
if [ -f "logs/frontend.pid" ]; then
    FRONTEND_PID=$(cat logs/frontend.pid)
    if kill -0 $FRONTEND_PID 2>/dev/null; then
        echo -e "${YELLOW}正在停止前端服务 (PID: $FRONTEND_PID)...${NC}"
        kill $FRONTEND_PID
        echo -e "${GREEN}✅ 前端服务已停止${NC}"
    else
        echo "前端服务未运行"
    fi
    rm -f logs/frontend.pid
fi

# 清理端口
echo -e "${YELLOW}清理端口占用...${NC}"
PORT_8080=$(lsof -ti:8080 2>/dev/null)
if [ ! -z "$PORT_8080" ]; then
    echo "强制杀死8080端口进程: $PORT_8080"
    lsof -ti:8080 | xargs kill -9 2>/dev/null
fi

PORT_3000=$(lsof -ti:3000 2>/dev/null)
if [ ! -z "$PORT_3000" ]; then
    echo "强制杀死3000端口进程: $PORT_3000"
    lsof -ti:3000 | xargs kill -9 2>/dev/null
fi

echo -e "${GREEN}✅ 所有服务已停止${NC}" 
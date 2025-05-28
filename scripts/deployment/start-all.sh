#!/bin/bash

echo "🚀 启动AI八卦运势小程序完整服务"
echo "=================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}正在启动完整的AI八卦运势小程序服务...${NC}"
echo ""

# 检查脚本权限
if [ ! -x "start-backend.sh" ]; then
    chmod +x start-backend.sh
fi

if [ ! -x "start-frontend.sh" ]; then
    chmod +x start-frontend.sh
fi

# 启动后端服务（后台运行）
echo -e "${BLUE}1. 启动后端服务${NC}"
echo -e "${YELLOW}后端服务将在后台运行...${NC}"
./start-backend.sh &
BACKEND_PID=$!

# 等待后端启动
echo -e "${YELLOW}等待后端服务启动...${NC}"
sleep 10

# 检查后端是否启动成功
if curl -s http://localhost:8080/actuator/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 后端服务启动成功 (PID: $BACKEND_PID)${NC}"
else
    echo -e "${YELLOW}⚠️  后端服务可能还在启动中...${NC}"
fi

echo ""

# 启动前端服务
echo -e "${BLUE}2. 启动前端服务 (微信小程序版本)${NC}"
echo -e "${GREEN}前端服务将在前台运行...${NC}"
echo ""

# 设置清理函数
cleanup() {
    echo ""
    echo -e "${YELLOW}正在停止服务...${NC}"
    if [ ! -z "$BACKEND_PID" ]; then
        kill $BACKEND_PID 2>/dev/null
        echo -e "${GREEN}✅ 后端服务已停止${NC}"
    fi
    
    # 杀死所有相关进程
    pkill -f "mvn spring-boot:run" 2>/dev/null
    pkill -f "npm run dev:mp-weixin" 2>/dev/null
    
    echo -e "${GREEN}✅ 所有服务已停止${NC}"
    exit 0
}

# 设置信号处理
trap cleanup SIGINT SIGTERM

# 启动前端
./start-frontend.sh

# 如果前端退出，清理后端
cleanup 
#!/bin/bash

echo "=== 后端快速重启 ==="

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 强制杀死8080端口进程
echo -e "${YELLOW}正在停止后端服务...${NC}"
PORT_8080=$(lsof -ti:8080 2>/dev/null)
if [ ! -z "$PORT_8080" ]; then
    echo "发现占用进程ID: $PORT_8080"
    lsof -ti:8080 | xargs kill -9 2>/dev/null
    sleep 3
    
    # 确认端口已释放
    if [ -z "$(lsof -ti:8080 2>/dev/null)" ]; then
        echo -e "${GREEN}✅ 后端服务已停止${NC}"
    else
        echo -e "${YELLOW}⚠️  端口可能仍被占用，继续启动...${NC}"
    fi
else
    echo -e "${GREEN}✅ 端口8080未被占用${NC}"
fi

# 检查当前目录
if [ ! -f "backend/pom.xml" ]; then
    echo -e "${RED}❌ 请在项目根目录执行此脚本${NC}"
    exit 1
fi

# 重新启动
echo -e "${YELLOW}正在重新启动后端服务...${NC}"
cd backend && mvn spring-boot:run 
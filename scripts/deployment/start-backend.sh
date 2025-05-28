#!/bin/bash

echo "🚀 启动AI八卦运势小程序后端服务"
echo "=================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查并杀死占用8080端口的进程
echo -e "${BLUE}1. 检查8080端口占用情况${NC}"
PORT_PIDS=$(lsof -ti:8080)

if [ -n "$PORT_PIDS" ]; then
    echo -e "${YELLOW}⚠️  发现8080端口被占用，进程ID: $PORT_PIDS${NC}"
    echo -e "${YELLOW}正在杀死占用进程...${NC}"
    kill -9 $PORT_PIDS
    sleep 2
    echo -e "${GREEN}✅ 端口清理完成${NC}"
else
    echo -e "${GREEN}✅ 8080端口空闲${NC}"
fi

# 检查环境变量
echo -e "${BLUE}2. 检查环境变量配置${NC}"
if [ -z "$DEEPSEEK_API_KEY" ]; then
    echo -e "${RED}❌ DEEPSEEK_API_KEY 环境变量未设置${NC}"
    echo -e "${YELLOW}正在设置默认API密钥...${NC}"
    export DEEPSEEK_API_KEY="sk-161f80e197f64439a4a9f0b4e9e30c40"
    echo -e "${GREEN}✅ API密钥已设置${NC}"
else
    echo -e "${GREEN}✅ DEEPSEEK_API_KEY 已配置${NC}"
fi

# 进入后端目录
echo -e "${BLUE}3. 进入后端目录${NC}"
cd backend

# 检查Maven是否可用
if ! command -v mvn &> /dev/null; then
    echo -e "${RED}❌ Maven未安装或不在PATH中${NC}"
    exit 1
fi

# 清理并编译
echo -e "${BLUE}4. 清理并编译项目${NC}"
mvn clean compile -q

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 项目编译失败${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 项目编译成功${NC}"

# 启动Spring Boot应用
echo -e "${BLUE}5. 启动Spring Boot应用${NC}"
echo -e "${GREEN}🌟 后端服务启动中...${NC}"
echo -e "${GREEN}📍 服务地址: http://localhost:8080${NC}"
echo -e "${GREEN}📍 API文档: http://localhost:8080/swagger-ui.html${NC}"
echo -e "${YELLOW}💡 按 Ctrl+C 停止服务${NC}"
echo ""

# 启动应用
mvn spring-boot:run 
#!/bin/bash

echo "📱 启动AI八卦运势小程序前端服务 (微信小程序版本)"
echo "=================================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查Node.js和npm
echo -e "${BLUE}1. 检查开发环境${NC}"
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js未安装${NC}"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ npm未安装${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Node.js版本: $(node --version)${NC}"
echo -e "${GREEN}✅ npm版本: $(npm --version)${NC}"

# 进入前端目录
echo -e "${BLUE}2. 进入前端目录${NC}"
cd frontend

# 检查依赖
echo -e "${BLUE}3. 检查项目依赖${NC}"
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}⚠️  node_modules不存在，正在安装依赖...${NC}"
    npm install
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ 依赖安装失败${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ 依赖安装完成${NC}"
else
    echo -e "${GREEN}✅ 依赖已存在${NC}"
fi

# 清理之前的构建
echo -e "${BLUE}4. 清理之前的构建${NC}"
if [ -d "dist" ]; then
    rm -rf dist
    echo -e "${GREEN}✅ 清理完成${NC}"
fi

# 启动微信小程序开发服务
echo -e "${BLUE}5. 启动微信小程序开发服务${NC}"
echo -e "${GREEN}🌟 微信小程序版本启动中...${NC}"
echo -e "${GREEN}📍 构建目录: dist/dev/mp-weixin${NC}"
echo -e "${GREEN}📍 请在微信开发者工具中导入 dist/dev/mp-weixin 目录${NC}"
echo -e "${YELLOW}💡 按 Ctrl+C 停止服务${NC}"
echo ""

# 启动微信小程序版本
npm run dev:mp-weixin 
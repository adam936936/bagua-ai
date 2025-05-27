#!/bin/bash

echo "=== AI八卦运势小程序前端启动 ==="

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查当前目录
if [ ! -f "frontend/package.json" ]; then
    echo -e "${RED}❌ 请在项目根目录执行此脚本${NC}"
    exit 1
fi

# 步骤1: 检查Node.js环境
echo -e "${YELLOW}步骤1: 检查Node.js环境${NC}"
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js未安装或未配置到PATH${NC}"
    exit 1
fi

NODE_VERSION=$(node -v)
echo -e "${GREEN}✅ Node.js版本: $NODE_VERSION${NC}"

# 步骤2: 检查npm环境
echo -e "${YELLOW}步骤2: 检查npm环境${NC}"
if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ npm未安装${NC}"
    exit 1
fi

NPM_VERSION=$(npm -v)
echo -e "${GREEN}✅ npm版本: $NPM_VERSION${NC}"

# 步骤3: 进入frontend目录
echo -e "${YELLOW}步骤3: 进入前端目录${NC}"
cd frontend

# 步骤4: 检查依赖
echo -e "${YELLOW}步骤4: 检查依赖${NC}"
if [ ! -d "node_modules" ]; then
    echo "node_modules不存在，正在安装依赖..."
    npm install
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ 依赖安装失败${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ 依赖已存在${NC}"
fi

# 步骤5: 启动开发服务器
echo -e "${YELLOW}步骤5: 启动微信小程序开发模式${NC}"
echo "正在启动前端开发服务器..."
echo "命令: npm run dev:mp-weixin"
echo ""

# 启动前端
npm run dev:mp-weixin

# 检查启动结果
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 前端启动成功${NC}"
    echo "请打开微信开发者工具，导入 dist/dev/mp-weixin 目录"
else
    echo -e "${RED}❌ 前端启动失败，请检查错误信息${NC}"
    exit 1
fi 
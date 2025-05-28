#!/bin/bash
# 微信小程序配置检查脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 微信小程序配置检查${NC}"
echo "================================================"

# 检查清单
checks_passed=0
total_checks=8

# 1. 检查Node.js
echo -n "1. Node.js 环境: "
if command -v node &> /dev/null; then
    echo -e "${GREEN}✅ $(node --version)${NC}"
    ((checks_passed++))
else
    echo -e "${RED}❌ 未安装${NC}"
fi

# 2. 检查npm
echo -n "2. npm 环境: "
if command -v npm &> /dev/null; then
    echo -e "${GREEN}✅ $(npm --version)${NC}"
    ((checks_passed++))
else
    echo -e "${RED}❌ 未安装${NC}"
fi

# 3. 检查前端目录
echo -n "3. 前端项目: "
if [ -d "frontend" ] && [ -f "frontend/package.json" ]; then
    echo -e "${GREEN}✅ 存在${NC}"
    ((checks_passed++))
else
    echo -e "${RED}❌ 不存在${NC}"
fi

# 4. 检查依赖安装
echo -n "4. 前端依赖: "
if [ -d "frontend/node_modules" ]; then
    echo -e "${GREEN}✅ 已安装${NC}"
    ((checks_passed++))
else
    echo -e "${YELLOW}⚠️  未安装${NC}"
fi

# 5. 检查manifest.json
echo -n "5. 小程序配置: "
if [ -f "frontend/src/manifest.json" ]; then
    echo -e "${GREEN}✅ 存在${NC}"
    ((checks_passed++))
else
    echo -e "${RED}❌ 不存在${NC}"
fi

# 6. 检查AppID配置
echo -n "6. AppID 配置: "
if [ -f "frontend/src/manifest.json" ]; then
    if grep -q "请填入您的微信小程序AppID" frontend/src/manifest.json; then
        echo -e "${YELLOW}⚠️  未配置${NC}"
    else
        echo -e "${GREEN}✅ 已配置${NC}"
        ((checks_passed++))
    fi
else
    echo -e "${RED}❌ 配置文件不存在${NC}"
fi

# 7. 检查后端服务
echo -n "7. 后端服务: "
if curl -s http://localhost:8081/actuator/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 运行中 (8081)${NC}"
    ((checks_passed++))
elif curl -s http://localhost:8080/actuator/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 运行中 (8080)${NC}"
    ((checks_passed++))
else
    echo -e "${RED}❌ 未运行${NC}"
fi

# 8. 检查构建产物
echo -n "8. 构建产物: "
if [ -d "frontend/dist/dev/mp-weixin" ]; then
    echo -e "${GREEN}✅ 存在${NC}"
    ((checks_passed++))
else
    echo -e "${YELLOW}⚠️  未构建${NC}"
fi

echo ""
echo "================================================"
echo -e "${BLUE}📊 检查结果: ${checks_passed}/${total_checks} 项通过${NC}"

if [ $checks_passed -eq $total_checks ]; then
    echo -e "${GREEN}🎉 所有检查通过！可以开始开发调试${NC}"
    echo ""
    echo -e "${BLUE}📱 下一步：${NC}"
    echo "1. 打开微信开发者工具"
    echo "2. 导入项目: frontend/dist/dev/mp-weixin"
    echo "3. 开始调试"
elif [ $checks_passed -ge 6 ]; then
    echo -e "${YELLOW}⚠️  基本配置完成，但有些项目需要注意${NC}"
    echo ""
    echo -e "${BLUE}🔧 建议操作：${NC}"
    if [ ! -d "frontend/node_modules" ]; then
        echo "• 安装前端依赖: cd frontend && npm install"
    fi
    if grep -q "请填入您的微信小程序AppID" frontend/src/manifest.json 2>/dev/null; then
        echo "• 配置AppID: 编辑 frontend/src/manifest.json"
    fi
    if ! curl -s http://localhost:8081/actuator/health > /dev/null 2>&1 && ! curl -s http://localhost:8080/actuator/health > /dev/null 2>&1; then
        echo "• 启动后端服务: ./start.sh prod"
    fi
    if [ ! -d "frontend/dist/dev/mp-weixin" ]; then
        echo "• 构建小程序: cd frontend && npm run dev:mp-weixin"
    fi
else
    echo -e "${RED}❌ 配置不完整，需要先完成基础配置${NC}"
    echo ""
    echo -e "${BLUE}🔧 必需操作：${NC}"
    if ! command -v node &> /dev/null; then
        echo "• 安装Node.js: https://nodejs.org/"
    fi
    if [ ! -d "frontend" ]; then
        echo "• 检查项目结构"
    fi
    if [ ! -f "frontend/src/manifest.json" ]; then
        echo "• 创建小程序配置文件"
    fi
fi

echo ""
echo -e "${BLUE}📚 参考文档：${NC}"
echo "• 完整指南: docs/wechat-miniprogram-deployment-guide.md"
echo "• 快速启动: ./start-miniprogram-dev.sh" 
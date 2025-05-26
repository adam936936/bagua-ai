#!/bin/bash
# 微信小程序开发环境启动脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔮 微信小程序开发环境启动脚本${NC}"
echo "================================================"

# 检查Node.js环境
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js 未安装，请先安装 Node.js${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Node.js 版本: $(node --version)${NC}"

# 检查npm环境
if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ npm 未安装${NC}"
    exit 1
fi

echo -e "${GREEN}✅ npm 版本: $(npm --version)${NC}"

# 检查前端目录
if [ ! -d "frontend" ]; then
    echo -e "${RED}❌ frontend 目录不存在${NC}"
    exit 1
fi

# 进入前端目录
cd frontend

# 检查package.json
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ package.json 不存在${NC}"
    exit 1
fi

# 安装依赖
echo -e "${YELLOW}📦 检查并安装依赖...${NC}"
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}📦 首次安装依赖，可能需要几分钟...${NC}"
    npm install
else
    echo -e "${GREEN}✅ 依赖已安装${NC}"
fi

# 检查manifest.json配置
echo -e "${YELLOW}🔧 检查小程序配置...${NC}"
if [ ! -f "src/manifest.json" ]; then
    echo -e "${RED}❌ src/manifest.json 不存在，请先配置小程序信息${NC}"
    exit 1
fi

# 检查AppID配置
if grep -q "请填入您的微信小程序AppID" src/manifest.json; then
    echo -e "${YELLOW}⚠️  请先在 src/manifest.json 中配置您的微信小程序AppID${NC}"
    echo -e "${YELLOW}   1. 登录微信公众平台 https://mp.weixin.qq.com/${NC}"
    echo -e "${YELLOW}   2. 获取AppID：开发 → 开发管理 → 开发设置${NC}"
    echo -e "${YELLOW}   3. 替换 src/manifest.json 中的 AppID${NC}"
    echo ""
    read -p "是否已配置AppID？(y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}❌ 请先配置AppID后再运行此脚本${NC}"
        exit 1
    fi
fi

# 启动后端服务检查
echo -e "${YELLOW}🔧 检查后端服务...${NC}"
cd ..

# 检查后端是否运行
if curl -s http://localhost:8081/actuator/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 后端服务已运行 (端口8081)${NC}"
elif curl -s http://localhost:8080/actuator/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 后端服务已运行 (端口8080)${NC}"
else
    echo -e "${YELLOW}⚠️  后端服务未运行，正在启动...${NC}"
    if [ -f "start.sh" ]; then
        ./start.sh prod &
        echo -e "${YELLOW}⏳ 等待后端服务启动...${NC}"
        sleep 10
        
        # 再次检查
        if curl -s http://localhost:8081/actuator/health > /dev/null 2>&1; then
            echo -e "${GREEN}✅ 后端服务启动成功${NC}"
        else
            echo -e "${RED}❌ 后端服务启动失败，请手动检查${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ 找不到后端启动脚本${NC}"
        exit 1
    fi
fi

# 返回前端目录
cd frontend

# 构建小程序
echo -e "${YELLOW}🔨 构建微信小程序...${NC}"
npm run dev:mp-weixin

# 检查构建结果
if [ -d "dist/dev/mp-weixin" ]; then
    echo -e "${GREEN}✅ 小程序构建成功${NC}"
    echo ""
    echo "================================================"
    echo -e "${GREEN}🎉 微信小程序开发环境准备完成！${NC}"
    echo ""
    echo -e "${BLUE}📱 下一步操作：${NC}"
    echo "1. 打开微信开发者工具"
    echo "2. 选择'导入项目'"
    echo "3. 项目目录选择: $(pwd)/dist/dev/mp-weixin"
    echo "4. 填入您的AppID"
    echo "5. 开始调试开发"
    echo ""
    echo -e "${BLUE}🔗 相关地址：${NC}"
    echo "• 项目目录: $(pwd)/dist/dev/mp-weixin"
    echo "• 后端API: http://localhost:8081/api"
    echo "• 健康检查: http://localhost:8081/actuator/health"
    echo ""
    echo -e "${BLUE}📚 参考文档：${NC}"
    echo "• 完整部署指南: docs/wechat-miniprogram-deployment-guide.md"
    echo "• 微信开发者工具: https://developers.weixin.qq.com/miniprogram/dev/devtools/"
    echo ""
    echo -e "${YELLOW}💡 提示：${NC}"
    echo "• 代码修改后会自动重新构建"
    echo "• 如需停止，按 Ctrl+C"
    echo "• 如需重新构建，运行: npm run dev:mp-weixin"
    
    # 监听文件变化（可选）
    echo ""
    read -p "是否启动文件监听模式？(y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}👀 启动文件监听模式...${NC}"
        echo -e "${YELLOW}文件变化时会自动重新构建${NC}"
        echo -e "${YELLOW}按 Ctrl+C 停止监听${NC}"
        npm run dev:mp-weixin -- --watch
    fi
    
else
    echo -e "${RED}❌ 小程序构建失败${NC}"
    echo "请检查构建日志中的错误信息"
    exit 1
fi 
#!/bin/bash

# AI八卦运势小程序一键启动脚本
# 作者: fortune
# 日期: 2024-01-01

set -e

echo "🔮 AI八卦运势小程序启动脚本"
echo "================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查环境变量
check_env() {
    echo -e "${BLUE}📋 检查环境变量...${NC}"
    
    if [ -z "$DEEPSEEK_API_KEY" ]; then
        echo -e "${YELLOW}⚠️  DEEPSEEK_API_KEY 未设置，请设置后重试${NC}"
        echo "export DEEPSEEK_API_KEY=your-api-key"
        exit 1
    fi
    
    if [ -z "$WECHAT_APP_ID" ]; then
        echo -e "${YELLOW}⚠️  WECHAT_APP_ID 未设置，使用默认值${NC}"
        export WECHAT_APP_ID="your-wechat-app-id"
    fi
    
    if [ -z "$WECHAT_APP_SECRET" ]; then
        echo -e "${YELLOW}⚠️  WECHAT_APP_SECRET 未设置，使用默认值${NC}"
        export WECHAT_APP_SECRET="your-wechat-app-secret"
    fi
    
    echo -e "${GREEN}✅ 环境变量检查完成${NC}"
}

# 检查依赖
check_dependencies() {
    echo -e "${BLUE}🔍 检查系统依赖...${NC}"
    
    # 检查Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker 未安装，请先安装 Docker${NC}"
        exit 1
    fi
    
    # 检查Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}❌ Docker Compose 未安装，请先安装 Docker Compose${NC}"
        exit 1
    fi
    
    # 检查Java (用于构建)
    if ! command -v java &> /dev/null; then
        echo -e "${YELLOW}⚠️  Java 未安装，将使用 Docker 构建${NC}"
    fi
    
    # 检查Maven (用于构建)
    if ! command -v mvn &> /dev/null; then
        echo -e "${YELLOW}⚠️  Maven 未安装，将使用 Docker 构建${NC}"
    fi
    
    # 检查Node.js (用于前端构建)
    if ! command -v node &> /dev/null; then
        echo -e "${YELLOW}⚠️  Node.js 未安装，前端需要手动构建${NC}"
    fi
    
    echo -e "${GREEN}✅ 依赖检查完成${NC}"
}

# 构建后端
build_backend() {
    echo -e "${BLUE}🏗️  构建后端项目...${NC}"
    
    cd backend
    
    if command -v mvn &> /dev/null; then
        echo "使用本地 Maven 构建..."
        mvn clean package -DskipTests
    else
        echo "使用 Docker 构建..."
        # 使用阿里云镜像源
        docker run --rm \
            -v "$PWD":/usr/src/app \
            -v ~/.m2:/root/.m2 \
            -w /usr/src/app \
            -e MAVEN_OPTS="-Dmaven.repo.local=/root/.m2/repository" \
            registry.cn-hangzhou.aliyuncs.com/library/maven:3.8.4-openjdk-11 \
            mvn clean package -DskipTests -Dmaven.test.skip=true
    fi
    
    cd ..
    echo -e "${GREEN}✅ 后端构建完成${NC}"
}

# 构建前端
build_frontend() {
    echo -e "${BLUE}🎨 构建前端项目...${NC}"
    
    cd frontend
    
    if command -v npm &> /dev/null; then
        echo "安装依赖..."
        npm install
        
        echo "构建项目..."
        npm run build:h5
    else
        echo -e "${YELLOW}⚠️  Node.js 未安装，跳过前端构建${NC}"
        echo "请手动执行: cd frontend && npm install && npm run build:h5"
    fi
    
    cd ..
    echo -e "${GREEN}✅ 前端构建完成${NC}"
}

# 启动服务
start_services() {
    echo -e "${BLUE}🚀 启动服务...${NC}"
    
    # 停止已存在的容器
    docker-compose down
    
    # 启动所有服务
    docker-compose up -d
    
    echo -e "${GREEN}✅ 服务启动完成${NC}"
}

# 等待服务就绪
wait_for_services() {
    echo -e "${BLUE}⏳ 等待服务就绪...${NC}"
    
    # 等待MySQL就绪
    echo "等待 MySQL 启动..."
    until docker-compose exec mysql mysqladmin ping -h"localhost" --silent; do
        sleep 2
    done
    
    # 等待Redis就绪
    echo "等待 Redis 启动..."
    until docker-compose exec redis redis-cli ping; do
        sleep 2
    done
    
    # 等待后端就绪
    echo "等待后端服务启动..."
    until curl -f http://localhost:8080/api/actuator/health &> /dev/null; do
        sleep 5
    done
    
    echo -e "${GREEN}✅ 所有服务已就绪${NC}"
}

# 显示服务状态
show_status() {
    echo -e "${BLUE}📊 服务状态${NC}"
    echo "================================"
    
    docker-compose ps
    
    echo ""
    echo -e "${GREEN}🎉 启动完成！${NC}"
    echo "================================"
    echo "📱 前端地址: http://localhost"
    echo "🔧 后端API: http://localhost:8080/api"
    echo "📚 API文档: http://localhost:8080/api/swagger-ui.html"
    echo "💾 数据库: localhost:3306 (用户名: fortune, 密码: fortune123456)"
    echo "🗄️  Redis: localhost:6379"
    echo ""
    echo "📋 常用命令:"
    echo "  查看日志: docker-compose logs -f [service_name]"
    echo "  停止服务: docker-compose down"
    echo "  重启服务: docker-compose restart [service_name]"
    echo ""
    echo -e "${YELLOW}💡 提示: 首次启动可能需要几分钟时间下载镜像和初始化数据库${NC}"
}

# 主函数
main() {
    echo "开始启动 AI八卦运势小程序..."
    echo ""
    
    check_env
    check_dependencies
    build_backend
    build_frontend
    start_services
    wait_for_services
    show_status
    
    echo ""
    echo -e "${GREEN}🎊 恭喜！AI八卦运势小程序已成功启动！${NC}"
}

# 错误处理
trap 'echo -e "${RED}❌ 启动过程中发生错误${NC}"; exit 1' ERR

# 执行主函数
main "$@" 
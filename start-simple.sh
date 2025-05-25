#!/bin/bash

# AI八卦运势小程序简化启动脚本
# 作者: fortune
# 日期: 2024-01-01

set -e

echo "🔮 AI八卦运势小程序简化启动脚本"
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
        echo -e "${YELLOW}⚠️  DEEPSEEK_API_KEY 未设置，使用默认值${NC}"
        export DEEPSEEK_API_KEY="your-deepseek-api-key"
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
    
    echo -e "${GREEN}✅ 依赖检查完成${NC}"
}

# 启动基础服务（MySQL + Redis）
start_infrastructure() {
    echo -e "${BLUE}🚀 启动基础服务...${NC}"
    
    # 停止已存在的容器
    docker-compose down
    
    # 只启动MySQL和Redis
    docker-compose up -d mysql redis
    
    echo -e "${GREEN}✅ 基础服务启动完成${NC}"
}

# 等待基础服务就绪
wait_for_infrastructure() {
    echo -e "${BLUE}⏳ 等待基础服务就绪...${NC}"
    
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
    
    echo -e "${GREEN}✅ 基础服务已就绪${NC}"
}

# 构建并启动后端（本地方式）
start_backend() {
    echo -e "${BLUE}🏗️  启动后端服务...${NC}"
    
    cd backend
    
    # 检查是否有Maven
    if command -v mvn &> /dev/null; then
        echo "使用本地 Maven 构建并启动..."
        mvn clean package -DskipTests
        
        # 设置环境变量并启动
        export SPRING_DATASOURCE_URL="jdbc:mysql://localhost:3306/fortune_db?useUnicode=true&characterEncoding=utf8&useSSL=false&serverTimezone=Asia/Shanghai"
        export SPRING_DATASOURCE_USERNAME="fortune"
        export SPRING_DATASOURCE_PASSWORD="fortune123456"
        export SPRING_REDIS_HOST="localhost"
        export SPRING_REDIS_PORT="6379"
        
        echo "启动后端应用..."
        nohup java -jar target/fortune-mini-app-1.0.0.jar > ../backend.log 2>&1 &
        echo $! > ../backend.pid
        
        echo -e "${GREEN}✅ 后端服务启动完成${NC}"
    else
        echo -e "${RED}❌ Maven 未安装，请先安装 Maven${NC}"
        exit 1
    fi
    
    cd ..
}

# 等待后端就绪
wait_for_backend() {
    echo -e "${BLUE}⏳ 等待后端服务就绪...${NC}"
    
    # 等待后端就绪
    echo "等待后端服务启动..."
    for i in {1..30}; do
        if curl -f http://localhost:8080/api/actuator/health &> /dev/null; then
            echo -e "${GREEN}✅ 后端服务已就绪${NC}"
            return 0
        fi
        echo "等待中... ($i/30)"
        sleep 5
    done
    
    echo -e "${RED}❌ 后端服务启动超时${NC}"
    exit 1
}

# 显示服务状态
show_status() {
    echo -e "${BLUE}📊 服务状态${NC}"
    echo "================================"
    
    echo "Docker 服务:"
    docker-compose ps
    
    echo ""
    echo "后端服务:"
    if [ -f backend.pid ]; then
        pid=$(cat backend.pid)
        if ps -p $pid > /dev/null; then
            echo "✅ 后端服务运行中 (PID: $pid)"
        else
            echo "❌ 后端服务未运行"
        fi
    else
        echo "❌ 后端服务未启动"
    fi
    
    echo ""
    echo -e "${GREEN}🎉 启动完成！${NC}"
    echo "================================"
    echo "🔧 后端API: http://localhost:8080/api"
    echo "📚 API文档: http://localhost:8080/api/swagger-ui.html"
    echo "💾 数据库: localhost:3306 (用户名: fortune, 密码: fortune123456)"
    echo "🗄️  Redis: localhost:6379"
    echo ""
    echo "📋 常用命令:"
    echo "  查看后端日志: tail -f backend.log"
    echo "  停止后端: kill \$(cat backend.pid)"
    echo "  停止基础服务: docker-compose down"
    echo ""
    echo -e "${YELLOW}💡 提示: 后端日志保存在 backend.log 文件中${NC}"
}

# 停止服务
stop_services() {
    echo -e "${BLUE}🛑 停止服务...${NC}"
    
    # 停止后端
    if [ -f backend.pid ]; then
        pid=$(cat backend.pid)
        if ps -p $pid > /dev/null; then
            kill $pid
            echo "后端服务已停止"
        fi
        rm -f backend.pid
    fi
    
    # 停止Docker服务
    docker-compose down
    
    echo -e "${GREEN}✅ 所有服务已停止${NC}"
}

# 主函数
main() {
    case "${1:-start}" in
        "start")
            echo "开始启动 AI八卦运势小程序..."
            echo ""
            
            check_env
            check_dependencies
            start_infrastructure
            wait_for_infrastructure
            start_backend
            wait_for_backend
            show_status
            
            echo ""
            echo -e "${GREEN}🎊 恭喜！AI八卦运势小程序已成功启动！${NC}"
            ;;
        "stop")
            stop_services
            ;;
        "status")
            show_status
            ;;
        *)
            echo "用法: $0 {start|stop|status}"
            echo "  start  - 启动所有服务"
            echo "  stop   - 停止所有服务"
            echo "  status - 查看服务状态"
            exit 1
            ;;
    esac
}

# 错误处理
trap 'echo -e "${RED}❌ 启动过程中发生错误${NC}"; exit 1' ERR

# 执行主函数
main "$@" 
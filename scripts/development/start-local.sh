#!/bin/bash

# AI八卦运势小程序本地启动脚本
# 作者: fortune
# 日期: 2024-01-01

set -e

echo "🔮 AI八卦运势小程序本地启动脚本"
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
    
    echo -e "${GREEN}✅ 环境变量检查完成${NC}"
}

# 检查依赖
check_dependencies() {
    echo -e "${BLUE}🔍 检查系统依赖...${NC}"
    
    # 检查Java
    if ! command -v java &> /dev/null; then
        echo -e "${RED}❌ Java 未安装，请先安装 Java 11+${NC}"
        exit 1
    fi
    
    # 检查Maven
    if ! command -v mvn &> /dev/null; then
        echo -e "${RED}❌ Maven 未安装，请先安装 Maven${NC}"
        exit 1
    fi
    
    # 检查MySQL（可选）
    if command -v mysql &> /dev/null; then
        echo -e "${GREEN}✅ 检测到本地 MySQL${NC}"
        USE_LOCAL_MYSQL=true
    else
        echo -e "${YELLOW}⚠️  未检测到本地 MySQL，将使用 H2 内存数据库${NC}"
        USE_LOCAL_MYSQL=false
    fi
    
    # 检查Redis（可选）
    if command -v redis-server &> /dev/null; then
        echo -e "${GREEN}✅ 检测到本地 Redis${NC}"
        USE_LOCAL_REDIS=true
    else
        echo -e "${YELLOW}⚠️  未检测到本地 Redis，将禁用缓存功能${NC}"
        USE_LOCAL_REDIS=false
    fi
    
    echo -e "${GREEN}✅ 依赖检查完成${NC}"
}

# 启动MySQL（如果需要）
start_mysql() {
    if [ "$USE_LOCAL_MYSQL" = true ]; then
        echo -e "${BLUE}🗄️  检查 MySQL 服务...${NC}"
        
        # 检查MySQL是否运行
        if pgrep -x "mysqld" > /dev/null; then
            echo -e "${GREEN}✅ MySQL 已运行${NC}"
        else
            echo -e "${YELLOW}⚠️  MySQL 未运行，请手动启动 MySQL 服务${NC}"
            echo "macOS: brew services start mysql"
            echo "Linux: sudo systemctl start mysql"
            exit 1
        fi
        
        # 检查数据库是否存在
        if mysql -u root -e "USE fortune_db;" 2>/dev/null; then
            echo -e "${GREEN}✅ 数据库 fortune_db 已存在${NC}"
        else
            echo -e "${BLUE}📋 创建数据库...${NC}"
            mysql -u root -e "CREATE DATABASE IF NOT EXISTS fortune_db DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
            mysql -u root fortune_db < backend/src/main/resources/sql/init.sql
            echo -e "${GREEN}✅ 数据库创建完成${NC}"
        fi
    fi
}

# 启动Redis（如果需要）
start_redis() {
    if [ "$USE_LOCAL_REDIS" = true ]; then
        echo -e "${BLUE}🗄️  检查 Redis 服务...${NC}"
        
        # 检查Redis是否运行
        if pgrep -x "redis-server" > /dev/null; then
            echo -e "${GREEN}✅ Redis 已运行${NC}"
        else
            echo -e "${BLUE}🚀 启动 Redis...${NC}"
            nohup redis-server > redis.log 2>&1 &
            echo $! > redis.pid
            sleep 2
            echo -e "${GREEN}✅ Redis 启动完成${NC}"
        fi
    fi
}

# 创建本地配置文件
create_local_config() {
    echo -e "${BLUE}📝 创建本地配置文件...${NC}"
    
    cat > backend/src/main/resources/application-local.yml << EOF
server:
  port: 8080
  servlet:
    context-path: /api

spring:
  application:
    name: fortune-mini-app
  
  # 数据库配置
  datasource:
EOF

    if [ "$USE_LOCAL_MYSQL" = true ]; then
        cat >> backend/src/main/resources/application-local.yml << EOF
    driver-class-name: com.mysql.cj.jdbc.Driver
    url: jdbc:mysql://localhost:3306/fortune_db?useUnicode=true&characterEncoding=utf8&useSSL=false&serverTimezone=Asia/Shanghai
    username: root
    password: 
EOF
    else
        cat >> backend/src/main/resources/application-local.yml << EOF
    driver-class-name: org.h2.Driver
    url: jdbc:h2:mem:fortune_db;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE
    username: sa
    password: 
  h2:
    console:
      enabled: true
      path: /h2-console
EOF
    fi

    if [ "$USE_LOCAL_REDIS" = true ]; then
        cat >> backend/src/main/resources/application-local.yml << EOF
  
  # Redis配置
  redis:
    host: localhost
    port: 6379
    password: 
    database: 0
    timeout: 3000ms
EOF
    else
        cat >> backend/src/main/resources/application-local.yml << EOF
  
  # 禁用Redis
  redis:
    host: localhost
    port: 6379
    password: 
    database: 0
    timeout: 3000ms
    lettuce:
      pool:
        enabled: false
EOF
    fi

    cat >> backend/src/main/resources/application-local.yml << EOF

# MyBatis-Plus配置
mybatis-plus:
  configuration:
    map-underscore-to-camel-case: true
    cache-enabled: false
    log-impl: org.apache.ibatis.logging.stdout.StdOutImpl
  global-config:
    db-config:
      id-type: auto

# 日志配置
logging:
  level:
    com.fortune: debug
    org.springframework.web: info

# 自定义配置
fortune:
  jwt:
    secret: fortune-mini-app-secret-key-2024
    expiration: 86400000
  deepseek:
    api-url: https://api.deepseek.com/v1/chat/completions
    api-key: \${DEEPSEEK_API_KEY:your-deepseek-api-key}
    model: deepseek-chat
    max-tokens: 500
    temperature: 0.7
  wechat:
    app-id: \${WECHAT_APP_ID:your-wechat-app-id}
    app-secret: \${WECHAT_APP_SECRET:your-wechat-app-secret}
EOF

    echo -e "${GREEN}✅ 本地配置文件创建完成${NC}"
}

# 构建并启动后端
start_backend() {
    echo -e "${BLUE}🏗️  构建并启动后端服务...${NC}"
    
    cd backend
    
    echo "构建项目..."
    mvn clean package -DskipTests
    
    echo "启动后端应用..."
    nohup java -jar target/fortune-mini-app-1.0.0.jar --spring.profiles.active=local > ../backend.log 2>&1 &
    echo $! > ../backend.pid
    
    echo -e "${GREEN}✅ 后端服务启动完成${NC}"
    
    cd ..
}

# 等待后端就绪
wait_for_backend() {
    echo -e "${BLUE}⏳ 等待后端服务就绪...${NC}"
    
    for i in {1..30}; do
        if curl -f http://localhost:8080/api/actuator/health &> /dev/null; then
            echo -e "${GREEN}✅ 后端服务已就绪${NC}"
            return 0
        fi
        echo "等待中... ($i/30)"
        sleep 5
    done
    
    echo -e "${RED}❌ 后端服务启动超时${NC}"
    echo "请查看日志: tail -f backend.log"
    exit 1
}

# 显示服务状态
show_status() {
    echo -e "${BLUE}📊 服务状态${NC}"
    echo "================================"
    
    # 检查后端服务
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
    
    # 检查MySQL
    if [ "$USE_LOCAL_MYSQL" = true ]; then
        if pgrep -x "mysqld" > /dev/null; then
            echo "✅ MySQL 服务运行中"
        else
            echo "❌ MySQL 服务未运行"
        fi
    else
        echo "📝 使用 H2 内存数据库"
    fi
    
    # 检查Redis
    if [ "$USE_LOCAL_REDIS" = true ]; then
        if pgrep -x "redis-server" > /dev/null; then
            echo "✅ Redis 服务运行中"
        else
            echo "❌ Redis 服务未运行"
        fi
    else
        echo "⚠️  Redis 功能已禁用"
    fi
    
    echo ""
    echo -e "${GREEN}🎉 启动完成！${NC}"
    echo "================================"
    echo "🔧 后端API: http://localhost:8080/api"
    echo "📚 API文档: http://localhost:8080/api/swagger-ui.html"
    
    if [ "$USE_LOCAL_MYSQL" = false ]; then
        echo "💾 H2数据库控制台: http://localhost:8080/api/h2-console"
        echo "   JDBC URL: jdbc:h2:mem:fortune_db"
        echo "   用户名: sa"
        echo "   密码: (空)"
    else
        echo "💾 MySQL数据库: localhost:3306/fortune_db"
    fi
    
    echo ""
    echo "📋 常用命令:"
    echo "  查看后端日志: tail -f backend.log"
    echo "  停止服务: $0 stop"
    echo "  查看状态: $0 status"
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
    
    # 停止Redis（如果是我们启动的）
    if [ -f redis.pid ]; then
        pid=$(cat redis.pid)
        if ps -p $pid > /dev/null; then
            kill $pid
            echo "Redis 服务已停止"
        fi
        rm -f redis.pid
    fi
    
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
            start_mysql
            start_redis
            create_local_config
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
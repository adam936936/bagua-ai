#!/bin/bash

# 后端JAR直接启动脚本
# 用于绕过Docker问题，直接启动后端服务

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_info "🚀 开始启动后端JAR服务..."

# 检查Java环境
if ! command -v java &> /dev/null; then
    log_error "Java未安装或不在PATH中"
    exit 1
fi

JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
log_info "Java版本: $JAVA_VERSION"

# 检查JAR文件
JAR_FILE="backend/target/fortune-mini-app-1.0.0.jar"
if [ ! -f "$JAR_FILE" ]; then
    log_error "JAR文件不存在: $JAR_FILE"
    log_info "请先构建项目: cd backend && mvn clean package -DskipTests"
    exit 1
fi

# 检查配置文件
if [ ! -f "config/prod.env" ]; then
    log_error "配置文件不存在: config/prod.env"
    log_info "请先运行: ./setup-secure-config.sh"
    exit 1
fi

# 加载环境变量
log_info "加载环境配置..."
source config/prod.env

# 检查数据库和Redis连接
log_info "检查依赖服务..."

# 检查MySQL
if ! docker ps | grep -q "bagua-mysql-public"; then
    log_warning "MySQL容器未运行，启动MySQL..."
    docker-compose -f docker-compose.public.yml --env-file config/prod.env up -d mysql
    
    # 等待MySQL启动
    log_info "等待MySQL启动..."
    for i in {1..30}; do
        if docker-compose -f docker-compose.public.yml exec -T mysql mysqladmin ping -h localhost -u root -p$MYSQL_ROOT_PASSWORD > /dev/null 2>&1; then
            log_success "MySQL启动成功"
            break
        fi
        if [ $i -eq 30 ]; then
            log_error "MySQL启动超时"
            exit 1
        fi
        echo -n "."
        sleep 2
    done
fi

# 检查Redis
if ! docker ps | grep -q "bagua-redis-public"; then
    log_warning "Redis容器未运行，启动Redis..."
    docker-compose -f docker-compose.public.yml --env-file config/prod.env up -d redis
    
    # 等待Redis启动
    log_info "等待Redis启动..."
    for i in {1..15}; do
        if docker-compose -f docker-compose.public.yml exec -T redis redis-cli -a $REDIS_PASSWORD ping > /dev/null 2>&1; then
            log_success "Redis启动成功"
            break
        fi
        if [ $i -eq 15 ]; then
            log_error "Redis启动超时"
            exit 1
        fi
        echo -n "."
        sleep 1
    done
fi

# 停止可能运行的后端容器
if docker ps | grep -q "bagua-backend-public"; then
    log_info "停止现有的后端容器..."
    docker stop bagua-backend-public > /dev/null 2>&1 || true
    docker rm bagua-backend-public > /dev/null 2>&1 || true
fi

# 创建日志目录
mkdir -p logs

# 设置JVM参数
JVM_OPTS="-Xms512m -Xmx1024m"
JVM_OPTS="$JVM_OPTS -Dspring.profiles.active=prod"
JVM_OPTS="$JVM_OPTS -Dserver.port=8080"
JVM_OPTS="$JVM_OPTS -Dserver.address=0.0.0.0"

# 设置Spring Boot环境变量
export SPRING_PROFILES_ACTIVE=prod
export TZ=Asia/Shanghai

# 数据库配置
export SPRING_DATASOURCE_URL="jdbc:mysql://localhost:3306/${MYSQL_DATABASE}?useUnicode=true&characterEncoding=utf8&useSSL=false&serverTimezone=Asia/Shanghai"
export SPRING_DATASOURCE_USERNAME="$MYSQL_USERNAME"
export SPRING_DATASOURCE_PASSWORD="$MYSQL_PASSWORD"

# Redis配置
export SPRING_REDIS_HOST=localhost
export SPRING_REDIS_PORT=6379
export SPRING_REDIS_PASSWORD="$REDIS_PASSWORD"

# AI服务配置
export DEEPSEEK_API_KEY="$DEEPSEEK_API_KEY"
export DEEPSEEK_API_URL="$DEEPSEEK_API_URL"
export DEEPSEEK_MODEL="$DEEPSEEK_MODEL"

# 微信配置
export WECHAT_APP_ID="$WECHAT_APP_ID"
export WECHAT_APP_SECRET="$WECHAT_APP_SECRET"

# JWT配置
export JWT_SECRET="$JWT_SECRET"
export ENCRYPTION_KEY="$ENCRYPTION_KEY"

# 启动后端服务
log_info "启动后端服务..."
log_info "JAR文件: $JAR_FILE"
log_info "JVM参数: $JVM_OPTS"

# 检查端口是否被占用
if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1; then
    log_warning "端口8080已被占用，尝试停止现有进程..."
    if [ -f "backend.pid" ]; then
        OLD_PID=$(cat backend.pid)
        if kill -0 $OLD_PID 2>/dev/null; then
            log_info "停止旧进程 (PID: $OLD_PID)..."
            kill $OLD_PID
            sleep 3
        fi
        rm -f backend.pid
    fi
fi

# 启动服务
nohup java $JVM_OPTS -jar "$JAR_FILE" > logs/backend-jar.log 2>&1 &
BACKEND_PID=$!

# 保存PID
echo $BACKEND_PID > backend.pid
log_info "后端服务已启动，PID: $BACKEND_PID"

# 等待服务启动
log_info "等待后端服务启动..."
for i in {1..60}; do
    if curl -s http://localhost:8080/api/actuator/health > /dev/null 2>&1; then
        log_success "后端服务启动成功！"
        break
    fi
    if [ $i -eq 60 ]; then
        log_error "后端服务启动超时"
        log_info "查看日志: tail -f logs/backend-jar.log"
        exit 1
    fi
    echo -n "."
    sleep 2
done

# 测试API接口
log_info "测试API接口..."
if curl -s http://localhost:8080/api/actuator/health | grep -q "UP"; then
    log_success "✅ 健康检查通过"
else
    log_warning "⚠️ 健康检查可能有问题"
fi

# 显示服务信息
log_success "🎉 后端服务启动完成！"
echo ""
echo "📋 服务信息:"
echo "- 后端API: http://localhost:8080"
echo "- 健康检查: http://localhost:8080/api/actuator/health"
echo "- 进程ID: $BACKEND_PID"
echo "- 日志文件: logs/backend-jar.log"
echo ""
echo "🔧 管理命令:"
echo "- 查看日志: tail -f logs/backend-jar.log"
echo "- 停止服务: kill $BACKEND_PID 或 ./stop-backend.sh"
echo "- 重启服务: ./start-backend-jar.sh"
echo ""
echo "🧪 测试命令:"
echo "- 健康检查: curl http://localhost:8080/api/actuator/health"
echo "- 测试运势: curl -X POST http://localhost:8080/api/fortune/calculate -H 'Content-Type: application/json' -d '{\"name\":\"测试\",\"birthDate\":\"1990-01-01\",\"birthTime\":\"子时\",\"gender\":\"male\"}'" 
#!/bin/bash

echo "🚀 启动八卦AI本地开发环境"
echo "================================"

# 设置颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查MySQL是否运行
echo -e "${BLUE}[1/5] 检查MySQL服务...${NC}"
if ! mysqladmin ping -h localhost --silent; then
    echo -e "${YELLOW}MySQL未运行，尝试启动...${NC}"
    # macOS
    if command -v brew >/dev/null 2>&1; then
        brew services start mysql
    # Linux
    elif command -v systemctl >/dev/null 2>&1; then
        sudo systemctl start mysql
    else
        echo -e "${RED}请手动启动MySQL服务${NC}"
        exit 1
    fi
    
    # 等待MySQL启动
    echo "等待MySQL启动..."
    sleep 3
fi

# 检查MySQL连接
echo -e "${BLUE}[2/5] 测试MySQL连接...${NC}"
if mysql -u root -p123456 -e "SELECT 1;" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ MySQL连接成功${NC}"
elif mysql -u root -e "SELECT 1;" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ MySQL连接成功（无密码）${NC}"
    export MYSQL_PASSWORD=""
else
    echo -e "${RED}❌ MySQL连接失败，请检查密码配置${NC}"
    echo "请确保MySQL root用户密码为123456，或设置环境变量 MYSQL_PASSWORD"
    exit 1
fi

# 初始化数据库
echo -e "${BLUE}[3/5] 初始化数据库...${NC}"
if [ "$1" = "--init-db" ] || [ ! -f ".db-initialized" ]; then
    echo "执行数据库初始化脚本..."
    
    if [ -n "$MYSQL_PASSWORD" ]; then
        mysql -u root -p"$MYSQL_PASSWORD" < complete-database-init.sql
    else
        mysql -u root < complete-database-init.sql
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ 数据库初始化成功${NC}"
        touch .db-initialized
    else
        echo -e "${RED}❌ 数据库初始化失败${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}数据库已初始化，跳过...${NC}"
    echo "如需重新初始化，请删除 .db-initialized 文件或使用 --init-db 参数"
fi

# 编译后端
echo -e "${BLUE}[4/5] 编译后端项目...${NC}"
cd backend
if mvn clean compile -DskipTests -q; then
    echo -e "${GREEN}✅ 后端编译成功${NC}"
else
    echo -e "${RED}❌ 后端编译失败${NC}"
    exit 1
fi

# 启动后端
echo -e "${BLUE}[5/5] 启动后端服务...${NC}"
echo -e "${YELLOW}启动参数: --spring.profiles.active=local-mysql${NC}"
echo ""
echo "🌟 服务地址:"
echo "   - 后端API: http://localhost:8080/api"
echo "   - 健康检查: http://localhost:8080/api/actuator/health"
echo "   - 简单测试: http://localhost:8080/api/simple/hello"
echo ""
echo "📋 测试API:"
echo "   - 登录测试: POST http://localhost:8080/api/user/login"
echo "   - 用户统计: GET http://localhost:8080/api/user/stats"
echo "   - 八字测算: POST http://localhost:8080/api/fortune/calculate"
echo ""
echo -e "${GREEN}🎉 启动完成！按 Ctrl+C 停止服务${NC}"
echo "================================"

# 启动应用
mvn spring-boot:run -Dspring-boot.run.profiles=local-mysql 
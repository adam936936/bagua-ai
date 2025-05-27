#!/bin/bash

echo "=== AI八卦运势小程序后端启动 ==="

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查当前目录
if [ ! -f "backend/pom.xml" ]; then
    echo -e "${RED}❌ 请在项目根目录执行此脚本${NC}"
    exit 1
fi

# 步骤1: 检查端口占用
echo -e "${YELLOW}步骤1: 检查端口占用${NC}"
PORT_8080=$(lsof -ti:8080 2>/dev/null)
if [ ! -z "$PORT_8080" ]; then
    echo -e "${YELLOW}⚠️  端口8080被占用，进程ID: $PORT_8080${NC}"
    echo "占用进程详情:"
    lsof -i:8080
    echo ""
    read -p "是否要杀死占用进程？(y/n): " kill_choice
    if [ "$kill_choice" = "y" ] || [ "$kill_choice" = "Y" ]; then
        echo "正在杀死进程..."
        lsof -ti:8080 | xargs kill -9 2>/dev/null
        sleep 2
        # 再次检查
        if [ -z "$(lsof -ti:8080 2>/dev/null)" ]; then
            echo -e "${GREEN}✅ 进程已杀死，端口8080现在可用${NC}"
        else
            echo -e "${RED}❌ 无法杀死进程，请手动处理${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ 请手动处理端口占用问题后重试${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ 端口8080可用${NC}"
fi

# 步骤2: 检查Java环境
echo -e "${YELLOW}步骤2: 检查Java环境${NC}"
if ! command -v java &> /dev/null; then
    echo -e "${RED}❌ Java未安装或未配置到PATH${NC}"
    exit 1
fi

JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
echo -e "${GREEN}✅ Java版本: $JAVA_VERSION${NC}"

# 步骤3: 检查Maven环境
echo -e "${YELLOW}步骤3: 检查Maven环境${NC}"
if ! command -v mvn &> /dev/null; then
    echo -e "${RED}❌ Maven未安装或未配置到PATH${NC}"
    exit 1
fi

MVN_VERSION=$(mvn -version | head -n 1)
echo -e "${GREEN}✅ $MVN_VERSION${NC}"

# 步骤4: 检查数据库连接
echo -e "${YELLOW}步骤4: 检查数据库连接${NC}"
if command -v mysql &> /dev/null; then
    # 这里可以添加数据库连接测试
    echo -e "${GREEN}✅ MySQL客户端可用${NC}"
else
    echo -e "${YELLOW}⚠️  MySQL客户端未找到，请确保数据库正常运行${NC}"
fi

# 步骤5: 进入backend目录并启动
echo -e "${YELLOW}步骤5: 启动Spring Boot应用${NC}"
cd backend

echo "正在编译和启动应用..."
echo "命令: mvn spring-boot:run"
echo ""

# 启动应用
mvn spring-boot:run

# 检查启动结果
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 后端启动成功${NC}"
else
    echo -e "${RED}❌ 后端启动失败，请检查错误信息${NC}"
    exit 1
fi 
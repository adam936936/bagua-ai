#!/bin/bash

echo "🚀 启动AI八卦运势小程序后端服务"
echo "=================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 强制清理8080端口的函数
cleanup_port_8080() {
    echo -e "${BLUE}🔍 检查8080端口占用情况${NC}"
    
    # 方法1: 使用lsof查找占用进程
    PORT_PIDS=$(lsof -ti:8080 2>/dev/null)
    
    # 方法2: 使用netstat作为备选
    if [ -z "$PORT_PIDS" ]; then
        PORT_PIDS=$(netstat -tulpn 2>/dev/null | grep :8080 | awk '{print $7}' | cut -d'/' -f1 | grep -v '-')
    fi
    
    # 方法3: 使用ss命令作为备选
    if [ -z "$PORT_PIDS" ]; then
        PORT_PIDS=$(ss -tulpn 2>/dev/null | grep :8080 | awk '{print $6}' | cut -d',' -f2 | cut -d'=' -f2)
    fi
    
    if [ -n "$PORT_PIDS" ]; then
        echo -e "${YELLOW}⚠️  发现8080端口被占用，进程ID: $PORT_PIDS${NC}"
        
        # 逐个杀死进程
        for pid in $PORT_PIDS; do
            if [ -n "$pid" ] && [ "$pid" != "-" ]; then
                echo -e "${YELLOW}正在终止进程 $pid...${NC}"
                
                # 先尝试优雅关闭
                kill -TERM $pid 2>/dev/null
                sleep 2
                
                # 检查进程是否还存在
                if kill -0 $pid 2>/dev/null; then
                    echo -e "${YELLOW}优雅关闭失败，强制杀死进程 $pid...${NC}"
                    kill -9 $pid 2>/dev/null
                    sleep 1
                fi
                
                # 再次检查
                if kill -0 $pid 2>/dev/null; then
                    echo -e "${RED}❌ 无法杀死进程 $pid${NC}"
                else
                    echo -e "${GREEN}✅ 进程 $pid 已终止${NC}"
                fi
            fi
        done
        
        # 等待端口释放
        echo -e "${YELLOW}等待端口释放...${NC}"
        sleep 3
        
        # 最终检查
        FINAL_CHECK=$(lsof -ti:8080 2>/dev/null)
        if [ -n "$FINAL_CHECK" ]; then
            echo -e "${RED}❌ 端口8080仍被占用，请手动检查${NC}"
            echo -e "${YELLOW}💡 可以运行: sudo lsof -ti:8080 | xargs sudo kill -9${NC}"
            read -p "是否继续启动？(y/n): " continue_start
            if [[ $continue_start != "y" && $continue_start != "Y" ]]; then
                exit 1
            fi
        else
            echo -e "${GREEN}✅ 端口8080已成功释放${NC}"
        fi
    else
        echo -e "${GREEN}✅ 8080端口空闲，可以启动服务${NC}"
    fi
}

# 检查Java环境
check_java() {
    echo -e "${BLUE}☕ 检查Java环境${NC}"
    if ! command -v java &> /dev/null; then
        echo -e "${RED}❌ Java未安装或不在PATH中${NC}"
        exit 1
    fi
    
    JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
    echo -e "${GREEN}✅ Java版本: $JAVA_VERSION${NC}"
}

# 检查Maven环境
check_maven() {
    echo -e "${BLUE}📦 检查Maven环境${NC}"
    if ! command -v mvn &> /dev/null; then
        echo -e "${RED}❌ Maven未安装或不在PATH中${NC}"
        exit 1
    fi
    
    MVN_VERSION=$(mvn -version 2>&1 | head -n 1 | cut -d' ' -f3)
    echo -e "${GREEN}✅ Maven版本: $MVN_VERSION${NC}"
}

# 检查环境变量
check_env_vars() {
    echo -e "${BLUE}🔑 检查环境变量配置${NC}"
    if [ -z "$DEEPSEEK_API_KEY" ]; then
        echo -e "${RED}❌ DEEPSEEK_API_KEY 环境变量未设置${NC}"
        echo -e "${YELLOW}正在设置默认API密钥...${NC}"
        export DEEPSEEK_API_KEY="[请配置您的API密钥]"
        echo -e "${GREEN}✅ API密钥已设置${NC}"
    else
        echo -e "${GREEN}✅ DEEPSEEK_API_KEY 已配置${NC}"
    fi
}

# 主执行流程
echo -e "${BLUE}==================== 启动前检查 ====================${NC}"

# 1. 强制清理端口
cleanup_port_8080

# 2. 检查Java环境
check_java

# 3. 检查Maven环境  
check_maven

# 4. 检查环境变量
check_env_vars

# 5. 进入后端目录
echo -e "${BLUE}📁 进入后端目录${NC}"
if [ ! -d "backend" ]; then
    echo -e "${RED}❌ backend目录不存在${NC}"
    exit 1
fi
cd backend

# 6. 清理并编译
echo -e "${BLUE}🔨 清理并编译项目${NC}"
echo -e "${YELLOW}正在执行 mvn clean compile...${NC}"
mvn clean compile -q

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 项目编译失败${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 项目编译成功${NC}"

# 7. 最后一次端口检查
echo -e "${BLUE}🔍 启动前最后一次端口检查${NC}"
FINAL_PORT_CHECK=$(lsof -ti:8080 2>/dev/null)
if [ -n "$FINAL_PORT_CHECK" ]; then
    echo -e "${RED}❌ 端口8080仍被占用，无法启动${NC}"
    exit 1
fi

# 8. 启动Spring Boot应用
echo -e "${BLUE}==================== 启动服务 ====================${NC}"
echo -e "${GREEN}🌟 后端服务启动中...${NC}"
echo -e "${GREEN}📍 服务地址: http://localhost:8080${NC}"
echo -e "${GREEN}📍 API文档: http://localhost:8080/swagger-ui.html${NC}"
echo -e "${GREEN}📍 健康检查: http://localhost:8080/actuator/health${NC}"
echo -e "${YELLOW}💡 按 Ctrl+C 停止服务${NC}"
echo ""

# 启动应用
mvn spring-boot:run 
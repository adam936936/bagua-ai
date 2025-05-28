#!/bin/bash

# 端口清理脚本
# 用法: ./cleanup-port.sh [端口号]
# 默认清理8080端口

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 获取端口号参数，默认为8080
PORT=${1:-8080}

echo -e "${BLUE}🧹 端口清理工具${NC}"
echo -e "${BLUE}==================${NC}"
echo -e "${YELLOW}目标端口: $PORT${NC}"
echo ""

# 清理指定端口的函数
cleanup_port() {
    local port=$1
    echo -e "${BLUE}🔍 检查端口 $port 占用情况${NC}"
    
    # 方法1: 使用lsof查找占用进程
    PORT_PIDS=$(lsof -ti:$port 2>/dev/null)
    
    # 方法2: 使用netstat作为备选
    if [ -z "$PORT_PIDS" ]; then
        PORT_PIDS=$(netstat -tulpn 2>/dev/null | grep :$port | awk '{print $7}' | cut -d'/' -f1 | grep -v '-' | grep -E '^[0-9]+$')
    fi
    
    # 方法3: 使用ss命令作为备选
    if [ -z "$PORT_PIDS" ]; then
        PORT_PIDS=$(ss -tulpn 2>/dev/null | grep :$port | awk '{print $6}' | cut -d',' -f2 | cut -d'=' -f2 | grep -E '^[0-9]+$')
    fi
    
    if [ -n "$PORT_PIDS" ]; then
        echo -e "${YELLOW}⚠️  发现端口 $port 被占用${NC}"
        echo -e "${YELLOW}占用进程ID: $PORT_PIDS${NC}"
        echo ""
        
        # 显示进程详细信息
        echo -e "${BLUE}📋 进程详细信息:${NC}"
        for pid in $PORT_PIDS; do
            if [ -n "$pid" ] && [ "$pid" != "-" ]; then
                if ps -p $pid > /dev/null 2>&1; then
                    echo -e "${YELLOW}PID $pid:${NC} $(ps -p $pid -o comm= 2>/dev/null || echo '未知进程')"
                fi
            fi
        done
        echo ""
        
        # 询问是否清理
        read -p "是否清理这些进程？(y/n): " confirm
        if [[ $confirm != "y" && $confirm != "Y" ]]; then
            echo -e "${YELLOW}❌ 用户取消操作${NC}"
            exit 0
        fi
        
        # 逐个杀死进程
        for pid in $PORT_PIDS; do
            if [ -n "$pid" ] && [ "$pid" != "-" ]; then
                if ps -p $pid > /dev/null 2>&1; then
                    echo -e "${YELLOW}🔄 正在终止进程 $pid...${NC}"
                    
                    # 先尝试优雅关闭
                    kill -TERM $pid 2>/dev/null
                    sleep 2
                    
                    # 检查进程是否还存在
                    if ps -p $pid > /dev/null 2>&1; then
                        echo -e "${YELLOW}⚡ 优雅关闭失败，强制杀死进程 $pid...${NC}"
                        kill -9 $pid 2>/dev/null
                        sleep 1
                    fi
                    
                    # 再次检查
                    if ps -p $pid > /dev/null 2>&1; then
                        echo -e "${RED}❌ 无法杀死进程 $pid${NC}"
                    else
                        echo -e "${GREEN}✅ 进程 $pid 已终止${NC}"
                    fi
                fi
            fi
        done
        
        # 等待端口释放
        echo -e "${YELLOW}⏳ 等待端口释放...${NC}"
        sleep 3
        
        # 最终检查
        FINAL_CHECK=$(lsof -ti:$port 2>/dev/null)
        if [ -n "$FINAL_CHECK" ]; then
            echo -e "${RED}❌ 端口 $port 仍被占用${NC}"
            echo -e "${YELLOW}💡 建议手动检查: lsof -i:$port${NC}"
            echo -e "${YELLOW}💡 强制清理命令: sudo lsof -ti:$port | xargs sudo kill -9${NC}"
            exit 1
        else
            echo -e "${GREEN}🎉 端口 $port 已成功释放${NC}"
        fi
    else
        echo -e "${GREEN}✅ 端口 $port 空闲，无需清理${NC}"
    fi
}

# 显示当前端口使用情况
show_port_info() {
    local port=$1
    echo -e "${BLUE}📊 端口 $port 使用情况:${NC}"
    
    # 使用lsof显示详细信息
    if command -v lsof &> /dev/null; then
        lsof_result=$(lsof -i:$port 2>/dev/null)
        if [ -n "$lsof_result" ]; then
            echo "$lsof_result"
        else
            echo -e "${GREEN}端口 $port 未被占用${NC}"
        fi
    else
        echo -e "${YELLOW}lsof 命令不可用，使用 netstat 检查${NC}"
        netstat -tulpn 2>/dev/null | grep :$port || echo -e "${GREEN}端口 $port 未被占用${NC}"
    fi
    echo ""
}

# 主执行流程
show_port_info $PORT
cleanup_port $PORT

echo -e "${BLUE}==================${NC}"
echo -e "${GREEN}🏁 端口清理完成${NC}" 
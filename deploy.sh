#!/bin/bash

# 八卦运势AI小程序 - 一键部署入口脚本
# Ubuntu生产环境 - Docker环境优先
# 作者: AI助手
# 日期: 2025-01-17

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 显示横幅
echo -e "${CYAN}"
echo "=================================================="
echo "    八卦运势AI小程序 - 一键部署"
echo "    Ubuntu生产环境 | Docker环境优先"
echo "=================================================="
echo -e "${NC}"

# 显示选择菜单
echo -e "${BLUE}请选择操作:${NC}"
echo "1) 完整部署 (首次部署推荐，包含环境安装和项目构建)"
echo "2) 快速启动 (适用于已构建项目)"
echo "3) 只部署前端 (解决前端网络问题)"
echo "4) 只部署后端 (数据库+API服务)"
echo "5) 检查状态 (查看当前部署状态)"
echo "6) 停止服务 (停止所有运行的服务)"
echo "7) 查看部署指南"
echo "8) 退出"
echo ""

read -p "请输入选择 (1-8): " choice

case $choice in
    1)
        echo -e "${GREEN}开始完整部署...${NC}"
        ./ubuntu-quick-deploy.sh
        ;;
    2)
        echo -e "${GREEN}开始快速启动...${NC}"
        ./ubuntu-quick-start.sh
        ;;
    3)
        echo -e "${GREEN}只部署前端...${NC}"
        ./deploy-frontend-only.sh
        ;;
    4)
        echo -e "${GREEN}只部署后端...${NC}"
        ./deploy-backend-only.sh
        ;;
    5)
        echo -e "${GREEN}检查部署状态...${NC}"
        ./check-status.sh
        ;;
    6)
        echo -e "${GREEN}停止所有服务...${NC}"
        ./stop-all-services.sh
        ;;
    7)
        echo -e "${GREEN}打开部署指南...${NC}"
        if command -v less &> /dev/null; then
            less UBUNTU_DEPLOYMENT_GUIDE.md
        elif command -v more &> /dev/null; then
            more UBUNTU_DEPLOYMENT_GUIDE.md
        else
            cat UBUNTU_DEPLOYMENT_GUIDE.md
        fi
        ;;
    8)
        echo "退出"
        exit 0
        ;;
    *)
        echo "无效选择，请重新运行脚本"
        exit 1
        ;;
esac 
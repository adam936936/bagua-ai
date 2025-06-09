#!/bin/bash

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查Node.js环境
check_nodejs() {
    log_info "检查Node.js环境..."
    
    if ! command -v node &> /dev/null; then
        log_error "Node.js未安装，请先安装Node.js 16+"
        exit 1
    fi
    
    NODE_VERSION=$(node --version)
    log_info "Node.js版本: $NODE_VERSION"
    
    if ! command -v npm &> /dev/null; then
        log_error "npm未安装"
        exit 1
    fi
}

# 安装前端依赖
install_dependencies() {
    log_info "检查前端依赖..."
    
    cd frontend
    
    if [ ! -d "node_modules" ]; then
        log_info "安装前端依赖..."
        npm install
    else
        log_info "依赖已存在，跳过安装"
    fi
    
    cd ..
}

# 构建前端H5版本
build_frontend() {
    log_info "构建前端H5版本..."
    
    cd frontend
    
    # 清理旧的构建
    if [ -d "dist/build/h5" ]; then
        rm -rf dist/build/h5
        log_info "清理旧的构建文件"
    fi
    
    # 构建H5版本 - 使用正确的命令
    log_info "开始构建H5版本..."
    npm run build:h5
    
    if [ ! -d "dist/build/h5" ]; then
        log_error "前端构建失败！检查构建错误信息"
        log_info "可用的构建命令："
        log_info "  - npm run build:h5 (H5版本)"
        log_info "  - npm run build:mp-weixin (微信小程序)"
        exit 1
    fi
    
    if [ ! -f "dist/build/h5/index.html" ]; then
        log_error "构建产物不完整！index.html文件不存在"
        exit 1
    fi
    
    log_info "前端H5版本构建成功！"
    log_info "构建产物位置: frontend/dist/build/h5/"
    
    cd ..
}

# 验证构建结果
verify_build() {
    log_info "验证构建结果..."
    
    local build_dir="frontend/dist/build/h5"
    
    # 检查关键文件
    if [ -f "$build_dir/index.html" ]; then
        log_info "✅ index.html 存在"
    else
        log_error "❌ index.html 不存在"
        exit 1
    fi
    
    # 检查静态资源
    if [ -d "$build_dir/static" ] || ls $build_dir/*.js &> /dev/null || ls $build_dir/*.css &> /dev/null; then
        log_info "✅ 静态资源文件存在"
    else
        log_warning "⚠️  静态资源目录可能不存在"
    fi
    
    # 显示构建目录内容
    echo ""
    log_info "构建产物内容："
    ls -la "$build_dir/"
}

# 重启Docker服务
restart_docker_services() {
    log_info "重启Docker服务以加载新的前端文件..."
    
    # 设置环境变量 (请替换为您的实际配置)
    export MYSQL_PASSWORD='[请配置您的MySQL密码]'
    export MYSQL_ROOT_PASSWORD='[请配置您的MySQL root密码]'
    export REDIS_PASSWORD='[请配置您的Redis密码]'
    export JWT_SECRET='[请配置您的JWT密钥]'
    export DEEPSEEK_API_KEY='[请配置您的API密钥]'
    export WECHAT_APP_ID='[请配置您的微信AppID]'
    export WECHAT_APP_SECRET='[请配置您的微信AppSecret]'
    
    # 只重启Nginx服务
    if docker compose -f docker-compose.prod.yml ps nginx-prod | grep -q "Up"; then
        log_info "重启Nginx服务..."
        docker compose -f docker-compose.prod.yml restart nginx-prod
        
        # 等待服务启动
        sleep 5
        
        # 验证服务状态
        if docker compose -f docker-compose.prod.yml ps nginx-prod | grep -q "Up"; then
            log_info "✅ Nginx服务重启成功"
        else
            log_error "❌ Nginx服务重启失败"
            exit 1
        fi
    else
        log_info "启动完整Docker服务..."
        docker compose -f docker-compose.prod.yml up -d
        
        # 等待服务启动
        sleep 10
    fi
}

# 验证部署
verify_deployment() {
    log_info "验证前端部署..."
    
    # 等待服务完全启动
    sleep 3
    
    # 测试本地访问
    if curl -f -s http://localhost/ > /dev/null 2>&1; then
        log_info "✅ 前端HTTP访问测试成功"
    else
        log_warning "⚠️  前端HTTP访问测试失败，检查Nginx配置"
    fi
    
    # 检查容器中的文件
    if docker compose -f docker-compose.prod.yml exec nginx-prod test -f /usr/share/nginx/html/index.html; then
        log_info "✅ 容器中前端文件存在"
    else
        log_error "❌ 容器中前端文件不存在"
    fi
}

# 显示访问信息
show_access_info() {
    echo ""
    echo "🎉 前端部署完成！"
    echo ""
    echo "📱 访问地址："
    echo "  - HTTP:  http://localhost/"
    echo "  - HTTPS: https://localhost/ (忽略SSL警告)"
    echo ""
    echo "🔗 如果有公网IP，可通过以下地址访问："
    echo "  - HTTP:  http://your-server-ip/"
    echo "  - HTTPS: https://your-server-ip/"
    echo ""
    echo "🛠️  调试命令："
    echo "  - 查看Nginx日志: docker compose -f docker-compose.prod.yml logs nginx-prod"
    echo "  - 查看容器状态: docker compose -f docker-compose.prod.yml ps"
    echo "  - 进入Nginx容器: docker compose -f docker-compose.prod.yml exec nginx-prod sh"
}

# 主函数
main() {
    echo "🚀 开始部署AI八卦运势小程序前端..."
    echo ""
    
    check_nodejs
    install_dependencies
    build_frontend
    verify_build
    restart_docker_services
    verify_deployment
    show_access_info
    
    echo ""
    log_info "前端部署流程完成！"
}

# 错误处理
trap 'log_error "部署过程中发生错误！请检查错误信息"; exit 1' ERR

# 执行主函数
main "$@" 
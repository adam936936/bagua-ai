#!/bin/bash

# ==============================================
# 八卦运势小程序 - 前端生产环境构建脚本
# 支持微信小程序和H5双端构建部署
# 版本: v2.0.0
# 创建时间: 2025-06-05
# ==============================================

set -e

# 脚本配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
FRONTEND_DIR="$PROJECT_DIR/frontend"
LOG_FILE="/tmp/frontend-build-$(date +%Y%m%d_%H%M%S).log"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# 日志函数
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${PURPLE}[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS:${NC} $1" | tee -a "$LOG_FILE"
}

# 显示帮助信息
show_help() {
    cat << EOF
八卦运势小程序 - 前端生产环境构建脚本 v2.0.0

使用方法:
    $0 [选项]

选项:
    -h, --help              显示此帮助信息
    -e, --env ENV          指定环境 (dev|test|prod) 默认: prod
    -p, --platform PLATFORM 指定平台 (h5|mp-weixin|all) 默认: all
    -c, --clean            清理构建目录
    -s, --skip-deps        跳过依赖安装
    --api-url URL          指定API基础URL
    --upload-to-cos        上传到腾讯云COS
    --deploy-miniprogram   自动部署微信小程序

示例:
    $0 --env prod --platform all
    $0 --platform h5 --api-url https://api.fortune.com
    $0 --clean --upload-to-cos

EOF
}

# 解析命令行参数
parse_args() {
    ENV="prod"
    PLATFORM="all"
    CLEAN=false
    SKIP_DEPS=false
    API_URL=""
    UPLOAD_TO_COS=false
    DEPLOY_MINIPROGRAM=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -e|--env)
                ENV="$2"
                shift 2
                ;;
            -p|--platform)
                PLATFORM="$2"
                shift 2
                ;;
            -c|--clean)
                CLEAN=true
                shift
                ;;
            -s|--skip-deps)
                SKIP_DEPS=true
                shift
                ;;
            --api-url)
                API_URL="$2"
                shift 2
                ;;
            --upload-to-cos)
                UPLOAD_TO_COS=true
                shift
                ;;
            --deploy-miniprogram)
                DEPLOY_MINIPROGRAM=true
                shift
                ;;
            *)
                error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 检查环境
check_environment() {
    log "检查构建环境..."
    
    # 检查Node.js
    if ! command -v node &> /dev/null; then
        error "Node.js未安装"
        exit 1
    fi
    
    NODE_VERSION=$(node --version)
    info "Node.js版本: $NODE_VERSION"
    
    # 检查npm
    if ! command -v npm &> /dev/null; then
        error "npm未安装"
        exit 1
    fi
    
    NPM_VERSION=$(npm --version)
    info "npm版本: $NPM_VERSION"
    
    # 检查前端目录
    if [ ! -d "$FRONTEND_DIR" ]; then
        error "前端目录不存在: $FRONTEND_DIR"
        exit 1
    fi
    
    success "环境检查通过"
}

# 安装依赖
install_dependencies() {
    if [ "$SKIP_DEPS" = true ]; then
        info "跳过依赖安装"
        return
    fi
    
    log "安装前端依赖..."
    
    cd "$FRONTEND_DIR"
    
    # 清理node_modules和lock文件
    if [ "$CLEAN" = true ]; then
        log "清理现有依赖..."
        rm -rf node_modules package-lock.json yarn.lock
    fi
    
    # 安装依赖
    npm install --legacy-peer-deps --production=false
    
    success "依赖安装完成"
}

# 检查uni-app版本
check_uniapp_version() {
    log "检查uni-app版本..."
    
    cd "$FRONTEND_DIR"
    
    # 检查package.json中的uni-app版本
    local uniapp_version=$(node -p "require('./package.json').dependencies['@dcloudio/uni-app']" 2>/dev/null || echo "unknown")
    info "uni-app版本: $uniapp_version"
    
    # 检查是否是最新版本
    if [[ "$uniapp_version" == *"4060620250520001"* ]]; then
        success "uni-app已是最新版本"
    else
        warn "uni-app版本较旧，建议升级"
    fi
}

# 配置环境变量
configure_environment() {
    log "配置构建环境变量..."
    
    cd "$FRONTEND_DIR"
    
    # 设置API基础URL
    if [ -n "$API_URL" ]; then
        API_BASE_URL="$API_URL"
    else
        case $ENV in
            "dev")
                API_BASE_URL="http://localhost:8080/api"
                ;;
            "test")
                API_BASE_URL="https://test-api.fortune.com/api"
                ;;
            "prod")
                API_BASE_URL="https://api.fortune.com/api"
                ;;
            *)
                error "未知环境: $ENV"
                exit 1
                ;;
        esac
    fi
    
    info "API基础URL: $API_BASE_URL"
    
    # 更新request.ts配置
    if [ -f "src/utils/request.ts" ]; then
        # 使用sed替换API URL
        sed -i.bak "s|private baseURL = '[^']*'|private baseURL = '$API_BASE_URL'|g" src/utils/request.ts
        success "API配置已更新"
    else
        warn "request.ts文件不存在，跳过API配置"
    fi
    
    # 设置环境变量
    export NODE_ENV="production"
    export UNI_PLATFORM="$PLATFORM"
    export API_BASE_URL="$API_BASE_URL"
    
    success "环境配置完成"
}

# 构建H5版本
build_h5() {
    log "构建H5版本..."
    
    cd "$FRONTEND_DIR"
    
    # 执行H5构建
    npm run build:h5
    
    # 检查构建结果
    if [ -d "dist/build/h5" ]; then
        local build_size=$(du -sh dist/build/h5 | cut -f1)
        success "H5构建完成，大小: $build_size"
        
        # 生成构建信息
        cat > "dist/build/h5/build-info.json" << EOF
{
  "buildTime": "$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)",
  "environment": "$ENV",
  "platform": "h5",
  "apiUrl": "$API_BASE_URL",
  "version": "$(node -p "require('./package.json').version" 2>/dev/null || echo "unknown")",
  "nodeVersion": "$(node --version)",
  "npmVersion": "$(npm --version)",
  "uniappVersion": "$(node -p "require('./package.json').dependencies['@dcloudio/uni-app']" 2>/dev/null || echo "unknown")"
}
EOF
        
    else
        error "H5构建失败"
        exit 1
    fi
}

# 构建微信小程序版本
build_miniprogram() {
    log "构建微信小程序版本..."
    
    cd "$FRONTEND_DIR"
    
    # 执行微信小程序构建
    npm run build:mp-weixin
    
    # 检查构建结果
    if [ -d "dist/build/mp-weixin" ]; then
        local build_size=$(du -sh dist/build/mp-weixin | cut -f1)
        success "微信小程序构建完成，大小: $build_size"
        
        # 生成构建信息
        cat > "dist/build/mp-weixin/build-info.json" << EOF
{
  "buildTime": "$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)",
  "environment": "$ENV",
  "platform": "mp-weixin",
  "apiUrl": "$API_BASE_URL",
  "version": "$(node -p "require('./package.json').version" 2>/dev/null || echo "unknown")",
  "nodeVersion": "$(node --version)",
  "npmVersion": "$(npm --version)",
  "uniappVersion": "$(node -p "require('./package.json').dependencies['@dcloudio/uni-app']" 2>/dev/null || echo "unknown")",
  "appId": "$(node -p "require('./dist/build/mp-weixin/project.config.json').appid" 2>/dev/null || echo "unknown")"
}
EOF
        
        # 检查关键文件
        local key_files=("app.js" "app.json" "app.wxss" "project.config.json")
        for file in "${key_files[@]}"; do
            if [ -f "dist/build/mp-weixin/$file" ]; then
                info "✓ $file"
            else
                error "✗ $file (缺失)"
            fi
        done
        
    else
        error "微信小程序构建失败"
        exit 1
    fi
}

# 执行构建
execute_build() {
    log "开始执行构建..."
    
    case $PLATFORM in
        "h5")
            build_h5
            ;;
        "mp-weixin")
            build_miniprogram
            ;;
        "all")
            build_h5
            build_miniprogram
            ;;
        *)
            error "不支持的平台: $PLATFORM"
            exit 1
            ;;
    esac
    
    success "构建执行完成"
}

# 优化构建产物
optimize_build() {
    log "优化构建产物..."
    
    cd "$FRONTEND_DIR"
    
    # 压缩静态资源
    if [ -d "dist/build/h5" ]; then
        info "压缩H5静态资源..."
        find dist/build/h5 -name "*.js" -exec gzip -k {} \; 2>/dev/null || true
        find dist/build/h5 -name "*.css" -exec gzip -k {} \; 2>/dev/null || true
        find dist/build/h5 -name "*.html" -exec gzip -k {} \; 2>/dev/null || true
    fi
    
    # 生成文件清单
    if [ -d "dist/build" ]; then
        find dist/build -type f -exec ls -lh {} \; > dist/build/file-manifest.txt
        info "已生成文件清单: dist/build/file-manifest.txt"
    fi
    
    success "构建优化完成"
}

# 上传到腾讯云COS
upload_to_cos() {
    if [ "$UPLOAD_TO_COS" != true ]; then
        return
    fi
    
    log "上传静态资源到腾讯云COS..."
    
    # 检查coscli工具
    if ! command -v coscli &> /dev/null; then
        warn "coscli工具未安装，跳过COS上传"
        return
    fi
    
    cd "$FRONTEND_DIR"
    
    if [ -d "dist/build/h5" ]; then
        # 上传H5静态资源
        coscli sync dist/build/h5/ cos://fortune-static/h5/ --include "*.js,*.css,*.html,*.png,*.jpg,*.ico"
        success "H5静态资源上传完成"
    fi
    
    success "COS上传完成"
}

# 自动部署微信小程序
deploy_miniprogram() {
    if [ "$DEPLOY_MINIPROGRAM" != true ]; then
        return
    fi
    
    log "自动部署微信小程序..."
    
    # 检查微信开发者工具CLI
    if ! command -v wx-cli &> /dev/null; then
        warn "微信开发者工具CLI未安装，跳过自动部署"
        return
    fi
    
    cd "$FRONTEND_DIR"
    
    if [ -d "dist/build/mp-weixin" ]; then
        # 预览版本
        wx-cli preview --project dist/build/mp-weixin --desc "自动构建 $(date '+%Y-%m-%d %H:%M:%S')"
        success "微信小程序预览版本生成完成"
    fi
    
    success "微信小程序部署完成"
}

# 生成构建报告
generate_build_report() {
    log "生成构建报告..."
    
    cd "$FRONTEND_DIR"
    
    local report_file="dist/build-report-$(date +%Y%m%d_%H%M%S).json"
    
    cat > "$report_file" << EOF
{
  "buildInfo": {
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)",
    "environment": "$ENV",
    "platform": "$PLATFORM",
    "version": "$(node -p "require('./package.json').version" 2>/dev/null || echo "unknown")",
    "nodeVersion": "$(node --version)",
    "npmVersion": "$(npm --version)",
    "uniappVersion": "$(node -p "require('./package.json').dependencies['@dcloudio/uni-app']" 2>/dev/null || echo "unknown")"
  },
  "configuration": {
    "apiUrl": "$API_BASE_URL",
    "cleanBuild": $CLEAN,
    "skipDeps": $SKIP_DEPS,
    "uploadToCos": $UPLOAD_TO_COS,
    "deployMiniprogram": $DEPLOY_MINIPROGRAM
  },
  "buildResults": {
EOF

    # H5构建结果
    if [ -d "dist/build/h5" ]; then
        local h5_size=$(du -s dist/build/h5 | cut -f1)
        cat >> "$report_file" << EOF
    "h5": {
      "success": true,
      "size": $h5_size,
      "path": "dist/build/h5"
    },
EOF
    else
        cat >> "$report_file" << EOF
    "h5": {
      "success": false,
      "error": "Build directory not found"
    },
EOF
    fi

    # 微信小程序构建结果
    if [ -d "dist/build/mp-weixin" ]; then
        local mp_size=$(du -s dist/build/mp-weixin | cut -f1)
        cat >> "$report_file" << EOF
    "mp-weixin": {
      "success": true,
      "size": $mp_size,
      "path": "dist/build/mp-weixin"
    }
EOF
    else
        cat >> "$report_file" << EOF
    "mp-weixin": {
      "success": false,
      "error": "Build directory not found"
    }
EOF
    fi

    cat >> "$report_file" << EOF
  },
  "logFile": "$LOG_FILE"
}
EOF
    
    success "构建报告已生成: $report_file"
}

# 显示构建结果
show_build_result() {
    success "🎉 前端构建完成!"
    
    echo
    echo "=================="
    echo "   构建信息汇总"
    echo "=================="
    echo "环境: $ENV"
    echo "平台: $PLATFORM"
    echo "API URL: $API_BASE_URL"
    echo "日志文件: $LOG_FILE"
    echo
    
    echo "=================="
    echo "   构建产物"
    echo "=================="
    
    cd "$FRONTEND_DIR"
    
    if [ -d "dist/build/h5" ]; then
        local h5_size=$(du -sh dist/build/h5 | cut -f1)
        echo "H5版本: dist/build/h5 ($h5_size)"
    fi
    
    if [ -d "dist/build/mp-weixin" ]; then
        local mp_size=$(du -sh dist/build/mp-weixin | cut -f1)
        echo "微信小程序: dist/build/mp-weixin ($mp_size)"
    fi
    
    echo
    echo "=================="
    echo "   部署说明"
    echo "=================="
    echo "H5版本部署:"
    echo "  1. 将 dist/build/h5 目录内容上传到Web服务器"
    echo "  2. 配置Nginx指向该目录"
    echo ""
    echo "微信小程序部署:"
    echo "  1. 打开微信开发者工具"
    echo "  2. 导入项目: $(pwd)/dist/build/mp-weixin"
    echo "  3. 上传代码并提交审核"
    echo
}

# 主函数
main() {
    echo -e "${PURPLE}"
    cat << 'EOF'
 ╔═══════════════════════════════════════════════════════════════╗
 ║                    八卦运势小程序                             ║
 ║                前端生产环境构建脚本 v2.0.0                    ║
 ║                                                               ║
 ║   支持H5和微信小程序双端构建部署                              ║
 ║   基于uni-app 3.0最新版本                                    ║
 ╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    # 解析命令行参数
    parse_args "$@"
    
    # 执行构建流程
    check_environment
    install_dependencies
    check_uniapp_version
    configure_environment
    execute_build
    optimize_build
    upload_to_cos
    deploy_miniprogram
    generate_build_report
    show_build_result
    
    success "前端构建脚本执行完成！"
}

# 执行主函数
main "$@" 
#!/bin/bash

# AI八卦运势小程序 - 腾讯云Docker环境一键部署脚本
# 适用于腾讯云预装Docker的Ubuntu镜像
# 使用方法: sudo ./scripts/deploy-wechat-miniprogram.sh

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
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

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 检查Node.js环境
check_nodejs() {
    log_step "检查Node.js环境..."
    
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
    
    NPM_VERSION=$(npm --version)
    log_info "npm版本: $NPM_VERSION"
}

# 安装前端依赖
install_dependencies() {
    log_step "检查前端依赖..."
    
    cd frontend
    
    if [ ! -d "node_modules" ]; then
        log_info "安装前端依赖..."
        npm install
    else
        log_info "依赖已存在，跳过安装"
    fi
    
    cd ..
}

# 构建微信小程序版本
build_miniprogram() {
    log_step "构建微信小程序版本..."
    
    cd frontend
    
    # 清理旧的构建
    if [ -d "dist/build/mp-weixin" ]; then
        rm -rf dist/build/mp-weixin
        log_info "清理旧的构建文件"
    fi
    
    # 构建微信小程序版本
    log_info "开始构建微信小程序..."
    npm run build:mp-weixin
    
    if [ ! -d "dist/build/mp-weixin" ]; then
        log_error "微信小程序构建失败！检查构建错误信息"
        exit 1
    fi
    
    if [ ! -f "dist/build/mp-weixin/app.json" ]; then
        log_error "构建产物不完整！app.json文件不存在"
        exit 1
    fi
    
    log_info "微信小程序构建成功！"
    log_info "构建产物位置: frontend/dist/build/mp-weixin/"
    
    cd ..
}

# 验证构建结果
verify_build() {
    log_step "验证构建结果..."
    
    local build_dir="frontend/dist/build/mp-weixin"
    
    # 检查关键文件
    local required_files=("app.json" "app.js" "app.wxss" "project.config.json")
    
    for file in "${required_files[@]}"; do
        if [ -f "$build_dir/$file" ]; then
            log_info "✅ $file 存在"
        else
            log_error "❌ $file 不存在"
            exit 1
        fi
    done
    
    # 检查页面文件
    if [ -d "$build_dir/pages" ]; then
        log_info "✅ pages目录存在"
        local page_count=$(find "$build_dir/pages" -name "*.wxml" | wc -l)
        log_info "📄 页面数量: $page_count"
    else
        log_warning "⚠️  pages目录不存在"
    fi
    
    # 显示构建目录内容
    echo ""
    log_info "微信小程序构建产物内容："
    ls -la "$build_dir/"
    
    echo ""
    log_info "项目配置文件内容预览："
    if [ -f "$build_dir/project.config.json" ]; then
        head -10 "$build_dir/project.config.json"
    fi
}

# 检查项目配置
check_project_config() {
    log_step "检查项目配置..."
    
    local config_file="frontend/dist/build/mp-weixin/project.config.json"
    
    if [ -f "$config_file" ]; then
        # 检查AppID配置
        if grep -q "appid" "$config_file"; then
            local appid=$(grep "appid" "$config_file" | head -1)
            log_info "微信小程序AppID: $appid"
        else
            log_warning "⚠️  未找到AppID配置"
        fi
        
        # 检查项目名称
        if grep -q "projectname" "$config_file"; then
            local project_name=$(grep "projectname" "$config_file" | head -1)
            log_info "项目名称: $project_name"
        fi
    else
        log_error "项目配置文件不存在"
        exit 1
    fi
}

# 生成部署报告
generate_deploy_report() {
    log_step "生成部署报告..."
    
    local build_dir="frontend/dist/build/mp-weixin"
    local report_file="WECHAT_MINIPROGRAM_DEPLOY_REPORT.md"
    
    cat > "$report_file" << EOF
# 微信小程序部署报告

## 📱 项目信息
- **项目名称**: AI八卦运势小程序
- **构建时间**: $(date '+%Y-%m-%d %H:%M:%S')
- **构建版本**: $(date '+%Y%m%d%H%M%S')
- **Node.js版本**: $(node --version)
- **npm版本**: $(npm --version)

## 📁 构建产物位置
\`\`\`
$(pwd)/$build_dir/
\`\`\`

## 📋 文件清单
\`\`\`
$(ls -la "$build_dir/")
\`\`\`

## 📄 关键文件检查
$(for file in app.json app.js app.wxss project.config.json; do
    if [ -f "$build_dir/$file" ]; then
        echo "- ✅ $file"
    else
        echo "- ❌ $file (缺失)"
    fi
done)

## 📱 页面文件
$(if [ -d "$build_dir/pages" ]; then
    echo "页面总数: $(find "$build_dir/pages" -name "*.wxml" | wc -l)"
    echo ""
    echo "页面列表:"
    find "$build_dir/pages" -name "*.wxml" | sed 's/.*\/pages\//- pages\//' | sed 's/\.wxml//'
else
    echo "❌ pages目录不存在"
fi)

## 🛠️ 微信开发者工具导入步骤

### 1. 打开微信开发者工具
- 确保已安装微信开发者工具
- 选择"小程序"项目类型

### 2. 导入项目
- 项目目录: \`$(pwd)/$build_dir\`
- AppID: 从project.config.json中获取
- 项目名称: AI八卦运势小程序

### 3. 配置验证
- 检查页面是否正常显示
- 验证API接口配置
- 测试基本功能

### 4. 上传发布
- 在开发者工具中点击"上传"
- 填写版本号和备注
- 登录微信公众平台进行审核

## 🔧 常见问题
1. **页面显示异常**: 检查页面路径配置
2. **API调用失败**: 检查服务器域名配置
3. **组件加载错误**: 检查组件引用路径

---
生成时间: $(date)
EOF

    log_info "部署报告已生成: $report_file"
}

# 显示微信开发者工具导入指南
show_import_guide() {
    echo ""
    echo "🎉 微信小程序构建完成！"
    echo ""
    echo "📱 下一步操作："
    echo "  1. 打开微信开发者工具"
    echo "  2. 选择'导入项目'"
    echo "  3. 项目目录: $(pwd)/frontend/dist/build/mp-weixin"
    echo "  4. AppID: [请配置您的AppID] (从project.config.json获取)"
    echo "  5. 项目名称: AI八卦运势小程序"
    echo ""
    echo "🔗 重要文件路径："
    echo "  - 项目配置: frontend/dist/build/mp-weixin/project.config.json"
    echo "  - 应用配置: frontend/dist/build/mp-weixin/app.json"
    echo "  - 页面文件: frontend/dist/build/mp-weixin/pages/"
    echo ""
    echo "📋 检查清单："
    echo "  - [ ] 微信开发者工具可以正常导入项目"
    echo "  - [ ] 项目在模拟器中正常显示"
    echo "  - [ ] 页面跳转功能正常"
    echo "  - [ ] API接口连接正常（需配置服务器域名）"
    echo ""
    echo "🚀 发布流程："
    echo "  1. 在开发者工具中测试功能"
    echo "  2. 点击'上传'按钮"
    echo "  3. 登录微信公众平台"
    echo "  4. 提交审核"
    echo "  5. 审核通过后发布"
    echo ""
    echo "📖 详细文档: 查看生成的 WECHAT_MINIPROGRAM_DEPLOY_REPORT.md"
}

# 构建Web版本（可选）
build_h5_version() {
    if [ "${BUILD_H5:-false}" == "true" ]; then
        log_step "同时构建H5版本..."
        
        cd frontend
        
        # 清理旧的H5构建
        if [ -d "dist/build/h5" ]; then
            rm -rf dist/build/h5
        fi
        
        # 构建H5版本
        npm run build:h5
        
        if [ -d "dist/build/h5" ]; then
            log_info "✅ H5版本构建成功: frontend/dist/build/h5/"
        else
            log_warning "⚠️  H5版本构建失败"
        fi
        
        cd ..
    fi
}

# 主函数
main() {
    echo "🚀 开始构建AI八卦运势微信小程序..."
    echo ""
    
    check_nodejs
    install_dependencies
    build_miniprogram
    verify_build
    check_project_config
    build_h5_version
    generate_deploy_report
    show_import_guide
    
    echo ""
    log_info "微信小程序构建流程完成！"
}

# 错误处理
trap 'log_error "构建过程中发生错误！请检查错误信息"; exit 1' ERR

# 处理命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --with-h5)
            export BUILD_H5=true
            shift
            ;;
        --help)
            echo "用法: $0 [选项]"
            echo "选项:"
            echo "  --with-h5    同时构建H5版本"
            echo "  --help       显示帮助信息"
            exit 0
            ;;
        *)
            log_error "未知参数: $1"
            exit 1
            ;;
    esac
done

# 执行主函数
main "$@" 
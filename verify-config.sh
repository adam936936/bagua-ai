#!/bin/bash

# 配置验证脚本
# 用于检查生产环境配置是否完整

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

# 检查配置文件是否存在
if [ ! -f "config/prod.env" ]; then
    log_error "配置文件不存在: config/prod.env"
    exit 1
fi

log_info "🔍 验证生产环境配置..."

# 加载环境变量
source config/prod.env

# 检查必需的配置项
check_config() {
    local var_name=$1
    local var_value=$2
    local is_required=${3:-true}
    
    if [ -z "$var_value" ]; then
        if [ "$is_required" = true ]; then
            log_error "缺少必需配置: $var_name"
            return 1
        else
            log_warning "可选配置未设置: $var_name"
        fi
    else
        # 检查是否为默认值或示例值
        case "$var_name" in
            "DEEPSEEK_API_KEY")
                if [[ "$var_value" == *"your-deepseek-api-key"* ]] || [[ "$var_value" == "sk-test-key"* ]]; then
                    log_warning "$var_name 使用的是示例值，请设置真实的API密钥"
                else
                    log_success "$var_name ✓"
                fi
                ;;
            "WECHAT_APP_ID")
                if [[ "$var_value" == *"your-app-id"* ]] || [[ "$var_value" == "wx-your-app"* ]]; then
                    log_warning "$var_name 使用的是示例值，请设置真实的微信App ID"
                else
                    log_success "$var_name ✓"
                fi
                ;;
            "WECHAT_APP_SECRET")
                if [[ "$var_value" == *"your-app-secret"* ]]; then
                    log_warning "$var_name 使用的是示例值，请设置真实的微信App Secret"
                else
                    log_success "$var_name ✓"
                fi
                ;;
            *)
                log_success "$var_name ✓"
                ;;
        esac
    fi
}

error_count=0

# 检查数据库配置
log_info "检查数据库配置..."
check_config "MYSQL_ROOT_PASSWORD" "$MYSQL_ROOT_PASSWORD" || ((error_count++))
check_config "MYSQL_DATABASE" "$MYSQL_DATABASE" || ((error_count++))
check_config "MYSQL_USERNAME" "$MYSQL_USERNAME" || ((error_count++))
check_config "MYSQL_PASSWORD" "$MYSQL_PASSWORD" || ((error_count++))

# 检查Redis配置
log_info "检查Redis配置..."
check_config "REDIS_PASSWORD" "$REDIS_PASSWORD" || ((error_count++))

# 检查AI服务配置
log_info "检查AI服务配置..."
check_config "DEEPSEEK_API_KEY" "$DEEPSEEK_API_KEY" || ((error_count++))
check_config "DEEPSEEK_API_URL" "$DEEPSEEK_API_URL" || ((error_count++))

# 检查微信配置
log_info "检查微信配置..."
check_config "WECHAT_APP_ID" "$WECHAT_APP_ID" || ((error_count++))
check_config "WECHAT_APP_SECRET" "$WECHAT_APP_SECRET" || ((error_count++))

# 检查安全配置
log_info "检查安全配置..."
check_config "JWT_SECRET" "$JWT_SECRET" || ((error_count++))
check_config "ENCRYPTION_KEY" "$ENCRYPTION_KEY" || ((error_count++))

# 检查域名配置
log_info "检查域名配置..."
check_config "DOMAIN_NAME" "$DOMAIN_NAME" || ((error_count++))

# 检查文件存在性
log_info "检查必需文件..."
if [ ! -f "backend/target/fortune-mini-app-1.0.0.jar" ]; then
    log_error "JAR文件不存在: backend/target/fortune-mini-app-1.0.0.jar"
    ((error_count++))
else
    log_success "JAR文件存在 ✓"
fi

if [ ! -f "backend/complete-init.sql" ]; then
    log_error "数据库初始化文件不存在: backend/complete-init.sql"
    ((error_count++))
else
    log_success "数据库初始化文件存在 ✓"
fi

# 总结
echo ""
if [ $error_count -eq 0 ]; then
    log_success "🎉 配置验证通过！可以开始部署。"
    echo ""
    log_info "建议的部署命令:"
    echo "  chmod +x deploy-public.sh"
    echo "  ./deploy-public.sh"
else
    log_error "❌ 发现 $error_count 个配置问题，请修复后再部署。"
    exit 1
fi 
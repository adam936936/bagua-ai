#!/bin/bash

# 安全配置生成脚本
# 用于生成安全的生产环境配置

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

# 生成安全密码的函数
generate_password() {
    local length=${1:-32}
    openssl rand -base64 $length | tr -d "=+/" | cut -c1-$length
}

# 生成JWT密钥的函数
generate_jwt_secret() {
    openssl rand -base64 64 | tr -d "=+/" | cut -c1-64
}

log_info "🔐 开始生成安全的生产环境配置..."

# 检查是否存在配置文件
if [ -f "config/prod.env" ]; then
    log_warning "config/prod.env 已存在"
    read -p "是否覆盖现有配置？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "取消操作"
        exit 0
    fi
fi

# 复制模板文件
if [ ! -f "config/prod.env.template" ]; then
    log_error "模板文件不存在: config/prod.env.template"
    exit 1
fi

cp config/prod.env.template config/prod.env

# 生成安全密码
MYSQL_ROOT_PASSWORD="Fortune2025!$(generate_password 16)"
MYSQL_PASSWORD="BaguaUser2025!$(generate_password 12)"
REDIS_PASSWORD="Redis2025!$(generate_password 16)"
JWT_SECRET=$(generate_jwt_secret)
ENCRYPTION_KEY=$(generate_password 32)
GRAFANA_PASSWORD="Grafana2025!$(generate_password 12)"

# 获取用户输入
log_info "请输入以下配置信息："

read -p "域名或IP地址 (默认: localhost): " DOMAIN_NAME
DOMAIN_NAME=${DOMAIN_NAME:-localhost}

read -p "DeepSeek API密钥: " DEEPSEEK_API_KEY
if [ -z "$DEEPSEEK_API_KEY" ]; then
    log_warning "未输入DeepSeek API密钥，请稍后手动配置"
    DEEPSEEK_API_KEY="sk-your-deepseek-api-key-here"
fi

read -p "微信小程序App ID: " WECHAT_APP_ID
if [ -z "$WECHAT_APP_ID" ]; then
    log_warning "未输入微信App ID，请稍后手动配置"
    WECHAT_APP_ID="wx-your-app-id-here"
fi

read -p "微信小程序App Secret: " WECHAT_APP_SECRET
if [ -z "$WECHAT_APP_SECRET" ]; then
    log_warning "未输入微信App Secret，请稍后手动配置"
    WECHAT_APP_SECRET="your-app-secret-here"
fi

# 替换配置文件中的占位符
sed -i.bak "s|DOMAIN_NAME=your-domain-or-ip|DOMAIN_NAME=$DOMAIN_NAME|g" config/prod.env
sed -i.bak "s|MYSQL_ROOT_PASSWORD=your-secure-root-password|MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD|g" config/prod.env
sed -i.bak "s|MYSQL_PASSWORD=your-secure-user-password|MYSQL_PASSWORD=$MYSQL_PASSWORD|g" config/prod.env
sed -i.bak "s|REDIS_PASSWORD=your-secure-redis-password|REDIS_PASSWORD=$REDIS_PASSWORD|g" config/prod.env
sed -i.bak "s|JWT_SECRET=your-jwt-secret-key-at-least-32-characters-long|JWT_SECRET=$JWT_SECRET|g" config/prod.env
sed -i.bak "s|ENCRYPTION_KEY=your-encryption-key-for-sensitive-data|ENCRYPTION_KEY=$ENCRYPTION_KEY|g" config/prod.env
sed -i.bak "s|DEEPSEEK_API_KEY=sk-your-deepseek-api-key-here|DEEPSEEK_API_KEY=$DEEPSEEK_API_KEY|g" config/prod.env
sed -i.bak "s|WECHAT_APP_ID=wx-your-app-id-here|WECHAT_APP_ID=$WECHAT_APP_ID|g" config/prod.env
sed -i.bak "s|WECHAT_APP_SECRET=your-app-secret-here|WECHAT_APP_SECRET=$WECHAT_APP_SECRET|g" config/prod.env
sed -i.bak "s|GRAFANA_ADMIN_PASSWORD=your-secure-grafana-password|GRAFANA_ADMIN_PASSWORD=$GRAFANA_PASSWORD|g" config/prod.env

# 删除备份文件
rm -f config/prod.env.bak

# 设置文件权限
chmod 600 config/prod.env

log_success "✅ 安全配置文件已生成: config/prod.env"
log_warning "⚠️  重要提醒："
echo "1. 请妥善保管 config/prod.env 文件"
echo "2. 不要将此文件提交到版本控制系统"
echo "3. 如需备份，请使用加密存储"
echo "4. 定期更换密码和密钥"

echo ""
log_info "生成的配置信息："
echo "- 域名: $DOMAIN_NAME"
echo "- MySQL Root密码: [已生成]"
echo "- MySQL用户密码: [已生成]"
echo "- Redis密码: [已生成]"
echo "- JWT密钥: [已生成]"
echo "- 加密密钥: [已生成]"
echo "- Grafana密码: [已生成]"

if [ "$DEEPSEEK_API_KEY" = "sk-your-deepseek-api-key-here" ]; then
    log_warning "请手动配置DeepSeek API密钥"
fi

if [ "$WECHAT_APP_ID" = "wx-your-app-id-here" ]; then
    log_warning "请手动配置微信小程序App ID"
fi

if [ "$WECHAT_APP_SECRET" = "your-app-secret-here" ]; then
    log_warning "请手动配置微信小程序App Secret"
fi

echo ""
log_info "下一步操作："
echo "1. 运行配置验证: ./verify-config.sh"
echo "2. 启动部署: ./deploy-public.sh" 
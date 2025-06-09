#!/bin/bash

# 全面安全扫描脚本
# 用于检测项目中的敏感信息泄漏

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# 创建结果目录
SCAN_DATE=$(date +"%Y%m%d_%H%M%S")
SCAN_DIR="security_scan_${SCAN_DATE}"
mkdir -p "$SCAN_DIR"

echo "🔐 开始全面安全扫描..."
echo "扫描结果将保存到: $SCAN_DIR/"
echo ""

# 定义敏感信息模式
declare -A SENSITIVE_PATTERNS=(
    ["微信AppID"]="wx[a-z0-9]{16}"
    ["微信AppSecret"]="[a-z0-9]{32}"
    ["API_KEY"]="sk-[a-zA-Z0-9]{40,}"
    ["JWT_SECRET"]="FortuneJWT.*"
    ["密码明文"]="password.*=.*[^{].*[a-zA-Z0-9!@#$%^&*()_+-=]{8,}"
    ["MySQL密码"]="MYSQL_.*PASSWORD.*=.*[^{].*"
    ["Redis密码"]="REDIS_PASSWORD.*=.*[^{].*"
    ["商户号"]="mch.*id.*=.*[0-9]{8,}"
    ["支付密钥"]="pay.*key.*=.*[a-zA-Z0-9]{16,}"
    ["私钥文件"]="-----BEGIN.*PRIVATE.*KEY-----"
    ["证书文件"]="-----BEGIN.*CERTIFICATE-----"
    ["邮箱地址"]="[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"
    ["IP地址"]="[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"
    ["数据库连接"]="jdbc:.*://.*"
    ["硬编码Token"]="['\"].*token.*['\"].*:.*['\"][a-zA-Z0-9]{20,}['\"]"
)

# 扫描函数
scan_sensitive_info() {
    local pattern_name="$1"
    local pattern="$2"
    local output_file="$SCAN_DIR/${pattern_name}_results.txt"
    
    log_info "扫描 $pattern_name..."
    
    # 使用grep扫描，排除二进制文件和备份目录
    grep -r -i -E "$pattern" . \
        --exclude-dir=.git \
        --exclude-dir=node_modules \
        --exclude-dir=backup \
        --exclude-dir=target \
        --exclude-dir=build \
        --exclude-dir=dist \
        --exclude="*.class" \
        --exclude="*.jar" \
        --exclude="*.war" \
        --exclude="*.log" \
        --exclude="*.jpg" \
        --exclude="*.png" \
        --exclude="*.gif" \
        --exclude="*.pdf" \
        --exclude="*.zip" \
        --exclude="*.tar.gz" \
        > "$output_file" 2>/dev/null
    
    local count=$(wc -l < "$output_file" 2>/dev/null || echo "0")
    if [ "$count" -gt 0 ]; then
        log_error "发现 $count 处 $pattern_name 泄漏"
        echo "详细信息已保存到: $output_file"
    else
        log_success "$pattern_name - 安全"
        rm "$output_file" 2>/dev/null
    fi
}

# 执行扫描
for pattern_name in "${!SENSITIVE_PATTERNS[@]}"; do
    scan_sensitive_info "$pattern_name" "${SENSITIVE_PATTERNS[$pattern_name]}"
done

# 特殊检查：配置文件
log_info "检查配置文件..."
find . -name "*.properties" -o -name "*.yml" -o -name "*.yaml" -o -name "*.json" -o -name "*.env*" | \
    grep -v -E "(node_modules|backup|target|build|dist)" | \
    while read file; do
        if grep -q -E "(password|secret|key|token)" "$file" 2>/dev/null; then
            echo "$file" >> "$SCAN_DIR/config_files_with_secrets.txt"
        fi
    done

# 检查Git历史中的敏感信息
log_info "检查Git历史..."
if command -v git &> /dev/null && git rev-parse --git-dir > /dev/null 2>&1; then
    git log --all --full-history --source -- \
        | grep -i -E "(password|secret|key|token|appid)" \
        > "$SCAN_DIR/git_history_secrets.txt" 2>/dev/null || true
fi

# 检查环境变量
log_info "检查环境变量..."
env | grep -i -E "(password|secret|key|token)" > "$SCAN_DIR/env_variables.txt" 2>/dev/null || true

# 生成报告
log_info "生成安全扫描报告..."
cat > "$SCAN_DIR/security_scan_report.md" << EOF
# 安全扫描报告

**扫描时间**: $(date)
**项目路径**: $(pwd)

## 📋 扫描摘要

EOF

# 统计结果
total_issues=0
for file in "$SCAN_DIR"/*_results.txt; do
    if [ -f "$file" ]; then
        filename=$(basename "$file" .txt)
        count=$(wc -l < "$file")
        total_issues=$((total_issues + count))
        echo "- **${filename}**: $count 处问题" >> "$SCAN_DIR/security_scan_report.md"
    fi
done

cat >> "$SCAN_DIR/security_scan_report.md" << EOF

**总计**: $total_issues 处潜在安全问题

## 🚨 高危问题

$(if [ -f "$SCAN_DIR/微信AppID_results.txt" ]; then echo "### 微信AppID泄漏"; cat "$SCAN_DIR/微信AppID_results.txt"; fi)
$(if [ -f "$SCAN_DIR/微信AppSecret_results.txt" ]; then echo "### 微信AppSecret泄漏"; cat "$SCAN_DIR/微信AppSecret_results.txt"; fi)
$(if [ -f "$SCAN_DIR/API_KEY_results.txt" ]; then echo "### API密钥泄漏"; cat "$SCAN_DIR/API_KEY_results.txt"; fi)

## 🔧 修复建议

1. **立即更换泄漏的密钥**
2. **使用环境变量管理敏感配置**
3. **更新.gitignore文件**
4. **从Git历史中移除敏感信息**
5. **定期轮换密钥**

## 📞 需要立即处理的文件

$(if [ -f "$SCAN_DIR/config_files_with_secrets.txt" ]; then cat "$SCAN_DIR/config_files_with_secrets.txt"; fi)

EOF

# 显示结果
echo ""
echo "🔍 安全扫描完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $total_issues -eq 0 ]; then
    log_success "🎉 未发现敏感信息泄漏"
else
    log_error "⚠️  发现 $total_issues 处潜在安全问题"
    echo ""
    echo "📊 详细报告："
    echo "  - 完整报告: $SCAN_DIR/security_scan_report.md"
    echo "  - 问题详情: $SCAN_DIR/*_results.txt"
    echo ""
    echo "🚨 建议立即处理以下高危问题："
    
    # 显示高危问题
    for critical in "微信AppID" "微信AppSecret" "API_KEY" "JWT_SECRET"; do
        if [ -f "$SCAN_DIR/${critical}_results.txt" ]; then
            echo ""
            log_error "[$critical]"
            head -5 "$SCAN_DIR/${critical}_results.txt" | sed 's/^/  /'
            local count=$(wc -l < "$SCAN_DIR/${critical}_results.txt")
            if [ $count -gt 5 ]; then
                echo "  ... 还有 $((count - 5)) 处类似问题"
            fi
        fi
    done
fi

echo ""
echo "🛡️  安全建议："
echo "  1. 立即轮换所有泄漏的密钥"
echo "  2. 配置环境变量管理敏感信息"
echo "  3. 更新.gitignore防止未来泄漏"
echo "  4. 使用git filter-branch清理历史"
echo "  5. 定期运行此脚本检查"

# 设置权限
chmod 600 "$SCAN_DIR"/* 
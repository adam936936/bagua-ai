#!/bin/bash

# 八卦运势小程序 - 自动安全检查脚本
# 用于CI/CD环境中预防敏感信息泄漏
# 创建日期: 2025-06-11

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 当前时间
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 检查结果
ISSUES_FOUND=0

echo "🔒 八卦运势小程序 - 自动安全检查"
echo "=================================="
echo "检查时间: $TIMESTAMP"
echo ""

# 重要目录和文件模式
DIRS_TO_CHECK=(
    "frontend/src"
    "backend/src"
    "frontend/project.config.json"
    "backend/src/main/resources"
    "*.md"
    "*.yml"
    "*.yaml"
    "*.json"
    "*.properties"
)

# 文件类型
FILE_TYPES=(
    "*.js"
    "*.ts" 
    "*.json" 
    "*.java"
    "*.properties"
    "*.yml"
    "*.yaml"
    "*.md"
)

# 敏感信息模式
declare -A PATTERNS=(
    ["微信AppID"]="wx[a-z0-9]\{16\}"
    ["微信AppSecret"]="[a-f0-9]\{32\}"
    ["API密钥"]="sk-[a-zA-Z0-9]\{32,\}"
    ["密码"]="password.*=.*[a-zA-Z0-9]\{8,\}"
)

# 安全检查函数
check_pattern() {
    local name="$1"
    local pattern="$2"
    local exclude_pattern="${3:-NONE}"
    
    echo -e "🔍 检查 ${BLUE}$name${NC}..."
    
    for dir in "${DIRS_TO_CHECK[@]}"; do
        for type in "${FILE_TYPES[@]}"; do
            if [ "$exclude_pattern" = "NONE" ]; then
                MATCHES=$(grep -r "$pattern" "$dir" --include="$type" 2>/dev/null)
            else
                MATCHES=$(grep -r "$pattern" "$dir" --include="$type" | grep -v "$exclude_pattern" 2>/dev/null)
            fi
            
            if [ -n "$MATCHES" ]; then
                echo -e "${RED}❌ 发现 $name 泄露:${NC}"
                echo "$MATCHES" | head -3
                if [ $(echo "$MATCHES" | wc -l) -gt 3 ]; then
                    echo "... 更多结果已省略"
                fi
                ISSUES_FOUND=$((ISSUES_FOUND + 1))
                return 1
            fi
        done
    done
    
    echo -e "${GREEN}✅ 未发现 $name 泄露${NC}"
    return 0
}

# 执行安全检查
for name in "${!PATTERNS[@]}"; do
    pattern="${PATTERNS[$name]}"
    # 允许带有占位符的配置
    check_pattern "$name" "$pattern" "PLACEHOLDER"
done

# 检查.gitignore配置
echo -e "\n🔍 检查 ${BLUE}.gitignore${NC} 配置..."
if [ -f ".gitignore" ]; then
    REQUIRED_PATTERNS=(
        "\.env"
        "\.env\."
        "application-local"
        "application-secret"
        "config/local\.js"
    )
    
    MISSING_PATTERNS=0
    for pattern in "${REQUIRED_PATTERNS[@]}"; do
        if ! grep -q "$pattern" .gitignore; then
            echo -e "${RED}❌ .gitignore 缺少: $pattern${NC}"
            MISSING_PATTERNS=$((MISSING_PATTERNS + 1))
        fi
    done
    
    if [ $MISSING_PATTERNS -gt 0 ]; then
        echo -e "${RED}❌ .gitignore 配置不完善${NC}"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    else
        echo -e "${GREEN}✅ .gitignore 配置完善${NC}"
    fi
else
    echo -e "${RED}❌ .gitignore 文件不存在${NC}"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# 检查环境变量文件
echo -e "\n🔍 检查 ${BLUE}环境变量${NC} 文件..."
ENV_FILES=$(find . -name ".env*" -not -path "*/\.*" -not -name ".env.template" -not -name ".env.example" 2>/dev/null)
if [ -n "$ENV_FILES" ]; then
    echo -e "${RED}❌ 发现环境变量文件:${NC}"
    echo "$ENV_FILES"
    echo -e "${YELLOW}⚠️  环境变量文件不应提交到版本控制系统${NC}"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo -e "${GREEN}✅ 未发现环境变量文件${NC}"
fi

# 总结
echo -e "\n📊 安全检查结果"
echo "=================================="
echo "检查时间: $TIMESTAMP"

if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}🎉 恭喜！未发现安全问题${NC}"
    echo "代码可以安全提交"
    exit 0
else
    echo -e "${RED}⚠️  发现 $ISSUES_FOUND 个安全问题${NC}"
    echo -e "${RED}❌ 请修复上述问题后再提交代码${NC}"
    exit 1
fi 
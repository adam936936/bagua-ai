#!/bin/bash

echo "🔒 安全检查脚本 - 检测敏感信息泄露"
echo "=================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查结果统计
ISSUES_FOUND=0

echo -e "${BLUE}1. 检查API密钥泄露${NC}"
echo "--------------------"

# 检查sk-开头的密钥
echo "🔍 检查DeepSeek API密钥..."
SK_KEYS=$(grep -r "sk-[a-zA-Z0-9]\{32,\}" . --exclude-dir=.git --exclude-dir=node_modules --exclude="*.md" --exclude="security-check.sh" --exclude="package-lock.json" 2>/dev/null)

if [ -n "$SK_KEYS" ]; then
    echo -e "${RED}❌ 发现可能的API密钥泄露：${NC}"
    echo "$SK_KEYS"
    ((ISSUES_FOUND++))
else
    echo -e "${GREEN}✅ 未发现sk-开头的API密钥${NC}"
fi

echo ""
echo -e "${BLUE}2. 检查配置文件中的敏感信息${NC}"
echo "-----------------------------"

# 检查配置文件中的硬编码密钥
echo "🔍 检查配置文件..."
CONFIG_ISSUES=$(grep -r "api-key:.*sk-" . --include="*.yml" --include="*.yaml" --include="*.properties" 2>/dev/null)

if [ -n "$CONFIG_ISSUES" ]; then
    echo -e "${RED}❌ 发现配置文件中的硬编码密钥：${NC}"
    echo "$CONFIG_ISSUES"
    ((ISSUES_FOUND++))
else
    echo -e "${GREEN}✅ 配置文件中未发现硬编码密钥${NC}"
fi

echo ""
echo -e "${BLUE}3. 检查环境变量文件${NC}"
echo "--------------------"

# 检查.env文件
echo "🔍 检查.env文件..."
ENV_FILES=$(find . -name ".env*" -not -path "./.git/*" 2>/dev/null)

if [ -n "$ENV_FILES" ]; then
    echo -e "${YELLOW}⚠️  发现环境变量文件：${NC}"
    echo "$ENV_FILES"
    
    # 检查.env文件是否在.gitignore中
    if grep -q "\.env" .gitignore 2>/dev/null; then
        echo -e "${GREEN}✅ .env文件已在.gitignore中${NC}"
    else
        echo -e "${RED}❌ .env文件未在.gitignore中${NC}"
        ((ISSUES_FOUND++))
    fi
else
    echo -e "${GREEN}✅ 未发现.env文件${NC}"
fi

echo ""
echo -e "${BLUE}4. 检查其他敏感信息${NC}"
echo "--------------------"

# 检查密码、token等
echo "🔍 检查其他敏感信息..."
SENSITIVE_PATTERNS=(
    "password.*=.*[^{]"
    "token.*=.*[^{]"
    "secret.*=.*[^{]"
    "key.*=.*[^{]"
)

for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    MATCHES=$(grep -ri "$pattern" . --exclude-dir=.git --exclude-dir=node_modules --exclude="*.md" --exclude="security-check.sh" 2>/dev/null | grep -v "your-" | grep -v "placeholder" | grep -v "example")
    
    if [ -n "$MATCHES" ]; then
        echo -e "${YELLOW}⚠️  发现可能的敏感信息（模式: $pattern）：${NC}"
        echo "$MATCHES"
    fi
done

echo ""
echo -e "${BLUE}5. 检查.gitignore配置${NC}"
echo "--------------------"

if [ -f ".gitignore" ]; then
    echo -e "${GREEN}✅ .gitignore文件存在${NC}"
    
    # 检查关键模式
    GITIGNORE_PATTERNS=(
        "\.env"
        "\*\.key"
        "\*\.pem"
        "application-local\.yml"
        "application-secret\.yml"
    )
    
    for pattern in "${GITIGNORE_PATTERNS[@]}"; do
        if grep -q "$pattern" .gitignore; then
            echo -e "${GREEN}✅ .gitignore包含模式: $pattern${NC}"
        else
            echo -e "${YELLOW}⚠️  .gitignore缺少模式: $pattern${NC}"
        fi
    done
else
    echo -e "${RED}❌ .gitignore文件不存在${NC}"
    ((ISSUES_FOUND++))
fi

echo ""
echo -e "${BLUE}6. Git历史检查${NC}"
echo "----------------"

if [ -d ".git" ]; then
    echo "🔍 检查Git历史中的敏感信息..."
    
    # 检查最近10次提交中是否包含API密钥
    GIT_HISTORY_ISSUES=$(git log --oneline -10 | xargs -I {} git show {} | grep -E "sk-[a-zA-Z0-9]{32,}" 2>/dev/null)
    
    if [ -n "$GIT_HISTORY_ISSUES" ]; then
        echo -e "${RED}❌ Git历史中发现API密钥！需要清理历史记录${NC}"
        ((ISSUES_FOUND++))
    else
        echo -e "${GREEN}✅ 最近10次提交中未发现API密钥${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  不是Git仓库${NC}"
fi

echo ""
echo "=================================="
echo -e "${BLUE}📊 安全检查总结${NC}"
echo "=================================="

if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}🎉 恭喜！未发现安全问题${NC}"
    echo -e "${GREEN}✅ 代码库安全检查通过${NC}"
    exit 0
else
    echo -e "${RED}⚠️  发现 $ISSUES_FOUND 个安全问题${NC}"
    echo -e "${RED}❌ 请立即修复上述问题${NC}"
    echo ""
    echo -e "${YELLOW}🔧 修复建议：${NC}"
    echo "1. 立即撤销泄露的API密钥"
    echo "2. 生成新的API密钥"
    echo "3. 使用环境变量配置敏感信息"
    echo "4. 更新.gitignore文件"
    echo "5. 如有必要，清理Git历史记录"
    echo ""
    echo -e "${BLUE}📖 详细指南请查看: SECURITY.md${NC}"
    exit 1
fi 
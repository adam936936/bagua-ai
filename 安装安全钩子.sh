#!/bin/bash

# 八卦运势小程序 - 安装安全检查钩子
# 创建日期: 2025-06-11

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "🔒 八卦运势小程序 - 安装安全检查钩子"
echo "======================================"

# 检查是否在Git仓库中
if [ ! -d ".git" ]; then
    echo -e "${RED}❌ 错误: 当前目录不是Git仓库${NC}"
    exit 1
fi

# 检查自动安全检查脚本是否存在
if [ ! -f "自动安全检查.sh" ]; then
    echo -e "${RED}❌ 错误: 自动安全检查脚本不存在${NC}"
    exit 1
fi

# 创建pre-commit钩子
PRE_COMMIT_HOOK=".git/hooks/pre-commit"

echo -e "${BLUE}📝 创建pre-commit钩子...${NC}"

cat > "$PRE_COMMIT_HOOK" << 'EOF'
#!/bin/bash

echo "🔒 执行安全检查..."
./自动安全检查.sh

# 检查安全检查脚本的退出状态
if [ $? -ne 0 ]; then
    echo -e "\033[0;31m❌ 安全检查失败，提交已被阻止\033[0m"
    echo -e "\033[0;31m   请修复安全问题后再提交\033[0m"
    exit 1
fi

echo -e "\033[0;32m✅ 安全检查通过\033[0m"
EOF

# 设置执行权限
chmod +x "$PRE_COMMIT_HOOK"

echo -e "${GREEN}✅ pre-commit钩子已安装${NC}"
echo "现在每次提交前都会自动运行安全检查"

# 添加使用说明
echo -e "\n${YELLOW}📋 使用说明${NC}"
echo "=================================="
echo "1. 每次git commit前会自动运行安全检查"
echo "2. 如果检测到敏感信息泄露，提交将被阻止"
echo "3. 如需跳过安全检查，可使用: git commit --no-verify"
echo "   (不推荐使用--no-verify，除非你确定没有敏感信息)"
echo ""
echo -e "${BLUE}💡 提示${NC}: 建议团队所有成员都运行此安装脚本" 
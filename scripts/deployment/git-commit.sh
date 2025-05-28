#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 AI八卦运势小程序 - Git提交脚本${NC}"
echo "=============================================="

# 检查是否在Git仓库中
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ 错误：当前目录不是Git仓库${NC}"
    exit 1
fi

# 显示当前Git状态
echo -e "${YELLOW}📊 当前Git状态：${NC}"
git status --short

echo ""

# 检查是否有未提交的更改
if git diff-index --quiet HEAD --; then
    echo -e "${GREEN}✅ 没有未提交的更改${NC}"
    read -p "是否继续推送到远程仓库？(y/n): " continue_push
    if [[ $continue_push != "y" && $continue_push != "Y" ]]; then
        echo -e "${YELLOW}⏹️ 操作已取消${NC}"
        exit 0
    fi
else
    echo -e "${YELLOW}📝 发现未提交的更改${NC}"
    
    # 询问提交信息
    echo ""
    echo -e "${BLUE}请输入提交信息：${NC}"
    read -p "提交信息: " commit_message
    
    if [[ -z "$commit_message" ]]; then
        echo -e "${RED}❌ 提交信息不能为空${NC}"
        exit 1
    fi
    
    # 添加所有更改
    echo -e "${YELLOW}📁 添加所有更改到暂存区...${NC}"
    git add .
    
    # 显示将要提交的文件
    echo -e "${YELLOW}📋 将要提交的文件：${NC}"
    git diff --cached --name-status
    
    echo ""
    read -p "确认提交这些更改？(y/n): " confirm_commit
    if [[ $confirm_commit != "y" && $confirm_commit != "Y" ]]; then
        echo -e "${YELLOW}⏹️ 提交已取消${NC}"
        git reset
        exit 0
    fi
    
    # 执行提交
    echo -e "${YELLOW}💾 执行提交...${NC}"
    if git commit -m "$commit_message"; then
        echo -e "${GREEN}✅ 提交成功！${NC}"
    else
        echo -e "${RED}❌ 提交失败${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${BLUE}🔄 开始推送到远程仓库...${NC}"

# 推送到Gitee
echo -e "${YELLOW}1️⃣ 推送到Gitee...${NC}"
if git push gitee main 2>/dev/null; then
    echo -e "${GREEN}✅ Gitee推送成功！${NC}"
    echo -e "${BLUE}🌐 Gitee仓库地址: https://gitee.com/zhangyq93/bagua-ai${NC}"
    gitee_success=true
else
    echo -e "${RED}❌ Gitee推送失败${NC}"
    gitee_success=false
fi

echo ""

# 推送到GitHub
echo -e "${YELLOW}2️⃣ 推送到GitHub...${NC}"
if git push origin main 2>/dev/null; then
    echo -e "${GREEN}✅ GitHub推送成功！${NC}"
    echo -e "${BLUE}🌐 GitHub仓库地址: https://github.com/adam936936/bagua-ai${NC}"
    github_success=true
else
    echo -e "${RED}❌ GitHub推送失败${NC}"
    github_success=false
fi

echo ""
echo "=============================================="

# 总结
if [[ $gitee_success == true && $github_success == true ]]; then
    echo -e "${GREEN}🎉 所有仓库推送成功！${NC}"
elif [[ $gitee_success == true || $github_success == true ]]; then
    echo -e "${YELLOW}⚠️ 部分仓库推送成功${NC}"
else
    echo -e "${RED}❌ 所有仓库推送失败${NC}"
    echo -e "${YELLOW}💡 提示：${NC}"
    echo "- 检查网络连接"
    echo "- 确认SSH密钥配置正确"
    echo "- 或使用HTTPS方式推送"
fi

echo ""
echo -e "${BLUE}📝 仓库信息：${NC}"
echo "- Gitee用户名: zhangyq93"
echo "- GitHub用户名: adam936936"
echo "- 邮箱: adam936@163.com"
echo ""
echo -e "${GREEN}✨ Git提交脚本执行完成！${NC}" 
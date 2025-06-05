#!/bin/bash
# setup-git.sh - Git环境配置脚本
# 配置GitHub和Gitee的SSH连接

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔧 配置Git和SSH环境...${NC}"

# 检查Git是否已安装
check_git_installed() {
    if ! command -v git &> /dev/null; then
        echo -e "${RED}❌ Git未安装，请先安装Git${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Git已安装: $(git --version)${NC}"
}

# 配置Git用户信息
configure_git_user() {
    echo -e "${BLUE}👤 配置Git用户信息...${NC}"
    
    # 检查是否已配置
    current_name=$(git config --global user.name 2>/dev/null)
    current_email=$(git config --global user.email 2>/dev/null)
    
    if [ -n "$current_name" ] && [ -n "$current_email" ]; then
        echo "当前配置:"
        echo "  姓名: $current_name"
        echo "  邮箱: $current_email"
        read -p "是否重新配置? (y/N): " reconfigure
        if [[ ! $reconfigure == [Yy] ]]; then
            return
        fi
    fi
    
    read -p "请输入您的姓名: " user_name
    read -p "请输入您的邮箱: " user_email
    
    git config --global user.name "$user_name"
    git config --global user.email "$user_email"
    
    echo -e "${GREEN}✅ Git用户信息配置完成${NC}"
}

# 生成SSH密钥
generate_ssh_key() {
    echo -e "${BLUE}🔑 配置SSH密钥...${NC}"
    
    # 检查是否已存在SSH密钥
    if [ -f ~/.ssh/id_rsa ]; then
        echo -e "${YELLOW}⚠️ SSH密钥已存在${NC}"
        read -p "是否重新生成? (y/N): " regenerate
        if [[ ! $regenerate == [Yy] ]]; then
            return
        fi
        # 备份现有密钥
        cp ~/.ssh/id_rsa ~/.ssh/id_rsa.backup.$(date +%Y%m%d_%H%M%S)
        cp ~/.ssh/id_rsa.pub ~/.ssh/id_rsa.pub.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    # 获取邮箱（用于SSH密钥注释）
    email=$(git config --global user.email)
    if [ -z "$email" ]; then
        read -p "请输入邮箱地址: " email
    fi
    
    echo "📝 生成SSH密钥..."
    ssh-keygen -t rsa -b 4096 -C "$email" -f ~/.ssh/id_rsa -N ""
    
    echo -e "${GREEN}✅ SSH密钥生成完成${NC}"
}

# 配置SSH
configure_ssh() {
    echo -e "${BLUE}⚙️ 配置SSH连接...${NC}"
    
    # 创建SSH配置文件
    mkdir -p ~/.ssh
    
    # 备份现有配置
    if [ -f ~/.ssh/config ]; then
        cp ~/.ssh/config ~/.ssh/config.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    cat > ~/.ssh/config << EOF
# GitHub配置
Host github.com
    HostName github.com
    User git
    Port 22
    IdentityFile ~/.ssh/id_rsa
    TCPKeepAlive yes
    IdentitiesOnly yes

# GitHub 443端口配置（解决网络问题）
Host github-443
    HostName ssh.github.com
    User git
    Port 443
    IdentityFile ~/.ssh/id_rsa
    TCPKeepAlive yes
    IdentitiesOnly yes

# Gitee配置
Host gitee.com
    HostName gitee.com
    User git
    Port 22
    IdentityFile ~/.ssh/id_rsa
    TCPKeepAlive yes
    IdentitiesOnly yes

# Gitee 443端口配置（解决网络问题）
Host gitee-443
    HostName gitee.com
    User git
    Port 443
    IdentityFile ~/.ssh/id_rsa
    TCPKeepAlive yes
    IdentitiesOnly yes
EOF

    # 设置权限
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/config
    chmod 600 ~/.ssh/id_rsa
    chmod 644 ~/.ssh/id_rsa.pub
    
    echo -e "${GREEN}✅ SSH配置完成${NC}"
}

# 显示公钥
show_public_key() {
    echo -e "${BLUE}🔑 您的SSH公钥：${NC}"
    echo "=================================="
    cat ~/.ssh/id_rsa.pub
    echo "=================================="
    echo ""
    echo -e "${YELLOW}📋 请将上述公钥添加到以下平台：${NC}"
    echo ""
    echo "GitHub: https://github.com/settings/ssh/new"
    echo "Gitee:  https://gitee.com/profile/sshkeys"
    echo ""
    read -p "按回车键继续..."
}

# 测试SSH连接
test_ssh_connections() {
    echo -e "${BLUE}🔍 测试SSH连接...${NC}"
    
    # 测试GitHub
    echo "测试GitHub连接..."
    if ssh -o ConnectTimeout=10 -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        echo -e "${GREEN}✅ GitHub SSH连接成功${NC}"
    else
        echo -e "${YELLOW}⚠️ GitHub SSH连接失败，尝试443端口...${NC}"
        if ssh -o ConnectTimeout=10 -T git@ssh.github.com -p 443 2>&1 | grep -q "successfully authenticated"; then
            echo -e "${GREEN}✅ GitHub SSH (443端口)连接成功${NC}"
        else
            echo -e "${RED}❌ GitHub SSH连接失败${NC}"
            echo "请检查:"
            echo "1. 网络连接是否正常"
            echo "2. 公钥是否已添加到GitHub"
            echo "3. 防火墙是否阻止SSH连接"
        fi
    fi
    
    echo ""
    
    # 测试Gitee
    echo "测试Gitee连接..."
    if ssh -o ConnectTimeout=10 -T git@gitee.com 2>&1 | grep -q "successfully authenticated"; then
        echo -e "${GREEN}✅ Gitee SSH连接成功${NC}"
    else
        echo -e "${RED}❌ Gitee SSH连接失败${NC}"
        echo "请检查:"
        echo "1. 网络连接是否正常"
        echo "2. 公钥是否已添加到Gitee"
        echo "3. 防火墙是否阻止SSH连接"
    fi
}

# 配置远程仓库
configure_remotes() {
    echo -e "${BLUE}🔗 配置远程仓库...${NC}"
    
    # 检查是否在Git仓库中
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️ 当前目录不是Git仓库，跳过远程仓库配置${NC}"
        return
    fi
    
    echo "当前远程仓库:"
    if git remote -v | grep -q .; then
        git remote -v
    else
        echo "  (无)"
    fi
    
    echo ""
    read -p "是否添加远程仓库? (y/N): " add_remote
    if [[ $add_remote == [Yy] ]]; then
        echo ""
        echo "请选择要添加的远程仓库类型:"
        echo "1) GitHub"
        echo "2) Gitee"
        echo "3) 自定义"
        
        read -p "请输入选择 (1-3): " remote_type
        
        case $remote_type in
            1)
                read -p "请输入GitHub用户名: " github_user
                read -p "请输入仓库名: " repo_name
                git remote add origin git@github.com:${github_user}/${repo_name}.git
                echo -e "${GREEN}✅ GitHub远程仓库添加成功${NC}"
                ;;
            2)
                read -p "请输入Gitee用户名: " gitee_user
                read -p "请输入仓库名: " repo_name
                git remote add origin git@gitee.com:${gitee_user}/${repo_name}.git
                echo -e "${GREEN}✅ Gitee远程仓库添加成功${NC}"
                ;;
            3)
                read -p "请输入远程仓库名称: " remote_name
                read -p "请输入远程仓库URL: " remote_url
                git remote add $remote_name $remote_url
                echo -e "${GREEN}✅ 自定义远程仓库添加成功${NC}"
                ;;
        esac
        
        # 询问是否添加多个远程仓库
        read -p "是否添加另一个远程仓库? (y/N): " add_another
        if [[ $add_another == [Yy] ]]; then
            configure_remotes
        fi
    fi
}

# 生成使用指南
generate_usage_guide() {
    echo -e "${BLUE}📚 生成使用指南...${NC}"
    
    cat > git-usage-guide.md << EOF
# Git使用指南

## SSH配置完成
- ✅ Git用户信息已配置
- ✅ SSH密钥已生成
- ✅ SSH配置已完成

## 使用方法

### 1. 提交代码
使用提交脚本:
\`\`\`bash
./scripts/git-commit.sh
\`\`\`

### 2. 常用Git命令
\`\`\`bash
# 查看状态
git status

# 添加文件
git add .

# 提交代码
git commit -m "提交信息"

# 推送代码
git push origin main

# 拉取代码
git pull origin main
\`\`\`

### 3. 远程仓库管理
\`\`\`bash
# 查看远程仓库
git remote -v

# 添加远程仓库
git remote add origin <仓库URL>

# 修改远程仓库URL
git remote set-url origin <新URL>
\`\`\`

### 4. 网络问题解决
如果遇到连接问题，可以尝试使用443端口:
\`\`\`bash
# GitHub
git remote set-url origin git@github-443:username/repo.git

# Gitee
git remote set-url origin git@gitee-443:username/repo.git
\`\`\`

## 公钥信息
您的SSH公钥位置: ~/.ssh/id_rsa.pub

请确保已将公钥添加到:
- GitHub: https://github.com/settings/ssh/new
- Gitee: https://gitee.com/profile/sshkeys
EOF

    echo -e "${GREEN}✅ 使用指南已生成: git-usage-guide.md${NC}"
}

# 主流程
main() {
    echo -e "${GREEN}🚀 开始Git环境配置...${NC}"
    echo ""
    
    check_git_installed
    echo ""
    
    configure_git_user
    echo ""
    
    generate_ssh_key
    echo ""
    
    configure_ssh
    echo ""
    
    show_public_key
    
    test_ssh_connections
    echo ""
    
    configure_remotes
    echo ""
    
    generate_usage_guide
    echo ""
    
    echo -e "${GREEN}🎉 Git环境配置完成！${NC}"
    echo ""
    echo "下一步:"
    echo "1. 确保公钥已添加到GitHub和Gitee"
    echo "2. 使用 ./scripts/git-commit.sh 提交代码"
    echo "3. 查看 git-usage-guide.md 了解更多用法"
}

# 显示帮助信息
show_help() {
    echo "Git环境配置脚本使用说明"
    echo "========================"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示此帮助信息"
    echo ""
    echo "功能:"
    echo "  ✅ 配置Git用户信息"
    echo "  ✅ 生成SSH密钥"
    echo "  ✅ 配置SSH连接"
    echo "  ✅ 测试连接状态"
    echo "  ✅ 配置远程仓库"
    echo ""
    echo "支持平台:"
    echo "  🐙 GitHub"
    echo "  🦊 Gitee"
}

# 解析命令行参数
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    *)
        main
        ;;
esac 
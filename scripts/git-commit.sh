#!/bin/bash
# git-commit.sh - 标准化Git提交脚本
# 支持GitHub和Gitee同时提交

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查Git状态
check_git_status() {
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo -e "${RED}❌ 当前目录不是Git仓库${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Git仓库检查通过${NC}"
}

# 检查网络连接
check_network() {
    echo -e "${BLUE}🔍 检查网络连接...${NC}"
    
    # 测试GitHub连接
    if ssh -o ConnectTimeout=5 -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        echo -e "${GREEN}✅ GitHub连接正常${NC}"
        GITHUB_OK=true
    else
        echo -e "${YELLOW}⚠️ GitHub连接失败，尝试443端口${NC}"
        if ssh -o ConnectTimeout=5 -T git@ssh.github.com -p 443 2>&1 | grep -q "successfully authenticated"; then
            echo -e "${GREEN}✅ GitHub (443端口)连接正常${NC}"
            GITHUB_OK=true
        else
            echo -e "${RED}❌ GitHub连接失败${NC}"
            GITHUB_OK=false
        fi
    fi
    
    # 测试Gitee连接
    if ssh -o ConnectTimeout=5 -T git@gitee.com 2>&1 | grep -q "successfully authenticated"; then
        echo -e "${GREEN}✅ Gitee连接正常${NC}"
        GITEE_OK=true
    else
        echo -e "${RED}❌ Gitee连接失败${NC}"
        GITEE_OK=false
    fi
    
    # 如果都连接失败，提示用户
    if [ "$GITHUB_OK" = false ] && [ "$GITEE_OK" = false ]; then
        echo -e "${RED}❌ 所有Git仓库连接失败，请检查网络或SSH配置${NC}"
        read -p "是否继续执行本地提交? (y/N): " continue_choice
        if [[ ! $continue_choice == [Yy] ]]; then
            exit 1
        fi
    fi
}

# 显示Git状态
show_git_status() {
    echo -e "${BLUE}📋 当前Git状态:${NC}"
    git status --short
    echo ""
}

# 预提交检查
pre_commit_check() {
    echo -e "${BLUE}🔍 执行预提交检查...${NC}"
    
    # 检查是否有未暂存的更改
    if ! git diff --quiet; then
        echo -e "${YELLOW}⚠️ 检测到未暂存的更改${NC}"
        show_git_status
        read -p "是否暂存所有更改? (y/N): " choice
        if [[ $choice == [Yy] ]]; then
            git add .
            echo -e "${GREEN}✅ 已暂存所有更改${NC}"
        fi
    fi
    
    # 检查是否有已暂存但未提交的更改
    if git diff --cached --quiet; then
        echo -e "${RED}❌ 没有需要提交的更改${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ 预提交检查完成${NC}"
}

# 生成提交信息
generate_commit_message() {
    echo -e "${BLUE}📝 生成提交信息...${NC}"
    
    # 提交类型选择
    echo "请选择提交类型:"
    echo "1) feat: 新功能"
    echo "2) fix: 修复bug"
    echo "3) docs: 文档更新"
    echo "4) style: 代码格式化"
    echo "5) refactor: 代码重构"
    echo "6) test: 测试相关"
    echo "7) chore: 构建/工具相关"
    echo "8) perf: 性能优化"
    echo "9) ci: CI/CD相关"
    
    read -p "请输入选择 (1-9): " type_choice
    
    case $type_choice in
        1) commit_type="feat" ;;
        2) commit_type="fix" ;;
        3) commit_type="docs" ;;
        4) commit_type="style" ;;
        5) commit_type="refactor" ;;
        6) commit_type="test" ;;
        7) commit_type="chore" ;;
        8) commit_type="perf" ;;
        9) commit_type="ci" ;;
        *) commit_type="chore" ;;
    esac
    
    read -p "请输入提交描述: " commit_desc
    
    # 可选：添加详细说明
    read -p "是否添加详细说明? (y/N): " add_detail
    if [[ $add_detail == [Yy] ]]; then
        echo "请输入详细说明 (输入END结束):"
        detail_lines=""
        while IFS= read -r line; do
            if [ "$line" = "END" ]; then
                break
            fi
            detail_lines="${detail_lines}${line}\n"
        done
    fi
    
    # 生成完整的提交信息
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    current_branch=$(git branch --show-current)
    
    COMMIT_MESSAGE="${commit_type}: ${commit_desc}"
    
    if [ -n "$detail_lines" ]; then
        COMMIT_MESSAGE="${COMMIT_MESSAGE}

${detail_lines}"
    fi
    
    COMMIT_MESSAGE="${COMMIT_MESSAGE}

分支: ${current_branch}
提交时间: ${timestamp}
提交者: $(git config user.name) <$(git config user.email)>"

    echo -e "${GREEN}生成的提交信息:${NC}"
    echo "----------------------------------------"
    echo "$COMMIT_MESSAGE"
    echo "----------------------------------------"
    
    read -p "确认提交信息? (Y/n): " confirm
    if [[ $confirm == [Nn] ]]; then
        echo -e "${YELLOW}重新生成提交信息...${NC}"
        generate_commit_message
    fi
}

# 执行提交
execute_commit() {
    echo -e "${BLUE}📤 执行本地提交...${NC}"
    
    # 提交到本地仓库
    if git commit -m "$COMMIT_MESSAGE"; then
        echo -e "${GREEN}✅ 本地提交成功${NC}"
        
        # 显示提交信息
        echo -e "${BLUE}最新提交信息:${NC}"
        git log --oneline -1
    else
        echo -e "${RED}❌ 本地提交失败${NC}"
        exit 1
    fi
}

# 推送到远程仓库
push_to_remotes() {
    echo -e "${BLUE}📤 推送到远程仓库...${NC}"
    
    # 获取当前分支
    current_branch=$(git branch --show-current)
    
    # 获取所有远程仓库
    remotes=($(git remote))
    
    if [ ${#remotes[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️ 没有配置远程仓库${NC}"
        return
    fi
    
    # 推送到所有远程仓库
    for remote in "${remotes[@]}"; do
        echo -e "${BLUE}📤 推送到 $remote ($current_branch)...${NC}"
        
        # 获取远程仓库URL来判断是哪个平台
        remote_url=$(git remote get-url $remote)
        
        if echo "$remote_url" | grep -q "github"; then
            platform="GitHub"
            if [ "$GITHUB_OK" = false ]; then
                echo -e "${YELLOW}⚠️ 跳过 $platform ($remote) - 网络连接失败${NC}"
                continue
            fi
        elif echo "$remote_url" | grep -q "gitee"; then
            platform="Gitee"
            if [ "$GITEE_OK" = false ]; then
                echo -e "${YELLOW}⚠️ 跳过 $platform ($remote) - 网络连接失败${NC}"
                continue
            fi
        else
            platform="Unknown"
        fi
        
        if git push $remote $current_branch; then
            echo -e "${GREEN}✅ 推送到 $platform ($remote) 成功${NC}"
        else
            echo -e "${RED}❌ 推送到 $platform ($remote) 失败${NC}"
            
            # 询问是否强制推送
            read -p "是否尝试强制推送? (y/N): " force_push
            if [[ $force_push == [Yy] ]]; then
                if git push --force-with-lease $remote $current_branch; then
                    echo -e "${GREEN}✅ 强制推送到 $platform ($remote) 成功${NC}"
                else
                    echo -e "${RED}❌ 强制推送到 $platform ($remote) 失败${NC}"
                fi
            fi
        fi
    done
}

# 显示推送结果
show_push_summary() {
    echo ""
    echo -e "${GREEN}🎉 提交推送完成！${NC}"
    echo -e "${BLUE}📊 推送摘要:${NC}"
    
    current_branch=$(git branch --show-current)
    commit_hash=$(git rev-parse --short HEAD)
    
    echo "分支: $current_branch"
    echo "提交: $commit_hash"
    echo "远程仓库:"
    
    for remote in $(git remote); do
        remote_url=$(git remote get-url $remote)
        echo "  - $remote: $remote_url"
    done
}

# 主流程
main() {
    echo -e "${GREEN}🚀 开始Git提交流程...${NC}"
    echo ""
    
    check_git_status
    echo ""
    
    check_network
    echo ""
    
    show_git_status
    
    pre_commit_check
    echo ""
    
    generate_commit_message
    echo ""
    
    execute_commit
    echo ""
    
    read -p "是否推送到远程仓库? (Y/n): " push_choice
    if [[ ! $push_choice == [Nn] ]]; then
        push_to_remotes
        echo ""
        show_push_summary
    else
        echo -e "${YELLOW}⚠️ 已跳过推送，只进行了本地提交${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}✅ Git提交流程完成！${NC}"
}

# 显示帮助信息
show_help() {
    echo "Git提交脚本使用说明"
    echo "===================="
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示此帮助信息"
    echo "  -q, --quick    快速提交模式（跳过网络检查）"
    echo ""
    echo "功能:"
    echo "  ✅ 自动检查Git状态和网络连接"
    echo "  ✅ 标准化提交信息格式"
    echo "  ✅ 支持多个远程仓库同时推送"
    echo "  ✅ 智能错误处理和重试机制"
    echo ""
    echo "支持的远程仓库:"
    echo "  🐙 GitHub"
    echo "  🦊 Gitee"
    echo "  📦 其他Git仓库"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -q|--quick)
            QUICK_MODE=true
            shift
            ;;
        *)
            echo "未知选项: $1"
            echo "使用 $0 --help 查看帮助"
            exit 1
            ;;
    esac
done

# 快速模式跳过网络检查
if [ "$QUICK_MODE" = true ]; then
    GITHUB_OK=true
    GITEE_OK=true
fi

# 执行主流程
main "$@" 
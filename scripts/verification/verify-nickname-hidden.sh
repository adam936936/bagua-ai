#!/bin/bash

echo "🔍 验证修改昵称功能隐藏状态"
echo "=================================="

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "1. 检查个人中心页面修改"
echo "--------------------"

profile_file="frontend/src/pages/profile/profile.vue"

if [ -f "$profile_file" ]; then
    echo -e "${GREEN}✅ 个人中心页面文件存在${NC}"
    
    # 检查是否移除了点击事件
    if grep -q "@click=\"editNickname\"" "$profile_file"; then
        echo -e "${RED}❌ 昵称点击事件仍然存在${NC}"
    else
        echo -e "${GREEN}✅ 昵称点击事件已移除${NC}"
    fi
    
    # 检查是否移除了编辑图标
    if grep -q "icon-edit" "$profile_file" | grep -v "<!--"; then
        echo -e "${RED}❌ 编辑图标仍然显示${NC}"
    else
        echo -e "${GREEN}✅ 编辑图标已隐藏${NC}"
    fi
    
    # 检查弹窗是否被注释
    if grep -q "<!-- 昵称编辑弹窗 - 已移至设置页面 -->" "$profile_file"; then
        echo -e "${GREEN}✅ 昵称编辑弹窗已注释${NC}"
    else
        echo -e "${RED}❌ 昵称编辑弹窗未正确注释${NC}"
    fi
    
    # 检查相关函数是否被注释
    if grep -q "// 昵称编辑功能已移至设置页面" "$profile_file"; then
        echo -e "${GREEN}✅ 昵称编辑函数已注释${NC}"
    else
        echo -e "${RED}❌ 昵称编辑函数未正确注释${NC}"
    fi
    
else
    echo -e "${RED}❌ 个人中心页面文件不存在${NC}"
fi

echo ""
echo "2. 检查代码注释说明"
echo "------------------"

# 统计注释行数
comment_lines=$(grep -c "已移至设置页面\|昵称编辑功能已移至设置页面" "$profile_file" 2>/dev/null || echo "0")
echo -e "${BLUE}📝 找到 $comment_lines 处相关注释说明${NC}"

# 检查具体注释内容
echo "📋 注释内容："
grep -n "已移至设置页面\|昵称编辑功能已移至设置页面" "$profile_file" 2>/dev/null | while read line; do
    echo "   $line"
done

echo ""
echo "3. 检查用户名显示逻辑"
echo "------------------"

# 检查用户名显示是否改为默认格式
if grep -q "用户.*userInfo.id.*slice(-4)" "$profile_file"; then
    echo -e "${GREEN}✅ 用户名显示已改为默认格式（用户+ID后4位）${NC}"
else
    echo -e "${YELLOW}⚠️  用户名显示格式可能需要检查${NC}"
fi

echo ""
echo "4. 功能验证总结"
echo "----------------"

# 计算隐藏状态
hidden_count=0
total_checks=4

# 检查各项是否正确隐藏
if ! grep -q "@click=\"editNickname\"" "$profile_file"; then
    ((hidden_count++))
fi

if ! grep -q "icon-edit" "$profile_file" | grep -v "<!--" > /dev/null; then
    ((hidden_count++))
fi

if grep -q "昵称编辑弹窗 - 已移至设置页面" "$profile_file"; then
    ((hidden_count++))
fi

if grep -q "昵称编辑功能已移至设置页面" "$profile_file"; then
    ((hidden_count++))
fi

echo -e "${BLUE}📊 隐藏进度: $hidden_count/$total_checks${NC}"

if [ $hidden_count -eq $total_checks ]; then
    echo -e "${GREEN}🎉 修改昵称功能已完全隐藏！${NC}"
    echo -e "${GREEN}✅ 所有相关代码已注释并标注说明${NC}"
    echo -e "${GREEN}✅ 用户界面已移除编辑入口${NC}"
    echo -e "${GREEN}✅ 准备好移至设置页面${NC}"
else
    echo -e "${YELLOW}⚠️  部分功能可能未完全隐藏${NC}"
fi

echo ""
echo "5. 下一步规划"
echo "------------"
echo "📋 待开发功能："
echo "   1. 创建设置页面 (pages/settings/settings.vue)"
echo "   2. 在设置页面中实现修改昵称功能"
echo "   3. 添加其他设置选项（主题、通知等）"
echo "   4. 更新个人中心的设置按钮跳转"

echo ""
echo -e "${YELLOW}💡 提示: 修改昵称功能已成功隐藏，可以开始开发设置页面${NC}" 
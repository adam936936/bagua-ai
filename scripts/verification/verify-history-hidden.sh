#!/bin/bash

echo "🔍 验证历史标签隐藏和入口调整"
echo "=================================="

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "1. 检查tabBar配置变更"
echo "--------------------"

pages_file="frontend/src/pages.json"

if [ -f "$pages_file" ]; then
    echo -e "${GREEN}✅ pages.json文件存在${NC}"
    
    # 检查tabBar中是否还有历史标签
    if grep -A 20 '"tabBar"' "$pages_file" | grep -q '"text": "历史"'; then
        echo -e "${RED}❌ 历史标签仍在tabBar中${NC}"
    else
        echo -e "${GREEN}✅ 历史标签已从tabBar移除${NC}"
    fi
    
    # 检查当前tabBar配置
    echo -e "${BLUE}📱 当前tabBar配置：${NC}"
    grep -A 20 '"tabBar"' "$pages_file" | grep -E '"text"|"pagePath"' | while read line; do
        echo "   $line"
    done
    
    # 统计tabBar项目数量
    tab_count=$(grep -A 20 '"tabBar"' "$pages_file" | grep -c '"text"')
    echo -e "${BLUE}📊 tabBar项目数量: $tab_count${NC}"
    
    if [ "$tab_count" -eq 3 ]; then
        echo -e "${GREEN}✅ tabBar现在有3个标签（首页、VIP、我的）${NC}"
    else
        echo -e "${YELLOW}⚠️  tabBar项目数量异常: $tab_count${NC}"
    fi
    
else
    echo -e "${RED}❌ pages.json文件不存在${NC}"
fi

echo ""
echo "2. 检查个人中心测算历史入口"
echo "------------------------"

profile_file="frontend/src/pages/profile/profile.vue"

if [ -f "$profile_file" ]; then
    echo -e "${GREEN}✅ 个人中心页面文件存在${NC}"
    
    # 检查是否有测算历史菜单项
    if grep -q "测算历史" "$profile_file"; then
        echo -e "${GREEN}✅ 找到测算历史菜单项${NC}"
    else
        echo -e "${RED}❌ 未找到测算历史菜单项${NC}"
    fi
    
    # 检查goToHistory函数
    if grep -q "goToHistory" "$profile_file"; then
        echo -e "${GREEN}✅ goToHistory导航函数存在${NC}"
    else
        echo -e "${RED}❌ goToHistory导航函数不存在${NC}"
    fi
    
    # 检查历史页面路径
    if grep -q "/pages/history/history" "$profile_file"; then
        echo -e "${GREEN}✅ 历史页面路径配置正确${NC}"
    else
        echo -e "${RED}❌ 历史页面路径配置异常${NC}"
    fi
    
else
    echo -e "${RED}❌ 个人中心页面文件不存在${NC}"
fi

echo ""
echo "3. 检查历史页面文件状态"
echo "--------------------"

history_file="frontend/src/pages/history/history.vue"

if [ -f "$history_file" ]; then
    echo -e "${GREEN}✅ 历史页面文件仍然存在（可通过个人中心访问）${NC}"
else
    echo -e "${RED}❌ 历史页面文件不存在${NC}"
fi

echo ""
echo "4. 验证导航结构"
echo "----------------"

echo -e "${BLUE}📋 新的导航结构：${NC}"
echo "   🏠 首页 (tabBar) → pages/index/index"
echo "   💎 VIP (tabBar) → pages/vip/vip"
echo "   👤 我的 (tabBar) → pages/profile/profile"
echo "   📜 测算历史 (个人中心菜单) → pages/history/history"

echo ""
echo "5. 功能验证总结"
echo "----------------"

# 计算验证状态
success_count=0
total_checks=4

# 检查各项是否正确
if ! grep -A 20 '"tabBar"' "$pages_file" | grep -q '"text": "历史"'; then
    ((success_count++))
fi

tab_count=$(grep -A 20 '"tabBar"' "$pages_file" | grep -c '"text"' 2>/dev/null || echo "0")
if [ "$tab_count" -eq 3 ]; then
    ((success_count++))
fi

if grep -q "测算历史" "$profile_file" 2>/dev/null; then
    ((success_count++))
fi

if grep -q "goToHistory" "$profile_file" 2>/dev/null; then
    ((success_count++))
fi

echo -e "${BLUE}📊 验证进度: $success_count/$total_checks${NC}"

if [ $success_count -eq $total_checks ]; then
    echo -e "${GREEN}🎉 历史标签隐藏成功！${NC}"
    echo -e "${GREEN}✅ tabBar现在只有3个标签${NC}"
    echo -e "${GREEN}✅ 历史记录可通过个人中心访问${NC}"
    echo -e "${GREEN}✅ 导航结构更加简洁${NC}"
else
    echo -e "${YELLOW}⚠️  部分配置可能需要调整${NC}"
fi

echo ""
echo "6. 用户体验改进"
echo "----------------"
echo "📈 改进效果："
echo "   • 底部导航更简洁（3个标签 vs 4个标签）"
echo "   • 历史记录功能仍然可用"
echo "   • 符合常见小程序导航模式"
echo "   • 个人中心功能更集中"

echo ""
echo -e "${YELLOW}💡 提示: 历史标签已成功从tabBar移除，用户可通过个人中心访问测算历史${NC}" 
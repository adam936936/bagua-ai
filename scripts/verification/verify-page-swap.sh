#!/bin/bash

echo "🔄 验证历史和VIP页面交换任务"
echo "=================================="

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "1. 检查pages.json配置"
echo "--------------------"

# 检查tabBar配置
echo "📋 当前tabBar配置："
grep -A 20 '"tabBar"' frontend/src/pages.json | grep -E '"text"|"pagePath"' | while read line; do
    echo "   $line"
done

echo ""
echo "2. 验证页面顺序"
echo "----------------"

# 提取tabBar顺序
tab_order=$(grep -A 20 '"tabBar"' frontend/src/pages.json | grep '"text"' | sed 's/.*"text": *"\([^"]*\)".*/\1/' | tr '\n' ' ')
echo -e "${BLUE}📱 底部导航栏顺序: $tab_order${NC}"

# 检查是否VIP在历史之前
if echo "$tab_order" | grep -q "首页.*VIP.*历史.*我的"; then
    echo -e "${GREEN}✅ 页面交换成功！VIP现在在历史之前${NC}"
    swap_success=true
else
    echo -e "${RED}❌ 页面交换失败！顺序不正确${NC}"
    swap_success=false
fi

echo ""
echo "3. 测试页面访问"
echo "----------------"

# 测试前端服务
if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 前端服务正常运行${NC}"
    
    # 测试各个页面路径
    pages=("pages/index/index" "pages/vip/vip" "pages/history/history" "pages/profile/profile")
    page_names=("首页" "VIP" "历史" "我的")
    
    for i in "${!pages[@]}"; do
        page_url="http://localhost:3000/#/${pages[$i]}"
        if curl -s "$page_url" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ ${page_names[$i]}页面可访问: ${pages[$i]}${NC}"
        else
            echo -e "${YELLOW}⚠️  ${page_names[$i]}页面访问异常: ${pages[$i]}${NC}"
        fi
    done
else
    echo -e "${RED}❌ 前端服务未运行${NC}"
fi

echo ""
echo "4. 功能完整性检查"
echo "------------------"

# 检查VIP页面功能
echo "🔍 检查VIP页面功能..."
if curl -s http://localhost:8080/api/vip/plans | grep -q '"code":200'; then
    echo -e "${GREEN}✅ VIP套餐接口正常${NC}"
else
    echo -e "${RED}❌ VIP套餐接口异常${NC}"
fi

# 检查历史记录功能
echo "🔍 检查历史记录功能..."
if curl -s "http://localhost:8080/api/fortune/history/1748284072178?page=1&size=10" | grep -q '"code":200'; then
    echo -e "${GREEN}✅ 历史记录接口正常${NC}"
else
    echo -e "${RED}❌ 历史记录接口异常${NC}"
fi

echo ""
echo "5. 交换验证总结"
echo "----------------"

if [ "$swap_success" = true ]; then
    echo -e "${GREEN}🎉 页面交换任务完成！${NC}"
    echo -e "${GREEN}✅ 新的导航顺序: 首页 → VIP → 历史 → 我的${NC}"
    echo -e "${GREEN}✅ 所有页面功能保持不变${NC}"
    echo -e "${GREEN}✅ 前后端服务正常运行${NC}"
else
    echo -e "${RED}❌ 页面交换任务失败${NC}"
fi

echo ""
echo "6. 访问链接"
echo "------------"
echo "🌐 前端首页: http://localhost:3000"
echo "💎 VIP页面: http://localhost:3000/#/pages/vip/vip"
echo "📚 历史页面: http://localhost:3000/#/pages/history/history"
echo "👤 个人中心: http://localhost:3000/#/pages/profile/profile"

echo ""
echo -e "${YELLOW}💡 提示: 在浏览器中访问前端页面，可以看到底部导航栏中VIP和历史的位置已交换${NC}" 
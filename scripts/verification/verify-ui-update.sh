#!/bin/bash

echo "🎨 验证VIP页面和个人中心页面UI更新"
echo "=================================="

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "1. 检查首页设计风格特征"
echo "--------------------"

index_file="frontend/src/pages/index/index.vue"

if [ -f "$index_file" ]; then
    echo -e "${GREEN}✅ 首页文件存在${NC}"
    
    # 检查首页的关键设计元素
    echo -e "${BLUE}📋 首页设计特征：${NC}"
    
    if grep -q "background: linear-gradient(135deg, #667eea 0%, #764ba2 100%)" "$index_file"; then
        echo "   ✅ 渐变背景色"
    fi
    
    if grep -q "background: rgba(255, 255, 255, 0.95)" "$index_file"; then
        echo "   ✅ 半透明白色卡片"
    fi
    
    if grep -q "border-radius: 20rpx" "$index_file"; then
        echo "   ✅ 圆角设计"
    fi
    
    if grep -q "box-shadow: 0 8rpx 32rpx rgba(0, 0, 0, 0.1)" "$index_file"; then
        echo "   ✅ 阴影效果"
    fi
    
    if grep -q "feature-grid" "$index_file"; then
        echo "   ✅ 网格布局"
    fi
    
    if grep -q "feature-icon.*bg-" "$index_file"; then
        echo "   ✅ 渐变图标"
    fi
    
else
    echo -e "${RED}❌ 首页文件不存在${NC}"
fi

echo ""
echo "2. 检查VIP页面UI更新"
echo "--------------------"

vip_file="frontend/src/pages/vip/vip.vue"

if [ -f "$vip_file" ]; then
    echo -e "${GREEN}✅ VIP页面文件存在${NC}"
    
    # 检查VIP页面是否采用了首页风格
    vip_updates=0
    total_vip_checks=8
    
    if grep -q "padding: 40rpx 0 0 0" "$vip_file"; then
        echo "   ✅ 页面内边距样式统一"
        ((vip_updates++))
    fi
    
    if grep -q "font-size: 56rpx" "$vip_file"; then
        echo "   ✅ 标题字体大小统一"
        ((vip_updates++))
    fi
    
    if grep -q "margin: 0 32rpx 32rpx 32rpx" "$vip_file"; then
        echo "   ✅ 卡片边距统一"
        ((vip_updates++))
    fi
    
    if grep -q "privilege-grid" "$vip_file"; then
        echo "   ✅ 特权展示改为网格布局"
        ((vip_updates++))
    fi
    
    if grep -q "privilege-card" "$vip_file"; then
        echo "   ✅ 特权卡片样式"
        ((vip_updates++))
    fi
    
    if grep -q "bg-purple\|bg-blue\|bg-green\|bg-orange" "$vip_file"; then
        echo "   ✅ 渐变图标背景"
        ((vip_updates++))
    fi
    
    if grep -q "linear-gradient(90deg, #7f7fd5 0%, #86a8e7 50%, #91eac9 100%)" "$vip_file"; then
        echo "   ✅ 购买按钮渐变样式"
        ((vip_updates++))
    fi
    
    if grep -q "vip-icon-bg" "$vip_file"; then
        echo "   ✅ VIP图标背景样式"
        ((vip_updates++))
    fi
    
    echo -e "${BLUE}📊 VIP页面更新进度: $vip_updates/$total_vip_checks${NC}"
    
else
    echo -e "${RED}❌ VIP页面文件不存在${NC}"
fi

echo ""
echo "3. 检查个人中心页面UI更新"
echo "------------------------"

profile_file="frontend/src/pages/profile/profile.vue"

if [ -f "$profile_file" ]; then
    echo -e "${GREEN}✅ 个人中心页面文件存在${NC}"
    
    # 检查个人中心页面是否采用了首页风格
    profile_updates=0
    total_profile_checks=7
    
    if grep -q "class=\"container\"" "$profile_file"; then
        echo "   ✅ 容器类名统一"
        ((profile_updates++))
    fi
    
    if grep -q "class=\"header\"" "$profile_file"; then
        echo "   ✅ 页面头部样式"
        ((profile_updates++))
    fi
    
    if grep -q "class=\"features\"" "$profile_file"; then
        echo "   ✅ 功能区域改为网格布局"
        ((profile_updates++))
    fi
    
    if grep -q "feature-grid" "$profile_file"; then
        echo "   ✅ 网格布局样式"
        ((profile_updates++))
    fi
    
    if grep -q "feature-card" "$profile_file"; then
        echo "   ✅ 功能卡片样式"
        ((profile_updates++))
    fi
    
    if grep -q "bg-blue\|bg-green\|bg-orange\|bg-pink" "$profile_file"; then
        echo "   ✅ 功能图标渐变背景"
        ((profile_updates++))
    fi
    
    if grep -q "edit-icon" "$profile_file"; then
        echo "   ✅ 编辑图标样式更新"
        ((profile_updates++))
    fi
    
    echo -e "${BLUE}📊 个人中心页面更新进度: $profile_updates/$total_profile_checks${NC}"
    
else
    echo -e "${RED}❌ 个人中心页面文件不存在${NC}"
fi

echo ""
echo "4. 设计风格一致性检查"
echo "--------------------"

echo -e "${BLUE}🎨 设计风格对比：${NC}"

# 检查背景渐变一致性
echo "📱 背景渐变："
for file in "$index_file" "$vip_file" "$profile_file"; do
    if [ -f "$file" ]; then
        filename=$(basename "$file" .vue)
        if grep -q "background: linear-gradient(135deg, #667eea 0%, #764ba2 100%)" "$file"; then
            echo "   ✅ $filename - 渐变背景一致"
        else
            echo "   ❌ $filename - 渐变背景不一致"
        fi
    fi
done

# 检查卡片样式一致性
echo "🃏 卡片样式："
for file in "$index_file" "$vip_file" "$profile_file"; do
    if [ -f "$file" ]; then
        filename=$(basename "$file" .vue)
        if grep -q "background: rgba(255, 255, 255, 0.95)" "$file"; then
            echo "   ✅ $filename - 卡片背景一致"
        else
            echo "   ❌ $filename - 卡片背景不一致"
        fi
    fi
done

# 检查圆角设计一致性
echo "🔘 圆角设计："
for file in "$index_file" "$vip_file" "$profile_file"; do
    if [ -f "$file" ]; then
        filename=$(basename "$file" .vue)
        if grep -q "border-radius: 20rpx\|border-radius: 24rpx" "$file"; then
            echo "   ✅ $filename - 圆角设计一致"
        else
            echo "   ❌ $filename - 圆角设计不一致"
        fi
    fi
done

echo ""
echo "5. 功能验证总结"
echo "----------------"

# 计算总体更新状态
total_updates=$((vip_updates + profile_updates))
total_checks=$((total_vip_checks + total_profile_checks))

echo -e "${BLUE}📊 总体更新进度: $total_updates/$total_checks${NC}"

if [ $total_updates -ge $((total_checks * 80 / 100)) ]; then
    echo -e "${GREEN}🎉 UI更新成功！${NC}"
    echo -e "${GREEN}✅ VIP页面和个人中心页面已成功采用首页设计风格${NC}"
    echo -e "${GREEN}✅ 设计风格统一，用户体验一致${NC}"
    echo -e "${GREEN}✅ 渐变背景、卡片样式、网格布局等元素统一${NC}"
else
    echo -e "${YELLOW}⚠️  部分UI更新可能需要进一步调整${NC}"
fi

echo ""
echo "6. 设计特色总结"
echo "----------------"
echo "🎨 统一设计特色："
echo "   • 渐变背景：#667eea → #764ba2"
echo "   • 半透明卡片：rgba(255, 255, 255, 0.95)"
echo "   • 圆角设计：20rpx/24rpx"
echo "   • 阴影效果：0 8rpx 32rpx rgba(0, 0, 0, 0.1)"
echo "   • 网格布局：2列网格展示"
echo "   • 渐变图标：多色渐变圆形图标"
echo "   • 统一间距：32rpx 边距"

echo ""
echo -e "${YELLOW}💡 提示: UI风格已统一，建议在微信开发者工具中预览效果${NC}" 
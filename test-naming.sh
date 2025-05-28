#!/bin/bash

# AI起名功能测试脚本
echo "🎯 AI起名功能测试"
echo "=================="

# 测试1：男孩起名
echo "📝 测试1：王姓男孩（2025年4月28日辰时）"
curl -s -X POST http://localhost:8080/api/fortune/recommend-names \
  -H "Content-Type: application/json" \
  -d '{"surname":"王","gender":1,"birthYear":2025,"birthMonth":4,"birthDay":28,"birthHour":4,"userId":1748396447350}' | jq .

echo ""

# 测试2：女孩起名
echo "📝 测试2：李姓女孩（2024年8月15日午时）"
curl -s -X POST http://localhost:8080/api/fortune/recommend-names \
  -H "Content-Type: application/json" \
  -d '{"surname":"李","gender":0,"birthYear":2024,"birthMonth":8,"birthDay":15,"birthHour":6,"userId":1748396447350}' | jq .

echo ""

# 测试3：张姓男孩
echo "📝 测试3：张姓男孩（2023年12月1日子时）"
curl -s -X POST http://localhost:8080/api/fortune/recommend-names \
  -H "Content-Type: application/json" \
  -d '{"surname":"张","gender":1,"birthYear":2023,"birthMonth":12,"birthDay":1,"birthHour":0,"userId":1748396447350}' | jq .

echo ""

# 测试4：陈姓女孩
echo "📝 测试4：陈姓女孩（2025年1月10日酉时）"
curl -s -X POST http://localhost:8080/api/fortune/recommend-names \
  -H "Content-Type: application/json" \
  -d '{"surname":"陈","gender":0,"birthYear":2025,"birthMonth":1,"birthDay":10,"birthHour":9,"userId":1748396447350}' | jq .

echo ""
echo "✅ AI起名功能测试完成！"
echo ""
echo "🔮 功能特点："
echo "- 根据出生年月日时精确计算天干地支"
echo "- 分析五行（金木水火土）缺失情况"
echo "- 推荐相应五行属性的字来补足缺失"
echo "- 男孩女孩推荐不同风格的名字"
echo "- 每次推荐都有随机性，确保多样化" 
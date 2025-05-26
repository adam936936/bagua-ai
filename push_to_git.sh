#!/bin/bash

echo "🚀 八卦AI运势小程序 - Git推送脚本"
echo "=================================="

# 检查Git状态
echo "📊 检查Git状态..."
git status

echo ""
echo "🔄 尝试推送到远程仓库..."

# 尝试推送到Gitee
echo "1️⃣ 尝试推送到Gitee..."
if git push gitee main; then
    echo "✅ Gitee推送成功！"
    echo "🌐 Gitee仓库地址: https://gitee.com/zhangyq93/bagua-ai"
else
    echo "❌ Gitee推送失败"
fi

echo ""

# 尝试推送到GitHub
echo "2️⃣ 尝试推送到GitHub..."
if git push origin main; then
    echo "✅ GitHub推送成功！"
    echo "🌐 GitHub仓库地址: https://github.com/adam936936/bagua-ai"
else
    echo "❌ GitHub推送失败"
fi

echo ""
echo "📝 提示："
echo "- 如果推送失败，可能需要输入用户名和密码"
echo "- Gitee用户名: zhangyq93"
echo "- GitHub用户名: adam936936"
echo "- 邮箱: adam936@163.com"
echo ""
echo "🎉 推送脚本执行完成！" 
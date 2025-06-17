#!/bin/bash

# 微信小程序开发环境停止脚本

echo "🛑 停止微信小程序开发环境..."

# 停止前端代理服务器
if [ -f "frontend-proxy.pid" ]; then
    PROXY_PID=$(cat frontend-proxy.pid)
    if ps -p $PROXY_PID > /dev/null 2>&1; then
        echo "🌐 停止前端代理服务器 (PID: $PROXY_PID)..."
        kill $PROXY_PID
        rm frontend-proxy.pid
        echo "✅ 前端代理服务器已停止"
    else
        echo "⚠️  前端代理服务器进程不存在"
        rm frontend-proxy.pid
    fi
else
    echo "⚠️  未找到前端代理服务器PID文件"
fi

# 停止Docker服务
echo "🐳 停止Docker服务..."
docker-compose down

echo "✅ 微信小程序开发环境已停止"

# 清理日志文件（可选）
read -p "是否清理日志文件？(y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🧹 清理日志文件..."
    rm -f frontend-proxy.log
    echo "✅ 日志文件已清理"
fi 
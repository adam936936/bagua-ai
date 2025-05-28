#!/bin/bash

echo "=== 端口占用检查 ==="

# 检查8080端口（后端）
echo "检查8080端口（后端）..."
PORT_8080=$(lsof -ti:8080 2>/dev/null)
if [ ! -z "$PORT_8080" ]; then
    echo "⚠️  端口8080被占用，进程ID: $PORT_8080"
    echo "占用进程详情:"
    lsof -i:8080
    echo ""
    read -p "是否要杀死占用进程？(y/n): " kill_choice
    if [ "$kill_choice" = "y" ] || [ "$kill_choice" = "Y" ]; then
        echo "正在杀死进程..."
        lsof -ti:8080 | xargs kill -9 2>/dev/null
        sleep 2
        # 再次检查
        if [ -z "$(lsof -ti:8080 2>/dev/null)" ]; then
            echo "✅ 进程已杀死，端口8080现在可用"
        else
            echo "❌ 无法杀死进程，请手动处理"
            exit 1
        fi
    else
        echo "❌ 请手动处理端口占用问题"
        exit 1
    fi
else
    echo "✅ 端口8080可用"
fi

# 检查3000端口（前端开发服务器，如果使用）
echo "检查3000端口（前端开发服务器）..."
PORT_3000=$(lsof -ti:3000 2>/dev/null)
if [ ! -z "$PORT_3000" ]; then
    echo "⚠️  端口3000被占用，进程ID: $PORT_3000"
    echo "占用进程详情:"
    lsof -i:3000
    echo ""
    read -p "是否要杀死占用进程？(y/n): " kill_choice
    if [ "$kill_choice" = "y" ] || [ "$kill_choice" = "Y" ]; then
        echo "正在杀死进程..."
        lsof -ti:3000 | xargs kill -9 2>/dev/null
        echo "✅ 进程已杀死"
    fi
else
    echo "✅ 端口3000可用"
fi

echo "=== 端口检查完成 ===" 
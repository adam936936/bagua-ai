#!/bin/bash
# 八卦AI项目停止脚本

echo "🛑 停止八卦AI后端服务..."

# 检查PID文件是否存在
if [ -f "backend.pid" ]; then
    PID=$(cat backend.pid)
    
    # 检查进程是否存在
    if ps -p $PID > /dev/null; then
        echo "🔍 找到进程 $PID，正在停止..."
        kill $PID
        
        # 等待进程停止
        sleep 3
        
        # 强制停止（如果还在运行）
        if ps -p $PID > /dev/null; then
            echo "⚠️  强制停止进程 $PID..."
            kill -9 $PID
        fi
        
        echo "✅ 服务已停止"
    else
        echo "⚠️  进程 $PID 不存在"
    fi
    
    # 删除PID文件
    rm -f backend.pid
else
    echo "⚠️  PID文件不存在，尝试查找Java进程..."
    
    # 查找并停止Java进程
    JAVA_PID=$(pgrep -f "fortune-mini-app")
    if [ ! -z "$JAVA_PID" ]; then
        echo "🔍 找到Java进程 $JAVA_PID，正在停止..."
        kill $JAVA_PID
        sleep 3
        
        if ps -p $JAVA_PID > /dev/null; then
            kill -9 $JAVA_PID
        fi
        echo "✅ Java进程已停止"
    else
        echo "ℹ️  未找到运行中的服务"
    fi
fi

echo "🎉 停止完成！" 
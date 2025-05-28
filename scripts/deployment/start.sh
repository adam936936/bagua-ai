#!/bin/bash
# 八卦AI项目启动脚本
# 使用方法: ./start.sh [dev|prod]

# 设置环境变量
export JAVA_HOME="/opt/homebrew/Cellar/openjdk@17/17.0.15/libexec/openjdk.jdk/Contents/Home"
export PATH="/opt/homebrew/bin:$JAVA_HOME/bin:$PATH"

# 设置Homebrew镜像源（解决网络问题）
export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"

# 获取环境参数，默认为dev
PROFILE=${1:-dev}

echo "🔮 启动八卦AI后端服务 - 环境: $PROFILE"
echo "================================================"

# 检查Java环境
if ! command -v java &> /dev/null; then
    echo "❌ Java未找到，请检查JAVA_HOME配置"
    exit 1
fi

echo "✅ Java版本: $(java -version 2>&1 | head -n 1)"

# 检查jar文件是否存在
JAR_FILE="backend/target/fortune-mini-app-1.0.0.jar"
if [ ! -f "$JAR_FILE" ]; then
    echo "❌ JAR文件不存在，正在构建项目..."
    mvn clean package -DskipTests
    if [ $? -ne 0 ]; then
        echo "❌ 项目构建失败"
        exit 1
    fi
fi

# 检查MySQL服务（生产环境）
if [ "$PROFILE" = "prod" ]; then
    echo "🔍 检查MySQL服务状态..."
    if ! brew services list | grep mysql | grep started > /dev/null; then
        echo "🚀 启动MySQL服务..."
        brew services start mysql
        sleep 3
        
        # 验证MySQL连接
        if ! mysql -u root -e "SELECT 1;" 2>/dev/null; then
            echo "❌ MySQL连接失败，请检查MySQL服务状态"
            echo "💡 提示: 运行 'mysql -u root' 测试连接"
            exit 1
        fi
        echo "✅ MySQL服务已启动"
    else
        echo "✅ MySQL服务已运行"
    fi
    
    # 检查数据库是否存在
    if ! mysql -u root -e "USE fortune_db;" 2>/dev/null; then
        echo "🔧 创建数据库和用户..."
        mysql -u root << EOF
CREATE DATABASE IF NOT EXISTS fortune_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'fortune_user'@'localhost' IDENTIFIED BY 'fortune_password_2024';
GRANT ALL PRIVILEGES ON fortune_db.* TO 'fortune_user'@'localhost';
FLUSH PRIVILEGES;
EOF
        echo "✅ 数据库创建完成"
        
        # 初始化数据库表
        echo "🔧 初始化数据库表..."
        mysql -u fortune_user -pfortune_password_2024 fortune_db < backend/src/main/resources/sql/init-mysql.sql
        echo "✅ 数据库表初始化完成"
    fi
fi

# 检查Redis服务
echo "🔍 检查Redis服务状态..."
if ! pgrep redis-server > /dev/null; then
    echo "🚀 启动Redis服务..."
    redis-server --daemonize yes
    sleep 2
    echo "✅ Redis服务已启动"
else
    echo "✅ Redis服务已运行"
fi

# 创建日志目录
mkdir -p logs

# 启动应用
echo "🚀 启动Spring Boot应用..."
echo "环境配置: $PROFILE"
echo "JAR文件: $JAR_FILE"
echo "================================================"

# 根据环境设置不同的JVM参数
if [ "$PROFILE" = "prod" ]; then
    JVM_OPTS="-Xms512m -Xmx1024m -XX:+UseG1GC"
else
    JVM_OPTS="-Xms256m -Xmx512m"
fi

# 启动应用
java $JVM_OPTS -jar $JAR_FILE --spring.profiles.active=$PROFILE &

# 获取进程ID
APP_PID=$!
echo $APP_PID > backend.pid

echo "✅ 应用启动中，进程ID: $APP_PID"
echo "📝 进程ID已保存到 backend.pid"

# 等待应用启动
echo "⏳ 等待应用启动..."
sleep 10

# 检查应用是否启动成功
if ps -p $APP_PID > /dev/null; then
    echo "🎉 服务启动成功！"
    echo "================================================"
    
    # 根据环境设置端口
    if [ "$PROFILE" = "prod" ]; then
        PORT=8081
    else
        PORT=8080
    fi
    
    echo "🌐 访问地址: http://localhost:$PORT"
    echo "📊 健康检查: http://localhost:$PORT/actuator/health"
    echo "🔮 今日运势: http://localhost:$PORT/api/fortune/today-fortune"
    
    if [ "$PROFILE" = "dev" ]; then
        echo "🗄️  H2控制台: http://localhost:8080/h2-console"
        echo "   用户名: sa"
        echo "   密码: (空)"
        echo "   JDBC URL: jdbc:h2:mem:fortune_db"
    fi
    
    if [ "$PROFILE" = "prod" ]; then
        echo "🗄️  MySQL数据库: fortune_db"
        echo "   用户名: fortune_user"
        echo "   密码: fortune_password_2024"
    fi
    
    echo "================================================"
    echo "💡 停止服务: kill $APP_PID 或 ./stop.sh"
    echo "📋 查看日志: tail -f logs/fortune-app.log"
else
    echo "❌ 应用启动失败"
    exit 1
fi 
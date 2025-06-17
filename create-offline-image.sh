#!/bin/bash

echo "=== 创建离线Docker镜像 ==="

# 1. 创建基于scratch的最小镜像
cat > backend/Dockerfile.scratch << 'EOF'
# 使用scratch空镜像，完全离线构建
FROM scratch

# 复制本地JDK运行时（需要先提取）
COPY jre/ /opt/java/

# 设置环境变量
ENV JAVA_HOME=/opt/java
ENV PATH=$PATH:$JAVA_HOME/bin

# 设置工作目录
WORKDIR /app

# 复制应用JAR
COPY target/*.jar app.jar

# 暴露端口
EXPOSE 8080

# 启动应用
ENTRYPOINT ["/opt/java/bin/java", "-jar", "app.jar"]
EOF

# 2. 提取本地JDK运行时
echo "提取本地JDK运行时..."
if [ -d "/usr/lib/jvm/java-17-openjdk-amd64" ]; then
    JDK_PATH="/usr/lib/jvm/java-17-openjdk-amd64"
elif [ -d "/usr/lib/jvm/java-17-openjdk" ]; then
    JDK_PATH="/usr/lib/jvm/java-17-openjdk"
else
    echo "未找到JDK 17，请确认JDK安装路径"
    exit 1
fi

echo "使用JDK路径: $JDK_PATH"

# 3. 创建JRE运行时
echo "创建JRE运行时..."
mkdir -p backend/jre

# 使用jlink创建最小运行时
$JDK_PATH/bin/jlink \
    --add-modules java.base,java.logging,java.desktop,java.management,java.security.jgss,java.instrument,java.sql,java.naming,java.net.http \
    --strip-debug \
    --no-man-pages \
    --no-header-files \
    --compress=2 \
    --output backend/jre

echo "JRE运行时创建完成"

# 4. 构建Docker镜像
echo "构建Docker镜像..."
cd backend
sudo docker build -f Dockerfile.scratch -t bagua-backend:prod .

echo "=== 离线镜像构建完成 ==="
echo "镜像大小:"
sudo docker images bagua-backend:prod 
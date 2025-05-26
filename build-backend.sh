#!/bin/bash

echo "🏗️ 使用Docker构建后端项目..."

# 创建临时的构建Dockerfile
cat > backend/Dockerfile.build << 'EOF'
FROM maven:3.8.6-openjdk-11-slim

WORKDIR /app

# 复制pom.xml和源码
COPY pom.xml .
COPY src ./src

# 构建项目
RUN mvn clean package -DskipTests

# 复制构建结果到输出目录
CMD ["cp", "target/fortune-mini-app-1.0.0.jar", "/output/"]
EOF

# 创建输出目录
mkdir -p backend/target

# 使用Docker构建项目
docker run --rm \
  -v "$(pwd)/backend:/app" \
  -v "$(pwd)/backend/target:/output" \
  maven:3.8.6-openjdk-11-slim \
  sh -c "cd /app && mvn clean package -DskipTests && cp target/*.jar /output/"

echo "✅ 后端项目构建完成" 
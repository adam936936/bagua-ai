# 构建阶段 - 合并Dockerfile.build的逻辑
FROM maven:3.8.6-openjdk-17-slim AS builder

WORKDIR /app

# 复制pom.xml和源码
COPY pom.xml .
COPY src ./src

# 构建项目
RUN mvn clean package -DskipTests

# 运行阶段
FROM openjdk:17-jdk-slim

# 设置时区
ENV TZ=Asia/Shanghai

# 安装curl用于健康检查
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app

# 从构建阶段复制JAR文件
COPY --from=builder /app/target/*.jar app.jar

# 暴露端口
EXPOSE 8080

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/api/actuator/health || exit 1

# 启动应用
ENTRYPOINT ["java", "-jar", "app.jar"] 
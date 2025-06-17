# 使用官方OpenJDK镜像（最稳定）
FROM openjdk:17-jdk-slim

# 设置时区
ENV TZ=Asia/Shanghai

# 安装curl
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app

# 复制JAR文件
COPY target/*.jar app.jar

# 暴露端口
EXPOSE 8080

# 启动应用
ENTRYPOINT ["java", "-jar", "app.jar"] 
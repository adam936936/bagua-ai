# 使用Docker Hub官方OpenJDK 17镜像
FROM openjdk:17-jdk-slim

# 设置时区和编码
ENV TZ=Asia/Shanghai
ENV LANG=C.UTF-8

# 安装必要工具
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 创建应用用户
RUN groupadd -r app && useradd -r -g app app

# 设置工作目录
WORKDIR /app

# 复制预构建的JAR文件
COPY target/*.jar app.jar

# 创建日志目录
RUN mkdir -p /app/logs && chown -R app:app /app

# 切换到应用用户
USER app

# 暴露端口
EXPOSE 8080

# 设置JVM参数
ENV JAVA_OPTS="-Xms512m -Xmx1024m -XX:+UseG1GC"

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
  CMD curl -f http://localhost:8080/api/actuator/health || exit 1

# 启动应用
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"] 
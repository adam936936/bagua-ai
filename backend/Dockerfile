# 使用Eclipse Temurin官方镜像（OpenJDK的官方发行版）
FROM eclipse-temurin:17-jdk-alpine

# 设置时区和编码
ENV TZ=Asia/Shanghai
ENV LANG=C.UTF-8

# 安装curl（Alpine使用apk包管理器）
RUN apk add --no-cache curl

# 创建应用用户
RUN addgroup -g 1000 app && adduser -D -s /bin/sh -u 1000 -G app app

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
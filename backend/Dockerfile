# 使用阿里云OpenJDK 11作为基础镜像
FROM registry.cn-hangzhou.aliyuncs.com/library/openjdk:11-jre-slim

# 设置工作目录
WORKDIR /app

# 复制Maven构建的jar文件
COPY target/fortune-mini-app-1.0.0.jar app.jar

# 暴露端口
EXPOSE 8080

# 设置JVM参数
ENV JAVA_OPTS="-Xms512m -Xmx1024m -XX:+UseG1GC"

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/api/actuator/health || exit 1

# 启动应用
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"] 
#!/bin/bash

echo "=== Docker镜像拉取修复脚本 ==="

# 1. 配置Docker镜像加速器
echo "配置Docker镜像加速器..."
sudo mkdir -p /etc/docker

sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com",
    "https://dockerhub.azk8s.cn"
  ],
  "insecure-registries": [
    "docker.mirrors.ustc.edu.cn",
    "hub-mirror.c.163.com"
  ]
}
EOF

# 2. 重启Docker服务
echo "重启Docker服务..."
sudo systemctl daemon-reload
sudo systemctl restart docker

# 3. 测试不同的镜像源
echo "测试镜像拉取..."

echo "方案1: 尝试官方OpenJDK镜像"
if sudo docker pull openjdk:17-jdk-slim; then
    echo "✅ 官方镜像拉取成功"
    sudo docker build -t bagua-backend:prod ./backend
    exit 0
fi

echo "方案2: 尝试Eclipse Temurin镜像"
if sudo docker pull eclipse-temurin:17-jdk-alpine; then
    echo "✅ Eclipse Temurin镜像拉取成功"
    sudo docker build -f backend/Dockerfile.temurin -t bagua-backend:prod ./backend
    exit 0
fi

echo "方案3: 尝试Amazon Corretto镜像"
if sudo docker pull amazoncorretto:17-alpine; then
    echo "✅ Amazon Corretto镜像拉取成功"
    sudo docker build -f backend/Dockerfile.corretto -t bagua-backend:prod ./backend
    exit 0
fi

echo "方案4: 尝试手动构建基础镜像"
echo "使用本地JDK创建基础镜像..."
sudo docker build -f backend/Dockerfile.local -t bagua-backend:prod ./backend

echo "=== 修复完成 ===" 
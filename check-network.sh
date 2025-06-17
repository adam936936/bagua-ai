#!/bin/bash

echo "=== Docker网络诊断 ==="

# 1. 检查基本网络连接
echo "1. 检查网络连接..."
ping -c 3 8.8.8.8
ping -c 3 registry-1.docker.io

# 2. 检查DNS解析
echo "2. 检查DNS解析..."
nslookup registry-1.docker.io
nslookup hub.docker.com

# 3. 检查HTTP/HTTPS访问
echo "3. 检查HTTP访问..."
curl -I https://registry-1.docker.io/v2/
curl -I https://hub.docker.com

# 4. 检查Docker配置
echo "4. 检查Docker配置..."
sudo docker info | grep -A 10 "Registry Mirrors"
cat /etc/docker/daemon.json 2>/dev/null || echo "daemon.json不存在"

# 5. 检查防火墙
echo "5. 检查防火墙..."
sudo ufw status
sudo iptables -L | head -20

# 6. 检查代理设置
echo "6. 检查代理设置..."
echo "HTTP_PROXY: $HTTP_PROXY"
echo "HTTPS_PROXY: $HTTPS_PROXY"
echo "NO_PROXY: $NO_PROXY"

# 7. 尝试手动下载镜像清单
echo "7. 尝试手动下载镜像清单..."
curl -v https://registry-1.docker.io/v2/library/ubuntu/manifests/22.04

echo "=== 诊断完成 ===" 
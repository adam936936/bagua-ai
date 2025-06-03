# 腾讯云Docker部署指南

## 🚀 快速部署

### 一键部署脚本
```bash
# 1. 克隆项目到腾讯云服务器
git clone https://github.com/yourusername/bagua-ai.git
cd bagua-ai

# 2. 运行一键部署脚本
chmod +x scripts/deploy-to-tencent-cloud.sh
./scripts/deploy-to-tencent-cloud.sh
```

### 手动部署
如果您喜欢逐步部署，请参考详细文档：
- 📖 [完整部署指南](docs/TENCENT_CLOUD_DEPLOYMENT_GUIDE.md)

## 🛠️ 部署前准备

### 1. 腾讯云服务器要求
- **CPU**: 2核
- **内存**: 4GB
- **硬盘**: 40GB SSD
- **操作系统**: Ubuntu 20.04 LTS
- **带宽**: 5Mbps

### 2. 安全组配置
确保开放以下端口：
```
80    - HTTP服务
443   - HTTPS服务  
8080  - 应用端口
22    - SSH连接
```

### 3. 域名配置（可选）
```bash
# 配置DNS解析
A记录: api.yourdomain.com -> 服务器IP
A记录: www.yourdomain.com -> 服务器IP
```

## 🔧 配置要求

### 必需的API密钥
部署前请准备以下API密钥：

1. **DeepSeek API Key**
   ```bash
   # 获取地址: https://platform.deepseek.com/
   DEEPSEEK_API_KEY=your-deepseek-api-key
   ```

2. **微信小程序配置**
   ```bash
   # 微信公众平台: https://mp.weixin.qq.com/
   WECHAT_APP_ID=your-wechat-app-id
   WECHAT_APP_SECRET=your-wechat-app-secret
   ```

### 环境变量配置
脚本会自动生成 `.env` 文件，但您需要手动配置以上API密钥。

## 📋 部署步骤

### 自动部署
```bash
# 1. 连接到腾讯云服务器
ssh ubuntu@your-server-ip

# 2. 下载项目
git clone https://github.com/yourusername/bagua-ai.git
cd bagua-ai

# 3. 执行部署脚本
./scripts/deploy-to-tencent-cloud.sh
```

### 手动部署
```bash
# 1. 安装Docker和Docker Compose
sudo apt update
sudo apt install docker.io docker-compose

# 2. 创建环境配置
cp .env.example .env
vim .env  # 编辑配置

# 3. 构建和启动
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d
```

## ✅ 验证部署

### 检查服务状态
```bash
# 查看容器状态
docker-compose -f docker-compose.prod.yml ps

# 检查应用健康
curl http://localhost:8080/api/actuator/health

# 检查数据库连接
docker exec fortune-mysql-prod mysql -u fortune_user -p -e "SHOW DATABASES;"
```

### 访问地址
- **应用API**: `http://your-server-ip:8080/api`
- **健康检查**: `http://your-server-ip:8080/api/actuator/health`
- **Nginx代理**: `http://your-server-ip/api`

## 🔄 管理操作

### 查看日志
```bash
# 查看应用日志
docker-compose -f docker-compose.prod.yml logs -f backend

# 查看所有服务日志
docker-compose -f docker-compose.prod.yml logs -f
```

### 重启服务
```bash
# 重启所有服务
docker-compose -f docker-compose.prod.yml restart

# 重启单个服务
docker-compose -f docker-compose.prod.yml restart backend
```

### 更新应用
```bash
# 拉取最新代码
git pull

# 重新构建并启动
docker-compose -f docker-compose.prod.yml build backend
docker-compose -f docker-compose.prod.yml up -d backend
```

### 数据备份
```bash
# 手动备份
./backup.sh

# 自动备份已配置为每天凌晨2点执行
```

## 🛡️ 安全配置

### 防火墙设置
```bash
sudo ufw enable
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8080/tcp
```

### SSL证书（可选）
```bash
# 安装Certbot
sudo apt install certbot python3-certbot-nginx

# 获取SSL证书
sudo certbot --nginx -d yourdomain.com
```

## 📊 监控和维护

### 系统监控
```bash
# 查看系统资源
htop
df -h

# 查看Docker容器资源
docker stats
```

### 性能优化
- 调整JVM内存参数
- 优化MySQL配置
- 配置Redis缓存策略
- 启用Nginx压缩

## ❗ 故障排查

### 常见问题

1. **容器启动失败**
   ```bash
   # 查看错误日志
   docker-compose -f docker-compose.prod.yml logs container-name
   
   # 检查端口占用
   netstat -tulpn | grep :8080
   ```

2. **数据库连接失败**
   ```bash
   # 检查MySQL容器
   docker exec fortune-mysql-prod mysql -u root -p -e "SHOW DATABASES;"
   
   # 检查网络连接
   docker network ls
   ```

3. **应用无法访问**
   ```bash
   # 检查防火墙
   sudo ufw status
   
   # 检查服务端口
   curl http://localhost:8080/api/actuator/health
   ```

### 获取帮助
- 📖 查看完整文档: `docs/TENCENT_CLOUD_DEPLOYMENT_GUIDE.md`
- 📝 查看部署日志: `/tmp/deploy.log`
- 🐛 提交Issue: GitHub Issues

## 📄 相关文档

- [完整部署指南](docs/TENCENT_CLOUD_DEPLOYMENT_GUIDE.md)
- [项目架构文档](architecture.md)
- [API接口文档](api_test_report.md)
- [启动指南](START_GUIDE.md)

---

**注意**: 首次部署请仔细阅读完整部署指南，确保所有配置正确。 
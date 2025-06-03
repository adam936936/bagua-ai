# 腾讯云Docker环境部署指南（预装版）

## 🚀 适用环境

本指南专门针对腾讯云预装Docker的Ubuntu镜像，包括：
- 腾讯云轻量应用服务器 - Docker CE 镜像
- 腾讯云CVM实例 - Docker CE 应用镜像
- Ubuntu 20.04/22.04 + Docker Engine 预装环境

## ⚡ 一键部署

### 快速启动命令
```bash
# 1. SSH连接到服务器
ssh root@your-server-ip

# 2. 下载部署脚本
curl -O https://raw.githubusercontent.com/yourusername/bagua-ai/main/scripts/deploy-to-tencent-cloud-docker.sh

# 3. 运行一键部署
sudo bash deploy-to-tencent-cloud-docker.sh https://github.com/yourusername/bagua-ai.git
```

### 手动部署
如果您已经有项目文件，可以不指定Git仓库：
```bash
sudo bash deploy-to-tencent-cloud-docker.sh
```

## 🛠️ 部署前准备

### 1. 服务器要求
- **镜像选择**: 腾讯云Docker CE应用镜像
- **配置推荐**: 2核4GB，40GB SSD
- **网络**: 公网IP，5Mbps带宽

### 2. 安全组配置
确保在腾讯云控制台开放以下端口：
```
端口    协议    来源        说明
22     TCP    0.0.0.0/0   SSH连接
80     TCP    0.0.0.0/0   HTTP服务
443    TCP    0.0.0.0/0   HTTPS服务
8080   TCP    0.0.0.0/0   应用端口
```

### 3. API密钥准备
部署前请准备以下API密钥：
```bash
# DeepSeek API
DEEPSEEK_API_KEY=your-deepseek-api-key

# 微信小程序
WECHAT_APP_ID=your-wechat-app-id
WECHAT_APP_SECRET=your-wechat-app-secret
```

## 📋 详细部署步骤

### 第一步：连接服务器
```bash
# 使用root用户连接（推荐）
ssh root@your-server-ip

# 或使用ubuntu用户
ssh ubuntu@your-server-ip
```

### 第二步：检查Docker环境
```bash
# 检查Docker版本
sudo docker --version

# 检查Docker服务状态
sudo systemctl status docker

# 如果Docker未启动，启动服务
sudo systemctl start docker
sudo systemctl enable docker
```

### 第三步：运行部署脚本
```bash
# 下载部署脚本
curl -O https://raw.githubusercontent.com/yourusername/bagua-ai/main/scripts/deploy-to-tencent-cloud-docker.sh

# 设置执行权限
chmod +x deploy-to-tencent-cloud-docker.sh

# 运行部署脚本（方式一：指定Git仓库）
sudo ./deploy-to-tencent-cloud-docker.sh https://github.com/yourusername/bagua-ai.git

# 运行部署脚本（方式二：使用本地文件）
sudo ./deploy-to-tencent-cloud-docker.sh
```

### 第四步：配置API密钥
部署脚本会暂停并提示配置API密钥：
```bash
# 编辑环境配置文件
sudo vim /opt/fortune-app/.env

# 或者使用sed命令快速替换
cd /opt/fortune-app
sudo sed -i 's/your-deepseek-api-key/实际的API密钥/' .env
sudo sed -i 's/your-wechat-app-id/实际的AppID/' .env
sudo sed -i 's/your-wechat-app-secret/实际的AppSecret/' .env
```

### 第五步：验证部署
脚本执行完成后，验证服务是否正常：
```bash
# 检查容器状态
cd /opt/fortune-app
sudo docker-compose -f docker-compose.prod.yml ps

# 测试健康检查
curl http://localhost:8080/api/actuator/health

# 测试外网访问
curl http://公网IP:8080/api/actuator/health
```

## 🔧 管理操作

### 常用命令
```bash
# 进入项目目录
cd /opt/fortune-app

# 查看服务状态
./manage.sh status

# 查看应用日志
./manage.sh logs backend

# 重启服务
./manage.sh restart

# 停止服务
./manage.sh stop

# 启动服务
./manage.sh start

# 备份数据
./manage.sh backup

# 更新应用
./manage.sh update
```

### 手动操作
```bash
# 查看容器状态
sudo docker ps

# 查看服务日志
sudo docker-compose -f docker-compose.prod.yml logs -f backend

# 重启特定服务
sudo docker-compose -f docker-compose.prod.yml restart backend

# 进入容器调试
sudo docker exec -it fortune-backend-prod /bin/bash
```

## ✅ 验证清单

部署完成后，检查以下项目：

### 服务状态
- [ ] MySQL容器运行正常
- [ ] Redis容器运行正常
- [ ] Backend容器运行正常
- [ ] Nginx容器运行正常

### 网络连通性
- [ ] 内网健康检查：`http://localhost:8080/api/actuator/health`
- [ ] 外网应用访问：`http://公网IP:8080/api/actuator/health`
- [ ] Nginx代理：`http://公网IP/health`

### 安全配置
- [ ] UFW防火墙已启用
- [ ] 腾讯云安全组配置正确
- [ ] 环境变量文件权限为600

## 🔍 故障排查

### 常见问题

1. **权限不足错误**
```bash
# 解决方案：使用sudo运行
sudo ./deploy-to-tencent-cloud-docker.sh
```

2. **Docker镜像拉取失败**
```bash
# 检查网络连接
ping ccr.ccs.tencentcloudcr.com

# 重新拉取镜像
sudo docker pull ccr.ccs.tencentcloudcr.com/public/mysql:8.0
```

3. **容器启动失败**
```bash
# 查看容器日志
sudo docker-compose -f docker-compose.prod.yml logs container-name

# 检查端口占用
sudo netstat -tulpn | grep :8080
```

4. **应用无法访问**
```bash
# 检查防火墙状态
sudo ufw status

# 检查腾讯云安全组配置
# 登录腾讯云控制台查看安全组规则
```

### 日志查看
```bash
# 部署日志
tail -f /tmp/deploy.log

# 应用日志
sudo docker-compose -f docker-compose.prod.yml logs -f backend

# 系统日志
sudo journalctl -u docker.service
```

## 📊 性能监控

### 资源监控
```bash
# 查看系统资源
free -h
df -h

# 查看Docker容器资源使用
sudo docker stats

# 查看网络连接
sudo netstat -tulpn
```

### 性能优化
```bash
# 调整JVM内存（根据服务器配置）
# 编辑 docker-compose.prod.yml 中的 JAVA_OPTS

# 优化MySQL配置
# 编辑 mysql/conf.d/custom.cnf

# 配置Nginx缓存
# 编辑 nginx/nginx.conf
```

## 🔄 数据备份

### 自动备份
定时备份已自动设置（每天凌晨2点）：
```bash
# 查看定时任务
sudo crontab -l

# 查看备份日志
tail -f /var/log/backup.log
```

### 手动备份
```bash
# 执行手动备份
cd /opt/fortune-app
sudo ./backup.sh

# 查看备份文件
ls -la /backup/
```

### 备份恢复
```bash
# 解压备份文件
cd /backup
sudo tar -xzf fortune_backup_YYYYMMDD_HHMMSS.tar.gz

# 恢复MySQL数据
sudo docker exec -i fortune-mysql-prod mysql -u用户名 -p密码 数据库名 < mysql_backup.sql

# 恢复Redis数据
sudo docker cp redis_backup.rdb fortune-redis-prod:/data/dump.rdb
sudo docker restart fortune-redis-prod
```

## 📄 相关文档

- [完整部署指南](docs/TENCENT_CLOUD_DOCKER_DEPLOYMENT_GUIDE.md)
- [项目架构说明](architecture.md)
- [API接口文档](api_test_report.md)
- [启动指南](START_GUIDE.md)

## 🆘 获取帮助

如遇问题，请按以下顺序排查：

1. **查看部署日志**：`/tmp/deploy.log`
2. **查看应用日志**：`sudo docker-compose logs`
3. **检查系统状态**：`./manage.sh status`
4. **参考故障排查**：见上文故障排查章节
5. **提交Issue**：GitHub Issues

---

**重要提醒**：
- 首次部署必须使用 `sudo` 权限
- 确保API密钥配置正确
- 定期备份重要数据
- 关注腾讯云安全组配置 
# 🚀 生产环境部署快速指南

## ⚡ 快速开始

### 1. 设置环境变量

创建 `.env.prod` 文件（或直接export）：

```bash
# 方法1：创建环境变量文件
cat > .env.prod << 'EOF'
# 数据库配置
MYSQL_PASSWORD=YourSecurePassword123!@#
MYSQL_ROOT_PASSWORD=YourRootPassword123!@#

# Redis配置  
REDIS_PASSWORD=YourRedisPassword123!@#

# JWT密钥（至少32位）
JWT_SECRET=YourJWTSecretKeyAtLeast32CharactersLong2024!@#$%

# DeepSeek API密钥
DEEPSEEK_API_KEY=sk-your-real-deepseek-api-key-here

# 微信小程序配置
WECHAT_APP_ID=wx1234567890abcdef
WECHAT_APP_SECRET=your_real_wechat_app_secret_here

# 微信支付配置（可选）
WECHAT_PAY_APP_ID=wx1234567890abcdef
WECHAT_PAY_MCH_ID=1234567890
WECHAT_PAY_API_KEY=your_real_wechat_pay_api_key_here
WECHAT_PAY_NOTIFY_URL=https://your-domain.com/api/vip/notify
EOF

# 加载环境变量
source .env.prod
```

```bash
# 方法2：直接export（临时）
export MYSQL_PASSWORD="YourSecurePassword123!@#"
export MYSQL_ROOT_PASSWORD="YourRootPassword123!@#" 
export REDIS_PASSWORD="YourRedisPassword123!@#"
export JWT_SECRET="YourJWTSecretKeyAtLeast32CharactersLong2024!@#$%"
export DEEPSEEK_API_KEY="sk-your-real-deepseek-api-key-here"
export WECHAT_APP_ID="wx1234567890abcdef"
export WECHAT_APP_SECRET="your_real_wechat_app_secret_here"
```

### 2. 一键部署

```bash
# 运行部署脚本
./scripts/deploy-prod.sh
```

### 3. 手动部署（可选）

如果你想手动执行每个步骤：

```bash
# 1. 预构建应用
cd backend && mvn clean package -DskipTests && cd ..

# 2. 创建必要目录
mkdir -p logs uploads mysql/{conf.d,logs} redis/logs nginx/{ssl,logs} static

# 3. 生成SSL证书（开发用）
openssl req -x509 -newkey rsa:4096 -keyout nginx/ssl/server.key -out nginx/ssl/server.crt -days 365 -nodes -subj "/C=CN/ST=Beijing/L=Beijing/O=Fortune AI/CN=fortune-ai.com"

# 4. 启动服务
docker-compose -f docker-compose.prod.yml up -d

# 5. 验证部署
curl http://localhost:8080/api/actuator/health
```

## 🔧 配置说明

### 生产环境特点
- ✅ **SSL/HTTPS支持**：自动重定向HTTP到HTTPS
- ✅ **请求限流**：API限流10r/s，登录1r/s
- ✅ **安全头**：XSS保护、内容类型保护等
- ✅ **性能优化**：Gzip压缩、连接池优化
- ✅ **监控支持**：健康检查、指标暴露
- ✅ **日志管理**：分割日志、30天保留

### 端口分配
- **80**: HTTP（重定向到HTTPS）
- **443**: HTTPS主服务
- **8080**: 后端应用直接访问
- **8081**: 管理端点（仅内网）
- **3306**: MySQL数据库
- **6379**: Redis缓存

### 安全特性
- 🔒 **密码强度要求**：16位以上复杂密码
- 🔒 **SSL加密传输**：HTTPS强制加密
- 🔒 **管理端点限制**：仅内网IP访问
- 🔒 **请求限流**：防止攻击和滥用
- 🔒 **安全头**：XSS、CSRF保护

## 📊 验证部署

### 健康检查
```bash
# 应用健康检查
curl http://localhost:8080/api/actuator/health

# Nginx健康检查
curl http://localhost/health

# 查看容器状态
docker-compose -f docker-compose.prod.yml ps
```

### 查看日志
```bash
# 查看所有服务日志
docker-compose -f docker-compose.prod.yml logs -f

# 查看特定服务日志
docker-compose -f docker-compose.prod.yml logs -f backend-prod
docker-compose -f docker-compose.prod.yml logs -f mysql-prod
docker-compose -f docker-compose.prod.yml logs -f redis-prod
docker-compose -f docker-compose.prod.yml logs -f nginx-prod
```

## 🛠️ 管理命令

```bash
# 停止所有服务
docker-compose -f docker-compose.prod.yml down

# 重启特定服务
docker-compose -f docker-compose.prod.yml restart backend-prod

# 查看资源使用
docker stats

# 备份数据库
docker-compose -f docker-compose.prod.yml exec mysql-prod mysqldump -uroot -p${MYSQL_ROOT_PASSWORD} fortune_db > backup_$(date +%Y%m%d_%H%M%S).sql

# 备份Redis
docker-compose -f docker-compose.prod.yml exec redis-prod redis-cli -a ${REDIS_PASSWORD} --rdb /data/backup_$(date +%Y%m%d_%H%M%S).rdb
```

## 🚨 故障排查

### 常见问题
1. **环境变量未设置**：确保所有必需变量已设置
2. **端口冲突**：检查80、443、8080等端口是否被占用
3. **权限问题**：确保脚本有执行权限
4. **磁盘空间不足**：检查可用磁盘空间

### 查看详细错误
```bash
# 查看容器启动失败原因
docker-compose -f docker-compose.prod.yml logs backend-prod

# 查看详细健康检查
curl -s http://localhost:8080/api/actuator/health | jq
```

## 📈 性能监控

### 访问监控端点
- **健康检查**: http://localhost:8080/api/actuator/health
- **应用信息**: http://localhost:8080/api/actuator/info  
- **性能指标**: http://localhost:8080/api/actuator/metrics
- **Nginx状态**: http://localhost/nginx_status（仅内网）

### 推荐监控工具
- **Prometheus + Grafana**：指标监控
- **ELK Stack**：日志分析
- **Uptime Kuma**：服务可用性监控

---

🎉 **恭喜！你已经成功部署了AI八卦运势小程序的生产环境！** 
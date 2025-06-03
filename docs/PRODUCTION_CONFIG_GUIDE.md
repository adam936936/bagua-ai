# AI八卦运势小程序 - 生产环境配置指南

## 📋 配置文件总览

### 环境配置文件说明

| 配置文件 | 用途 | 说明 |
|---------|------|------|
| `application.yml` | 默认配置 | 基础配置，适用于开发环境 |
| `application-local.yml` | 本地开发 | 本地开发环境配置（已测试通过） |
| `application-docker.yml` | Docker部署 | Docker容器化部署配置 |
| `application-prod.yml` | 生产环境 | 生产环境优化配置 |

## 🏗️ 生产环境部署步骤

### 1. 环境变量配置

创建 `.env` 文件，配置以下环境变量：

```bash
# 数据库配置
MYSQL_HOST=your-mysql-host
MYSQL_PORT=3306
MYSQL_DATABASE=fortune_db
MYSQL_USERNAME=fortune_user
MYSQL_PASSWORD=your_secure_mysql_password

# Redis配置
REDIS_HOST=your-redis-host
REDIS_PORT=6379
REDIS_PASSWORD=your_secure_redis_password

# JWT配置
JWT_SECRET=your_jwt_secret_key_at_least_32_characters_long

# DeepSeek AI API配置
DEEPSEEK_API_KEY=sk-your-deepseek-api-key

# 微信小程序配置
WECHAT_APP_ID=wx1234567890abcdef
WECHAT_APP_SECRET=your_wechat_app_secret

# 微信支付配置（可选）
WECHAT_PAY_APP_ID=wx1234567890abcdef
WECHAT_PAY_MCH_ID=1234567890
WECHAT_PAY_API_KEY=your_wechat_pay_api_key
WECHAT_PAY_NOTIFY_URL=https://your-domain.com/api/vip/notify
```

### 2. 应用配置选择

根据部署方式选择对应的配置文件：

#### 本地开发环境
```bash
export SPRING_PROFILES_ACTIVE=local
```

#### Docker部署
```bash
export SPRING_PROFILES_ACTIVE=docker
```

#### 生产环境
```bash
export SPRING_PROFILES_ACTIVE=prod
```

### 3. 数据库初始化

生产环境部署前，确保：

1. **创建数据库**：
```sql
CREATE DATABASE fortune_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'fortune_user'@'%' IDENTIFIED BY 'your_secure_password';
GRANT ALL PRIVILEGES ON fortune_db.* TO 'fortune_user'@'%';
FLUSH PRIVILEGES;
```

2. **运行初始化脚本**：
```bash
mysql -h $MYSQL_HOST -u $MYSQL_USERNAME -p$MYSQL_PASSWORD $MYSQL_DATABASE < backend/src/main/resources/sql/init.sql
```

### 4. 应用构建和启动

#### 传统部署方式
```bash
# 1. 构建应用
cd backend
mvn clean package -DskipTests -Pprod

# 2. 启动应用
java -jar -Dspring.profiles.active=prod target/fortune-mini-app-*.jar
```

#### Docker部署方式
```bash
# 1. 构建应用
cd backend && mvn clean package -DskipTests

# 2. 启动Docker容器
docker-compose up -d

# 3. 验证部署
curl http://localhost/api/actuator/health
```

## 🔧 配置文件详解

### 生产环境优化项

#### 数据源优化
- 连接池大小：最小10，最大50
- SSL连接：启用SSL加密
- 连接泄漏检测：60秒超时检测

#### JPA配置优化
- DDL模式：`validate`（不自动创建表）
- SQL日志：关闭（提高性能）
- 批处理：启用批量插入/更新

#### Redis优化
- 连接池：最大16个活跃连接
- 超时：5秒连接超时
- 密码认证：强制密码验证

#### 日志配置
- 日志级别：INFO/WARN
- 文件滚动：100MB文件大小，保留30天
- 日志路径：`/app/logs/fortune-app.log`

#### 管理端点安全
- 端点暴露：仅暴露health、info、metrics
- 健康检查：需要授权才显示详情
- 管理端口：8081（与应用端口分离）

## 🔐 安全配置建议

### 1. 密码安全
- 数据库密码：至少16位，包含字母数字特殊字符
- Redis密码：至少12位强密码
- JWT密钥：至少32位随机字符串

### 2. 网络安全
- 数据库：限制访问IP
- Redis：启用密码认证
- 应用：配置防火墙规则

### 3. 证书配置
- SSL证书：配置HTTPS
- 微信支付证书：上传到安全目录

## 📊 监控和日志

### 应用监控
- 健康检查：`/api/actuator/health`
- 应用信息：`/api/actuator/info`
- 性能指标：`/api/actuator/metrics`

### 日志监控
```bash
# 查看应用日志
tail -f /app/logs/fortune-app.log

# 查看错误日志
grep -i error /app/logs/fortune-app.log

# 查看访问统计
grep -c "GET\|POST" /var/log/nginx/access.log
```

## 🚀 部署验证清单

### 启动验证
- [ ] 应用正常启动
- [ ] 数据库连接成功
- [ ] Redis连接成功
- [ ] 健康检查通过

### 功能验证
- [ ] API接口响应正常
- [ ] 微信登录功能正常
- [ ] DeepSeek AI调用正常
- [ ] 日志记录正常

### 性能验证
- [ ] 响应时间 < 2秒
- [ ] 内存使用 < 1GB
- [ ] CPU使用率 < 50%
- [ ] 数据库连接池正常

## 🔄 维护和更新

### 应用更新流程
1. 备份当前版本
2. 停止应用服务
3. 更新应用文件
4. 更新数据库结构（如需要）
5. 启动新版本
6. 验证功能正常

### 数据备份
```bash
# 数据库备份
mysqldump -h $MYSQL_HOST -u $MYSQL_USERNAME -p$MYSQL_PASSWORD $MYSQL_DATABASE > backup_$(date +%Y%m%d_%H%M%S).sql

# Redis备份
redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD --rdb backup_$(date +%Y%m%d_%H%M%S).rdb
```

## 📞 故障排查

### 常见问题
1. **数据库连接失败**：检查网络、密码、防火墙
2. **Redis连接失败**：检查密码、端口、网络
3. **API调用失败**：检查API密钥、网络连接
4. **内存不足**：调整JVM参数，增加服务器内存

### 日志分析
```bash
# 查看启动错误
grep -A 10 -B 10 "Failed to start" /app/logs/fortune-app.log

# 查看数据库错误
grep -i "SQLException\|database" /app/logs/fortune-app.log

# 查看Redis错误
grep -i "redis\|connection" /app/logs/fortune-app.log
``` 
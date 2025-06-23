# Ubuntu生产环境快速部署指南

## 八卦运势AI小程序 - Docker环境优先部署

### 🚀 快速开始

本指南提供两种部署方式：
1. **完整部署** - 从源码开始构建并部署（推荐首次部署）
2. **快速启动** - 适用于已构建项目的快速启动

---

## 📋 系统要求

- **操作系统**: Ubuntu 18.04+ (推荐 Ubuntu 20.04/22.04)
- **权限**: root 或 sudo 权限
- **网络**: 可访问互联网（用于下载Docker镜像）
- **硬件**: 最低2GB内存，推荐4GB+

---

## 🎯 方式一：完整部署（首次部署推荐）

### 1. 准备工作

```bash
# 1. 克隆项目（如果还没有）
git clone <your-repo-url>
cd bagua-ai

# 2. 检查项目结构
ls -la
```

### 2. 一键完整部署

```bash
# 运行完整部署脚本
./ubuntu-quick-deploy.sh
```

**脚本功能：**
- ✅ 自动检查系统环境
- ✅ 安装Docker和Docker Compose
- ✅ 安装Node.js和Java环境
- ✅ 构建前端应用（H5版本 + 微信小程序版本）
- ✅ 构建后端应用
- ✅ 创建Docker镜像
- ✅ 按顺序部署：前端 → 后端
- ✅ 自动验证部署结果

### 3. 部署选项

```bash
# 跳过构建步骤（适用于已构建的项目）
./ubuntu-quick-deploy.sh --skip-build

# 只部署前端
./ubuntu-quick-deploy.sh --skip-backend

# 只部署后端
./ubuntu-quick-deploy.sh --skip-frontend

# 查看帮助
./ubuntu-quick-deploy.sh --help
```

---

## ⚡ 方式二：快速启动（适用于已构建项目）

### 1. 前置条件

确保以下文件存在：
- `backend/target/fortune-mini-app-1.0.0.jar` - 后端JAR文件
- `config/prod.env` - 生产环境配置
- `docker-compose.public.yml` - Docker编排文件

### 2. 构建后端（如果需要）

```bash
cd backend
mvn clean package -DskipTests
cd ..
```

### 3. 构建前端（如果需要）

```bash
cd frontend
npm install
npm run build:h5          # 构建H5版本
npm run build:mp-weixin   # 构建微信小程序版本
cd ..
```

### 4. 一键快速启动

```bash
# 运行快速启动脚本
./ubuntu-quick-start.sh
```

**脚本功能：**
- ✅ 检查Docker环境和必要文件
- ✅ 自动创建Nginx配置
- ✅ 按顺序启动：前端 → 数据库 → 后端
- ✅ 自动验证服务状态

---

## 🌐 服务访问地址

部署成功后，可以通过以下地址访问：

| 服务 | 地址 | 说明 |
|------|------|------|
| 前端Web应用 | http://localhost | 用户界面 |
| 后端API接口 | http://localhost:8080 | REST API |
| 数据库 | localhost:3306 | MySQL数据库 |
| Redis缓存 | localhost:6379 | Redis缓存 |

---

## 🔧 管理命令

### 查看服务状态
```bash
# 查看所有Docker容器
docker ps

# 查看服务状态
docker-compose -f docker-compose.public.yml ps
```

### 查看日志
```bash
# 查看前端日志
docker logs bagua-frontend-prod

# 查看后端日志
docker-compose -f docker-compose.public.yml logs -f backend

# 查看数据库日志
docker-compose -f docker-compose.public.yml logs -f mysql
```

### 服务控制
```bash
# 停止所有服务
docker-compose -f docker-compose.public.yml down
docker stop bagua-frontend-prod 2>/dev/null || true

# 重启服务
./ubuntu-quick-start.sh

# 重新构建并部署
./ubuntu-quick-deploy.sh
```

---

## 🧪 测试验证

### 健康检查
```bash
# 前端健康检查
curl http://localhost/health

# 后端健康检查
curl http://localhost:8080/api/actuator/health
```

### API测试
```bash
# 测试运势计算API
curl -X POST http://localhost:8080/api/fortune/calculate \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "测试用户",
    "birthDate": "1990-01-01",
    "birthTime": "子时",
    "gender": "male"
  }'
```

---

## 🛠️ 故障排除

### 常见问题

#### 1. Docker未运行
```bash
# 启动Docker服务
sudo systemctl start docker
sudo systemctl enable docker
```

#### 2. 端口被占用
```bash
# 检查端口占用
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :8080

# 停止占用端口的进程
sudo kill -9 <PID>
```

#### 3. 权限问题
```bash
# 将用户添加到docker组
sudo usermod -aG docker $USER
# 重新登录或运行
newgrp docker
```

#### 4. 构建失败
```bash
# 清理Maven缓存
cd backend
mvn clean
rm -rf target/
mvn package -DskipTests

# 清理npm缓存
cd frontend
rm -rf node_modules/
rm package-lock.json
npm install
```

### 日志查看
```bash
# 查看详细错误日志
docker-compose -f docker-compose.public.yml logs --tail=100 backend
docker logs bagua-frontend-prod --tail=100
```

---

## 📁 项目结构

```
bagua-ai/
├── ubuntu-quick-deploy.sh      # 完整部署脚本
├── ubuntu-quick-start.sh       # 快速启动脚本
├── docker-compose.public.yml   # Docker编排文件
├── config/
│   └── prod.env               # 生产环境配置
├── frontend/                  # 前端项目
│   ├── package.json
│   ├── dist/                  # 构建输出
│   └── src/
├── backend/                   # 后端项目
│   ├── pom.xml
│   ├── target/                # 构建输出
│   └── src/
├── nginx/                     # Nginx配置
├── logs/                      # 日志目录
└── uploads/                   # 上传文件目录
```

---

## 🔒 安全配置

### 生产环境建议

1. **修改默认密码**
   ```bash
   # 编辑配置文件
   nano config/prod.env
   
   # 修改以下配置
   MYSQL_ROOT_PASSWORD=your-secure-password
   MYSQL_PASSWORD=your-secure-password
   REDIS_PASSWORD=your-secure-password
   JWT_SECRET=your-jwt-secret
   ```

2. **配置防火墙**
   ```bash
   # 安装ufw
   sudo apt install ufw
   
   # 配置防火墙规则
   sudo ufw allow 22/tcp      # SSH
   sudo ufw allow 80/tcp      # HTTP
   sudo ufw allow 443/tcp     # HTTPS
   sudo ufw enable
   ```

3. **配置SSL证书**（可选）
   ```bash
   # 使用Let's Encrypt
   sudo apt install certbot
   sudo certbot --nginx -d your-domain.com
   ```

---

## 📞 支持

如果遇到问题，请：

1. 查看日志输出
2. 检查[故障排除](#故障排除)部分
3. 提交Issue到项目仓库

---

## 📝 更新日志

- **v1.0.0** (2025-01-17)
  - 初始版本
  - 支持完整部署和快速启动
  - Docker环境优先
  - 前端→后端部署顺序

---

**祝您部署顺利！🎉** 
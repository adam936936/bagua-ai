# 腾讯云部署脚本对比指南

## 📋 脚本概览

本项目提供了三个不同的腾讯云部署脚本，分别适用于不同的使用场景和需求：

| 脚本名称 | 复杂度 | 功能完整性 | 适用场景 | 执行时间 |
|---------|--------|------------|----------|----------|
| **统一版** | ⭐⭐⭐⭐⭐ | 完整 | 生产环境 | 15-30分钟 |
| **Docker版** | ⭐⭐⭐⭐ | 专业 | 预装Docker | 10-20分钟 |
| **快速版** | ⭐⭐ | 基础 | 快速测试 | 5-15分钟 |

## 🚀 1. 统一版 (deploy-to-tencent-cloud-unified.sh)

### 📝 特点
- **最完整的解决方案**，集成了所有功能
- 支持多种部署模式和可选组件
- 完善的错误处理和日志记录
- 详细的系统检查和优化配置

### 🎯 适用场景
- ✅ 生产环境部署
- ✅ 需要完整功能的项目
- ✅ 对稳定性要求高的场景
- ✅ 需要SSL、监控等高级功能

### 🛠️ 使用方法
```bash
# 基础部署
sudo ./scripts/deploy-to-tencent-cloud-unified.sh

# 使用预装Docker模式
sudo ./scripts/deploy-to-tencent-cloud-unified.sh --docker-preinstall

# 完整部署（包含SSL和监控）
sudo ./scripts/deploy-to-tencent-cloud-unified.sh --ssl --monitoring

# 指定Git仓库和自定义目录
sudo ./scripts/deploy-to-tencent-cloud-unified.sh --project-dir /var/www/app https://github.com/user/repo.git
```

### 🔧 功能特性
- ✅ 自动系统检查和优化
- ✅ Docker和Docker Compose自动安装
- ✅ 腾讯云镜像加速配置
- ✅ 完整的防火墙配置
- ✅ SSL/HTTPS支持（可选）
- ✅ 监控组件（可选）
- ✅ 自动备份和恢复
- ✅ 详细的管理脚本
- ✅ 定时任务设置
- ✅ 健康检查和故障恢复

---

## 🐳 2. Docker版 (deploy-to-tencent-cloud-docker.sh)

### 📝 特点
- **专为腾讯云Docker镜像设计**
- 针对预装Docker环境优化
- 包含完整的Docker配置和优化
- 详细的容器管理功能

### 🎯 适用场景
- ✅ 腾讯云Docker CE镜像
- ✅ 已有Docker环境的服务器
- ✅ 需要专业Docker配置
- ✅ 容器化部署优先

### 🛠️ 使用方法
```bash
# 基础部署
sudo ./scripts/deploy-to-tencent-cloud-docker.sh

# 指定Git仓库
sudo ./scripts/deploy-to-tencent-cloud-docker.sh https://github.com/user/repo.git
```

### 🔧 功能特性
- ✅ Docker环境检查和优化
- ✅ 腾讯云镜像仓库配置
- ✅ 完整的容器编排
- ✅ 数据卷管理
- ✅ 网络配置优化
- ✅ 容器健康检查
- ✅ 自动重启策略
- ✅ 日志管理
- ✅ 备份和恢复脚本

---

## ⚡ 3. 快速版 (deploy-to-tencent-cloud-quick.sh)

### 📝 特点
- **最简化的部署流程**
- 专注核心功能，快速上线
- 最少的用户交互
- 适合快速测试和演示

### 🎯 适用场景
- ✅ 快速测试部署
- ✅ 演示环境搭建
- ✅ 开发环境部署
- ✅ 初学者使用

### 🛠️ 使用方法
```bash
# 快速部署
sudo ./scripts/deploy-to-tencent-cloud-quick.sh

# 指定Git仓库
sudo ./scripts/deploy-to-tencent-cloud-quick.sh https://github.com/user/repo.git
```

### 🔧 功能特性
- ✅ 自动Docker安装
- ✅ 基础环境配置
- ✅ 一键部署启动
- ✅ 简化的管理脚本
- ✅ 基础防火墙配置
- ✅ 健康检查验证

---

## 🤔 如何选择合适的脚本？

### 生产环境推荐
```bash
# 选择统一版，功能最完整
sudo ./scripts/deploy-to-tencent-cloud-unified.sh --ssl --monitoring
```

### 腾讯云Docker镜像推荐
```bash
# 选择Docker版，专业优化
sudo ./scripts/deploy-to-tencent-cloud-docker.sh
```

### 快速测试推荐
```bash
# 选择快速版，简单快捷
sudo ./scripts/deploy-to-tencent-cloud-quick.sh
```

## 📊 详细对比表

| 功能特性 | 统一版 | Docker版 | 快速版 |
|---------|--------|----------|--------|
| 系统检查 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| Docker安装 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| 环境配置 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| 安全配置 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |
| 监控功能 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ❌ |
| SSL支持 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ❌ |
| 备份恢复 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ❌ |
| 错误处理 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |
| 管理脚本 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |
| 文档支持 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |

## 🔧 共同特性

所有脚本都包含以下基础功能：

### ✅ 基础功能
- Ubuntu系统支持
- Docker环境搭建
- MySQL + Redis + 后端 + Nginx
- 环境变量配置
- 基础防火墙设置
- 健康检查验证

### ✅ 管理功能
- 服务启动/停止/重启
- 日志查看
- 状态监控
- 基础管理脚本

### ✅ 安全功能
- 随机密码生成
- 文件权限设置
- 用户权限管理
- 基础防火墙规则

## 🚨 注意事项

### 通用注意事项
1. **必须使用 `sudo` 权限**运行所有脚本
2. **确保服务器网络连接正常**
3. **推荐至少4GB内存、10GB磁盘空间**
4. **仅支持Ubuntu 18.04+系统**

### API密钥配置
所有脚本部署后都需要配置API密钥：
```bash
cd /opt/fortune-app  # 或你的项目目录
vim .env

# 配置以下参数
DEEPSEEK_API_KEY=your-actual-api-key
WECHAT_APP_ID=your-actual-app-id
WECHAT_APP_SECRET=your-actual-app-secret
```

### 腾讯云安全组
确保在腾讯云控制台配置安全组规则：
- **入站规则**：22(SSH), 80(HTTP), 443(HTTPS), 8081(API)
- **出站规则**：全部允许

## 📞 技术支持

### 部署后验证
```bash
# 检查服务状态
cd /opt/fortune-app
./manage.sh status

# 查看应用日志
./manage.sh logs

# 测试API接口
curl http://localhost:8081/actuator/health
```

### 常见问题
1. **Docker权限问题**：重新登录或使用 `newgrp docker`
2. **端口占用**：检查是否有其他服务占用端口
3. **内存不足**：升级服务器配置或优化应用设置
4. **网络问题**：检查防火墙和安全组配置

### 获取帮助
```bash
# 查看脚本帮助
sudo ./scripts/deploy-to-tencent-cloud-unified.sh --help
sudo ./scripts/deploy-to-tencent-cloud-docker.sh --help

# 查看部署日志
tail -f /tmp/deploy.log
```

---

## 🎯 总结

- **生产环境**：选择 `deploy-to-tencent-cloud-unified.sh`
- **Docker专业**：选择 `deploy-to-tencent-cloud-docker.sh`  
- **快速测试**：选择 `deploy-to-tencent-cloud-quick.sh`

根据你的具体需求和环境选择最合适的部署脚本，确保项目能够稳定高效地运行！ 
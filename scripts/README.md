# 脚本文件组织结构

本目录包含AI八卦运势小程序项目的所有Shell脚本，按功能领域进行分类管理。

## 📁 目录结构

```
scripts/
├── deployment/     # 部署相关脚本
├── development/    # 开发相关脚本  
├── testing/        # 测试相关脚本
├── security/       # 安全检查脚本
├── verification/   # 功能验证脚本
└── README.md       # 本说明文档
```

## 🚀 deployment/ - 部署相关脚本

| 脚本名称 | 功能描述 | 使用方法 |
|---------|---------|---------|
| `start-all.sh` | 同时启动前后端服务 | `./scripts/deployment/start-all.sh` |
| `start-backend.sh` | 启动后端Spring Boot服务 | `./scripts/deployment/start-backend.sh` |
| `start-frontend.sh` | 启动前端uni-app服务 | `./scripts/deployment/start-frontend.sh` |
| `start.sh` | 完整的项目启动脚本 | `./scripts/deployment/start.sh` |
| `stop.sh` | 停止所有服务 | `./scripts/deployment/stop.sh` |
| `stop-all.sh` | 停止所有相关进程 | `./scripts/deployment/stop-all.sh` |
| `restart-backend.sh` | 重启后端服务 | `./scripts/deployment/restart-backend.sh` |
| `build-backend.sh` | 构建后端项目 | `./scripts/deployment/build-backend.sh` |
| `push_to_git.sh` | 推送代码到Git仓库 | `./scripts/deployment/push_to_git.sh` |

## 🛠️ development/ - 开发相关脚本

| 脚本名称 | 功能描述 | 使用方法 |
|---------|---------|---------|
| `start-local.sh` | 本地开发环境启动 | `./scripts/development/start-local.sh` |
| `start-simple.sh` | 简化版本启动脚本 | `./scripts/development/start-simple.sh` |
| `start-miniprogram-dev.sh` | 微信小程序开发环境启动 | `./scripts/development/start-miniprogram-dev.sh` |
| `check-miniprogram-config.sh` | 检查小程序配置 | `./scripts/development/check-miniprogram-config.sh` |
| `check-ports.sh` | 检查端口占用情况 | `./scripts/development/check-ports.sh` |

## 🧪 testing/ - 测试相关脚本

| 脚本名称 | 功能描述 | 使用方法 |
|---------|---------|---------|
| `test-api.sh` | API接口功能测试 | `./scripts/testing/test-api.sh [dev\|prod]` |
| `test-mvp.sh` | MVP功能完整性测试 | `./scripts/testing/test-mvp.sh` |

## 🔒 security/ - 安全检查脚本

| 脚本名称 | 功能描述 | 使用方法 |
|---------|---------|---------|
| `security-check.sh` | 全面安全检查，检测敏感信息泄露 | `./scripts/security/security-check.sh` |

## ✅ verification/ - 功能验证脚本

| 脚本名称 | 功能描述 | 使用方法 |
|---------|---------|---------|
| `verify-mvp.sh` | MVP功能验证 | `./scripts/verification/verify-mvp.sh` |
| `verify-ui-update.sh` | UI更新验证 | `./scripts/verification/verify-ui-update.sh` |
| `verify-history-hidden.sh` | 历史记录隐藏功能验证 | `./scripts/verification/verify-history-hidden.sh` |
| `verify-nickname-hidden.sh` | 昵称隐藏功能验证 | `./scripts/verification/verify-nickname-hidden.sh` |
| `verify-page-swap.sh` | 页面切换功能验证 | `./scripts/verification/verify-page-swap.sh` |

## 🎯 常用操作指南

### 快速启动项目
```bash
# 启动完整服务（推荐）
./scripts/deployment/start-all.sh

# 或者分别启动
./scripts/deployment/start-backend.sh
./scripts/deployment/start-frontend.sh
```

### 开发环境
```bash
# 本地开发环境
./scripts/development/start-local.sh

# 微信小程序开发
./scripts/development/start-miniprogram-dev.sh
```

### 测试验证
```bash
# API接口测试
./scripts/testing/test-api.sh

# 功能验证
./scripts/verification/verify-mvp.sh

# 安全检查
./scripts/security/security-check.sh
```

### 停止服务
```bash
# 停止所有服务
./scripts/deployment/stop-all.sh
```

## 📝 脚本使用注意事项

1. **权限设置**: 所有脚本都已设置执行权限，如遇权限问题请运行：
   ```bash
   chmod +x scripts/**/*.sh
   ```

2. **环境变量**: 部分脚本需要环境变量，特别是 `DEEPSEEK_API_KEY`

3. **依赖检查**: 脚本会自动检查必要的依赖（Java、Maven、Node.js等）

4. **日志输出**: 大部分脚本都有彩色输出，便于识别状态

5. **错误处理**: 脚本包含错误处理逻辑，遇到问题会给出明确提示

## 🔧 维护说明

- 新增脚本请按功能分类放入对应目录
- 更新脚本后请同步更新本README文档
- 建议为新脚本添加详细的注释和错误处理
- 保持脚本的一致性（颜色输出、错误处理等）

## 📞 技术支持

如遇到脚本使用问题，请查看：
1. 项目根目录的 `START_GUIDE.md`
2. 各脚本内的注释说明
3. 项目的 `README.md` 文档 
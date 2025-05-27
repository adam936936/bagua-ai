# AI八卦运势小程序 - 启动脚本总结

## 📁 脚本文件列表

| 脚本文件 | 功能描述 | 使用场景 |
|---------|---------|---------|
| `scripts/check-ports.sh` | 检查端口占用并提供清理选项 | 启动前检查 |
| `scripts/start-backend.sh` | 完整的后端启动流程 | 首次启动后端 |
| `scripts/start-frontend.sh` | 完整的前端启动流程 | 首次启动前端 |
| `scripts/restart-backend.sh` | 快速重启后端服务 | 后端代码更新后 |
| `scripts/stop-all.sh` | 停止所有服务并清理端口 | 关闭所有服务 |

## 🔧 脚本功能特点

### 1. 端口占用自动检查
- 每次启动前自动检查8080和3000端口
- 提供交互式选择是否杀死占用进程
- 支持强制清理端口占用

### 2. 环境检查
- Java版本检查
- Maven版本检查
- Node.js和npm版本检查
- MySQL客户端可用性检查

### 3. 错误处理
- 详细的错误信息输出
- 彩色输出便于识别状态
- 失败时自动退出并提示

### 4. 用户友好
- 清晰的步骤提示
- 进度显示
- 详细的使用说明

## 🚀 使用流程

### 标准启动流程
```bash
# 1. 检查端口（可选，启动脚本会自动检查）
./scripts/check-ports.sh

# 2. 启动后端
./scripts/start-backend.sh

# 3. 启动前端（新终端窗口）
./scripts/start-frontend.sh
```

### 开发过程中的常用操作
```bash
# 后端代码更新后快速重启
./scripts/restart-backend.sh

# 完全停止所有服务
./scripts/stop-all.sh
```

## ⚠️ 重要注意事项

### 1. 端口占用问题
- **问题**: 8080端口被占用是最常见的启动失败原因
- **解决**: 脚本会自动检测并提供清理选项
- **预防**: 使用`stop-all.sh`正确关闭服务

### 2. 目录要求
- 所有脚本必须在项目根目录执行
- 脚本会自动检查项目结构
- 确保`backend/pom.xml`和`frontend/package.json`存在

### 3. 权限要求
- 脚本需要执行权限：`chmod +x scripts/*.sh`
- 可能需要sudo权限来杀死某些进程

## 📊 测试结果

### 端口检查脚本测试
```bash
$ ./scripts/check-ports.sh
=== 端口占用检查 ===
检查8080端口（后端）...
⚠️  端口8080被占用，进程ID: 17130
是否要杀死占用进程？(y/n): y
正在杀死进程...
✅ 进程已杀死，端口8080现在可用
检查3000端口（前端开发服务器）...
✅ 端口3000可用
=== 端口检查完成 ===
```

### 后端启动测试
```bash
$ ./scripts/start-backend.sh
=== AI八卦运势小程序后端启动 ===
步骤1: 检查端口占用
✅ 端口8080可用
步骤2: 检查Java环境
✅ Java版本: 17.0.15
步骤3: 检查Maven环境
✅ Apache Maven 3.9.6
步骤4: 检查数据库连接
✅ MySQL客户端可用
步骤5: 启动Spring Boot应用
正在编译和启动应用...
```

### API测试
```bash
$ curl -s http://localhost:8080/api/fortune/today-fortune
{"code":200,"message":"操作成功","data":"【今日运势】..."}
```

## 🔍 故障排除

### 1. 脚本无法执行
```bash
# 检查权限
ls -la scripts/
# 赋予权限
chmod +x scripts/*.sh
```

### 2. 端口仍被占用
```bash
# 查看详细进程信息
lsof -i:8080
# 强制杀死所有相关进程
pkill -f "spring-boot:run"
```

### 3. Maven命令失败
```bash
# 检查Maven安装
mvn -version
# 检查Java环境
java -version
# 清理Maven缓存
mvn clean
```

### 4. 前端依赖问题
```bash
cd frontend
rm -rf node_modules package-lock.json
npm cache clean --force
npm install
```

## 📈 性能优化建议

### 1. 启动速度优化
- 使用Maven守护进程：`mvn -T 1C spring-boot:run`
- 预编译项目：`mvn compile`
- 使用开发配置文件

### 2. 资源使用优化
- 限制JVM内存：`export MAVEN_OPTS="-Xmx1024m"`
- 使用并行编译：`mvn -T 4 compile`

### 3. 开发效率提升
- 使用热重载：Spring Boot DevTools
- 配置IDE自动编译
- 使用代码监控工具

## 📝 维护建议

### 1. 定期更新
- 检查脚本兼容性
- 更新环境检查逻辑
- 添加新的错误处理

### 2. 日志管理
- 定期清理日志文件
- 配置日志轮转
- 监控磁盘空间使用

### 3. 安全考虑
- 避免在脚本中硬编码敏感信息
- 使用环境变量管理配置
- 定期检查脚本权限

## 🎯 总结

这套启动脚本解决了以下关键问题：

1. **端口占用问题** - 自动检测和清理
2. **环境检查** - 确保所有依赖正常
3. **错误处理** - 提供清晰的错误信息和解决建议
4. **用户体验** - 简化启动流程，减少手动操作

通过使用这些脚本，开发者可以：
- 快速启动和停止服务
- 避免常见的端口占用问题
- 获得清晰的状态反馈
- 减少环境配置错误

建议将这些脚本集成到开发工作流中，提高开发效率。 
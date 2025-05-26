# 八卦AI项目端口配置说明

## 🌐 端口分配

### 后端服务端口
- **开发环境 (dev)：** `8080`
- **生产环境 (prod)：** `8081`

### 前端服务端口
- **测试页面：** `3000`
- **UniApp开发服务器：** `3001` (待配置)

### 数据库服务端口
- **MySQL：** `3306`
- **Redis：** `6379`
- **H2控制台：** `8080/h2-console` (仅开发环境)

## 🚀 启动命令

### 后端服务
```bash
# 开发环境 (端口8080)
./start.sh dev

# 生产环境 (端口8081)
./start.sh prod
```

### API测试
```bash
# 测试开发环境 (端口8080)
./test-api.sh dev

# 测试生产环境 (端口8081)
./test-api.sh prod
```

### 前端测试页面
```bash
# 启动测试页面 (端口3000)
python3 -m http.server 3000
```

## 🔗 访问地址

### 开发环境 (dev)
- **API基础地址：** http://localhost:8080/api
- **健康检查：** http://localhost:8080/actuator/health
- **今日运势：** http://localhost:8080/api/fortune/today-fortune
- **H2控制台：** http://localhost:8080/h2-console

### 生产环境 (prod)
- **API基础地址：** http://localhost:8081/api
- **健康检查：** http://localhost:8081/actuator/health
- **今日运势：** http://localhost:8081/api/fortune/today-fortune

### 前端测试页面
- **测试页面：** http://localhost:3000/test-frontend.html

## ⚙️ 配置文件

### 开发环境配置
文件：`backend/src/main/resources/application-dev.yml`
```yaml
server:
  port: 8080
```

### 生产环境配置
文件：`backend/src/main/resources/application-prod.yml`
```yaml
server:
  port: 8081
```

## 🔧 端口冲突解决

### 检查端口占用
```bash
# 检查8080端口
lsof -i :8080

# 检查8081端口
lsof -i :8081

# 检查所有相关端口
lsof -i :8080 -i :8081 -i :3000 -i :3306 -i :6379
```

### 停止服务
```bash
# 停止后端服务
./stop.sh

# 停止特定端口的进程
kill $(lsof -t -i:8080)
kill $(lsof -t -i:8081)
```

## 📱 小程序配置

### 开发环境
在小程序代码中配置开发环境API地址：
```javascript
const API_BASE_DEV = 'http://localhost:8080/api';
```

### 生产环境
在小程序代码中配置生产环境API地址：
```javascript
const API_BASE_PROD = 'http://localhost:8081/api';
// 或者使用实际的服务器地址
const API_BASE_PROD = 'https://your-domain.com/api';
```

## 🌟 最佳实践

1. **开发调试：** 使用开发环境(8080)进行日常开发和调试
2. **生产测试：** 使用生产环境(8081)进行部署前的最终测试
3. **并行运行：** 可以同时运行开发和生产环境进行对比测试
4. **端口管理：** 定期检查端口占用，避免冲突
5. **文档更新：** 端口变更时及时更新相关文档

## 🔍 故障排除

### 常见问题
1. **端口被占用：** 使用`lsof`命令检查并停止占用进程
2. **服务无法访问：** 检查防火墙设置和端口配置
3. **API调用失败：** 确认使用正确的端口号
4. **数据库连接失败：** 检查MySQL和Redis服务状态

### 解决步骤
1. 检查服务状态：`./test-api.sh [env]`
2. 查看日志：`tail -f logs/fortune-app.log`
3. 重启服务：`./stop.sh && ./start.sh [env]`
4. 检查配置：确认配置文件中的端口设置

---

**💡 提示：** 建议在开发过程中保持端口配置的一致性，避免频繁修改端口号。 
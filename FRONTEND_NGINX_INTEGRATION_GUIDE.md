# 前端代码与Nginx关联操作指南

## 🔗 关联机制图解

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   前端源码      │    │   构建产物        │    │   Nginx容器     │
│   frontend/     │    │   dist/build/h5/  │    │   /usr/share/   │
│   src/          │───►│   ├── index.html  │───►│   nginx/html/   │
│   pages/        │    │   ├── static/     │    │   ├── index.html│
│   components/   │    │   └── assets/     │    │   ├── static/   │
│   ...           │    │                   │    │   └── assets/   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
      ↓                          ↓                       ↓
  npm run build:h5         Docker Volume Mount      Nginx serves files
```

## 🚀 具体操作步骤

### 第1步：检查前端项目结构

```bash
# 确认在项目根目录
pwd
# 应该显示: /path/to/bagua-ai

# 查看前端目录结构
ls -la frontend/
```

期望看到：
```
frontend/
├── src/                # 源代码
├── dist/               # 构建产物（可能不存在）
├── package.json        # 项目配置
├── vite.config.js      # 构建配置
└── ...
```

### 第2步：执行前端构建

```bash
# 进入前端目录
cd frontend

# 安装依赖（如果首次）
npm install

# 构建H5版本
npm run build:h5

# 检查构建结果
ls -la dist/build/h5/
```

构建成功后会看到：
```
dist/build/h5/
├── index.html          # 主页面
├── static/             # 静态资源
│   ├── css/           # 样式文件
│   ├── js/            # JavaScript文件
│   └── fonts/         # 字体文件
├── manifest.json      # PWA配置
└── favicon.ico        # 网站图标
```

### 第3步：理解Docker Volume挂载

在 `docker-compose.prod.yml` 中的关键配置：

```yaml
nginx-prod:
  volumes:
    # 这行是关键！将本地构建产物挂载到Nginx容器内
    - ./frontend/dist/build/h5:/usr/share/nginx/html:ro
```

**挂载说明：**
- `./frontend/dist/build/h5` → 宿主机路径（相对于docker-compose.yml文件）
- `/usr/share/nginx/html` → Nginx容器内的网站根目录
- `:ro` → 只读挂载（Read-Only）

### 第4步：Nginx配置处理前端请求

Nginx配置中的关键部分：

```nginx
# 1. 静态资源缓存（JS、CSS、图片等）
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
    root /usr/share/nginx/html;    # 从挂载的前端目录提供文件
    expires 1y;                    # 长期缓存
    add_header Cache-Control "public, immutable";
}

# 2. HTML文件不缓存（确保更新及时）
location ~* \.html$ {
    root /usr/share/nginx/html;
    expires -1;                    # 不缓存HTML
    add_header Cache-Control "no-cache, no-store, must-revalidate";
}

# 3. API请求代理到后端
location /api/ {
    proxy_pass http://backend_cluster;  # 转发到后端服务
    # ... 其他代理配置
}

# 4. SPA路由支持（最重要！）
location / {
    root /usr/share/nginx/html;         # 前端文件根目录
    index index.html;                   # 默认首页
    try_files $uri $uri/ @fallback;     # 尝试匹配文件，否则回退
}

# 5. SPA路由回退处理
location @fallback {
    root /usr/share/nginx/html;
    try_files /index.html =404;         # 所有未匹配的路由都返回index.html
}
```

### 第5步：启动服务验证关联

```bash
# 返回项目根目录
cd ..

# 设置环境变量
export MYSQL_PASSWORD='FortuneProd2025!@#'
export MYSQL_ROOT_PASSWORD='RootProd2025!@#'
export REDIS_PASSWORD='RedisProd2025!@#'
export JWT_SECRET='FortuneJWTSecretKeyForProductionEnvironment2024!@#$%^&*'
export DEEPSEEK_API_KEY='sk-161f80e197f64439a4a9f0b4e9e30c40'
export WECHAT_APP_ID='wxab173e904eb23fca'
export WECHAT_APP_SECRET='75ad9ccb5f2ff072b8cd207d71a07ada'

# 启动所有服务
docker compose -f docker-compose.prod.yml up -d

# 检查服务状态
docker compose -f docker-compose.prod.yml ps
```

### 第6步：验证前端文件挂载

```bash
# 检查Nginx容器内的文件
docker compose -f docker-compose.prod.yml exec nginx-prod ls -la /usr/share/nginx/html/

# 应该看到前端构建的文件
# index.html, static/, manifest.json 等

# 查看index.html内容（前几行）
docker compose -f docker-compose.prod.yml exec nginx-prod head -10 /usr/share/nginx/html/index.html
```

### 第7步：测试前端访问

```bash
# 1. 测试首页
curl -I http://localhost/

# 2. 测试静态资源
curl -I http://localhost/static/css/

# 3. 测试SPA路由（应该返回index.html）
curl -I http://localhost/pages/calculate

# 4. 测试API代理
curl http://localhost/api/simple/hello
```

## 🔧 常见问题排查

### 问题1：前端文件404

**原因：** 构建产物不存在或挂载路径错误

**解决：**
```bash
# 检查构建产物是否存在
ls -la frontend/dist/build/h5/

# 如果不存在，重新构建
cd frontend && npm run build:h5 && cd ..

# 重启Nginx服务
docker compose -f docker-compose.prod.yml restart nginx-prod
```

### 问题2：SPA路由404

**原因：** Nginx配置中缺少 `try_files` 配置

**解决：** 确保Nginx配置包含：
```nginx
location / {
    try_files $uri $uri/ @fallback;
}
location @fallback {
    try_files /index.html =404;
}
```

### 问题3：API请求失败

**原因：** API代理配置错误

**解决：** 检查Nginx配置：
```nginx
location /api/ {
    proxy_pass http://backend_cluster;  # 注意不要重复/api/
    # ... 其他配置
}
```

### 问题4：静态资源缓存问题

**原因：** 浏览器缓存旧文件

**解决：**
```bash
# 强制刷新浏览器缓存 (Ctrl+F5)
# 或清除浏览器缓存

# 检查Nginx缓存配置
docker compose -f docker-compose.prod.yml exec nginx-prod nginx -t
```

## 🛠️ 调试命令

### 查看Nginx配置
```bash
# 查看完整Nginx配置
docker compose -f docker-compose.prod.yml exec nginx-prod cat /etc/nginx/nginx.conf

# 测试Nginx配置语法
docker compose -f docker-compose.prod.yml exec nginx-prod nginx -t
```

### 查看Nginx日志
```bash
# 查看访问日志
docker compose -f docker-compose.prod.yml logs nginx-prod

# 实时查看日志
docker compose -f docker-compose.prod.yml logs -f nginx-prod

# 查看错误日志
tail -f logs/nginx/error.log
```

### 进入容器调试
```bash
# 进入Nginx容器
docker compose -f docker-compose.prod.yml exec nginx-prod sh

# 在容器内查看文件
ls -la /usr/share/nginx/html/
cat /usr/share/nginx/html/index.html
```

## 📋 完整部署检查清单

- [ ] 前端代码构建成功 (`npm run build:h5`)
- [ ] 构建产物存在 (`frontend/dist/build/h5/index.html`)
- [ ] Docker Compose配置Volume挂载正确
- [ ] Nginx配置包含前端路由支持
- [ ] 环境变量设置正确
- [ ] 所有Docker服务启动成功
- [ ] 前端页面可以访问 (`curl http://localhost/`)
- [ ] API代理工作正常 (`curl http://localhost/api/`)
- [ ] SPA路由工作正常
- [ ] 静态资源加载正常

## 🎯 最佳实践

1. **自动化部署脚本**：使用 `./scripts/deploy-frontend.sh` 一键部署
2. **版本控制**：每次部署前备份旧版本
3. **缓存策略**：静态资源长期缓存，HTML不缓存
4. **监控日志**：定期检查Nginx访问日志和错误日志
5. **性能优化**：启用Gzip压缩，优化图片资源

---

通过以上步骤，前端代码就能够正确地与Nginx关联，用户可以通过浏览器访问到完整的前端应用！ 
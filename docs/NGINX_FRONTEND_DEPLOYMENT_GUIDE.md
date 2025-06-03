# Nginx前端部署详细指南 - AI八卦运势小程序

## 📚 目录
- [概述](#概述)
- [Nginx配置详解](#nginx配置详解)
- [前端部署流程](#前端部署流程)
- [Docker集成配置](#docker集成配置)
- [性能优化](#性能优化)
- [故障排除](#故障排除)

## 📖 概述

### 部署架构图
```
┌──────────────────┐    ┌───────────────────┐    ┌─────────────────┐
│    用户浏览器      │    │      Nginx         │    │   前端文件       │
│   Browser        │◄──►│   (反向代理)        │◄──►│   /usr/share/   │
│                  │    │   Port: 80/443     │    │   nginx/html/   │
└──────────────────┘    └───────────────────┘    └─────────────────┘
                                  │
                                  ▼
                        ┌───────────────────┐
                        │   后端API服务      │
                        │   backend:8080    │
                        │   /api/*          │
                        └───────────────────┘
```

### 核心功能
- ✅ **静态资源服务**: 提供HTML、CSS、JS、图片等前端文件
- ✅ **SPA路由支持**: 处理单页应用的前端路由
- ✅ **API代理**: 将/api请求转发到后端服务
- ✅ **缓存优化**: 静态资源长期缓存，HTML不缓存
- ✅ **Gzip压缩**: 减少传输数据量
- ✅ **安全配置**: 防护常见Web攻击

## 🔧 Nginx配置详解

### 完整的生产环境配置 (nginx.prod.conf)

```nginx
# ==================== 全局配置 ====================
user nginx;                          # Nginx运行用户
worker_processes auto;               # 自动设置工作进程数（通常等于CPU核数）
pid /var/run/nginx.pid;             # PID文件位置
error_log /var/log/nginx/error.log warn;  # 错误日志配置

# ==================== 事件模块配置 ====================
events {
    worker_connections 2048;         # 每个工作进程的最大连接数
    use epoll;                      # Linux下使用epoll事件模型（高效）
    multi_accept on;                # 允许一次接受多个连接
}

# ==================== HTTP模块配置 ====================
http {
    include /etc/nginx/mime.types;   # 包含MIME类型定义
    default_type application/octet-stream;  # 默认MIME类型

    # ==================== 日志格式配置 ====================
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for" '
                    'rt=$request_time uct="$upstream_connect_time" '
                    'uht="$upstream_header_time" urt="$upstream_response_time"';

    access_log /var/log/nginx/access.log main;  # 访问日志配置

    # ==================== 基础性能配置 ====================
    sendfile on;                     # 启用sendfile，提高文件传输效率
    tcp_nopush on;                   # 启用TCP_NOPUSH，减少网络报文段数量
    tcp_nodelay on;                  # 启用TCP_NODELAY，减少延迟
    keepalive_timeout 65;            # 保持连接超时时间
    types_hash_max_size 2048;        # MIME类型哈希表大小
    client_max_body_size 50M;        # 客户端请求体最大大小
    client_body_buffer_size 10M;     # 客户端请求体缓冲区大小
    client_header_buffer_size 4k;    # 客户端请求头缓冲区大小
    large_client_header_buffers 4 16k;  # 大请求头缓冲区配置

    # ==================== Gzip压缩配置 ====================
    gzip on;                         # 启用Gzip压缩
    gzip_vary on;                    # 启用Vary: Accept-Encoding响应头
    gzip_min_length 1024;            # 只压缩大于1KB的文件
    gzip_comp_level 6;               # 压缩级别（1-9，6是性能与压缩率的平衡点）
    gzip_types
        text/plain                   # 纯文本
        text/css                     # CSS文件
        text/xml                     # XML文件
        text/javascript              # JavaScript文件
        application/javascript       # JavaScript应用程序
        application/json             # JSON数据
        application/xml+rss          # RSS XML
        application/atom+xml         # Atom XML
        image/svg+xml;              # SVG图片

    # ==================== 安全头配置 ====================
    add_header X-Frame-Options DENY;                    # 防止点击劫持
    add_header X-Content-Type-Options nosniff;          # 防止MIME类型嗅探
    add_header X-XSS-Protection "1; mode=block";        # XSS保护
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;  # HSTS

    # ==================== 限流配置 ====================
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;     # API请求限流
    limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;    # 登录请求限流

    # ==================== 后端服务配置 ====================
    upstream backend_cluster {
        server backend-prod:8080 max_fails=3 fail_timeout=30s;  # 后端服务器
        keepalive 32;                # 保持连接数
    }

    # 管理端点（仅内网访问）
    upstream management_cluster {
        server backend-prod:8081 max_fails=2 fail_timeout=20s;
        keepalive 8;
    }

    # ==================== HTTP服务器（重定向到HTTPS） ====================
    server {
        listen 80;                   # 监听HTTP端口
        server_name _;              # 匹配所有域名

        # 健康检查端点（HTTP允许）
        location /health {
            access_log off;          # 不记录健康检查日志
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }

        # 其他请求重定向到HTTPS
        location / {
            return 301 https://$server_name$request_uri;
        }
    }

    # ==================== HTTPS主服务器配置 ====================
    server {
        listen 443 ssl http2;        # 监听HTTPS端口，启用HTTP/2
        server_name _;

        # ==================== SSL配置 ====================
        ssl_certificate /etc/nginx/ssl/server.crt;      # SSL证书文件
        ssl_certificate_key /etc/nginx/ssl/server.key;  # SSL私钥文件
        ssl_protocols TLSv1.2 TLSv1.3;                 # 支持的SSL/TLS版本
        ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;  # 加密套件
        ssl_prefer_server_ciphers on;                   # 优先使用服务器端加密套件
        ssl_session_cache shared:SSL:10m;               # SSL会话缓存
        ssl_session_timeout 1h;                        # SSL会话超时时间

        # ==================== 前端静态资源配置 ====================
        
        # 静态资源文件（JS、CSS、图片、字体等）- 长期缓存
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            root /usr/share/nginx/html;     # 前端文件根目录
            expires 1y;                     # 缓存1年
            add_header Cache-Control "public, immutable";  # 不可变资源
            add_header Access-Control-Allow-Origin "*";    # 允许跨域
            gzip_static on;                 # 使用预压缩的gzip文件
            access_log off;                 # 不记录静态资源访问日志
        }

        # HTML文件 - 不缓存（确保更新及时）
        location ~* \.html$ {
            root /usr/share/nginx/html;
            expires -1;                     # 立即过期
            add_header Cache-Control "no-cache, no-store, must-revalidate";
            add_header Pragma "no-cache";
            add_header Expires "0";
        }

        # ==================== API代理配置 ====================
        
        # 通用API请求代理
        location /api/ {
            limit_req zone=api burst=20 nodelay;  # 限流：10r/s，突发20个请求
            
            # 代理到后端服务
            proxy_pass http://backend_cluster;
            
            # 请求头设置
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $host;
            proxy_set_header X-Forwarded-Port $server_port;
            
            # 超时配置
            proxy_connect_timeout 60s;     # 连接超时
            proxy_send_timeout 60s;        # 发送超时
            proxy_read_timeout 60s;        # 读取超时
            
            # 缓冲配置
            proxy_buffering on;            # 启用代理缓冲
            proxy_buffer_size 8k;          # 缓冲区大小
            proxy_buffers 8 8k;            # 缓冲区数量和大小
            
            # 错误页面处理
            proxy_intercept_errors on;
            error_page 502 503 504 /50x.html;
        }

        # 登录接口特殊限流（更严格）
        location /api/auth/login {
            limit_req zone=login burst=5 nodelay;  # 限流：1r/s，突发5个请求
            
            proxy_pass http://backend_cluster;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # ==================== 管理端点配置 ====================
        
        # 管理端点（仅内网访问）
        location /management/ {
            # IP访问控制（根据实际网络情况修改）
            allow 172.20.0.0/16;          # Docker网络
            allow 127.0.0.1;              # 本地访问
            deny all;                     # 拒绝其他IP
            
            proxy_pass http://management_cluster/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # ==================== 文件上传配置 ====================
        
        # 用户上传的文件服务
        location /uploads/ {
            alias /app/uploads/;           # 上传文件目录
            expires 1d;                   # 缓存1天
            add_header Cache-Control "public";
        }

        # ==================== 前端SPA路由配置 ====================
        
        # 前端单页应用路由支持（最重要的配置）
        location / {
            root /usr/share/nginx/html;    # 前端文件根目录
            index index.html index.htm;   # 默认首页文件
            
            # SPA路由核心配置：所有未匹配的请求都尝试返回文件，否则回退到index.html
            try_files $uri $uri/ @fallback;
            
            # 安全配置
            add_header X-Frame-Options DENY;
            add_header X-Content-Type-Options nosniff;
        }
        
        # SPA路由回退处理
        location @fallback {
            root /usr/share/nginx/html;
            try_files /index.html =404;   # 最终回退到index.html
        }

        # ==================== 错误页面配置 ====================
        
        # 自定义错误页面
        location = /50x.html {
            root /usr/share/nginx/html;
        }

        # ==================== 监控端点配置 ====================
        
        # Nginx状态监控（仅内网访问）
        location = /nginx_status {
            stub_status on;              # 启用状态页面
            allow 172.20.0.0/16;         # 允许Docker网络访问
            allow 127.0.0.1;             # 允许本地访问
            deny all;                    # 拒绝其他访问
        }
    }
}
```

## 🚀 前端部署流程

### 第1步：构建前端应用

```bash
# 进入前端目录
cd frontend

# 安装依赖（如果需要）
npm install

# 构建H5版本（生产环境）
npm run build:h5

# 验证构建结果
ls -la dist/build/h5/
# 应该看到：index.html, static/目录等
```

### 第2步：配置Docker Volume挂载

在 `docker-compose.prod.yml` 中的Nginx服务配置：

```yaml
nginx-prod:
  image: nginx:1.25-alpine
  container_name: bagua-nginx-prod
  restart: unless-stopped
  ports:
    - "80:80"        # HTTP端口
    - "443:443"      # HTTPS端口
  volumes:
    # ⭐ 关键配置：挂载前端构建产物到Nginx容器
    - ./nginx/nginx.prod.conf:/etc/nginx/nginx.conf:ro           # Nginx配置文件
    - ./ssl:/etc/nginx/ssl:ro                                    # SSL证书目录
    - ./logs/nginx:/var/log/nginx                                # 日志目录
    - ./frontend/dist/build/h5:/usr/share/nginx/html:ro          # ⭐ 前端文件挂载
  depends_on:
    - backend-prod   # 依赖后端服务
  networks:
    - fortune-prod-network
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost/health"]
    interval: 30s
    timeout: 10s
    retries: 3
```

### 第3步：启动服务

```bash
# 设置环境变量
export MYSQL_PASSWORD='FortuneProd2025!@#'
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

### 第4步：验证部署

```bash
# 1. 检查前端页面
curl -I http://localhost/
# 应该返回200状态码

# 2. 检查API代理
curl http://localhost/api/simple/hello
# 应该返回后端API响应

# 3. 检查SPA路由
curl -I http://localhost/pages/calculate
# 应该返回200（由于try_files配置）

# 4. 检查静态资源
curl -I http://localhost/static/css/
# 应该有适当的缓存头
```

## 🐳 Docker集成配置

### 完整的docker-compose.prod.yml配置

```yaml
version: '3.8'

services:
  # ==================== MySQL数据库 ====================
  mysql-prod:
    image: mysql:8.0
    container_name: bagua-mysql-prod
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
      MYSQL_CHARSET: utf8mb4
      MYSQL_COLLATION: utf8mb4_unicode_ci
    ports:
      - "3306:3306"
    volumes:
      - mysql_prod_data:/var/lib/mysql
      - ./backend/src/main/resources/sql/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    command: --default-authentication-plugin=mysql_native_password 
             --character-set-server=utf8mb4 
             --collation-server=utf8mb4_unicode_ci
    networks:
      - fortune-prod-network
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 20s
      retries: 10

  # ==================== Redis缓存 ====================
  redis-prod:
    image: redis:6.2-alpine
    container_name: bagua-redis-prod
    restart: unless-stopped
    command: redis-server --requirepass ${REDIS_PASSWORD} --appendonly yes
    ports:
      - "6379:6379"
    volumes:
      - redis_prod_data:/data
    networks:
      - fortune-prod-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3

  # ==================== 后端应用 ====================
  backend-prod:
    build:
      context: ./backend
      dockerfile: Dockerfile.prod
    container_name: bagua-backend-prod
    restart: unless-stopped
    ports:
      - "8081:8080"     # 内部端口8080，外部映射到8081
    environment:
      - SPRING_PROFILES_ACTIVE=prod
      - MYSQL_HOST=mysql-prod
      - MYSQL_PORT=3306
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USERNAME=${MYSQL_USER}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - REDIS_HOST=redis-prod
      - REDIS_PORT=6379
      - REDIS_PASSWORD=${REDIS_PASSWORD}
      - DEEPSEEK_API_KEY=${DEEPSEEK_API_KEY}
      - WECHAT_APP_ID=${WECHAT_APP_ID}
      - WECHAT_APP_SECRET=${WECHAT_APP_SECRET}
      - JWT_SECRET=${JWT_SECRET}
    depends_on:
      mysql-prod:
        condition: service_healthy
      redis-prod:
        condition: service_healthy
    volumes:
      - ./logs/backend:/app/logs
    networks:
      - fortune-prod-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/api/actuator/health"]
      interval: 60s
      timeout: 30s
      retries: 3
      start_period: 5m

  # ==================== Nginx反向代理 ====================
  nginx-prod:
    image: nginx:1.25-alpine
    container_name: bagua-nginx-prod
    restart: unless-stopped
    ports:
      - "80:80"         # HTTP端口
      - "443:443"       # HTTPS端口
    volumes:
      # 配置文件挂载
      - ./nginx/nginx.prod.conf:/etc/nginx/nginx.conf:ro
      
      # SSL证书目录（如果有HTTPS）
      - ./ssl:/etc/nginx/ssl:ro
      
      # 日志目录挂载
      - ./logs/nginx:/var/log/nginx
      
      # ⭐ 前端静态文件挂载（最重要）
      - ./frontend/dist/build/h5:/usr/share/nginx/html:ro
    depends_on:
      - backend-prod
    networks:
      - fortune-prod-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3

# ==================== 数据卷配置 ====================
volumes:
  mysql_prod_data:
    driver: local
  redis_prod_data:
    driver: local

# ==================== 网络配置 ====================
networks:
  fortune-prod-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

## ⚡ 性能优化

### 1. 启用HTTP/2
```nginx
# 在server块中启用HTTP/2
listen 443 ssl http2;
```

### 2. 配置Gzip预压缩
```bash
# 在构建时预压缩静态文件
cd frontend/dist/build/h5
find . -type f \( -name "*.js" -o -name "*.css" -o -name "*.html" \) -exec gzip -9 -k {} \;
```

```nginx
# Nginx配置中启用gzip_static
location ~* \.(js|css|html)$ {
    gzip_static on;  # 优先使用预压缩文件
    # ... 其他配置
}
```

### 3. 浏览器缓存策略
```nginx
# 不同类型文件的缓存策略
location ~* \.(js|css)$ {
    expires 1y;                    # JavaScript和CSS缓存1年
    add_header Cache-Control "public, immutable";
}

location ~* \.(png|jpg|jpeg|gif|ico|svg)$ {
    expires 6M;                    # 图片缓存6个月
    add_header Cache-Control "public";
}

location ~* \.(woff|woff2|ttf|eot)$ {
    expires 1y;                    # 字体文件缓存1年
    add_header Cache-Control "public, immutable";
    add_header Access-Control-Allow-Origin "*";  # 字体跨域
}
```

### 4. 连接优化
```nginx
# HTTP/1.1连接复用
upstream backend_cluster {
    server backend-prod:8080;
    keepalive 32;              # 保持32个连接
    keepalive_requests 100;    # 每个连接最多处理100个请求
    keepalive_timeout 60s;     # 连接超时60秒
}
```

## 🛠️ 故障排除

### 常见问题及解决方案

#### 1. 前端页面404错误
**现象**: 访问 `http://localhost/` 返回404

**排查步骤**:
```bash
# 1. 检查前端文件是否存在
ls -la frontend/dist/build/h5/
ls -la frontend/dist/build/h5/index.html

# 2. 检查Docker挂载
docker compose -f docker-compose.prod.yml exec nginx-prod ls -la /usr/share/nginx/html/

# 3. 检查Nginx配置
docker compose -f docker-compose.prod.yml exec nginx-prod nginx -t
```

**解决方案**:
```bash
# 重新构建前端
cd frontend && npm run build:h5

# 重启Nginx服务
docker compose -f docker-compose.prod.yml restart nginx-prod
```

#### 2. SPA路由不工作
**现象**: 刷新页面或直接访问路由时404

**原因**: 缺少 `try_files` 配置

**解决方案**:
```nginx
# 确保Nginx配置中有正确的try_files
location / {
    try_files $uri $uri/ @fallback;
}

location @fallback {
    try_files /index.html =404;
}
```

#### 3. API请求失败
**现象**: 前端无法访问后端API

**排查步骤**:
```bash
# 1. 检查后端服务状态
curl http://localhost:8081/api/actuator/health

# 2. 检查Nginx代理
curl http://localhost/api/actuator/health

# 3. 查看Nginx错误日志
docker compose -f docker-compose.prod.yml logs nginx-prod
```

#### 4. 静态资源加载失败
**现象**: CSS、JS文件404或加载慢

**排查步骤**:
```bash
# 1. 检查文件路径
curl -I http://localhost/static/css/main.css

# 2. 检查缓存头
curl -I http://localhost/static/js/main.js

# 3. 检查Gzip压缩
curl -H "Accept-Encoding: gzip" -I http://localhost/static/js/main.js
```

### 调试命令大全

```bash
# ==================== 服务状态检查 ====================
# 查看所有容器状态
docker compose -f docker-compose.prod.yml ps

# 查看特定服务日志
docker compose -f docker-compose.prod.yml logs nginx-prod
docker compose -f docker-compose.prod.yml logs -f nginx-prod  # 实时日志

# 进入Nginx容器调试
docker compose -f docker-compose.prod.yml exec nginx-prod sh

# ==================== 配置验证 ====================
# 验证Nginx配置语法
docker compose -f docker-compose.prod.yml exec nginx-prod nginx -t

# 重新加载Nginx配置
docker compose -f docker-compose.prod.yml exec nginx-prod nginx -s reload

# 查看Nginx配置
docker compose -f docker-compose.prod.yml exec nginx-prod cat /etc/nginx/nginx.conf

# ==================== 网络连接测试 ====================
# 测试前端页面
curl -I http://localhost/
curl -I http://localhost/pages/calculate

# 测试API代理
curl http://localhost/api/simple/hello
curl http://localhost/api/actuator/health

# 测试静态资源
curl -I http://localhost/static/css/
curl -I http://localhost/static/js/

# ==================== 性能分析 ====================
# 查看Nginx状态
curl http://localhost/nginx_status

# 分析访问日志
tail -f logs/nginx/access.log | grep -E "\.(js|css|png|jpg)"

# 查看响应时间
tail -f logs/nginx/access.log | grep "rt="
```

## 📋 部署检查清单

### 部署前检查
- [ ] 前端代码构建成功 (`npm run build:h5`)
- [ ] 构建产物完整 (`index.html`、`static/`目录存在)
- [ ] Nginx配置文件语法正确
- [ ] Docker Compose配置正确
- [ ] 环境变量设置完整

### 部署后验证
- [ ] 容器启动成功
- [ ] 前端页面可访问 (`curl http://localhost/`)
- [ ] API代理正常 (`curl http://localhost/api/`)
- [ ] SPA路由工作 (刷新页面不404)
- [ ] 静态资源加载正常
- [ ] 缓存策略生效
- [ ] 错误日志无异常

### 性能检查
- [ ] Gzip压缩启用
- [ ] 静态资源缓存配置
- [ ] HTTP/2启用（如果使用HTTPS）
- [ ] 连接复用配置
- [ ] 响应时间合理

---

## 🎯 总结

通过本指南，你已经掌握了：

1. **完整的Nginx配置**: 从基础配置到高级优化
2. **前端部署流程**: 构建、挂载、启动、验证
3. **Docker集成**: 容器化部署和服务编排
4. **性能优化**: 缓存、压缩、连接优化
5. **故障排除**: 常见问题诊断和解决

现在你可以将AI八卦运势小程序的前端成功部署到生产环境，为用户提供稳定、高效的Web服务！ 
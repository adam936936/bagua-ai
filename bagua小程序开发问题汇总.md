# Bagua小程序开发问题汇总

**项目：** 八卦运势小程序  
**文档目的：** 汇总开发过程中遇到的重大问题，分析原因并提供解决方案，避免后续项目踩坑  
**更新时间：** 2025年6月5日  

## 🚨 重大问题分类

### P0级问题 - 阻塞性架构和环境问题

#### 问题1：UniApp架构设计和原生语法问题

**问题描述：**
- 项目初期基于UniApp 3.0架构设计微信小程序
- 使用了部分原生微信小程序语法，导致跨平台兼容性问题
- UniApp组件库和原生API混用造成代码维护困难

**具体表现：**
```javascript
// 问题代码示例：混用原生API和UniApp API
wx.getUserInfo() // 原生微信API
uni.getUserInfo() // UniApp API
```

**根本原因：**
1. 对UniApp框架理解不够深入
2. 没有制定统一的代码规范
3. 开发过程中图方便使用了原生API

**解决方案：**
```javascript
// 统一使用UniApp API
uni.getUserInfo({
  success: function(res) {
    console.log(res.userInfo)
  }
})

// 条件编译处理平台差异
// #ifdef MP-WEIXIN
// 微信小程序特有代码
// #endif

// #ifdef H5
// H5特有代码
// #endif
```

**预防措施：**
- 项目初期制定严格的编码规范
- 优先使用UniApp API，避免平台原生API
- 建立代码审查机制
- 使用ESLint规则限制原生API使用

---

#### 问题2：网络环境和依赖管理问题

**问题描述：**
- Maven依赖下载失败，网络超时
- Docker镜像拉取失败
- npm包安装网络问题
- 防火墙和代理配置问题

**具体表现：**
```bash
# Maven依赖下载失败
[ERROR] Failed to execute goal on project bagua-backend: Could not resolve dependencies
# Docker拉取失败
Error response from daemon: Get https://registry-1.docker.io/v2/: net/http: TLS handshake timeout
# npm安装失败
npm ERR! network request timeout
```

**根本原因：**
1. 网络环境限制，无法访问外网镜像源
2. 未配置国内镜像源
3. 企业防火墙限制
4. 代理配置错误

**解决方案：**

**Maven配置（settings.xml）：**
```xml
<mirrors>
  <mirror>
    <id>aliyun-maven</id>
    <name>Aliyun Maven</name>
    <url>https://maven.aliyun.com/repository/public</url>
    <mirrorOf>central</mirrorOf>
  </mirror>
</mirrors>
```

**npm配置：**
```bash
# 设置淘宝镜像
npm config set registry https://registry.npmmirror.com
# 或使用cnpm
npm install -g cnpm --registry=https://registry.npmmirror.com
```

**Docker配置：**
```json
// /etc/docker/daemon.json
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://registry.docker-cn.com"
  ]
}
```

**预防措施：**
- 项目初期配置所有镜像源
- 提供网络环境检查脚本
- 文档化网络配置步骤
- 建立离线安装包备份

---

#### 问题3：服务启动流程和端口管理问题

**问题描述：**
- 每次启动忘记使用预制的启动脚本
- 端口被占用导致服务启动失败
- 服务依赖关系不明确
- 缺少启动前的环境检查

**具体表现：**
```bash
# 常见错误
Error: listen EADDRINUSE: address already in use :::8080
Error: listen EADDRINUSE: address already in use :::3306
```

**根本原因：**
1. 未建立标准化的启动流程
2. 缺少端口检查机制
3. 服务依赖顺序不明确
4. 开发习惯不规范

**解决方案：**

**创建智能启动脚本：**
```bash
#!/bin/bash
# start-all-services.sh

echo "🚀 启动Bagua小程序服务..."

# 检查端口占用
check_port() {
    local port=$1
    local service=$2
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; then
        echo "❌ 端口 $port 被占用 ($service)"
        echo "占用进程: $(lsof -Pi :$port -sTCP:LISTEN)"
        read -p "是否杀死占用进程? (y/N): " choice
        if [[ $choice == [Yy] ]]; then
            kill -9 $(lsof -Pi :$port -sTCP:LISTEN -t)
            echo "✅ 已杀死占用进程"
        else
            echo "❌ 请手动处理端口占用后重试"
            exit 1
        fi
    else
        echo "✅ 端口 $port 可用 ($service)"
    fi
}

# 检查环境依赖
check_dependencies() {
    echo "🔍 检查环境依赖..."
    
    # 检查Java
    if ! command -v java &> /dev/null; then
        echo "❌ Java未安装"
        exit 1
    fi
    
    # 检查Node.js
    if ! command -v node &> /dev/null; then
        echo "❌ Node.js未安装"
        exit 1
    fi
    
    # 检查Docker
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker未安装"
        exit 1
    fi
    
    echo "✅ 环境依赖检查通过"
}

# 启动服务
start_services() {
    echo "📦 启动基础服务..."
    
    # 1. 启动MySQL和Redis
    docker-compose up -d mysql redis
    sleep 10
    
    # 2. 检查数据库连接
    echo "🔍 检查数据库连接..."
    # 这里可以添加数据库连接测试
    
    # 3. 启动后端服务
    echo "🎯 启动后端服务..."
    cd backend
    mvn spring-boot:run > ../backend.log 2>&1 &
    echo $! > ../backend.pid
    cd ..
    
    # 4. 等待后端启动
    echo "⏳ 等待后端服务启动..."
    for i in {1..30}; do
        if curl -s http://localhost:8080/actuator/health > /dev/null; then
            echo "✅ 后端服务启动成功"
            break
        fi
        sleep 2
    done
    
    # 5. 启动前端服务
    echo "🎨 启动前端服务..."
    cd frontend
    npm run dev:h5 > ../frontend.log 2>&1 &
    echo $! > ../frontend.pid
    cd ..
}

# 主流程
main() {
    check_dependencies
    check_port 3306 "MySQL"
    check_port 6379 "Redis"
    check_port 8080 "Backend"
    check_port 3000 "Frontend"
    
    start_services
    
    echo "🎉 所有服务启动完成！"
    echo "后端服务: http://localhost:8080"
    echo "前端服务: http://localhost:3000"
}

main "$@"
```

**停止服务脚本：**
```bash
#!/bin/bash
# stop-all-services.sh

echo "🛑 停止所有服务..."

# 停止前端服务
if [ -f frontend.pid ]; then
    kill $(cat frontend.pid) 2>/dev/null
    rm frontend.pid
    echo "✅ 前端服务已停止"
fi

# 停止后端服务
if [ -f backend.pid ]; then
    kill $(cat backend.pid) 2>/dev/null
    rm backend.pid
    echo "✅ 后端服务已停止"
fi

# 停止Docker服务
docker-compose down
echo "✅ Docker服务已停止"

echo "🎉 所有服务已停止"
```

**预防措施：**
- 统一使用启动脚本，禁止手动启动
- 脚本中加入详细的日志输出
- 建立服务健康检查机制
- 制作启动流程检查清单

---

### P1级问题 - 环境配置和部署问题

#### 问题4：Docker环境配置和数据库差异问题

**问题描述：**
- 未提前规划dev和prod环境的Docker配置
- 本地开发使用H2数据库，生产使用MySQL，环境不一致
- 配置文件管理混乱
- 环境切换复杂

**具体表现：**
```yaml
# 问题：环境配置混乱
spring:
  datasource:
    url: jdbc:h2:mem:testdb  # 本地
    # url: jdbc:mysql://localhost:3306/bagua  # 生产
```

**根本原因：**
1. 未建立环境标准化规范
2. 配置管理策略不清晰
3. Docker编排文件设计不合理
4. 环境一致性意识不足

**解决方案：**

**环境配置标准化：**
```
项目结构:
├── docker-compose.dev.yml      # 开发环境
├── docker-compose.prod.yml     # 生产环境
├── docker-compose.test.yml     # 测试环境
├── env/
│   ├── .env.dev               # 开发环境变量
│   ├── .env.prod              # 生产环境变量
│   └── .env.test              # 测试环境变量
└── config/
    ├── application-dev.yml    # 开发配置
    ├── application-prod.yml   # 生产配置
    └── application-test.yml   # 测试配置
```

**开发环境配置（docker-compose.dev.yml）：**
```yaml
version: '3.8'
services:
  mysql-dev:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: dev123456
      MYSQL_DATABASE: bagua_dev
    ports:
      - "3307:3306"  # 避免与本地MySQL冲突
    volumes:
      - mysql_dev_data:/var/lib/mysql
      - ./sql/init-dev.sql:/docker-entrypoint-initdb.d/init.sql

  redis-dev:
    image: redis:7-alpine
    ports:
      - "6380:6379"  # 避免与本地Redis冲突

  backend-dev:
    build: ./backend
    environment:
      SPRING_PROFILES_ACTIVE: dev
      DB_HOST: mysql-dev
      DB_PORT: 3306
      REDIS_HOST: redis-dev
    ports:
      - "8080:8080"
    depends_on:
      - mysql-dev
      - redis-dev

volumes:
  mysql_dev_data:
```

**生产环境配置（docker-compose.prod.yml）：**
```yaml
version: '3.8'
services:
  mysql-prod:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD_FILE: /run/secrets/mysql_root_password
      MYSQL_DATABASE: bagua_prod
    volumes:
      - mysql_prod_data:/var/lib/mysql
      - ./sql/init-prod.sql:/docker-entrypoint-initdb.d/init.sql
    secrets:
      - mysql_root_password
    networks:
      - backend

  backend-prod:
    image: bagua-backend:latest
    environment:
      SPRING_PROFILES_ACTIVE: prod
      DB_HOST: mysql-prod
      REDIS_HOST: redis-prod
    networks:
      - backend
      - frontend
    depends_on:
      - mysql-prod
      - redis-prod

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.prod.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    networks:
      - frontend

secrets:
  mysql_root_password:
    file: ./secrets/mysql_root_password.txt

networks:
  backend:
    driver: bridge
  frontend:
    driver: bridge

volumes:
  mysql_prod_data:
```

**环境切换脚本：**
```bash
#!/bin/bash
# switch-env.sh

ENV=${1:-dev}

case $ENV in
  dev)
    echo "🔄 切换到开发环境..."
    docker-compose -f docker-compose.dev.yml --env-file env/.env.dev up -d
    ;;
  test)
    echo "🔄 切换到测试环境..."
    docker-compose -f docker-compose.test.yml --env-file env/.env.test up -d
    ;;
  prod)
    echo "🔄 切换到生产环境..."
    docker-compose -f docker-compose.prod.yml --env-file env/.env.prod up -d
    ;;
  *)
    echo "❌ 无效环境: $ENV"
    echo "使用方法: $0 [dev|test|prod]"
    exit 1
    ;;
esac
```

**预防措施：**
- 项目初期建立环境标准
- 所有环境使用相同的数据库类型
- 配置文件模板化管理
- 建立环境一致性检查

---

#### 问题5：Git和代码仓库管理问题

**问题描述：**
- Git和Gitee SSH配置问题
- 网络问题导致推送失败
- 没有标准化的提交脚本
- 代码提交流程不规范

**具体表现：**
```bash
# SSH连接失败
ssh: connect to host gitee.com port 22: Connection refused
# 推送失败
fatal: unable to access 'https://gitee.com/xxx/bagua.git/': Failed to connect
```

**根本原因：**
1. SSH密钥配置不正确
2. 网络环境限制
3. Git配置不标准
4. 缺少自动化提交流程

**解决方案：**

**SSH配置标准化：**
```bash
#!/bin/bash
# setup-git.sh - Git环境配置脚本

echo "🔧 配置Git环境..."

# 1. 生成SSH密钥
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "📝 生成SSH密钥..."
    ssh-keygen -t rsa -b 4096 -C "your-email@example.com" -f ~/.ssh/id_rsa -N ""
fi

# 2. 配置SSH
cat > ~/.ssh/config << EOF
# GitHub配置
Host github.com
    HostName github.com
    User git
    Port 22
    IdentityFile ~/.ssh/id_rsa
    TCPKeepAlive yes
    IdentitiesOnly yes

# Gitee配置
Host gitee.com
    HostName gitee.com
    User git
    Port 22
    IdentityFile ~/.ssh/id_rsa
    TCPKeepAlive yes
    IdentitiesOnly yes

# 解决网络问题的备用配置
Host github-443
    HostName ssh.github.com
    User git
    Port 443
    IdentityFile ~/.ssh/id_rsa

Host gitee-443
    HostName gitee.com
    User git
    Port 443
    IdentityFile ~/.ssh/id_rsa
EOF

# 3. 设置权限
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/id_rsa

# 4. 测试连接
echo "🔍 测试SSH连接..."
ssh -T git@github.com
ssh -T git@gitee.com

echo "✅ Git环境配置完成"
echo "📋 请将以下公钥添加到Git仓库:"
cat ~/.ssh/id_rsa.pub
```

**标准化提交脚本：**
```bash
#!/bin/bash
# git-commit.sh - 标准化Git提交脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查Git状态
check_git_status() {
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo -e "${RED}❌ 当前目录不是Git仓库${NC}"
        exit 1
    fi
}

# 检查网络连接
check_network() {
    echo "🔍 检查网络连接..."
    
    # 测试GitHub连接
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        echo -e "${GREEN}✅ GitHub连接正常${NC}"
        GITHUB_OK=true
    else
        echo -e "${YELLOW}⚠️ GitHub连接失败，尝试443端口${NC}"
        if ssh -T git@github-443 2>&1 | grep -q "successfully authenticated"; then
            echo -e "${GREEN}✅ GitHub (443端口)连接正常${NC}"
            GITHUB_OK=true
        else
            echo -e "${RED}❌ GitHub连接失败${NC}"
            GITHUB_OK=false
        fi
    fi
    
    # 测试Gitee连接
    if ssh -T git@gitee.com 2>&1 | grep -q "successfully authenticated"; then
        echo -e "${GREEN}✅ Gitee连接正常${NC}"
        GITEE_OK=true
    else
        echo -e "${RED}❌ Gitee连接失败${NC}"
        GITEE_OK=false
    fi
}

# 预提交检查
pre_commit_check() {
    echo "🔍 执行预提交检查..."
    
    # 检查是否有未暂存的更改
    if ! git diff --quiet; then
        echo -e "${YELLOW}⚠️ 检测到未暂存的更改${NC}"
        git status --porcelain
        read -p "是否暂存所有更改? (y/N): " choice
        if [[ $choice == [Yy] ]]; then
            git add .
        fi
    fi
    
    # 运行测试（如果存在）
    if [ -f "package.json" ] && jq -e '.scripts.test' package.json > /dev/null; then
        echo "🧪 运行前端测试..."
        npm test
    fi
    
    if [ -f "backend/pom.xml" ]; then
        echo "🧪 运行后端测试..."
        cd backend && mvn test && cd ..
    fi
}

# 生成提交信息
generate_commit_message() {
    echo "📝 生成提交信息..."
    
    # 提交类型选择
    echo "请选择提交类型:"
    echo "1) feat: 新功能"
    echo "2) fix: 修复bug"
    echo "3) docs: 文档更新"
    echo "4) style: 代码格式化"
    echo "5) refactor: 代码重构"
    echo "6) test: 测试相关"
    echo "7) chore: 构建/工具相关"
    
    read -p "请输入选择 (1-7): " type_choice
    
    case $type_choice in
        1) commit_type="feat" ;;
        2) commit_type="fix" ;;
        3) commit_type="docs" ;;
        4) commit_type="style" ;;
        5) commit_type="refactor" ;;
        6) commit_type="test" ;;
        7) commit_type="chore" ;;
        *) commit_type="chore" ;;
    esac
    
    read -p "请输入提交描述: " commit_desc
    
    # 生成完整的提交信息
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    COMMIT_MESSAGE="${commit_type}: ${commit_desc}

提交时间: ${timestamp}
提交者: $(git config user.name)"
}

# 执行提交和推送
commit_and_push() {
    echo "📤 执行提交..."
    
    # 提交到本地仓库
    git commit -m "$COMMIT_MESSAGE"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ 本地提交成功${NC}"
    else
        echo -e "${RED}❌ 本地提交失败${NC}"
        exit 1
    fi
    
    # 推送到远程仓库
    echo "📤 推送到远程仓库..."
    
    # 获取当前分支
    current_branch=$(git branch --show-current)
    
    # 推送到所有远程仓库
    for remote in $(git remote); do
        echo "📤 推送到 $remote..."
        if git push $remote $current_branch; then
            echo -e "${GREEN}✅ 推送到 $remote 成功${NC}"
        else
            echo -e "${RED}❌ 推送到 $remote 失败${NC}"
        fi
    done
}

# 主流程
main() {
    echo "🚀 开始Git提交流程..."
    
    check_git_status
    check_network
    pre_commit_check
    generate_commit_message
    commit_and_push
    
    echo -e "${GREEN}🎉 Git提交流程完成！${NC}"
}

# 执行主流程
main "$@"
```

**预防措施：**
- 建立Git环境配置标准
- 制作网络问题排查手册
- 统一使用提交脚本
- 定期备份代码到多个平台

---

#### 问题6：生产环境部署和Nginx配置问题

**问题描述：**
- 部署到生产环境后出现404错误
- Nginx配置不正确
- 静态资源路径错误
- 反向代理配置失败

**具体表现：**
```
404 Not Found
nginx/1.20.1
```

**根本原因：**
1. Nginx配置文件错误
2. 静态资源路径配置不当
3. 反向代理规则不正确
4. 前端路由配置问题

**解决方案：**

**标准Nginx配置：**
```nginx
# nginx/nginx.prod.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # 日志格式
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    # 基础配置
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    # Gzip压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript 
               application/x-javascript application/xml+rss 
               application/javascript application/json;

    # 上游服务器
    upstream backend {
        server backend:8080;
        keepalive 32;
    }

    # 主服务器配置
    server {
        listen 80;
        server_name localhost;
        root /usr/share/nginx/html;
        index index.html index.htm;

        # 安全头
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header X-Content-Type-Options "nosniff" always;

        # 前端静态资源
        location / {
            try_files $uri $uri/ /index.html;
            expires 1y;
            add_header Cache-Control "public, immutable";
        }

        # API接口反向代理
        location /api/ {
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # 超时设置
            proxy_connect_timeout 30s;
            proxy_send_timeout 30s;
            proxy_read_timeout 30s;
            
            # 缓冲设置
            proxy_buffering on;
            proxy_buffer_size 4k;
            proxy_buffers 8 4k;
        }

        # 健康检查
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }

        # 错误页面
        error_page 404 /404.html;
        error_page 500 502 503 504 /50x.html;
        
        location = /50x.html {
            root /usr/share/nginx/html;
        }
    }

    # HTTPS配置（生产环境）
    server {
        listen 443 ssl http2;
        server_name your-domain.com;
        root /usr/share/nginx/html;

        # SSL证书
        ssl_certificate /etc/nginx/ssl/cert.pem;
        ssl_certificate_key /etc/nginx/ssl/key.pem;
        
        # SSL配置
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;

        # HSTS
        add_header Strict-Transport-Security "max-age=31536000" always;

        # 其他配置同HTTP
        location / {
            try_files $uri $uri/ /index.html;
        }

        location /api/ {
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto https;
        }
    }
}
```

**部署验证脚本：**
```bash
#!/bin/bash
# verify-deployment.sh - 部署验证脚本

echo "🔍 验证生产环境部署..."

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 检查服务状态
check_service_status() {
    echo "📋 检查服务状态..."
    
    services=("nginx" "backend" "mysql" "redis")
    for service in "${services[@]}"; do
        if docker-compose ps $service | grep -q "Up"; then
            echo -e "${GREEN}✅ $service 运行正常${NC}"
        else
            echo -e "${RED}❌ $service 运行异常${NC}"
            docker-compose logs $service
        fi
    done
}

# 检查端口连通性
check_ports() {
    echo "🔌 检查端口连通性..."
    
    ports=("80:Nginx HTTP" "443:Nginx HTTPS" "8080:Backend API")
    for port_info in "${ports[@]}"; do
        port=$(echo $port_info | cut -d: -f1)
        name=$(echo $port_info | cut -d: -f2)
        
        if nc -z localhost $port; then
            echo -e "${GREEN}✅ $name (端口$port) 连通${NC}"
        else
            echo -e "${RED}❌ $name (端口$port) 不通${NC}"
        fi
    done
}

# 检查API接口
check_api_endpoints() {
    echo "🌐 检查API接口..."
    
    base_url="http://localhost"
    endpoints=(
        "/api/simple/hello:基础接口"
        "/api/fortune/today-fortune:运势接口"
        "/api/user/stats:用户统计"
    )
    
    for endpoint_info in "${endpoints[@]}"; do
        endpoint=$(echo $endpoint_info | cut -d: -f1)
        name=$(echo $endpoint_info | cut -d: -f2)
        
        status_code=$(curl -s -o /dev/null -w "%{http_code}" "$base_url$endpoint")
        if [ "$status_code" = "200" ]; then
            echo -e "${GREEN}✅ $name ($endpoint) 正常${NC}"
        else
            echo -e "${RED}❌ $name ($endpoint) 异常 (状态码: $status_code)${NC}"
        fi
    done
}

# 检查前端页面
check_frontend() {
    echo "🎨 检查前端页面..."
    
    # 检查主页
    if curl -s http://localhost/ | grep -q "<!DOCTYPE html>"; then
        echo -e "${GREEN}✅ 前端主页正常${NC}"
    else
        echo -e "${RED}❌ 前端主页异常${NC}"
    fi
    
    # 检查静态资源
    if curl -s -o /dev/null -w "%{http_code}" http://localhost/static/css/app.css | grep -q "200"; then
        echo -e "${GREEN}✅ 静态资源正常${NC}"
    else
        echo -e "${YELLOW}⚠️ 静态资源可能异常${NC}"
    fi
}

# 检查SSL证书（如果启用HTTPS）
check_ssl() {
    if nc -z localhost 443; then
        echo "🔒 检查SSL证书..."
        cert_info=$(echo | openssl s_client -connect localhost:443 2>/dev/null | openssl x509 -noout -dates)
        echo "$cert_info"
    fi
}

# 生成部署报告
generate_report() {
    echo "📊 生成部署报告..."
    
    report_file="deployment-report-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "Bagua小程序部署验证报告"
        echo "生成时间: $(date)"
        echo "================================="
        echo ""
        
        echo "服务状态:"
        docker-compose ps
        echo ""
        
        echo "系统资源使用:"
        docker stats --no-stream
        echo ""
        
        echo "磁盘使用:"
        df -h
        echo ""
        
        echo "内存使用:"
        free -h
        
    } > $report_file
    
    echo "📋 部署报告已保存到: $report_file"
}

# 主流程
main() {
    echo "🚀 开始部署验证..."
    
    check_service_status
    echo ""
    
    check_ports
    echo ""
    
    check_api_endpoints
    echo ""
    
    check_frontend
    echo ""
    
    check_ssl
    echo ""
    
    generate_report
    
    echo -e "${GREEN}🎉 部署验证完成！${NC}"
}

main "$@"
```

**预防措施：**
- 建立标准化的Nginx配置模板
- 部署前进行配置验证
- 建立完整的部署检查清单
- 制作回滚方案和脚本

---

## 📚 问题根因分析

### 共同问题模式

1. **规划不足：** 项目初期缺少完整的技术方案和环境规划
2. **标准化缺失：** 缺少统一的开发、部署、运维标准
3. **自动化程度低：** 手工操作导致错误频发
4. **环境一致性差：** 开发、测试、生产环境差异较大
5. **文档不完善：** 缺少详细的操作手册和排错指南

### 解决策略

1. **前置规划：** 项目开始前制定完整的技术方案
2. **标准化：** 建立统一的开发和部署标准
3. **自动化：** 尽可能使用脚本和工具自动化操作
4. **环境一致性：** 所有环境使用相同的技术栈和配置
5. **文档化：** 详细记录所有操作步骤和解决方案

## 🛠️ 最佳实践总结

### 项目初始化检查清单

```markdown
□ 技术选型确定并文档化
□ 环境配置标准制定
□ 开发工具和依赖版本锁定
□ Git仓库和SSH配置
□ Docker环境配置
□ 网络环境和镜像源配置
□ 启动脚本和流程制定
□ 部署方案设计
□ 监控和日志方案
□ 文档模板准备
```

### 开发过程检查清单

```markdown
□ 使用统一的启动脚本
□ 定期运行测试
□ 遵循提交规范
□ 定期同步代码
□ 环境一致性检查
□ 配置文件管理
□ 依赖版本控制
□ 性能监控
□ 错误日志检查
□ 文档更新
```

### 部署前检查清单

```markdown
□ 环境配置验证
□ 网络连通性测试
□ 端口可用性检查
□ SSL证书配置
□ 数据库连接测试
□ 静态资源路径验证
□ API接口测试
□ 负载均衡配置
□ 监控告警配置
□ 回滚方案准备
```

## 🎯 经验教训

1. **问题早发现早解决：** 环境和配置问题要在项目初期解决
2. **标准化是关键：** 统一的标准可以避免大部分问题
3. **自动化提升效率：** 脚本化操作可以减少人为错误
4. **文档是必需品：** 详细的文档是项目成功的保障
5. **测试验证不可少：** 每个环节都要有验证机制

## 🔗 相关文档

- [项目环境配置指南](./PROJECT_ENV_SETUP.md)
- [Docker部署手册](./DOCKER_DEPLOYMENT.md)
- [Git提交规范](./GIT_COMMIT_GUIDE.md)
- [Nginx配置指南](./NGINX_CONFIG_GUIDE.md)
- [故障排除手册](./TROUBLESHOOTING.md)

---

**文档维护：** 请在遇到新问题时及时更新此文档，保持经验的积累和传承。 
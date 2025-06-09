# AI八卦运势小程序 - 前端生产环境部署指南

## 📋 项目概述

**项目类型**: uni-app 多端开发框架  
**技术栈**: Vue 3 + TypeScript + Vite + uni-app  
**支持平台**: H5网页、微信小程序、支付宝小程序等  
**生产部署**: H5版本部署到服务器，小程序版本发布到各平台  

## 🏗️ 项目结构

```
frontend/
├── src/                        # 源代码目录
│   ├── pages/                  # 页面文件
│   │   ├── index/              # 首页
│   │   ├── calculate/          # 八字测算页
│   │   ├── result/             # 结果展示页
│   │   ├── vip/                # VIP会员页
│   │   ├── history/            # 历史记录页
│   │   ├── profile/            # 个人中心页
│   │   └── ...
│   ├── api/                    # API接口
│   ├── utils/                  # 工具函数
│   ├── store/                  # 状态管理
│   ├── static/                 # 静态资源
│   ├── App.vue                 # 应用入口
│   ├── main.ts                 # 主入口文件
│   ├── pages.json              # 页面配置
│   └── manifest.json           # 应用配置
├── dist/                       # 构建输出目录
│   ├── build/                  # 生产构建
│   │   ├── h5/                 # H5版本输出
│   │   └── mp-weixin/          # 微信小程序输出
│   └── dev/                    # 开发构建
├── package.json                # 项目配置
├── vite.config.js              # 构建配置
└── tsconfig.json               # TypeScript配置
```

## 🛠️ 生产环境部署步骤

### 第1步：环境准备

#### 1.1 Node.js环境检查
```bash
# 检查Node.js版本（推荐16+）
node --version
npm --version

# 如果需要安装Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

#### 1.2 进入前端项目目录
```bash
cd /path/to/project/frontend
pwd
ls -la
```

### 第2步：依赖安装

#### 2.1 配置npm镜像（可选，提升下载速度）
```bash
# 设置淘宝镜像
npm config set registry https://registry.npmmirror.com

# 验证镜像设置
npm config get registry
```

#### 2.2 安装项目依赖
```bash
# 清理缓存
npm cache clean --force

# 安装依赖
npm install

# 检查依赖安装状态
npm list --depth=0
```

### 第3步：生产环境构建

#### 3.1 H5版本构建（Web部署）
```bash
# 构建H5生产版本
npm run build:h5

# 检查构建结果
ls -la dist/build/h5/
```

#### 3.2 微信小程序构建（可选）
```bash
# 构建微信小程序版本
npm run build:mp-weixin

# 检查构建结果
ls -la dist/build/mp-weixin/
```

### 第4步：配置生产环境

#### 4.1 创建生产环境配置
```bash
# 创建环境配置文件
cat > src/config/production.js << 'EOF'
export const config = {
  // API基础地址
  apiBaseUrl: 'https://your-domain.com/api',
  
  // 微信小程序配置
  wechatConfig: {
    appId: '[已移除微信AppID]'
  },
  
  // 其他生产环境配置
  environment: 'production',
  debug: false
}
EOF
```

#### 4.2 修改API配置（如果需要）
```bash
# 检查API配置文件
find src -name "*.js" -o -name "*.ts" | xargs grep -l "localhost:8080"

# 批量替换API地址（示例）
find src -name "*.js" -o -name "*.ts" -exec sed -i 's/localhost:8080/your-domain.com/g' {} \;
```

### 第5步：部署到生产服务器

#### 5.1 方案A：直接复制到Nginx静态目录
```bash
# 在服务器上执行
cd /path/to/project/frontend

# 构建H5版本
npm run build:h5

# 复制到Nginx静态目录
sudo cp -r dist/build/h5/* /usr/share/nginx/html/

# 设置权限
sudo chown -R nginx:nginx /usr/share/nginx/html/
sudo chmod -R 644 /usr/share/nginx/html/
```

#### 5.2 方案B：通过Docker部署
```bash
# 创建前端Dockerfile
cat > frontend/Dockerfile << 'EOF'
# 构建阶段
FROM node:18-alpine as builder

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build:h5

# 运行阶段
FROM nginx:1.25-alpine

# 复制构建产物
COPY --from=builder /app/dist/build/h5 /usr/share/nginx/html

# 复制Nginx配置
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

# 构建Docker镜像
docker build -t fortune-frontend:latest ./frontend

# 运行容器
docker run -d -p 80:80 --name fortune-frontend fortune-frontend:latest
```

#### 5.3 方案C：集成到现有Docker Compose
```yaml
# 在docker-compose.prod.yml中添加前端服务
  frontend-prod:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: bagua-frontend-prod
    restart: unless-stopped
    volumes:
      - ./frontend/dist/build/h5:/usr/share/nginx/html:ro
    networks:
      - fortune-prod-network
```

### 第6步：Nginx配置优化

#### 6.1 前端路由配置
```nginx
# 在nginx/nginx.prod.conf中添加前端路由配置
location / {
    root /usr/share/nginx/html;
    try_files $uri $uri/ /index.html;
    index index.html;
    
    # 缓存配置
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # HTML文件不缓存
    location ~* \.html$ {
        expires -1;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }
}

# API代理（已存在）
location /api/ {
    proxy_pass http://backend_cluster/api/;
    # ... 其他配置
}
```

### 第7步：自动化部署脚本

#### 7.1 创建前端部署脚本
```bash
cat > scripts/deploy-frontend.sh << 'EOF'
#!/bin/bash

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查Node.js环境
check_nodejs() {
    log_info "检查Node.js环境..."
    
    if ! command -v node &> /dev/null; then
        log_error "Node.js未安装"
        exit 1
    fi
    
    NODE_VERSION=$(node --version)
    log_info "Node.js版本: $NODE_VERSION"
}

# 安装依赖
install_dependencies() {
    log_info "安装前端依赖..."
    
    cd frontend
    
    if [ ! -d "node_modules" ]; then
        npm install
    else
        log_info "依赖已存在，跳过安装"
    fi
    
    cd ..
}

# 构建前端
build_frontend() {
    log_info "构建前端应用..."
    
    cd frontend
    
    # 清理旧的构建
    if [ -d "dist/build/h5" ]; then
        rm -rf dist/build/h5
    fi
    
    # 构建H5版本
    npm run build:h5
    
    if [ ! -d "dist/build/h5" ]; then
        log_error "前端构建失败"
        exit 1
    fi
    
    log_info "前端构建成功"
    cd ..
}

# 部署到Nginx
deploy_to_nginx() {
    log_info "部署前端到Nginx..."
    
    # 备份现有文件
    if [ -d "/usr/share/nginx/html.backup" ]; then
        rm -rf /usr/share/nginx/html.backup
    fi
    
    if [ -d "/usr/share/nginx/html" ]; then
        sudo mv /usr/share/nginx/html /usr/share/nginx/html.backup
    fi
    
    # 创建新目录
    sudo mkdir -p /usr/share/nginx/html
    
    # 复制文件
    sudo cp -r frontend/dist/build/h5/* /usr/share/nginx/html/
    
    # 设置权限
    sudo chown -R nginx:nginx /usr/share/nginx/html/
    sudo chmod -R 644 /usr/share/nginx/html/
    sudo find /usr/share/nginx/html -type d -exec chmod 755 {} \;
    
    log_info "前端部署完成"
}

# 重启Nginx
restart_nginx() {
    log_info "重启Nginx服务..."
    
    if command -v systemctl &> /dev/null; then
        sudo systemctl reload nginx
    elif command -v service &> /dev/null; then
        sudo service nginx reload
    else
        log_warning "无法自动重启Nginx，请手动重启"
    fi
}

# 验证部署
verify_deployment() {
    log_info "验证前端部署..."
    
    # 检查文件是否存在
    if [ ! -f "/usr/share/nginx/html/index.html" ]; then
        log_error "index.html文件不存在"
        exit 1
    fi
    
    # 测试HTTP访问
    if curl -f -s http://localhost/ > /dev/null; then
        log_info "前端访问测试成功"
    else
        log_warning "前端访问测试失败，请检查Nginx配置"
    fi
}

# 主函数
main() {
    log_info "开始前端部署..."
    
    check_nodejs
    install_dependencies
    build_frontend
    deploy_to_nginx
    restart_nginx
    verify_deployment
    
    log_info "前端部署完成！"
    echo ""
    echo "访问地址："
    echo "  - HTTP: http://your-domain.com"
    echo "  - HTTPS: https://your-domain.com"
}

# 执行主函数
main "$@"
EOF

# 设置执行权限
chmod +x scripts/deploy-frontend.sh
```

### 第8步：验证部署

#### 8.1 检查构建产物
```bash
# 检查H5构建结果
ls -la frontend/dist/build/h5/
head -20 frontend/dist/build/h5/index.html
```

#### 8.2 本地测试
```bash
# 使用Python启动本地服务器测试
cd frontend/dist/build/h5
python3 -m http.server 8000

# 或使用Node.js serve工具
npx serve -s . -l 8000
```

#### 8.3 生产环境测试
```bash
# 测试前端页面
curl -I http://your-domain.com/

# 测试API代理
curl http://your-domain.com/api/simple/hello

# 测试路由
curl -I http://your-domain.com/pages/calculate
```

## 🚀 快速部署命令

### 完整部署流程
```bash
# 1. 进入项目目录
cd /path/to/bagua-ai

# 2. 设置环境变量（如果需要）
export NODE_ENV=production
export API_BASE_URL=https://your-domain.com

# 3. 执行前端部署脚本
./scripts/deploy-frontend.sh

# 4. 验证部署
curl http://your-domain.com/
```

### Docker环境部署
```bash
# 构建并启动前端容器
docker compose -f docker-compose.prod.yml up -d frontend-prod

# 查看容器状态
docker compose -f docker-compose.prod.yml ps frontend-prod

# 查看容器日志
docker compose -f docker-compose.prod.yml logs frontend-prod
```

## 🔧 常见问题与解决方案

### 问题1：依赖安装失败
```bash
# 清理npm缓存
npm cache clean --force

# 删除node_modules重新安装
rm -rf node_modules package-lock.json
npm install
```

### 问题2：构建失败
```bash
# 检查Node.js版本
node --version  # 确保16+

# 检查磁盘空间
df -h

# 查看详细错误信息
npm run build:h5 --verbose
```

### 问题3：路由404错误
```nginx
# 在Nginx配置中添加前端路由支持
location / {
    try_files $uri $uri/ /index.html;
}
```

### 问题4：API跨域问题
```javascript
// 在前端配置中设置正确的API地址
const apiBaseUrl = process.env.NODE_ENV === 'production' 
  ? 'https://your-domain.com/api'
  : 'http://localhost:8080/api';
```

## 📱 微信小程序发布流程

### 1. 构建小程序版本
```bash
cd frontend
npm run build:mp-weixin
```

### 2. 微信开发者工具导入
1. 打开微信开发者工具
2. 导入项目：`frontend/dist/build/mp-weixin`
3. AppID：`[已移除微信AppID]`
4. 项目名称：`AI八卦运势小程序`

### 3. 提交审核
1. 在开发者工具中点击"上传"
2. 登录微信公众平台
3. 提交审核并发布

## 🎯 性能优化建议

### 1. 构建优化
```javascript
// vite.config.js 优化配置
export default defineConfig({
  plugins: [uni()],
  build: {
    terserOptions: {
      compress: {
        drop_console: true,  // 移除console
        drop_debugger: true  // 移除debugger
      }
    },
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['vue', 'pinia'],
          utils: ['./src/utils']
        }
      }
    }
  }
})
```

### 2. 缓存策略
```nginx
# 静态资源缓存
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff2?)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
    access_log off;
}
```

### 3. 图片优化
```bash
# 压缩图片资源
find src/static -name "*.png" -exec pngquant --quality=65-80 --ext .png --force {} \;
find src/static -name "*.jpg" -exec jpegoptim --max=80 {} \;
```

## 📊 监控与维护

### 1. 部署监控
```bash
# 创建健康检查脚本
cat > scripts/health-check-frontend.sh << 'EOF'
#!/bin/bash
HEALTH_URL="http://localhost/"
if curl -f -s $HEALTH_URL > /dev/null; then
    echo "✅ 前端服务正常"
    exit 0
else
    echo "❌ 前端服务异常"
    exit 1
fi
EOF

chmod +x scripts/health-check-frontend.sh
```

### 2. 日志监控
```bash
# 查看Nginx访问日志
tail -f /var/log/nginx/access.log | grep -E "\.(js|css|html)"

# 查看错误日志
tail -f /var/log/nginx/error.log
```

### 3. 自动更新
```bash
# 添加到crontab定期检查更新
# 0 2 * * * /path/to/scripts/deploy-frontend.sh > /var/log/frontend-deploy.log 2>&1
```

---

## 🎉 部署完成

前端应用部署完成后，你将拥有：

- ✅ **H5网页版本**: 通过浏览器访问完整功能
- ✅ **响应式设计**: 支持PC和移动端访问
- ✅ **API集成**: 与后端服务完美对接
- ✅ **路由支持**: SPA单页应用体验
- ✅ **生产优化**: 代码压缩、缓存策略
- ✅ **容器化部署**: 支持Docker环境

**前端访问地址**: `https://your-domain.com`  
**管理后台**: 可通过同一域名的不同路由访问  

🚀 **恭喜！AI八卦运势小程序前端已成功部署到生产环境！** 
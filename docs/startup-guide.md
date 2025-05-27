# AI八卦运势小程序 - 启动指南

## 概述
本文档提供了AI八卦运势小程序前端和后端的详细启动指南，包括环境检查、端口管理和常见问题处理。

## 环境要求

### 后端环境
- Java 17+
- Maven 3.6+
- MySQL 8.0+
- 端口：8080

### 前端环境
- Node.js 16+
- npm 或 yarn
- 微信开发者工具
- 端口：通常为随机端口

## 启动前检查

### 1. 端口占用检查脚本

创建端口检查脚本 `scripts/check-ports.sh`：

```bash
#!/bin/bash

echo "=== 端口占用检查 ==="

# 检查8080端口（后端）
echo "检查8080端口（后端）..."
PORT_8080=$(lsof -ti:8080)
if [ ! -z "$PORT_8080" ]; then
    echo "⚠️  端口8080被占用，进程ID: $PORT_8080"
    echo "占用进程详情:"
    lsof -i:8080
    echo ""
    read -p "是否要杀死占用进程？(y/n): " kill_choice
    if [ "$kill_choice" = "y" ] || [ "$kill_choice" = "Y" ]; then
        echo "正在杀死进程..."
        lsof -ti:8080 | xargs kill -9
        echo "✅ 进程已杀死"
    else
        echo "❌ 请手动处理端口占用问题"
        exit 1
    fi
else
    echo "✅ 端口8080可用"
fi

# 检查3000端口（前端开发服务器，如果使用）
echo "检查3000端口（前端开发服务器）..."
PORT_3000=$(lsof -ti:3000)
if [ ! -z "$PORT_3000" ]; then
    echo "⚠️  端口3000被占用，进程ID: $PORT_3000"
    echo "占用进程详情:"
    lsof -i:3000
    echo ""
    read -p "是否要杀死占用进程？(y/n): " kill_choice
    if [ "$kill_choice" = "y" ] || [ "$kill_choice" = "Y" ]; then
        echo "正在杀死进程..."
        lsof -ti:3000 | xargs kill -9
        echo "✅ 进程已杀死"
    fi
else
    echo "✅ 端口3000可用"
fi

echo "=== 端口检查完成 ==="
```

### 2. 数据库连接检查

```bash
#!/bin/bash

echo "=== 数据库连接检查 ==="

# 检查MySQL服务状态
if ! command -v mysql &> /dev/null; then
    echo "❌ MySQL客户端未安装"
    exit 1
fi

# 尝试连接数据库
mysql -u root -p -e "USE fortune_db; SHOW TABLES;" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ 数据库连接正常"
else
    echo "❌ 数据库连接失败，请检查："
    echo "  1. MySQL服务是否启动"
    echo "  2. 数据库fortune_db是否存在"
    echo "  3. 用户权限是否正确"
    exit 1
fi

echo "=== 数据库检查完成 ==="
```

## 后端启动

### 1. 后端启动脚本

创建 `scripts/start-backend.sh`：

```bash
#!/bin/bash

echo "=== AI八卦运势小程序后端启动 ==="

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查当前目录
if [ ! -f "backend/pom.xml" ]; then
    echo -e "${RED}❌ 请在项目根目录执行此脚本${NC}"
    exit 1
fi

# 步骤1: 检查端口占用
echo -e "${YELLOW}步骤1: 检查端口占用${NC}"
PORT_8080=$(lsof -ti:8080 2>/dev/null)
if [ ! -z "$PORT_8080" ]; then
    echo -e "${YELLOW}⚠️  端口8080被占用，进程ID: $PORT_8080${NC}"
    echo "占用进程详情:"
    lsof -i:8080
    echo ""
    read -p "是否要杀死占用进程？(y/n): " kill_choice
    if [ "$kill_choice" = "y" ] || [ "$kill_choice" = "Y" ]; then
        echo "正在杀死进程..."
        lsof -ti:8080 | xargs kill -9 2>/dev/null
        sleep 2
        # 再次检查
        if [ -z "$(lsof -ti:8080 2>/dev/null)" ]; then
            echo -e "${GREEN}✅ 进程已杀死，端口8080现在可用${NC}"
        else
            echo -e "${RED}❌ 无法杀死进程，请手动处理${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ 请手动处理端口占用问题后重试${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ 端口8080可用${NC}"
fi

# 步骤2: 检查Java环境
echo -e "${YELLOW}步骤2: 检查Java环境${NC}"
if ! command -v java &> /dev/null; then
    echo -e "${RED}❌ Java未安装或未配置到PATH${NC}"
    exit 1
fi

JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
echo -e "${GREEN}✅ Java版本: $JAVA_VERSION${NC}"

# 步骤3: 检查Maven环境
echo -e "${YELLOW}步骤3: 检查Maven环境${NC}"
if ! command -v mvn &> /dev/null; then
    echo -e "${RED}❌ Maven未安装或未配置到PATH${NC}"
    exit 1
fi

MVN_VERSION=$(mvn -version | head -n 1)
echo -e "${GREEN}✅ $MVN_VERSION${NC}"

# 步骤4: 检查数据库连接
echo -e "${YELLOW}步骤4: 检查数据库连接${NC}"
if command -v mysql &> /dev/null; then
    # 这里可以添加数据库连接测试
    echo -e "${GREEN}✅ MySQL客户端可用${NC}"
else
    echo -e "${YELLOW}⚠️  MySQL客户端未找到，请确保数据库正常运行${NC}"
fi

# 步骤5: 进入backend目录并启动
echo -e "${YELLOW}步骤5: 启动Spring Boot应用${NC}"
cd backend

echo "正在编译和启动应用..."
echo "命令: mvn spring-boot:run"
echo ""

# 启动应用
mvn spring-boot:run

# 检查启动结果
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 后端启动成功${NC}"
else
    echo -e "${RED}❌ 后端启动失败，请检查错误信息${NC}"
    exit 1
fi
```

### 2. 后端快速重启脚本

创建 `scripts/restart-backend.sh`：

```bash
#!/bin/bash

echo "=== 后端快速重启 ==="

# 强制杀死8080端口进程
echo "正在停止后端服务..."
lsof -ti:8080 | xargs kill -9 2>/dev/null
sleep 3

# 确认端口已释放
if [ -z "$(lsof -ti:8080 2>/dev/null)" ]; then
    echo "✅ 后端服务已停止"
else
    echo "⚠️  端口可能仍被占用，继续启动..."
fi

# 重新启动
echo "正在重新启动后端服务..."
cd backend && mvn spring-boot:run
```

## 前端启动

### 1. 前端启动脚本

创建 `scripts/start-frontend.sh`：

```bash
#!/bin/bash

echo "=== AI八卦运势小程序前端启动 ==="

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查当前目录
if [ ! -f "frontend/package.json" ]; then
    echo -e "${RED}❌ 请在项目根目录执行此脚本${NC}"
    exit 1
fi

# 步骤1: 检查Node.js环境
echo -e "${YELLOW}步骤1: 检查Node.js环境${NC}"
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js未安装或未配置到PATH${NC}"
    exit 1
fi

NODE_VERSION=$(node -v)
echo -e "${GREEN}✅ Node.js版本: $NODE_VERSION${NC}"

# 步骤2: 检查npm环境
echo -e "${YELLOW}步骤2: 检查npm环境${NC}"
if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ npm未安装${NC}"
    exit 1
fi

NPM_VERSION=$(npm -v)
echo -e "${GREEN}✅ npm版本: $NPM_VERSION${NC}"

# 步骤3: 进入frontend目录
echo -e "${YELLOW}步骤3: 进入前端目录${NC}"
cd frontend

# 步骤4: 检查依赖
echo -e "${YELLOW}步骤4: 检查依赖${NC}"
if [ ! -d "node_modules" ]; then
    echo "node_modules不存在，正在安装依赖..."
    npm install
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ 依赖安装失败${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ 依赖已存在${NC}"
fi

# 步骤5: 启动开发服务器
echo -e "${YELLOW}步骤5: 启动微信小程序开发模式${NC}"
echo "正在启动前端开发服务器..."
echo "命令: npm run dev:mp-weixin"
echo ""

# 启动前端
npm run dev:mp-weixin

# 检查启动结果
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 前端启动成功${NC}"
    echo "请打开微信开发者工具，导入 dist/dev/mp-weixin 目录"
else
    echo -e "${RED}❌ 前端启动失败，请检查错误信息${NC}"
    exit 1
fi
```

### 2. 前端构建脚本

创建 `scripts/build-frontend.sh`：

```bash
#!/bin/bash

echo "=== 前端构建 ==="

cd frontend

echo "正在构建生产版本..."
npm run build:mp-weixin

if [ $? -eq 0 ]; then
    echo "✅ 前端构建成功"
    echo "构建文件位于: dist/build/mp-weixin/"
else
    echo "❌ 前端构建失败"
    exit 1
fi
```

## 完整启动脚本

### 1. 一键启动脚本

创建 `scripts/start-all.sh`：

```bash
#!/bin/bash

echo "=== AI八卦运势小程序一键启动 ==="

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查项目结构
if [ ! -f "backend/pom.xml" ] || [ ! -f "frontend/package.json" ]; then
    echo -e "${RED}❌ 请在项目根目录执行此脚本${NC}"
    exit 1
fi

echo -e "${BLUE}开始启动AI八卦运势小程序...${NC}"

# 步骤1: 端口检查和清理
echo -e "${YELLOW}=== 步骤1: 端口检查和清理 ===${NC}"
./scripts/check-ports.sh
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 端口检查失败${NC}"
    exit 1
fi

# 步骤2: 启动后端
echo -e "${YELLOW}=== 步骤2: 启动后端服务 ===${NC}"
echo "正在后台启动后端..."
cd backend
nohup mvn spring-boot:run > ../logs/backend.log 2>&1 &
BACKEND_PID=$!
cd ..

echo "后端进程ID: $BACKEND_PID"
echo "等待后端启动..."

# 等待后端启动（最多等待60秒）
for i in {1..60}; do
    if curl -s http://localhost:8080/api/actuator/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 后端启动成功${NC}"
        break
    fi
    if [ $i -eq 60 ]; then
        echo -e "${RED}❌ 后端启动超时${NC}"
        kill $BACKEND_PID 2>/dev/null
        exit 1
    fi
    echo "等待中... ($i/60)"
    sleep 1
done

# 步骤3: 启动前端
echo -e "${YELLOW}=== 步骤3: 启动前端服务 ===${NC}"
cd frontend

# 检查依赖
if [ ! -d "node_modules" ]; then
    echo "正在安装前端依赖..."
    npm install
fi

echo "正在启动前端开发服务器..."
npm run dev:mp-weixin &
FRONTEND_PID=$!
cd ..

echo "前端进程ID: $FRONTEND_PID"

# 步骤4: 显示启动信息
echo -e "${GREEN}=== 启动完成 ===${NC}"
echo -e "${BLUE}后端服务:${NC} http://localhost:8080"
echo -e "${BLUE}前端开发:${NC} 请打开微信开发者工具，导入 frontend/dist/dev/mp-weixin 目录"
echo ""
echo -e "${YELLOW}进程信息:${NC}"
echo "后端PID: $BACKEND_PID"
echo "前端PID: $FRONTEND_PID"
echo ""
echo -e "${YELLOW}日志文件:${NC}"
echo "后端日志: logs/backend.log"
echo ""
echo -e "${YELLOW}停止服务:${NC}"
echo "后端: kill $BACKEND_PID"
echo "前端: kill $FRONTEND_PID"
echo "或使用: ./scripts/stop-all.sh"

# 保存PID到文件
mkdir -p logs
echo $BACKEND_PID > logs/backend.pid
echo $FRONTEND_PID > logs/frontend.pid
```

### 2. 停止所有服务脚本

创建 `scripts/stop-all.sh`：

```bash
#!/bin/bash

echo "=== 停止所有服务 ==="

# 停止后端
if [ -f "logs/backend.pid" ]; then
    BACKEND_PID=$(cat logs/backend.pid)
    if kill -0 $BACKEND_PID 2>/dev/null; then
        echo "正在停止后端服务 (PID: $BACKEND_PID)..."
        kill $BACKEND_PID
        sleep 2
        if kill -0 $BACKEND_PID 2>/dev/null; then
            echo "强制停止后端服务..."
            kill -9 $BACKEND_PID
        fi
        echo "✅ 后端服务已停止"
    else
        echo "后端服务未运行"
    fi
    rm -f logs/backend.pid
fi

# 停止前端
if [ -f "logs/frontend.pid" ]; then
    FRONTEND_PID=$(cat logs/frontend.pid)
    if kill -0 $FRONTEND_PID 2>/dev/null; then
        echo "正在停止前端服务 (PID: $FRONTEND_PID)..."
        kill $FRONTEND_PID
        echo "✅ 前端服务已停止"
    else
        echo "前端服务未运行"
    fi
    rm -f logs/frontend.pid
fi

# 清理端口
echo "清理端口占用..."
lsof -ti:8080 | xargs kill -9 2>/dev/null
lsof -ti:3000 | xargs kill -9 2>/dev/null

echo "✅ 所有服务已停止"
```

## 使用说明

### 1. 赋予脚本执行权限

```bash
chmod +x scripts/*.sh
```

### 2. 创建必要目录

```bash
mkdir -p logs
```

### 3. 启动服务

```bash
# 一键启动所有服务
./scripts/start-all.sh

# 或分别启动
./scripts/start-backend.sh
./scripts/start-frontend.sh
```

### 4. 停止服务

```bash
# 停止所有服务
./scripts/stop-all.sh

# 或手动停止
kill $(cat logs/backend.pid)
kill $(cat logs/frontend.pid)
```

## 常见问题处理

### 1. 端口占用问题

```bash
# 查看端口占用
lsof -i:8080
netstat -tulpn | grep 8080

# 强制杀死进程
lsof -ti:8080 | xargs kill -9
```

### 2. 后端启动失败

```bash
# 查看详细日志
tail -f logs/backend.log

# 检查Java版本
java -version

# 检查Maven版本
mvn -version
```

### 3. 前端启动失败

```bash
# 重新安装依赖
cd frontend
rm -rf node_modules package-lock.json
npm install

# 清理缓存
npm cache clean --force
```

### 4. 数据库连接问题

```bash
# 检查MySQL服务
brew services list | grep mysql  # macOS
systemctl status mysql          # Linux

# 测试数据库连接
mysql -u root -p -e "SHOW DATABASES;"
```

## 监控和日志

### 1. 实时监控脚本

创建 `scripts/monitor.sh`：

```bash
#!/bin/bash

echo "=== 服务监控 ==="

while true; do
    clear
    echo "=== AI八卦运势小程序服务状态 ==="
    echo "时间: $(date)"
    echo ""
    
    # 检查后端
    if curl -s http://localhost:8080/api/actuator/health > /dev/null 2>&1; then
        echo "✅ 后端服务: 运行中"
    else
        echo "❌ 后端服务: 未运行"
    fi
    
    # 检查端口
    if lsof -i:8080 > /dev/null 2>&1; then
        echo "✅ 端口8080: 已占用"
    else
        echo "❌ 端口8080: 未占用"
    fi
    
    echo ""
    echo "按 Ctrl+C 退出监控"
    sleep 5
done
```

### 2. 日志查看

```bash
# 查看后端日志
tail -f logs/backend.log

# 查看错误日志
grep -i error logs/backend.log

# 查看最近的日志
tail -n 100 logs/backend.log
```

这个启动指南提供了完整的脚本和说明，特别关注了端口占用问题的检查和处理。每次启动前都会自动检查端口占用情况，并提供选择是否杀死占用进程的选项。 
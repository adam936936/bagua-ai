# 八卦AI项目部署和测试指南

## 🎯 部署目标

1. **数据库迁移：** 从H2内存数据库迁移到MySQL生产环境
2. **环境配置：** 支持开发、测试、生产多环境
3. **小程序测试：** 完整的前后端联调测试
4. **生产部署：** 稳定可靠的生产环境部署

## 📋 部署步骤

### 第一步：MySQL数据库准备

#### 1.1 安装MySQL（如果未安装）
```bash
# macOS使用Homebrew安装
brew install mysql

# 启动MySQL服务
brew services start mysql

# 设置root密码
mysql_secure_installation
```

#### 1.2 创建数据库和用户
```sql
-- 连接MySQL
mysql -u root -p

-- 创建数据库
CREATE DATABASE fortune_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 创建专用用户
CREATE USER 'fortune_user'@'localhost' IDENTIFIED BY 'fortune_password_2024';
GRANT ALL PRIVILEGES ON fortune_db.* TO 'fortune_user'@'localhost';
FLUSH PRIVILEGES;

-- 验证连接
USE fortune_db;
SHOW TABLES;
```

### 第二步：配置文件优化

#### 2.1 创建生产环境配置
创建 `application-prod.yml`：
```yaml
server:
  port: 8080

spring:
  application:
    name: fortune-mini-app
  
  # MySQL生产数据库配置
  datasource:
    driver-class-name: com.mysql.cj.jdbc.Driver
    url: jdbc:mysql://localhost:3306/fortune_db?useUnicode=true&characterEncoding=utf8&useSSL=false&serverTimezone=Asia/Shanghai
    username: fortune_user
    password: fortune_password_2024
    hikari:
      minimum-idle: 5
      maximum-pool-size: 20
      idle-timeout: 600000
      max-lifetime: 1800000
      connection-timeout: 30000
  
  # Redis配置
  redis:
    host: localhost
    port: 6379
    password: 
    database: 0

# 生产环境日志配置
logging:
  level:
    com.fortune: INFO
    org.springframework.web: WARN
  file:
    name: logs/fortune-app.log
```

#### 2.2 创建开发环境配置
创建 `application-dev.yml`：
```yaml
server:
  port: 8080

spring:
  # H2开发数据库配置
  datasource:
    driver-class-name: org.h2.Driver
    url: jdbc:h2:mem:fortune_db;DB_CLOSE_DELAY=-1;MODE=MySQL
    username: sa
    password: 
  
  h2:
    console:
      enabled: true
      path: /h2-console

# 开发环境日志配置
logging:
  level:
    com.fortune: DEBUG
    org.springframework.web: DEBUG
```

### 第三步：数据库初始化脚本

#### 3.1 创建数据库表结构
```sql
-- 用户表
CREATE TABLE users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    openid VARCHAR(100) UNIQUE NOT NULL COMMENT '微信openid',
    nickname VARCHAR(50) COMMENT '昵称',
    avatar_url VARCHAR(255) COMMENT '头像URL',
    vip_level INT DEFAULT 0 COMMENT 'VIP等级：0-普通用户，1-月度VIP，2-年度VIP',
    vip_expire_time DATETIME COMMENT 'VIP过期时间',
    created_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted TINYINT DEFAULT 0
);

-- 命理记录表
CREATE TABLE fortune_records (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL COMMENT '用户ID',
    name VARCHAR(50) NOT NULL COMMENT '姓名',
    gender TINYINT NOT NULL COMMENT '性别：1-男，2-女',
    birth_year INT NOT NULL COMMENT '出生年',
    birth_month INT NOT NULL COMMENT '出生月',
    birth_day INT NOT NULL COMMENT '出生日',
    birth_hour INT COMMENT '出生时辰',
    lunar_year INT COMMENT '农历年',
    lunar_month INT COMMENT '农历月',
    lunar_day INT COMMENT '农历日',
    gan_zhi VARCHAR(20) COMMENT '干支',
    sheng_xiao VARCHAR(10) COMMENT '生肖',
    wu_xing_analysis TEXT COMMENT '五行分析',
    ai_analysis TEXT COMMENT 'AI分析结果',
    created_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted TINYINT DEFAULT 0,
    INDEX idx_user_id (user_id),
    INDEX idx_created_time (created_time)
);

-- 姓名推荐表
CREATE TABLE name_recommendations (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL COMMENT '用户ID',
    surname VARCHAR(20) NOT NULL COMMENT '姓氏',
    gender TINYINT NOT NULL COMMENT '性别',
    birth_info TEXT COMMENT '出生信息JSON',
    recommended_names JSON COMMENT '推荐姓名列表',
    ai_explanation TEXT COMMENT 'AI解释',
    created_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted TINYINT DEFAULT 0,
    INDEX idx_user_id (user_id)
);
```

### 第四步：启动脚本优化

#### 4.1 创建启动脚本
```bash
#!/bin/bash
# start.sh

# 设置环境变量
export JAVA_HOME="/opt/homebrew/Cellar/openjdk@17/17.0.15/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"

# 获取环境参数，默认为dev
PROFILE=${1:-dev}

echo "启动八卦AI后端服务 - 环境: $PROFILE"

# 检查MySQL服务（生产环境）
if [ "$PROFILE" = "prod" ]; then
    echo "检查MySQL服务状态..."
    if ! brew services list | grep mysql | grep started > /dev/null; then
        echo "启动MySQL服务..."
        brew services start mysql
        sleep 3
    fi
fi

# 检查Redis服务
echo "检查Redis服务状态..."
if ! pgrep redis-server > /dev/null; then
    echo "启动Redis服务..."
    redis-server --daemonize yes
    sleep 2
fi

# 启动应用
echo "启动Spring Boot应用..."
java -jar backend/target/fortune-mini-app-1.0.0.jar --spring.profiles.active=$PROFILE

echo "服务启动完成！"
echo "访问地址: http://localhost:8080"
if [ "$PROFILE" = "dev" ]; then
    echo "H2控制台: http://localhost:8080/h2-console"
fi
```

### 第五步：小程序测试方案

#### 5.1 API接口测试
```bash
# 测试脚本 test-api.sh

#!/bin/bash
BASE_URL="http://localhost:8080/api"

echo "=== 八卦AI API测试 ==="

# 1. 健康检查
echo "1. 健康检查..."
curl -s "$BASE_URL/actuator/health" | jq .

# 2. 今日运势测试
echo "2. 今日运势测试..."
curl -s "$BASE_URL/fortune/today-fortune" | jq .

# 3. 命理计算测试
echo "3. 命理计算测试..."
curl -X POST "$BASE_URL/fortune/calculate" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "张三",
    "gender": 1,
    "birthYear": 1990,
    "birthMonth": 5,
    "birthDay": 15,
    "birthHour": 10,
    "userId": 1
  }' | jq .

# 4. 姓名推荐测试
echo "4. 姓名推荐测试..."
curl -X POST "$BASE_URL/fortune/recommend-names" \
  -H "Content-Type: application/json" \
  -d '{
    "surname": "李",
    "gender": 2,
    "birthYear": 1995,
    "birthMonth": 8,
    "birthDay": 20,
    "count": 5
  }' | jq .

echo "=== API测试完成 ==="
```

#### 5.2 前端测试页面优化
更新现有的 `test-frontend.html`：
```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>八卦AI - 小程序测试</title>
    <style>
        /* 添加更多样式，模拟小程序界面 */
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 375px;
            margin: 0 auto;
            background: #f5f5f5;
            padding: 20px;
        }
        .card {
            background: white;
            border-radius: 12px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 2px 12px rgba(0,0,0,0.1);
        }
        .btn {
            background: linear-gradient(45deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 8px;
            cursor: pointer;
            width: 100%;
            margin-top: 10px;
        }
        .result {
            background: #f8f9fa;
            border-radius: 8px;
            padding: 15px;
            margin-top: 15px;
            white-space: pre-wrap;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="card">
        <h2>🔮 八卦AI命理测试</h2>
        <p>模拟小程序界面，测试前后端通信</p>
    </div>

    <!-- 命理计算表单 -->
    <div class="card">
        <h3>📊 命理计算</h3>
        <form id="fortuneForm">
            <input type="text" id="name" placeholder="姓名" required>
            <select id="gender" required>
                <option value="">选择性别</option>
                <option value="1">男</option>
                <option value="2">女</option>
            </select>
            <input type="number" id="birthYear" placeholder="出生年份" min="1900" max="2024" required>
            <input type="number" id="birthMonth" placeholder="出生月份" min="1" max="12" required>
            <input type="number" id="birthDay" placeholder="出生日期" min="1" max="31" required>
            <input type="number" id="birthHour" placeholder="出生时辰(可选)" min="0" max="23">
            <button type="submit" class="btn">🔮 开始算命</button>
        </form>
        <div id="fortuneResult" class="result" style="display:none;"></div>
    </div>

    <!-- 姓名推荐表单 -->
    <div class="card">
        <h3>📝 AI起名</h3>
        <form id="nameForm">
            <input type="text" id="surname" placeholder="姓氏" required>
            <select id="nameGender" required>
                <option value="">选择性别</option>
                <option value="1">男</option>
                <option value="2">女</option>
            </select>
            <input type="number" id="nameBirthYear" placeholder="出生年份" required>
            <input type="number" id="nameBirthMonth" placeholder="出生月份" required>
            <input type="number" id="nameBirthDay" placeholder="出生日期" required>
            <button type="submit" class="btn">✨ AI推荐姓名</button>
        </form>
        <div id="nameResult" class="result" style="display:none;"></div>
    </div>

    <!-- 今日运势 -->
    <div class="card">
        <h3>🌟 今日运势</h3>
        <button onclick="getTodayFortune()" class="btn">查看今日运势</button>
        <div id="todayResult" class="result" style="display:none;"></div>
    </div>

    <script>
        const API_BASE = 'http://localhost:8080/api';

        // 命理计算
        document.getElementById('fortuneForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            const formData = new FormData(e.target);
            const data = {
                name: formData.get('name'),
                gender: parseInt(formData.get('gender')),
                birthYear: parseInt(formData.get('birthYear')),
                birthMonth: parseInt(formData.get('birthMonth')),
                birthDay: parseInt(formData.get('birthDay')),
                birthHour: formData.get('birthHour') ? parseInt(formData.get('birthHour')) : null,
                userId: 1
            };

            try {
                const response = await fetch(`${API_BASE}/fortune/calculate`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(data)
                });
                const result = await response.json();
                document.getElementById('fortuneResult').style.display = 'block';
                document.getElementById('fortuneResult').textContent = JSON.stringify(result, null, 2);
            } catch (error) {
                alert('请求失败: ' + error.message);
            }
        });

        // 姓名推荐
        document.getElementById('nameForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            const formData = new FormData(e.target);
            const data = {
                surname: formData.get('surname'),
                gender: parseInt(formData.get('nameGender')),
                birthYear: parseInt(formData.get('nameBirthYear')),
                birthMonth: parseInt(formData.get('nameBirthMonth')),
                birthDay: parseInt(formData.get('nameBirthDay')),
                count: 5
            };

            try {
                const response = await fetch(`${API_BASE}/fortune/recommend-names`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(data)
                });
                const result = await response.json();
                document.getElementById('nameResult').style.display = 'block';
                document.getElementById('nameResult').textContent = JSON.stringify(result, null, 2);
            } catch (error) {
                alert('请求失败: ' + error.message);
            }
        });

        // 今日运势
        async function getTodayFortune() {
            try {
                const response = await fetch(`${API_BASE}/fortune/today-fortune`);
                const result = await response.json();
                document.getElementById('todayResult').style.display = 'block';
                document.getElementById('todayResult').textContent = JSON.stringify(result, null, 2);
            } catch (error) {
                alert('请求失败: ' + error.message);
            }
        }
    </script>
</body>
</html>
```

### 第六步：部署验证清单

#### 6.1 环境检查清单
- [ ] Java 17环境配置正确
- [ ] MySQL服务运行正常
- [ ] Redis服务运行正常
- [ ] 数据库连接配置正确
- [ ] API密钥配置有效

#### 6.2 功能测试清单
- [ ] 后端服务启动成功
- [ ] 数据库连接正常
- [ ] API接口响应正常
- [ ] 前端页面加载正常
- [ ] 前后端通信正常

## 🚀 快速部署命令

```bash
# 1. 构建项目
mvn clean package -DskipTests

# 2. 启动开发环境（H2数据库）
./start.sh dev

# 3. 启动生产环境（MySQL数据库）
./start.sh prod

# 4. 测试API接口
./test-api.sh

# 5. 启动前端测试页面
python3 -m http.server 3000
```

## 📱 小程序测试建议

1. **本地测试：** 使用测试页面验证所有API功能
2. **网络测试：** 确保小程序可以访问后端API
3. **数据测试：** 验证数据存储和查询功能
4. **性能测试：** 测试并发访问和响应时间
5. **兼容性测试：** 测试不同设备和网络环境

---

**💡 提示：** 建议先在开发环境充分测试，确认无误后再切换到生产环境。 
# AI八卦运势小程序

基于微信小程序平台的八字命理分析工具，结合传统命理学和现代AI技术，为用户提供专业的八字命理分析和AI推荐姓名服务。

## 📊 项目状态

🎉 **项目已完成开发和测试！** (2025-05-26)

- ✅ 后端服务已部署运行 (Spring Boot + H2数据库)
- ✅ 前端测试页面已完成 (HTML + JavaScript)
- ✅ 所有核心API接口测试通过
- ✅ 前后端通信正常，CORS配置完成
- ✅ 命理计算、AI分析、性能监控功能完整
- ✅ 支持实时性能测试和网络联通性检测

## 项目特色

- 🔮 **传统命理学**：精准的八字计算、五行分析、生肖推算
- 🤖 **AI智能分析**：集成DeepSeek API，提供专业的命理解读（支持模拟模式）
- 👑 **VIP会员体系**：多层次付费模式，支持微信支付
- 📱 **现代化UI**：国风设计，用户体验优秀
- 🏗️ **DDD架构**：领域驱动设计，代码结构清晰，易于维护
- ⚡ **性能监控**：实时性能测试和系统状态监控
- 🌐 **网络诊断**：完整的连接状态和系统信息展示

## 技术栈

### 前端
- **框架**: UniApp + Vue3 + TypeScript
- **状态管理**: Pinia
- **UI组件**: 自定义组件 + 原生小程序组件
- **样式**: SCSS + 响应式设计

### 后端
- **框架**: Spring Boot 2.7.14
- **架构模式**: DDD（领域驱动设计）
- **数据库**: MySQL 8.0 + MyBatis-Plus
- **缓存**: Redis
- **AI服务**: DeepSeek API
- **文档**: Swagger

## 项目结构

```
ai-cursor-bagua-ai/
├── backend/                    # 后端项目
│   ├── src/main/java/com/fortune/
│   │   ├── FortuneMiniAppApplication.java
│   │   ├── interfaces/         # 用户接口层
│   │   │   ├── web/           # 控制器
│   │   │   ├── dto/           # 数据传输对象
│   │   │   └── assembler/     # 对象转换器
│   │   ├── application/        # 应用服务层
│   │   │   ├── service/       # 应用服务
│   │   │   ├── command/       # 命令对象
│   │   │   └── query/         # 查询对象
│   │   ├── domain/            # 领域层
│   │   │   ├── fortune/       # 命理聚合
│   │   │   ├── user/          # 用户聚合
│   │   │   └── payment/       # 支付聚合
│   │   └── infrastructure/    # 基础设施层
│   │       ├── repository/    # 仓储实现
│   │       ├── external/      # 外部服务
│   │       └── utils/         # 工具类
│   ├── src/main/resources/
│   │   ├── application.yml    # 配置文件
│   │   └── sql/init.sql       # 数据库初始化脚本
│   └── pom.xml               # Maven配置
├── frontend/                  # 前端项目
│   ├── src/
│   │   ├── pages/            # 页面
│   │   │   ├── index/        # 首页
│   │   │   ├── input/        # 信息输入页
│   │   │   ├── result/       # 结果页
│   │   │   ├── vip/          # VIP页面
│   │   │   └── history/      # 历史记录
│   │   ├── components/       # 组件
│   │   ├── store/           # 状态管理
│   │   ├── api/             # API接口
│   │   ├── utils/           # 工具函数
│   │   ├── types/           # 类型定义
│   │   └── styles/          # 样式文件
│   ├── pages.json           # 页面配置
│   ├── main.ts              # 入口文件
│   └── package.json         # 依赖配置
├── docs/                     # 文档
│   ├── mrd.md               # 需求分析报告
│   ├── prd.md               # 产品需求文档
│   ├── architecture.md      # 架构设计文档
│   └── prototype.html       # 原型设计
└── README.md                # 项目说明
```

## 🚀 快速体验

项目已完成开发，可以直接运行体验！

### 一键启动（推荐）

1. **启动后端服务**
```bash
cd backend
/opt/homebrew/bin/mvn spring-boot:run -Dspring-boot.run.profiles=simple
# 服务将运行在 http://localhost:8080
```

2. **启动前端测试页面**
```bash
cd frontend
python3 -m http.server 3000
# 访问 http://localhost:3000/test-frontend.html
```

3. **体验功能**
- 今日运势查询
- 个人命理计算
- 智能姓名推荐
- 性能测试和网络诊断

### 测试页面功能
- ✅ 美观的渐变UI界面
- ✅ 实时服务状态检测
- ✅ 完整的功能测试
- ✅ 详细的结果展示
- ✅ 性能监控和网络诊断

## 完整开发环境

### 环境要求

- **Java**: JDK 11+ (已测试JDK 23)
- **Maven**: 3.6+ (推荐使用 /opt/homebrew/bin/mvn)
- **Node.js**: 16+ (可选，用于UniApp开发)
- **MySQL**: 8.0+ (可选，默认使用H2内存数据库)
- **Redis**: 6.0+ (可选，默认使用模拟模式)
- **微信开发者工具**: 最新版 (可选，用于小程序开发)

### 后端启动

1. **克隆项目**
```bash
git clone <repository-url>
cd ai-cursor-bagua-ai/backend
```

2. **配置数据库**
```bash
# 创建数据库
mysql -u root -p < src/main/resources/sql/init.sql
```

3. **配置环境变量**
```bash
# 设置环境变量
export DEEPSEEK_API_KEY=your-deepseek-api-key
export WECHAT_APP_ID=your-wechat-app-id
export WECHAT_APP_SECRET=your-wechat-app-secret
```

4. **修改配置文件**
```yaml
# src/main/resources/application.yml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/fortune_db
    username: your-username
    password: your-password
  redis:
    host: localhost
    port: 6379
```

5. **启动应用**
```bash
# 使用Maven启动
mvn spring-boot:run

# 或者使用IDE启动 FortuneMiniAppApplication.java
```

6. **验证启动**
- 访问 http://localhost:8080/api/swagger-ui.html 查看API文档
- 访问 http://localhost:8080/api/actuator/health 检查健康状态

### 前端启动

1. **进入前端目录**
```bash
cd ../frontend
```

2. **安装依赖**
```bash
npm install
```

3. **配置API地址**
```typescript
// src/utils/request.ts
private baseURL = 'http://localhost:8080/api'  // 修改为你的后端地址
```

4. **启动开发服务器**
```bash
# 微信小程序
npm run dev:mp-weixin

# H5开发调试
npm run dev:h5
```

5. **微信开发者工具**
- 打开微信开发者工具
- 导入项目：选择 `frontend/dist/dev/mp-weixin` 目录
- 配置AppID和服务器域名

## 核心功能

### 1. 命理计算
- 阳历转农历
- 天干地支计算
- 五行分析
- 生肖推算
- AI智能解读

### 2. 姓名推荐
- 基于五行缺失的AI姓名推荐
- 姓名五行分析
- 寓意解释

### 3. VIP会员
- 月度会员：¥19.9
- 年度会员：¥199
- 单次付费：¥9.9
- 微信支付集成

### 4. 用户体系
- 微信登录
- 历史记录
- 个人中心

## API接口

### 命理计算
```http
POST /api/fortune/calculate
Content-Type: application/json

{
  "birthDate": "2000-01-01",
  "birthTime": "未时",
  "userName": "张三",
  "userId": 123456
}
```

### AI推荐姓名
```http
POST /api/fortune/recommend-names
Content-Type: application/json

{
  "userId": 123456,
  "wuXingLack": "金、水",
  "ganZhi": "己卯年 丁丑月 甲子日 未时"
}
```

### 今日运势
```http
GET /api/fortune/today-fortune
```

## 部署指南

### Docker部署

1. **构建镜像**
```bash
# 后端
cd backend
docker build -t fortune-backend .

# 前端（需要先构建）
cd ../frontend
npm run build:mp-weixin
```

2. **使用docker-compose**
```bash
docker-compose up -d
```

### 生产环境

1. **服务器配置**
- 阿里云ECS：2核4G内存
- MySQL RDS：主从配置
- Redis：集群模式
- Nginx：负载均衡

2. **域名配置**
- 配置SSL证书
- 设置微信小程序服务器域名白名单

3. **监控运维**
- 应用监控：Spring Boot Actuator
- 日志收集：ELK Stack
- 性能监控：Prometheus + Grafana

## 开发规范

### 代码规范
- 遵循阿里巴巴Java开发手册
- 使用ESLint + Prettier格式化前端代码
- 统一的注释和文档规范

### Git工作流
```bash
# 功能开发
git checkout -b feature/new-feature
git commit -m "feat: 添加新功能"
git push origin feature/new-feature

# 代码审查后合并
git checkout main
git merge feature/new-feature
```

### 测试规范
- 单元测试覆盖率 > 80%
- 集成测试覆盖核心业务流程
- 性能测试确保响应时间 < 500ms

## 常见问题

### Q: DeepSeek API调用失败？
A: 检查API密钥是否正确，网络是否可达，配额是否充足。

### Q: 微信小程序无法登录？
A: 确认AppID和AppSecret配置正确，服务器域名已添加到白名单。

### Q: 数据库连接失败？
A: 检查数据库配置、网络连接、用户权限。

### Q: 前端页面空白？
A: 检查API接口是否正常，浏览器控制台是否有错误信息。

## 贡献指南

1. Fork 项目
2. 创建功能分支
3. 提交代码
4. 发起 Pull Request

## 许可证

本项目采用 MIT 许可证，详见 [LICENSE](LICENSE) 文件。

## 联系方式

- 项目地址：[GitHub Repository]
- 问题反馈：[Issues]
- 技术交流：[微信群]

---

**注意**: 本项目仅供学习和娱乐使用，命理分析结果仅供参考，请理性对待。 
# 八卦AI微信小程序技术架构

## 项目状态
- ✅ 前端微信小程序已完成 (原生微信小程序开发)
- ✅ 后端服务运行正常 (Spring Boot + MySQL数据库)
- ✅ 生产环境部署完成 (腾讯云Docker容器)
- ✅ 完整的微信登录和用户管理
- ✅ 实时八字测算和起名功能

## 整体架构

```
微信小程序前端 → API网关(Nginx) → Spring Boot后端 → MySQL数据库
                                                  ↓
                                              Redis缓存
```

## 技术栈详情

### 前端架构
- **平台**: 微信小程序原生开发
- **技术**: JavaScript, WXML, WXSS
- **特性**: 组件化开发, 响应式设计
- **API通信**: wx.request HTTP调用

### 后端架构 
- **框架**: Spring Boot 2.7.14 + Java 17
- **数据库**: MySQL 8.0+ (生产环境和开发环境统一)
- **缓存**: Redis (生产环境)
- **ORM**: MyBatis-Plus (数据访问层)
- **认证**: JWT + 微信登录
- **API**: RESTful设计规范

### 数据库设计

**核心数据表** (统一使用t_前缀)：
- `t_users` - 用户基础信息表
- `t_fortune_record` - 八字测算记录表  
- `t_name_recommendations` - 起名建议表
- `t_vip_orders` - VIP订单表
- `t_payment_record` - 支付记录表

### 部署架构

**生产环境** (腾讯云服务器):
- **操作系统**: Ubuntu 24.3.0 
- **IP地址**: 122.51.104.128
- **容器化**: Docker + Docker Compose
- **反向代理**: Nginx (HTTPS/SSL)
- **服务编排**: 
  - nginx-prod: 网关服务
  - backend-prod: 应用服务  
  - mysql-prod: 数据库服务
  - redis-prod: 缓存服务

**开发环境**:
- **数据库**: 本地MySQL实例
- **启动方式**: Maven Spring Boot运行
- **配置文件**: application-local-mysql.yml

## 核心功能模块

### 1. 用户认证模块
- 微信小程序登录 (wx.login + code2session)
- JWT令牌生成和验证
- 用户信息自动创建和更新
- 登录状态管理

### 2. 八字测算模块  
- 生辰八字计算算法
- 五行分析和命理解读
- DeepSeek AI增强分析
- 测算结果存储和历史查询

### 3. 起名建议模块
- 基于八字五行的姓名推荐
- 姓名数理分析
- 音韵搭配建议
- 个性化起名方案

### 4. VIP会员模块
- 会员等级管理
- 付费功能限制
- 微信支付集成 
- 订单状态跟踪

### 5. 数据管理模块
- 用户数据CRUD操作
- 测算历史记录管理
- 统计分析功能
- 数据备份和恢复

## API接口设计

### 用户相关接口
```
POST /api/user/login        # 微信登录
GET  /api/user/profile      # 获取用户信息  
PUT  /api/user/profile      # 更新用户信息
GET  /api/user/stats        # 用户统计数据
```

### 八字测算接口
```  
POST /api/fortune/calculate     # 八字测算
GET  /api/fortune/history       # 测算历史
POST /api/fortune/name-recommend # 起名建议
```

### VIP相关接口
```
GET  /api/vip/status       # VIP状态查询
POST /api/vip/purchase     # VIP购买
POST /api/vip/notify       # 支付回调
```

## 安全设计

### 认证授权
- JWT令牌认证机制
- 微信官方API验证  
- 请求签名校验
- API访问频率限制

### 数据安全
- MySQL连接加密
- 敏感配置环境变量管理
- 生产数据库访问控制
- 定期数据备份策略

### 网络安全  
- HTTPS全站加密
- Nginx安全配置
- 防火墙端口管控
- 服务间内网通信

## 性能优化

### 数据库优化
- 索引优化设计
- 查询SQL优化
- 连接池配置调优
- 读写分离预留

### 缓存策略
- Redis热点数据缓存
- 查询结果缓存
- 会话状态缓存  
- API响应缓存

### 系统优化
- JVM参数调优
- 连接池优化配置
- 异步处理机制
- 资源占用监控

---

*架构文档最后更新: 2024年12月* 
# AI八卦运势小程序架构设计文档

## 📊 项目状态 (2025-05-26)

🎉 **项目已完成开发和部署测试！**

- ✅ 后端服务运行正常 (Spring Boot + H2数据库)
- ✅ 前端测试页面完成 (HTML + JavaScript)
- ✅ 所有API接口测试通过
- ✅ 前后端通信稳定，CORS配置完成
- ✅ 核心功能验证完成：命理计算、AI分析、性能监控

## 1. 项目概述

### 1.1 项目背景
基于微信小程序平台的八字命理分析工具，结合传统命理学和现代AI技术，为用户提供专业的八字命理分析和AI推荐姓名服务。

### 1.2 技术栈选型
- **前端**: UniApp + Vue3 + TypeScript (设计) / HTML + JavaScript (测试页面)
- **后端**: Spring Boot + MyBatis-Plus + H2数据库 (已部署)
- **AI服务**: DeepSeek API (支持模拟模式)
- **部署**: 本地开发环境 (Docker + Nginx + 阿里云为生产环境设计)

## 2. 系统架构设计

### 2.1 整体架构图
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   微信小程序     │    │   Java后端服务   │    │   DeepSeek API  │
│   (UniApp)      │◄──►│  (Spring Boot)  │◄──►│                │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   微信开放平台   │    │   MySQL数据库   │    │   第三方服务     │
│                │    │                │    │   (支付/短信)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 2.2 技术架构分层
```
┌─────────────────────────────────────────────────────────────┐
│                    表现层 (Presentation Layer)               │
│  UniApp + Vue3 + TypeScript + Vant Weapp UI组件库           │
├─────────────────────────────────────────────────────────────┤
│                    网关层 (Gateway Layer)                   │
│  Nginx反向代理 + SSL证书 + 跨域处理                          │
├─────────────────────────────────────────────────────────────┤
│                    业务层 (Business Layer)                  │
│  Spring Boot + Spring Security + Spring Validation          │
├─────────────────────────────────────────────────────────────┤
│                    服务层 (Service Layer)                   │
│  命理计算服务 + AI推荐服务 + 用户管理服务 + 支付服务          │
├─────────────────────────────────────────────────────────────┤
│                    数据层 (Data Layer)                      │
│  MyBatis-Plus + MySQL + Redis缓存                          │
├─────────────────────────────────────────────────────────────┤
│                    基础设施层 (Infrastructure Layer)         │
│  Docker + 阿里云ECS + 阿里云RDS + 阿里云OSS                  │
└─────────────────────────────────────────────────────────────┘
```

## 3. 前端架构设计

### 3.1 UniApp项目结构
```
src/
├── pages/                    # 页面目录
│   ├── index/               # 首页
│   │   ├── index.vue
│   │   └── index.scss
│   ├── input/               # 信息输入页
│   │   ├── input.vue
│   │   └── input.scss
│   ├── result/              # 结果页
│   │   ├── result.vue
│   │   └── result.scss
│   └── vip/                 # VIP页面
│       ├── vip.vue
│       └── vip.scss
├── components/              # 组件目录
│   ├── common/              # 通用组件
│   ├── business/            # 业务组件
│   └── ui/                  # UI组件
├── api/                     # API接口
│   ├── fortune.ts           # 命理相关接口
│   ├── user.ts              # 用户相关接口
│   └── payment.ts           # 支付相关接口
├── store/                   # 状态管理
│   ├── modules/
│   │   ├── user.ts
│   │   └── fortune.ts
│   └── index.ts
├── utils/                   # 工具函数
│   ├── request.ts           # 网络请求封装
│   ├── storage.ts           # 本地存储
│   ├── date.ts              # 日期处理
│   └── validation.ts        # 表单验证
├── styles/                  # 样式文件
│   ├── common.scss          # 通用样式
│   ├── variables.scss       # 变量定义
│   └── mixins.scss          # 混入样式
└── static/                  # 静态资源
    ├── images/
    └── fonts/
```

### 3.2 核心技术规范

#### 3.2.1 代码规范
- 遵循Vue3 Composition API规范
- 使用TypeScript进行类型约束
- 采用ESLint + Prettier进行代码格式化
- 组件命名采用PascalCase，文件命名采用kebab-case

#### 3.2.2 状态管理
```typescript
// store/modules/fortune.ts
import { defineStore } from 'pinia'

export const useFortuneStore = defineStore('fortune', {
  state: () => ({
    birthInfo: {
      date: '',
      time: '',
      name: ''
    },
    result: {
      lunar: '',
      ganzhi: '',
      wuxing: '',
      shengxiao: '',
      aiAnalysis: '',
      nameRecommendations: []
    },
    isVip: false
  }),
  
  actions: {
    async calculateFortune(birthInfo: BirthInfo) {
      const response = await fortuneApi.calculate(birthInfo)
      this.result = response.data
    }
  }
})
```

#### 3.2.3 网络请求封装
```typescript
// utils/request.ts
import { RequestConfig } from '@/types/request'

class Request {
  private baseURL = 'https://api.yourdomain.com'
  
  async request<T>(config: RequestConfig): Promise<ApiResponse<T>> {
    return new Promise((resolve, reject) => {
      uni.request({
        url: this.baseURL + config.url,
        method: config.method || 'GET',
        data: config.data,
        header: {
          'Content-Type': 'application/json',
          'Authorization': uni.getStorageSync('token') || ''
        },
        success: (res) => {
          if (res.statusCode === 200) {
            resolve(res.data as ApiResponse<T>)
          } else {
            reject(new Error(`请求失败: ${res.statusCode}`))
          }
        },
        fail: reject
      })
    })
  }
}

export const request = new Request()
```

## 4. 后端架构设计（DDD领域驱动设计）

### 4.1 DDD分层架构
```
┌─────────────────────────────────────────────────────────────┐
│                    用户接口层 (User Interface)               │
│  Controller + DTO + Assembler + 异常处理                    │
├─────────────────────────────────────────────────────────────┤
│                    应用服务层 (Application)                  │
│  ApplicationService + Command + Query + Event               │
├─────────────────────────────────────────────────────────────┤
│                    领域层 (Domain)                          │
│  Entity + ValueObject + DomainService + Repository接口      │
├─────────────────────────────────────────────────────────────┤
│                    基础设施层 (Infrastructure)               │
│  Repository实现 + 外部服务 + 配置 + 工具类                   │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 DDD项目结构
```
src/main/java/com/fortune/
├── FortuneMiniAppApplication.java           # 启动类
├── interfaces/                             # 用户接口层
│   ├── web/                               # Web控制器
│   │   ├── FortuneController.java         # 命理计算控制器
│   │   ├── UserController.java            # 用户管理控制器
│   │   └── PaymentController.java         # 支付控制器
│   ├── dto/                               # 数据传输对象
│   │   ├── request/
│   │   │   ├── FortuneCalculateRequest.java
│   │   │   ├── UserLoginRequest.java
│   │   │   └── NameRecommendRequest.java
│   │   └── response/
│   │       ├── FortuneCalculateResponse.java
│   │       ├── UserInfoResponse.java
│   │       └── ApiResponse.java
│   ├── assembler/                         # 对象转换器
│   │   ├── FortuneAssembler.java
│   │   ├── UserAssembler.java
│   │   └── PaymentAssembler.java
│   └── exception/                         # 异常处理
│       ├── GlobalExceptionHandler.java
│       └── BusinessExceptionHandler.java
├── application/                            # 应用服务层
│   ├── service/                           # 应用服务
│   │   ├── FortuneApplicationService.java
│   │   ├── UserApplicationService.java
│   │   └── PaymentApplicationService.java
│   ├── command/                           # 命令对象
│   │   ├── CalculateFortuneCommand.java
│   │   ├── RecommendNameCommand.java
│   │   └── CreateUserCommand.java
│   ├── query/                             # 查询对象
│   │   ├── FortuneRecordQuery.java
│   │   └── UserInfoQuery.java
│   └── event/                             # 领域事件
│       ├── FortuneCalculatedEvent.java
│       ├── VipUpgradedEvent.java
│       └── PaymentCompletedEvent.java
├── domain/                                 # 领域层
│   ├── fortune/                           # 命理聚合
│   │   ├── entity/
│   │   │   ├── FortuneRecord.java         # 命理记录实体
│   │   │   └── NameRecommendation.java    # 姓名推荐实体
│   │   ├── valueobject/
│   │   │   ├── BirthInfo.java             # 出生信息值对象
│   │   │   ├── LunarDate.java             # 农历日期值对象
│   │   │   ├── GanZhi.java                # 天干地支值对象
│   │   │   ├── WuXingAnalysis.java        # 五行分析值对象
│   │   │   └── ShengXiao.java             # 生肖值对象
│   │   ├── service/
│   │   │   ├── FortuneCalculationService.java  # 命理计算领域服务
│   │   │   └── NameRecommendationService.java  # 姓名推荐领域服务
│   │   └── repository/
│   │       └── FortuneRecordRepository.java     # 命理记录仓储接口
│   ├── user/                              # 用户聚合
│   │   ├── entity/
│   │   │   └── User.java                  # 用户实体
│   │   ├── valueobject/
│   │   │   ├── UserId.java                # 用户ID值对象
│   │   │   ├── WechatInfo.java            # 微信信息值对象
│   │   │   └── VipInfo.java               # VIP信息值对象
│   │   ├── service/
│   │   │   └── UserDomainService.java     # 用户领域服务
│   │   └── repository/
│   │       └── UserRepository.java        # 用户仓储接口
│   ├── payment/                           # 支付聚合
│   │   ├── entity/
│   │   │   └── PaymentRecord.java         # 支付记录实体
│   │   ├── valueobject/
│   │   │   ├── OrderNo.java               # 订单号值对象
│   │   │   ├── Amount.java                # 金额值对象
│   │   │   └── ProductType.java           # 产品类型值对象
│   │   ├── service/
│   │   │   └── PaymentDomainService.java  # 支付领域服务
│   │   └── repository/
│   │       └── PaymentRecordRepository.java    # 支付记录仓储接口
│   └── shared/                            # 共享内核
│       ├── valueobject/
│       │   ├── BaseId.java                # 基础ID值对象
│       │   └── Money.java                 # 金钱值对象
│       └── exception/
│           ├── DomainException.java       # 领域异常
│           └── BusinessException.java     # 业务异常
├── infrastructure/                         # 基础设施层
│   ├── repository/                        # 仓储实现
│   │   ├── FortuneRecordRepositoryImpl.java
│   │   ├── UserRepositoryImpl.java
│   │   └── PaymentRecordRepositoryImpl.java
│   ├── external/                          # 外部服务
│   │   ├── DeepSeekApiService.java        # DeepSeek API服务
│   │   ├── WechatApiService.java          # 微信API服务
│   │   └── PaymentApiService.java         # 支付API服务
│   ├── persistence/                       # 持久化
│   │   ├── mapper/
│   │   │   ├── FortuneRecordMapper.java
│   │   │   ├── UserMapper.java
│   │   │   └── PaymentRecordMapper.java
│   │   └── po/                            # 持久化对象
│   │       ├── FortuneRecordPO.java
│   │       ├── UserPO.java
│   │       └── PaymentRecordPO.java
│   ├── config/                            # 配置类
│   │   ├── WebConfig.java
│   │   ├── SecurityConfig.java
│   │   ├── SwaggerConfig.java
│   │   └── DatabaseConfig.java
│   └── utils/                             # 工具类
│       ├── DateUtils.java
│       ├── FortuneUtils.java
│       ├── HttpUtils.java
│       └── JsonUtils.java
└── shared/                                 # 共享模块
    ├── constant/                          # 常量定义
    │   ├── FortuneConstants.java
    │   └── SystemConstants.java
    └── enums/                             # 枚举定义
        ├── ProductTypeEnum.java
        ├── PaymentStatusEnum.java
        └── VipTypeEnum.java
```

### 4.2 核心代码实现

#### 4.2.1 命理计算控制器
```java
@RestController
@RequestMapping("/api/fortune")
@Validated
@Slf4j
public class FortuneController {
    
    @Autowired
    private FortuneService fortuneService;
    
    @PostMapping("/calculate")
    @ApiOperation("计算命理信息")
    public ApiResponse<FortuneCalculateResponse> calculate(
            @Valid @RequestBody FortuneCalculateRequest request) {
        
        log.info("开始计算命理信息，请求参数：{}", request);
        
        FortuneCalculateResponse response = fortuneService.calculateFortune(request);
        
        return ApiResponse.success(response);
    }
    
    @PostMapping("/recommend-names")
    @ApiOperation("AI推荐姓名")
    public ApiResponse<List<NameRecommendation>> recommendNames(
            @Valid @RequestBody NameRecommendRequest request) {
        
        // 检查用户VIP状态
        if (!userService.isVipUser(request.getUserId())) {
            throw new BusinessException("请开通VIP会员后使用此功能");
        }
        
        List<NameRecommendation> recommendations = 
            fortuneService.recommendNames(request);
        
        return ApiResponse.success(recommendations);
    }
}
```

#### 4.2.2 命理计算服务
```java
@Service
@Slf4j
public class FortuneService {
    
    @Autowired
    private DeepSeekService deepSeekService;
    
    @Autowired
    private FortuneRecordMapper fortuneRecordMapper;
    
    public FortuneCalculateResponse calculateFortune(FortuneCalculateRequest request) {
        
        // 1. 阳历转农历
        LunarDate lunarDate = DateUtils.solarToLunar(request.getBirthDate());
        
        // 2. 计算天干地支
        GanZhi ganZhi = FortuneUtils.calculateGanZhi(
            request.getBirthDate(), request.getBirthTime());
        
        // 3. 分析五行
        WuXingAnalysis wuXingAnalysis = FortuneUtils.analyzeWuXing(ganZhi);
        
        // 4. 确定生肖
        String shengXiao = FortuneUtils.getShengXiao(lunarDate.getYear());
        
        // 5. 调用DeepSeek API生成AI解读
        String aiAnalysis = deepSeekService.generateFortuneAnalysis(
            ganZhi, wuXingAnalysis, shengXiao);
        
        // 6. 保存计算记录
        FortuneRecord record = new FortuneRecord();
        record.setUserId(request.getUserId());
        record.setBirthDate(request.getBirthDate());
        record.setBirthTime(request.getBirthTime());
        record.setResult(JSON.toJSONString(response));
        record.setCreateTime(new Date());
        fortuneRecordMapper.insert(record);
        
        // 7. 构建响应
        return FortuneCalculateResponse.builder()
            .lunar(lunarDate.toString())
            .ganZhi(ganZhi.toString())
            .wuXing(wuXingAnalysis.getElements())
            .wuXingLack(wuXingAnalysis.getLackElements())
            .shengXiao(shengXiao)
            .aiAnalysis(aiAnalysis)
            .build();
    }
    
    public List<NameRecommendation> recommendNames(NameRecommendRequest request) {
        
        // 调用DeepSeek API推荐姓名
        String prompt = buildNameRecommendPrompt(request);
        String aiResponse = deepSeekService.callApi(prompt);
        
        // 解析AI响应
        return parseNameRecommendations(aiResponse);
    }
}
```

#### 4.2.3 DeepSeek API服务
```java
@Service
@Slf4j
public class DeepSeekService {
    
    @Value("${deepseek.api.url}")
    private String apiUrl;
    
    @Value("${deepseek.api.key}")
    private String apiKey;
    
    @Autowired
    private RestTemplate restTemplate;
    
    public String generateFortuneAnalysis(GanZhi ganZhi, WuXingAnalysis wuXing, String shengXiao) {
        
        String prompt = String.format(
            "请根据以下八字信息进行命理分析：\n" +
            "天干地支：%s\n" +
            "五行分析：%s\n" +
            "五行缺失：%s\n" +
            "生肖：%s\n" +
            "请提供专业的命理解读，包括性格特点、事业建议、健康提醒等，字数控制在200字以内。",
            ganZhi.toString(),
            wuXing.getElements(),
            wuXing.getLackElements(),
            shengXiao
        );
        
        return callApi(prompt);
    }
    
    public String callApi(String prompt) {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(apiKey);
            
            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("model", "deepseek-chat");
            requestBody.put("messages", Arrays.asList(
                Map.of("role", "user", "content", prompt)
            ));
            requestBody.put("max_tokens", 500);
            requestBody.put("temperature", 0.7);
            
            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);
            
            ResponseEntity<Map> response = restTemplate.postForEntity(apiUrl, entity, Map.class);
            
            if (response.getStatusCode() == HttpStatus.OK) {
                Map<String, Object> responseBody = response.getBody();
                List<Map<String, Object>> choices = (List<Map<String, Object>>) responseBody.get("choices");
                Map<String, Object> message = (Map<String, Object>) choices.get(0).get("message");
                return (String) message.get("content");
            }
            
            throw new BusinessException("DeepSeek API调用失败");
            
        } catch (Exception e) {
            log.error("调用DeepSeek API异常", e);
            throw new BusinessException("AI分析服务暂时不可用，请稍后重试");
        }
    }
}
```

## 5. 数据库设计

### 5.1 数据库表结构

#### 5.1.1 用户表 (t_user)
```sql
CREATE TABLE `t_user` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  `openid` varchar(64) NOT NULL COMMENT '微信openid',
  `nickname` varchar(64) DEFAULT NULL COMMENT '昵称',
  `avatar_url` varchar(255) DEFAULT NULL COMMENT '头像URL',
  `phone` varchar(20) DEFAULT NULL COMMENT '手机号',
  `is_vip` tinyint(1) DEFAULT '0' COMMENT '是否VIP用户',
  `vip_expire_time` datetime DEFAULT NULL COMMENT 'VIP过期时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_openid` (`openid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';
```

#### 5.1.2 命理记录表 (t_fortune_record)
```sql
CREATE TABLE `t_fortune_record` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '记录ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `birth_date` date NOT NULL COMMENT '出生日期',
  `birth_time` varchar(10) NOT NULL COMMENT '出生时辰',
  `user_name` varchar(50) DEFAULT NULL COMMENT '用户姓名',
  `lunar_date` varchar(50) NOT NULL COMMENT '农历日期',
  `gan_zhi` varchar(50) NOT NULL COMMENT '天干地支',
  `wu_xing` varchar(100) NOT NULL COMMENT '五行属性',
  `wu_xing_lack` varchar(50) DEFAULT NULL COMMENT '五行缺失',
  `sheng_xiao` varchar(10) NOT NULL COMMENT '生肖',
  `ai_analysis` text COMMENT 'AI分析结果',
  `name_recommendations` json DEFAULT NULL COMMENT 'AI推荐姓名',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='命理记录表';
```

#### 5.1.3 支付记录表 (t_payment_record)
```sql
CREATE TABLE `t_payment_record` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '支付记录ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `order_no` varchar(64) NOT NULL COMMENT '订单号',
  `product_type` varchar(20) NOT NULL COMMENT '产品类型(MONTHLY/YEARLY/SINGLE)',
  `amount` decimal(10,2) NOT NULL COMMENT '支付金额',
  `status` varchar(20) NOT NULL COMMENT '支付状态',
  `wx_transaction_id` varchar(64) DEFAULT NULL COMMENT '微信交易号',
  `pay_time` datetime DEFAULT NULL COMMENT '支付时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_order_no` (`order_no`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='支付记录表';
```

## 6. API接口设计

### 6.1 RESTful API规范

#### 6.1.1 统一响应格式
```json
{
  "code": 200,
  "message": "success",
  "data": {},
  "timestamp": 1640995200000
}
```

#### 6.1.2 核心接口定义

**1. 命理计算接口**
```
POST /api/fortune/calculate
Content-Type: application/json

Request:
{
  "birthDate": "2000-01-01",
  "birthTime": "未时",
  "userName": "张三",
  "userId": 123456
}

Response:
{
  "code": 200,
  "message": "success",
  "data": {
    "lunar": "1999年腊月廿五",
    "ganZhi": "己卯年 丁丑月 甲子日 未时",
    "wuXing": "木木火土",
    "wuXingLack": "金、水",
    "shengXiao": "兔",
    "aiAnalysis": "您的八字五行偏木火...",
    "nameAnalysis": "姓名张三五行属火..."
  }
}
```

**2. AI推荐姓名接口**
```
POST /api/fortune/recommend-names
Content-Type: application/json

Request:
{
  "userId": 123456,
  "wuXingLack": "金、水",
  "ganZhi": "己卯年 丁丑月 甲子日 未时"
}

Response:
{
  "code": 200,
  "message": "success",
  "data": [
    {
      "name": "李泽润",
      "reason": "水木组合，弥补缺水，寓意润泽万物"
    },
    {
      "name": "王金瑞",
      "reason": "金金组合，补足缺金，寓意吉祥如意"
    },
    {
      "name": "张水清",
      "reason": "水水组合，强化水元素，寓意清澈纯净"
    }
  ]
}
```

**3. 用户登录接口**
```
POST /api/user/login
Content-Type: application/json

Request:
{
  "code": "wx_login_code",
  "userInfo": {
    "nickName": "用户昵称",
    "avatarUrl": "头像URL"
  }
}

Response:
{
  "code": 200,
  "message": "success",
  "data": {
    "token": "jwt_token_string",
    "userInfo": {
      "id": 123456,
      "nickname": "用户昵称",
      "avatarUrl": "头像URL",
      "isVip": false,
      "vipExpireTime": null
    }
  }
}
```

## 7. 部署架构

### 7.1 服务器架构
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Nginx反向代理  │    │   Spring Boot   │    │   MySQL主库     │
│   (负载均衡)     │◄──►│   应用服务器     │◄──►│                │
│   SSL终端       │    │   (多实例)       │    │                │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   CDN加速       │    │   Redis缓存     │    │   MySQL从库     │
│                │    │                │    │   (读写分离)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 7.2 Docker部署配置

#### 7.2.1 Dockerfile
```dockerfile
FROM openjdk:11-jre-slim

WORKDIR /app

COPY target/fortune-mini-app-1.0.0.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
```

#### 7.2.2 docker-compose.yml
```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      - SPRING_PROFILES_ACTIVE=prod
      - MYSQL_HOST=mysql
      - REDIS_HOST=redis
    depends_on:
      - mysql
      - redis
    networks:
      - fortune-network

  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: your_password
      MYSQL_DATABASE: fortune_db
    volumes:
      - mysql_data:/var/lib/mysql
    networks:
      - fortune-network

  redis:
    image: redis:6.2-alpine
    networks:
      - fortune-network

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - app
    networks:
      - fortune-network

volumes:
  mysql_data:

networks:
  fortune-network:
    driver: bridge
```

## 8. 安全设计

### 8.1 数据安全
- 用户敏感信息加密存储
- API接口采用HTTPS协议
- 数据库连接加密
- 定期数据备份

### 8.2 接口安全
- JWT Token认证
- 接口限流防刷
- 参数校验防注入
- 敏感操作日志记录

### 8.3 微信小程序安全
- 服务器域名白名单
- 用户授权信息验证
- 支付安全校验

## 9. 性能优化

### 9.1 缓存策略
- Redis缓存热点数据
- 命理计算结果缓存
- 用户会话信息缓存
- API响应结果缓存

### 9.2 数据库优化
- 读写分离
- 索引优化
- 分页查询
- 连接池配置

### 9.3 前端优化
- 图片懒加载
- 组件按需加载
- 本地存储优化
- 网络请求优化

## 10. 监控运维

### 10.1 应用监控
- Spring Boot Actuator健康检查
- 自定义业务指标监控
- 异常告警机制
- 性能指标收集

### 10.2 日志管理
- 结构化日志输出
- 日志分级管理
- 日志文件轮转
- 集中日志收集

### 10.3 备份策略
- 数据库定时备份
- 应用配置备份
- 静态资源备份
- 灾难恢复预案

## 11. 开发规范

### 11.1 代码规范
- 阿里巴巴Java开发手册
- 统一代码格式化配置
- 代码审查流程
- 单元测试覆盖率要求

### 11.2 Git工作流
- 功能分支开发
- 代码合并审查
- 版本标签管理
- 自动化部署流程

### 11.3 文档规范
- API文档自动生成
- 数据库变更记录
- 部署文档维护
- 故障处理手册

## 12. 项目计划

### 12.1 开发阶段
- **第一阶段(2周)**: 基础架构搭建、核心接口开发
- **第二阶段(3周)**: 前端页面开发、接口联调
- **第三阶段(1周)**: 支付功能、VIP体系开发
- **第四阶段(1周)**: 测试优化、部署上线

### 12.2 里程碑
- Week 2: 后端核心功能完成
- Week 4: 前端基础功能完成
- Week 6: 完整功能联调完成
- Week 7: 生产环境部署完成

这份架构设计文档为AI八卦运势小程序提供了完整的技术实现方案，涵盖了从前端到后端、从开发到部署的全流程设计，确保项目能够高质量、高效率地完成开发和上线。 
-- 八卦AI项目完整数据库初始化脚本
-- 执行时间: 2025-06-03
-- 数据库: MySQL 8.0+
-- 表名规范: 统一使用t_前缀

-- 创建数据库
CREATE DATABASE IF NOT EXISTS `fortune_db` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE `fortune_db`;

-- ===========================================
-- 核心业务表
-- ===========================================

-- 用户表
CREATE TABLE IF NOT EXISTS `t_users` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '用户ID',
    `openid` VARCHAR(100) UNIQUE NOT NULL COMMENT '微信openid',
    `nickname` VARCHAR(50) COMMENT '昵称',
    `avatar_url` VARCHAR(255) COMMENT '头像URL',
    `phone` VARCHAR(20) COMMENT '手机号',
    `vip_level` INT DEFAULT 0 COMMENT 'VIP等级：0-普通用户，1-月度VIP，2-年度VIP',
    `vip_expire_time` DATETIME COMMENT 'VIP过期时间',
    `created_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted` TINYINT DEFAULT 0 COMMENT '删除标记：0-未删除，1-已删除',
    INDEX idx_openid (openid),
    INDEX idx_created_time (created_time),
    INDEX idx_vip_level (vip_level)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- 命理记录表
CREATE TABLE IF NOT EXISTS `t_fortune_record` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '记录ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `name` VARCHAR(50) NOT NULL COMMENT '姓名',
    `gender` TINYINT NOT NULL COMMENT '性别：1-男，2-女',
    `birth_year` INT NOT NULL COMMENT '出生年',
    `birth_month` INT NOT NULL COMMENT '出生月',
    `birth_day` INT NOT NULL COMMENT '出生日',
    `birth_hour` INT COMMENT '出生时辰',
    `lunar_year` INT COMMENT '农历年',
    `lunar_month` INT COMMENT '农历月',
    `lunar_day` INT COMMENT '农历日',
    `gan_zhi` VARCHAR(20) COMMENT '干支',
    `sheng_xiao` VARCHAR(10) COMMENT '生肖',
    `wu_xing_analysis` TEXT COMMENT '五行分析',
    `ai_analysis` TEXT COMMENT 'AI分析结果',
    `name_analysis` TEXT COMMENT '姓名分析结果',
    `name_recommendations` JSON COMMENT 'AI推荐姓名',
    `created_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted` TINYINT DEFAULT 0 COMMENT '删除标记：0-未删除，1-已删除',
    INDEX idx_user_id (user_id),
    INDEX idx_created_time (created_time),
    INDEX idx_birth_date (birth_year, birth_month, birth_day),
    INDEX idx_user_time (user_id, created_time DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='命理记录表';

-- 姓名推荐表
CREATE TABLE IF NOT EXISTS `t_name_recommendations` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '推荐ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `surname` VARCHAR(20) NOT NULL COMMENT '姓氏',
    `gender` TINYINT NOT NULL COMMENT '性别：1-男，2-女',
    `birth_info` TEXT COMMENT '出生信息JSON',
    `recommended_names` JSON COMMENT '推荐姓名列表',
    `ai_explanation` TEXT COMMENT 'AI解释',
    `created_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted` TINYINT DEFAULT 0 COMMENT '删除标记：0-未删除，1-已删除',
    INDEX idx_user_id (user_id),
    INDEX idx_surname (surname),
    INDEX idx_created_time (created_time),
    INDEX idx_user_time (user_id, created_time DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='姓名推荐表';

-- ===========================================
-- VIP与订单表
-- ===========================================

-- VIP订单表
CREATE TABLE IF NOT EXISTS `t_vip_orders` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '订单ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `order_no` VARCHAR(64) UNIQUE NOT NULL COMMENT '订单号',
    `plan_type` VARCHAR(20) NOT NULL COMMENT '套餐类型(MONTHLY/YEARLY)',
    `amount` DECIMAL(10,2) NOT NULL COMMENT '订单金额',
    `status` VARCHAR(20) NOT NULL DEFAULT 'pending' COMMENT '订单状态',
    `payment_method` VARCHAR(20) COMMENT '支付方式',
    `transaction_id` VARCHAR(64) COMMENT '交易ID',
    `expire_time` DATETIME COMMENT '过期时间',
    `created_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted` TINYINT DEFAULT 0 COMMENT '删除标记',
    INDEX idx_user_id (user_id),
    INDEX idx_order_no (order_no),
    INDEX idx_status (status),
    INDEX idx_created_time (created_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='VIP订单表';

-- 支付记录表
CREATE TABLE IF NOT EXISTS `t_payment_record` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '支付记录ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `order_no` VARCHAR(64) NOT NULL COMMENT '订单号',
    `product_type` VARCHAR(20) NOT NULL COMMENT '产品类型(MONTHLY/YEARLY/SINGLE)',
    `amount` DECIMAL(10,2) NOT NULL COMMENT '支付金额',
    `status` VARCHAR(20) NOT NULL COMMENT '支付状态',
    `wx_transaction_id` VARCHAR(64) DEFAULT NULL COMMENT '微信交易号',
    `pay_time` DATETIME DEFAULT NULL COMMENT '支付时间',
    `created_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted` TINYINT DEFAULT 0 COMMENT '是否删除',
    UNIQUE KEY uk_order_no (order_no),
    KEY idx_user_id (user_id),
    KEY idx_status (status),
    KEY idx_created_time (created_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='支付记录表';

-- ===========================================
-- 系统日志表
-- ===========================================

-- 用户操作日志表
CREATE TABLE IF NOT EXISTS `t_user_logs` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '日志ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `action` VARCHAR(50) NOT NULL COMMENT '操作类型',
    `details` TEXT COMMENT '操作详情',
    `ip_address` VARCHAR(45) COMMENT 'IP地址',
    `user_agent` VARCHAR(500) COMMENT '用户代理',
    `created_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    INDEX idx_user_id (user_id),
    INDEX idx_action (action),
    INDEX idx_created_time (created_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户操作日志表';

-- API调用日志表
CREATE TABLE IF NOT EXISTS `t_api_logs` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '日志ID',
    `user_id` BIGINT COMMENT '用户ID',
    `api_path` VARCHAR(200) NOT NULL COMMENT 'API路径',
    `method` VARCHAR(10) NOT NULL COMMENT '请求方法',
    `request_params` TEXT COMMENT '请求参数',
    `response_code` INT COMMENT '响应状态码',
    `response_time` INT COMMENT '响应时间(毫秒)',
    `ip_address` VARCHAR(45) COMMENT 'IP地址',
    `created_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    INDEX idx_user_id (user_id),
    INDEX idx_api_path (api_path),
    INDEX idx_created_time (created_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='API调用日志表';

-- ===========================================
-- 插入测试数据
-- ===========================================

-- 插入测试用户
INSERT IGNORE INTO `t_users` (`openid`, `nickname`, `avatar_url`, `vip_level`) VALUES 
('test_openid_001', '测试用户1', 'https://example.com/avatar1.jpg', 0),
('test_openid_002', '测试用户2', 'https://example.com/avatar2.jpg', 1),
('test_openid_003', '测试用户3', 'https://example.com/avatar3.jpg', 2);

-- 插入测试命理记录（注意字段名顺序）
INSERT IGNORE INTO `t_fortune_record` (`user_id`, `name`, `gender`, `birth_year`, `birth_month`, `birth_day`, `birth_hour`, `gan_zhi`, `sheng_xiao`, `wu_xing_analysis`, `ai_analysis`) VALUES 
(1, '张三', 1, 1990, 5, 15, 10, '庚午年 辛巳月 甲子日 己巳时', '马', '五行分析：金木水火土均衡', 'AI分析：命格较好，事业运佳'),
(2, '李四', 2, 1995, 8, 20, 14, '乙亥年 甲申月 丁卯日 丁未时', '猪', '五行分析：木火较旺，土金稍弱', 'AI分析：性格开朗，财运不错'),
(3, '王五', 1, 1988, 12, 3, 8, '戊辰年 甲子月 庚申日 庚辰时', '龙', '五行分析：金土较强，木火稍弱', 'AI分析：稳重踏实，适合从商');

-- 插入测试姓名推荐记录
INSERT IGNORE INTO `t_name_recommendations` (`user_id`, `surname`, `gender`, `birth_info`, `recommended_names`, `ai_explanation`) VALUES 
(1, '张', 1, '{"birthYear":1990,"birthMonth":5,"birthDay":15}', '["张志远","张浩然","张明轩"]', '基于五行平衡推荐的优质姓名'),
(2, '李', 2, '{"birthYear":1995,"birthMonth":8,"birthDay":20}', '["李雅琪","李思涵","李欣怡"]', '符合女性特质的优雅姓名'),
(3, '王', 1, '{"birthYear":1988,"birthMonth":12,"birthDay":3}', '["王建华","王国强","王志成"]', '体现男性阳刚之气的名字');

-- 插入测试VIP订单
INSERT IGNORE INTO `t_vip_orders` (`user_id`, `order_no`, `plan_type`, `amount`, `status`, `expire_time`) VALUES 
(2, 'VIP202501001', 'MONTHLY', 19.90, 'paid', DATE_ADD(NOW(), INTERVAL 1 MONTH)),
(3, 'VIP202501002', 'YEARLY', 198.00, 'paid', DATE_ADD(NOW(), INTERVAL 1 YEAR));

-- 插入测试支付记录
INSERT IGNORE INTO `t_payment_record` (`user_id`, `order_no`, `product_type`, `amount`, `status`, `wx_transaction_id`, `pay_time`) VALUES 
(2, 'VIP202501001', 'MONTHLY', 19.90, 'success', 'wx_trans_001', NOW()),
(3, 'VIP202501002', 'YEARLY', 198.00, 'success', 'wx_trans_002', NOW());

-- ===========================================
-- 创建性能优化索引
-- ===========================================

-- 复合索引优化查询
CREATE INDEX idx_t_fortune_record_composite ON t_fortune_record(user_id, created_time DESC);
CREATE INDEX idx_t_name_recommendations_composite ON t_name_recommendations(user_id, created_time DESC);
CREATE INDEX idx_t_vip_orders_user_status ON t_vip_orders(user_id, status);
CREATE INDEX idx_t_payment_record_user_status ON t_payment_record(user_id, status);

-- ===========================================
-- 创建外键约束
-- ===========================================

-- 添加外键约束（可选，根据需求启用）
-- ALTER TABLE t_fortune_record ADD CONSTRAINT fk_fortune_user FOREIGN KEY (user_id) REFERENCES t_users(id);
-- ALTER TABLE t_name_recommendations ADD CONSTRAINT fk_name_user FOREIGN KEY (user_id) REFERENCES t_users(id);
-- ALTER TABLE t_vip_orders ADD CONSTRAINT fk_vip_user FOREIGN KEY (user_id) REFERENCES t_users(id);
-- ALTER TABLE t_payment_record ADD CONSTRAINT fk_payment_user FOREIGN KEY (user_id) REFERENCES t_users(id);

-- ===========================================
-- 显示创建结果
-- ===========================================

-- 显示所有表
SHOW TABLES;

-- 显示表结构
DESCRIBE t_users;
DESCRIBE t_fortune_record;
DESCRIBE t_name_recommendations;
DESCRIBE t_vip_orders;
DESCRIBE t_payment_record;

SELECT '数据库初始化完成！所有表均使用t_前缀，结构统一，数据完整。' AS message; 
-- 八卦AI项目完整数据库初始化脚本
-- 执行时间: 2025-06-03
-- 数据库: MySQL 8.0+

-- 创建数据库
CREATE DATABASE IF NOT EXISTS `fortune_db` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE `fortune_db`;

-- 用户表
CREATE TABLE IF NOT EXISTS `t_users` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '用户ID',
    `openid` VARCHAR(100) UNIQUE NOT NULL COMMENT '微信openid',
    `nickname` VARCHAR(50) COMMENT '昵称',
    `avatar_url` VARCHAR(255) COMMENT '头像URL',
    `vip_level` INT DEFAULT 0 COMMENT 'VIP等级：0-普通用户，1-月度VIP，2-年度VIP',
    `vip_expire_time` DATETIME COMMENT 'VIP过期时间',
    `created_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted` TINYINT DEFAULT 0 COMMENT '删除标记：0-未删除，1-已删除'
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
    `created_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted` TINYINT DEFAULT 0 COMMENT '删除标记：0-未删除，1-已删除',
    INDEX idx_user_id (user_id),
    INDEX idx_created_time (created_time),
    INDEX idx_birth_date (birth_year, birth_month, birth_day)
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
    INDEX idx_created_time (created_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='姓名推荐表';

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
    `updated_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted` TINYINT DEFAULT 0 COMMENT '删除标记',
    INDEX idx_user_id (user_id),
    INDEX idx_order_no (order_no),
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
    UNIQUE KEY `uk_order_no` (`order_no`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_created_time` (`created_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='支付记录表';

-- 插入测试数据
INSERT IGNORE INTO `t_users` (`openid`, `nickname`, `vip_level`) VALUES 
('test_openid_001', '测试用户1', 0),
('test_openid_002', '测试用户2', 1),
('test_openid_003', '测试用户3', 2);

-- 插入测试命理记录
INSERT IGNORE INTO `t_fortune_record` (`user_id`, `name`, `gender`, `birth_year`, `birth_month`, `birth_day`, `birth_hour`, `gan_zhi`, `sheng_xiao`, `wu_xing_analysis`, `ai_analysis`) VALUES 
(1, '张三', 1, 1990, 5, 15, 10, '庚午年 辛巳月 甲子日 己巳时', '马', '五行分析：金木水火土均衡', 'AI分析：命格较好，事业运佳'),
(2, '李四', 2, 1995, 8, 20, 14, '乙亥年 甲申月 丁卯日 丁未时', '猪', '五行分析：木火较旺，土金稍弱', 'AI分析：性格开朗，财运不错'),
(3, '王五', 1, 1988, 12, 3, 8, '戊辰年 甲子月 庚申日 庚辰时', '龙', '五行分析：金土较强，木火稍弱', 'AI分析：稳重踏实，适合从商');

-- 创建性能优化索引（如果不存在）
-- 使用存储过程安全地创建索引
DELIMITER //
CREATE PROCEDURE CreateIndexIfNotExists()
BEGIN
    DECLARE index_exists INT DEFAULT 0;
    
    -- 检查并创建 t_fortune_record 的复合索引
    SELECT COUNT(*) INTO index_exists 
    FROM information_schema.statistics 
    WHERE table_schema = DATABASE() 
    AND table_name = 't_fortune_record' 
    AND index_name = 'idx_t_fortune_record_composite';
    
    IF index_exists = 0 THEN
        ALTER TABLE t_fortune_record ADD INDEX idx_t_fortune_record_composite (user_id, created_time DESC);
    END IF;
    
    -- 检查并创建 t_name_recommendations 的复合索引
    SELECT COUNT(*) INTO index_exists 
    FROM information_schema.statistics 
    WHERE table_schema = DATABASE() 
    AND table_name = 't_name_recommendations' 
    AND index_name = 'idx_t_name_recommendations_composite';
    
    IF index_exists = 0 THEN
        ALTER TABLE t_name_recommendations ADD INDEX idx_t_name_recommendations_composite (user_id, created_time DESC);
    END IF;
END //
DELIMITER ;

CALL CreateIndexIfNotExists();
DROP PROCEDURE CreateIndexIfNotExists;

-- 显示创建的表
SHOW TABLES;

SELECT '数据库初始化完成！' AS message; 
-- 创建数据库
CREATE DATABASE IF NOT EXISTS `fortune_db` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE `fortune_db`;

-- 用户表
CREATE TABLE `t_users` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  `openid` varchar(100) NOT NULL COMMENT '微信openid',
  `nickname` varchar(50) DEFAULT NULL COMMENT '昵称',
  `avatar_url` varchar(255) DEFAULT NULL COMMENT '头像URL',
  `phone` varchar(20) DEFAULT NULL COMMENT '手机号',
  `vip_level` INT DEFAULT 0 COMMENT 'VIP等级：0-普通用户，1-月度VIP，2-年度VIP',
  `vip_expire_time` datetime DEFAULT NULL COMMENT 'VIP过期时间',
  `created_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint(1) DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_openid` (`openid`),
  KEY `idx_created_time` (`created_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- 命理记录表
CREATE TABLE `t_fortune_record` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '记录ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `name` varchar(50) NOT NULL COMMENT '姓名',
  `gender` tinyint NOT NULL COMMENT '性别：1-男，2-女',
  `birth_year` int NOT NULL COMMENT '出生年',
  `birth_month` int NOT NULL COMMENT '出生月',
  `birth_day` int NOT NULL COMMENT '出生日',
  `birth_hour` int COMMENT '出生时辰',
  `lunar_year` int COMMENT '农历年',
  `lunar_month` int COMMENT '农历月',
  `lunar_day` int COMMENT '农历日',
  `gan_zhi` varchar(20) COMMENT '干支',
  `sheng_xiao` varchar(10) COMMENT '生肖',
  `wu_xing_analysis` TEXT COMMENT '五行分析',
  `ai_analysis` text COMMENT 'AI分析结果',
  `name_analysis` text COMMENT '姓名分析结果',
  `name_recommendations` json DEFAULT NULL COMMENT 'AI推荐姓名',
  `created_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint(1) DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_created_time` (`created_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='命理记录表';

-- 姓名推荐表
CREATE TABLE `t_name_recommendations` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '推荐ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `surname` varchar(20) NOT NULL COMMENT '姓氏',
  `gender` tinyint NOT NULL COMMENT '性别：1-男，2-女',
  `birth_info` text COMMENT '出生信息JSON',
  `recommended_names` json COMMENT '推荐姓名列表',
  `ai_explanation` text COMMENT 'AI解释',
  `created_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint(1) DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_surname` (`surname`),
  KEY `idx_created_time` (`created_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='姓名推荐表';

-- VIP订单表
CREATE TABLE `t_vip_orders` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '订单ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `order_no` varchar(64) NOT NULL COMMENT '订单号',
  `plan_type` varchar(20) NOT NULL COMMENT '套餐类型(MONTHLY/YEARLY)',
  `amount` decimal(10,2) NOT NULL COMMENT '订单金额',
  `status` varchar(20) NOT NULL DEFAULT 'pending' COMMENT '订单状态',
  `payment_method` varchar(20) COMMENT '支付方式',
  `transaction_id` varchar(64) COMMENT '交易ID',
  `expire_time` datetime COMMENT '过期时间',
  `created_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint(1) DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_order_no` (`order_no`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_created_time` (`created_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='VIP订单表';

-- 支付记录表
CREATE TABLE `t_payment_record` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '支付记录ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `order_no` varchar(64) NOT NULL COMMENT '订单号',
  `product_type` varchar(20) NOT NULL COMMENT '产品类型(MONTHLY/YEARLY/SINGLE)',
  `amount` decimal(10,2) NOT NULL COMMENT '支付金额',
  `status` varchar(20) NOT NULL COMMENT '支付状态',
  `wx_transaction_id` varchar(64) DEFAULT NULL COMMENT '微信交易号',
  `pay_time` datetime DEFAULT NULL COMMENT '支付时间',
  `created_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint(1) DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_order_no` (`order_no`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_created_time` (`created_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='支付记录表';

-- 插入测试数据
INSERT INTO `t_users` (`openid`, `nickname`, `avatar_url`, `vip_level`) VALUES
('test_openid_001', '测试用户1', 'https://example.com/avatar1.jpg', 0),
('test_openid_002', '测试用户2', 'https://example.com/avatar2.jpg', 1);

-- 插入测试命理记录
INSERT INTO `t_fortune_record` (
  `user_id`, `name`, `gender`, `birth_year`, `birth_month`, `birth_day`, `birth_hour`,
  `gan_zhi`, `sheng_xiao`, `wu_xing_analysis`, `ai_analysis`, `name_analysis`
) VALUES (
  1, '张三', 1, 2000, 1, 1, 14,
  '己卯年 丁丑月 甲子日 未时', '兔', '木木火土', 
  '您的八字五行偏木火，性格开朗活泼，具有很强的创造力和表达能力。建议在事业上选择与文化、艺术相关的领域。',
  '姓名张三五行属火，与您的八字相配，有助于事业发展。'
); 
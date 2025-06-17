-- =====================================================
-- 八卦AI微信小程序 - 统一数据库初始化脚本
-- 版本: 1.0
-- 创建时间: 2024-01-01
-- 数据库: MySQL 8.0+
-- 说明: 此脚本与Mapper完全匹配，删除了不必要的复杂字段
-- =====================================================

-- 创建数据库
CREATE DATABASE IF NOT EXISTS `fortune_db` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE `fortune_db`;

-- =====================================================
-- 用户表
-- =====================================================
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
  `deleted` tinyint(1) DEFAULT '0' COMMENT '是否删除：0-未删除，1-已删除',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_openid` (`openid`),
  KEY `idx_created_time` (`created_time`),
  KEY `idx_vip_level` (`vip_level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- =====================================================
-- 命理记录表 (与FortuneRecordMapper完全匹配)
-- =====================================================
CREATE TABLE `t_fortune_record` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '记录ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `user_name` varchar(50) NOT NULL COMMENT '用户姓名',
  `birth_date` varchar(20) NOT NULL COMMENT '出生日期 (YYYY-MM-DD)',
  `birth_time` varchar(20) COMMENT '出生时间',
  `lunar_date` varchar(50) COMMENT '农历日期',
  `gan_zhi` varchar(50) COMMENT '干支',
  `wu_xing` varchar(100) COMMENT '五行分析',
  `wu_xing_lack` varchar(50) COMMENT '五行缺失',
  `sheng_xiao` varchar(10) COMMENT '生肖',
  `ai_analysis` text COMMENT 'AI分析结果',
  `name_analysis` text COMMENT '姓名分析结果',
  `name_recommendations` text COMMENT '姓名推荐',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint(1) DEFAULT '0' COMMENT '是否删除：0-未删除，1-已删除',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_create_time` (`create_time`),
  KEY `idx_user_id_create_time` (`user_id`, `create_time` DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='命理记录表';

-- =====================================================
-- VIP订单表 (与VipOrderMapper完全匹配)
-- =====================================================
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
  `deleted` tinyint(1) DEFAULT '0' COMMENT '是否删除：0-未删除，1-已删除',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_order_no` (`order_no`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_created_time` (`created_time`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='VIP订单表';

-- =====================================================
-- 插入测试数据
-- =====================================================

-- 插入测试用户
INSERT INTO `t_users` (`openid`, `nickname`, `avatar_url`, `vip_level`) VALUES
('test_openid_001', '测试用户1', 'https://example.com/avatar1.jpg', 0),
('test_openid_002', '测试用户2', 'https://example.com/avatar2.jpg', 1),
('test_openid_003', 'VIP用户', 'https://example.com/avatar3.jpg', 2);

-- =====================================================
-- 数据库优化
-- =====================================================

-- 创建复合索引优化查询性能
CREATE INDEX `idx_fortune_record_user_time` ON `t_fortune_record`(`user_id`, `create_time` DESC);
CREATE INDEX `idx_vip_orders_user_status` ON `t_vip_orders`(`user_id`, `status`);

-- =====================================================
-- 查看表结构 (用于验证)
-- =====================================================

-- 显示所有表
SHOW TABLES;

-- 显示表结构
-- DESCRIBE t_users;
-- DESCRIBE t_fortune_record;
-- DESCRIBE t_vip_orders;

-- =====================================================
-- 脚本执行完成
-- ===================================================== 
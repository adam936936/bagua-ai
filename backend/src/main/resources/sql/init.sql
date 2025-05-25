-- 创建数据库
CREATE DATABASE IF NOT EXISTS `fortune_db` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE `fortune_db`;

-- 用户表
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
  `deleted` tinyint(1) DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_openid` (`openid`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- 命理记录表
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
  `name_analysis` text COMMENT '姓名分析结果',
  `name_recommendations` json DEFAULT NULL COMMENT 'AI推荐姓名',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint(1) DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='命理记录表';

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
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint(1) DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_order_no` (`order_no`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='支付记录表';

-- 插入测试数据
INSERT INTO `t_user` (`openid`, `nickname`, `avatar_url`, `is_vip`) VALUES
('test_openid_001', '测试用户1', 'https://example.com/avatar1.jpg', 0),
('test_openid_002', '测试用户2', 'https://example.com/avatar2.jpg', 1);

-- 插入测试命理记录
INSERT INTO `t_fortune_record` (
  `user_id`, `birth_date`, `birth_time`, `user_name`, 
  `lunar_date`, `gan_zhi`, `wu_xing`, `wu_xing_lack`, `sheng_xiao`, 
  `ai_analysis`, `name_analysis`
) VALUES (
  1, '2000-01-01', '未时', '张三',
  '1999年腊月廿五', '己卯年 丁丑月 甲子日 未时', '木木火土', '金、水', '兔',
  '您的八字五行偏木火，性格开朗活泼，具有很强的创造力和表达能力。建议在事业上选择与文化、艺术相关的领域。',
  '姓名张三五行属火，与您的八字相配，有助于事业发展。'
); 
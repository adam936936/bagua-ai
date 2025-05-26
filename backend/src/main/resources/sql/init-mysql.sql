-- 八卦AI项目数据库初始化脚本
-- 创建时间: 2024-01-XX
-- 数据库: MySQL 8.0+

-- 用户表
CREATE TABLE IF NOT EXISTS users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '用户ID',
    openid VARCHAR(100) UNIQUE NOT NULL COMMENT '微信openid',
    nickname VARCHAR(50) COMMENT '昵称',
    avatar_url VARCHAR(255) COMMENT '头像URL',
    vip_level INT DEFAULT 0 COMMENT 'VIP等级：0-普通用户，1-月度VIP，2-年度VIP',
    vip_expire_time DATETIME COMMENT 'VIP过期时间',
    created_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT DEFAULT 0 COMMENT '删除标记：0-未删除，1-已删除'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- 命理记录表
CREATE TABLE IF NOT EXISTS fortune_records (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '记录ID',
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
    created_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT DEFAULT 0 COMMENT '删除标记：0-未删除，1-已删除',
    INDEX idx_user_id (user_id),
    INDEX idx_created_time (created_time),
    INDEX idx_birth_date (birth_year, birth_month, birth_day)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='命理记录表';

-- 姓名推荐表
CREATE TABLE IF NOT EXISTS name_recommendations (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '推荐ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    surname VARCHAR(20) NOT NULL COMMENT '姓氏',
    gender TINYINT NOT NULL COMMENT '性别：1-男，2-女',
    birth_info TEXT COMMENT '出生信息JSON',
    recommended_names JSON COMMENT '推荐姓名列表',
    ai_explanation TEXT COMMENT 'AI解释',
    created_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT DEFAULT 0 COMMENT '删除标记：0-未删除，1-已删除',
    INDEX idx_user_id (user_id),
    INDEX idx_surname (surname),
    INDEX idx_created_time (created_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='姓名推荐表';

-- 插入测试数据
INSERT INTO users (openid, nickname, vip_level) VALUES 
('test_openid_001', '测试用户1', 0),
('test_openid_002', '测试用户2', 1),
('test_openid_003', '测试用户3', 2);

-- 插入测试命理记录
INSERT INTO fortune_records (user_id, name, gender, birth_year, birth_month, birth_day, birth_hour, gan_zhi, sheng_xiao, wu_xing_analysis, ai_analysis) VALUES 
(1, '张三', 1, 1990, 5, 15, 10, '庚午年 辛巳月 甲子日 己巳时', '马', '五行分析：金木水火土均衡', 'AI分析：命格较好，事业运佳'),
(2, '李四', 2, 1995, 8, 20, 14, '乙亥年 甲申月 丁卯日 丁未时', '猪', '五行分析：木火较旺，土金稍弱', 'AI分析：性格开朗，财运不错'),
(3, '王五', 1, 1988, 12, 3, 8, '戊辰年 甲子月 庚申日 庚辰时', '龙', '五行分析：金土较强，木火稍弱', 'AI分析：稳重踏实，适合从商');

-- 创建索引优化查询性能
CREATE INDEX idx_fortune_records_composite ON fortune_records(user_id, created_time DESC);
CREATE INDEX idx_name_recommendations_composite ON name_recommendations(user_id, created_time DESC);

-- 查看表结构
SHOW TABLES;
DESCRIBE users;
DESCRIBE fortune_records;
DESCRIBE name_recommendations; 
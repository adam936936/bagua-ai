-- VIP订单表
CREATE TABLE IF NOT EXISTS vip_orders (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    order_no VARCHAR(64) NOT NULL UNIQUE COMMENT '订单号',
    plan_type VARCHAR(20) NOT NULL COMMENT '套餐类型：monthly, yearly, lifetime',
    amount DECIMAL(10,2) NOT NULL COMMENT '订单金额',
    status VARCHAR(20) NOT NULL DEFAULT 'pending' COMMENT '订单状态：pending, paid, cancelled, expired',
    payment_method VARCHAR(20) DEFAULT 'wechat' COMMENT '支付方式：wechat, alipay',
    transaction_id VARCHAR(64) COMMENT '微信支付交易号',
    expire_time DATETIME COMMENT 'VIP到期时间',
    created_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT NOT NULL DEFAULT 0 COMMENT '删除标记：0-未删除，1-已删除',
    
    INDEX idx_user_id (user_id),
    INDEX idx_order_no (order_no),
    INDEX idx_status (status),
    INDEX idx_expire_time (expire_time),
    INDEX idx_created_time (created_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='VIP订单表'; 
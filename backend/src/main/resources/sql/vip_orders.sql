-- VIP订单表
CREATE TABLE IF NOT EXISTS t_vip_orders (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '订单ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    order_no VARCHAR(64) UNIQUE NOT NULL COMMENT '订单号',
    plan_type VARCHAR(20) NOT NULL COMMENT '套餐类型(MONTHLY/YEARLY)',
    amount DECIMAL(10,2) NOT NULL COMMENT '订单金额',
    status VARCHAR(20) NOT NULL DEFAULT 'pending' COMMENT '订单状态',
    payment_method VARCHAR(20) COMMENT '支付方式',
    transaction_id VARCHAR(64) COMMENT '交易ID',
    expire_time DATETIME COMMENT '过期时间',
    created_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT DEFAULT 0 COMMENT '删除标记',
    INDEX idx_user_id (user_id),
    INDEX idx_order_no (order_no),
    INDEX idx_created_time (created_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='VIP订单表'; 
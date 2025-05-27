package com.fortune.domain.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * VIP订单实体
 */
public class VipOrder {
    private Long id;
    private Long userId;
    private String orderNo;
    private String planType; // monthly, yearly, lifetime
    private BigDecimal amount;
    private String status; // pending, paid, cancelled, expired
    private String paymentMethod; // wechat, alipay
    private String transactionId; // 微信支付交易号
    private LocalDateTime expireTime; // VIP到期时间
    private LocalDateTime createdTime;
    private LocalDateTime updatedTime;
    private Integer deleted;

    // 构造函数
    public VipOrder() {}

    public VipOrder(Long userId, String orderNo, String planType, BigDecimal amount) {
        this.userId = userId;
        this.orderNo = orderNo;
        this.planType = planType;
        this.amount = amount;
        this.status = "pending";
        this.paymentMethod = "wechat";
        this.createdTime = LocalDateTime.now();
        this.updatedTime = LocalDateTime.now();
        this.deleted = 0;
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getOrderNo() {
        return orderNo;
    }

    public void setOrderNo(String orderNo) {
        this.orderNo = orderNo;
    }

    public String getPlanType() {
        return planType;
    }

    public void setPlanType(String planType) {
        this.planType = planType;
    }

    public BigDecimal getAmount() {
        return amount;
    }

    public void setAmount(BigDecimal amount) {
        this.amount = amount;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getPaymentMethod() {
        return paymentMethod;
    }

    public void setPaymentMethod(String paymentMethod) {
        this.paymentMethod = paymentMethod;
    }

    public String getTransactionId() {
        return transactionId;
    }

    public void setTransactionId(String transactionId) {
        this.transactionId = transactionId;
    }

    public LocalDateTime getExpireTime() {
        return expireTime;
    }

    public void setExpireTime(LocalDateTime expireTime) {
        this.expireTime = expireTime;
    }

    public LocalDateTime getCreatedTime() {
        return createdTime;
    }

    public void setCreatedTime(LocalDateTime createdTime) {
        this.createdTime = createdTime;
    }

    public LocalDateTime getUpdatedTime() {
        return updatedTime;
    }

    public void setUpdatedTime(LocalDateTime updatedTime) {
        this.updatedTime = updatedTime;
    }

    public Integer getDeleted() {
        return deleted;
    }

    public void setDeleted(Integer deleted) {
        this.deleted = deleted;
    }
} 
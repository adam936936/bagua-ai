package com.fortune.application.service;

import com.fortune.domain.model.VipOrder;
import com.fortune.infrastructure.persistence.VipOrderMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * VIP服务
 */
@Service
public class VipService {
    
    private static final Logger logger = LoggerFactory.getLogger(VipService.class);
    
    @Autowired
    private VipOrderMapper vipOrderMapper;
    
    // @Autowired
    // private WechatPayService wechatPayService;
    
    // VIP套餐价格配置
    private static final Map<String, BigDecimal> PLAN_PRICES = new HashMap<>();
    private static final Map<String, String> PLAN_NAMES = new HashMap<>();
    
    static {
        PLAN_PRICES.put("monthly", new BigDecimal("19.90"));
        PLAN_PRICES.put("yearly", new BigDecimal("99.90"));
        PLAN_PRICES.put("lifetime", new BigDecimal("199.90"));
        
        PLAN_NAMES.put("monthly", "月度会员");
        PLAN_NAMES.put("yearly", "年度会员");
        PLAN_NAMES.put("lifetime", "终身会员");
    }
    
    /**
     * 获取套餐价格
     */
    public Map<String, Object> getPlanPrices() {
        Map<String, Object> result = new HashMap<>();
        for (Map.Entry<String, BigDecimal> entry : PLAN_PRICES.entrySet()) {
            Map<String, Object> planInfo = new HashMap<>();
            planInfo.put("price", entry.getValue());
            planInfo.put("name", PLAN_NAMES.get(entry.getKey()));
            result.put(entry.getKey(), planInfo);
        }
        return result;
    }
    
    /**
     * 创建VIP订单
     */
    public VipOrder createVipOrder(Long userId, String planType) {
        BigDecimal amount = PLAN_PRICES.get(planType);
        if (amount == null) {
            throw new RuntimeException("无效的套餐类型");
        }
        
        String orderNo = generateOrderNo();
        LocalDateTime expireTime = calculateExpireTime(planType);
        
        VipOrder vipOrder = new VipOrder(userId, orderNo, planType, amount);
        vipOrder.setExpireTime(expireTime);
        
        vipOrderMapper.insert(vipOrder);
        logger.info("创建VIP订单成功，订单号：{}，用户ID：{}，套餐类型：{}", orderNo, userId, planType);
        
        return vipOrder;
    }

    /**
     * 创建支付订单
     */
    public Map<String, Object> createPayOrder(String orderNo, String openId) {
        VipOrder vipOrder = vipOrderMapper.findByOrderNo(orderNo);
        if (vipOrder == null) {
            throw new RuntimeException("订单不存在");
        }
        
        if (!"pending".equals(vipOrder.getStatus())) {
            throw new RuntimeException("订单状态异常");
        }
        
        String description = PLAN_NAMES.get(vipOrder.getPlanType()) + " - AI八卦运势";
        
        // 模拟微信支付参数
        Map<String, Object> payParams = new HashMap<>();
        payParams.put("appId", "wx1234567890");
        payParams.put("timeStamp", String.valueOf(System.currentTimeMillis() / 1000));
        payParams.put("nonceStr", "nonce" + System.currentTimeMillis());
        payParams.put("package", "prepay_id=wx" + System.currentTimeMillis());
        payParams.put("signType", "MD5");
        payParams.put("paySign", "sign" + System.currentTimeMillis());
        
        return payParams;
    }
    
    /**
     * 模拟支付成功
     */
    public boolean mockPaymentSuccess(String orderNo) {
        VipOrder vipOrder = vipOrderMapper.findByOrderNo(orderNo);
        if (vipOrder == null) {
            logger.error("订单不存在：{}", orderNo);
            return false;
        }
        
        if (!"pending".equals(vipOrder.getStatus())) {
            logger.error("订单状态异常：{}，当前状态：{}", orderNo, vipOrder.getStatus());
            return false;
        }
        
        // 更新订单状态为已支付
        vipOrderMapper.updatePaymentStatus(orderNo, "paid", "mock_transaction_" + System.currentTimeMillis());
        logger.info("模拟支付成功，订单号：{}", orderNo);
        return true;
    }

    /**
     * 处理支付回调
     */
    public boolean handlePaymentNotify(Map<String, String> params) {
        // 验证签名
        if (false) {
            logger.error("支付回调签名验证失败");
            return false;
        }
        
        String orderNo = params.get("out_trade_no");
        String transactionId = params.get("transaction_id");
        String resultCode = params.get("result_code");
        
        if ("SUCCESS".equals(resultCode)) {
            // 支付成功，更新订单状态
            vipOrderMapper.updatePaymentStatus(orderNo, "paid", transactionId);
            logger.info("VIP订单支付成功，订单号：{}，交易号：{}", orderNo, transactionId);
            return true;
        } else {
            // 支付失败
            vipOrderMapper.updateStatus(orderNo, "failed");
            logger.warn("VIP订单支付失败，订单号：{}", orderNo);
            return false;
        }
    }
    
    /**
     * 检查用户VIP状态
     */
    public boolean isUserVip(Long userId) {
        return vipOrderMapper.countActiveVip(userId) > 0;
    }
    
    /**
     * 获取用户VIP信息
     */
    public VipOrder getUserVipInfo(Long userId) {
        return vipOrderMapper.findActiveVipByUserId(userId);
    }
    
    /**
     * 获取用户订单列表
     */
    public List<VipOrder> getUserOrders(Long userId) {
        return vipOrderMapper.findByUserId(userId);
    }
    
    /**
     * 获取用户VIP状态详情
     */
    public Map<String, Object> getUserVipStatus(Long userId) {
        Map<String, Object> status = new HashMap<>();
        VipOrder activeVip = vipOrderMapper.findActiveVipByUserId(userId);
        
        if (activeVip != null) {
            status.put("isVip", true);
            status.put("planType", activeVip.getPlanType());
            status.put("expireTime", activeVip.getExpireTime().toString());
        } else {
            status.put("isVip", false);
            status.put("planType", null);
            status.put("expireTime", null);
        }
        
        return status;
    }
    
    /**
     * 生成订单号
     */
    private String generateOrderNo() {
        return "VIP" + System.currentTimeMillis() + String.format("%04d", (int)(Math.random() * 10000));
    }
    
    /**
     * 计算VIP到期时间
     */
    private LocalDateTime calculateExpireTime(String planType) {
        LocalDateTime now = LocalDateTime.now();
        switch (planType) {
            case "monthly":
                return now.plusMonths(1);
            case "yearly":
                return now.plusYears(1);
            case "lifetime":
                return now.plusYears(100); // 100年后过期，相当于终身
            default:
                throw new IllegalArgumentException("无效的套餐类型");
        }
    }
} 
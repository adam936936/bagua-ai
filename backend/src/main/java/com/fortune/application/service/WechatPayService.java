package com.fortune.application.service;

import com.fortune.config.WechatPayConfig;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.security.MessageDigest;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

/**
 * 微信支付服务
 */
@Service
public class WechatPayService {
    
    private static final Logger logger = LoggerFactory.getLogger(WechatPayService.class);
    
    @Autowired
    private WechatPayConfig wechatPayConfig;
    
    /**
     * 创建统一下单参数
     */
    public Map<String, Object> createUnifiedOrder(String orderNo, BigDecimal amount, String description, String openId) {
        try {
            Map<String, String> params = new HashMap<>();
            params.put("appid", wechatPayConfig.getAppId());
            params.put("mch_id", wechatPayConfig.getMchId());
            params.put("nonce_str", generateNonceStr());
            params.put("body", description);
            params.put("out_trade_no", orderNo);
            params.put("total_fee", String.valueOf(amount.multiply(new BigDecimal("100")).intValue())); // 转换为分
            params.put("spbill_create_ip", "127.0.0.1");
            params.put("notify_url", wechatPayConfig.getNotifyUrl());
            params.put("trade_type", "JSAPI");
            params.put("openid", openId);
            
            // 生成签名
            String sign = generateSign(params);
            params.put("sign", sign);
            
            // 这里应该调用微信支付API，暂时返回模拟数据
            Map<String, Object> result = new HashMap<>();
            result.put("return_code", "SUCCESS");
            result.put("result_code", "SUCCESS");
            result.put("prepay_id", "wx" + System.currentTimeMillis());
            
            return result;
            
        } catch (Exception e) {
            logger.error("创建微信支付订单失败", e);
            throw new RuntimeException("创建支付订单失败");
        }
    }
    
    /**
     * 生成小程序支付参数
     */
    public Map<String, Object> generateMiniProgramPayParams(String prepayId) {
        try {
            Map<String, String> params = new HashMap<>();
            params.put("appId", wechatPayConfig.getAppId());
            params.put("timeStamp", String.valueOf(System.currentTimeMillis() / 1000));
            params.put("nonceStr", generateNonceStr());
            params.put("package", "prepay_id=" + prepayId);
            params.put("signType", "MD5");
            
            // 生成支付签名
            String paySign = generateSign(params);
            
            Map<String, Object> result = new HashMap<>();
            result.put("appId", params.get("appId"));
            result.put("timeStamp", params.get("timeStamp"));
            result.put("nonceStr", params.get("nonceStr"));
            result.put("package", params.get("package"));
            result.put("signType", params.get("signType"));
            result.put("paySign", paySign);
            
            return result;
            
        } catch (Exception e) {
            logger.error("生成小程序支付参数失败", e);
            throw new RuntimeException("生成支付参数失败");
        }
    }
    
    /**
     * 验证支付回调签名
     */
    public boolean verifyNotifySign(Map<String, String> params) {
        try {
            String sign = params.get("sign");
            params.remove("sign");
            
            String calculatedSign = generateSign(params);
            return sign.equals(calculatedSign);
            
        } catch (Exception e) {
            logger.error("验证支付回调签名失败", e);
            return false;
        }
    }
    
    /**
     * 生成随机字符串
     */
    private String generateNonceStr() {
        return UUID.randomUUID().toString().replace("-", "").substring(0, 32);
    }
    
    /**
     * 生成签名
     */
    private String generateSign(Map<String, String> params) throws Exception {
        // 排序参数
        TreeMap<String, String> sortedParams = new TreeMap<>(params);
        
        // 拼接参数
        StringBuilder sb = new StringBuilder();
        for (Map.Entry<String, String> entry : sortedParams.entrySet()) {
            if (entry.getValue() != null && !entry.getValue().isEmpty()) {
                sb.append(entry.getKey()).append("=").append(entry.getValue()).append("&");
            }
        }
        sb.append("key=").append(wechatPayConfig.getApiKey());
        
        // MD5加密
        MessageDigest md = MessageDigest.getInstance("MD5");
        byte[] digest = md.digest(sb.toString().getBytes("UTF-8"));
        
        StringBuilder hexString = new StringBuilder();
        for (byte b : digest) {
            String hex = Integer.toHexString(0xff & b);
            if (hex.length() == 1) {
                hexString.append('0');
            }
            hexString.append(hex);
        }
        
        return hexString.toString().toUpperCase();
    }
} 
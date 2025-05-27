package com.fortune.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * 微信支付配置
 */
@Configuration
@ConfigurationProperties(prefix = "wechat.pay")
public class WechatPayConfig {
    
    private String appId;
    private String mchId;
    private String apiKey;
    private String notifyUrl;
    private String certPath;
    
    // Getters and Setters
    public String getAppId() {
        return appId;
    }
    
    public void setAppId(String appId) {
        this.appId = appId;
    }
    
    public String getMchId() {
        return mchId;
    }
    
    public void setMchId(String mchId) {
        this.mchId = mchId;
    }
    
    public String getApiKey() {
        return apiKey;
    }
    
    public void setApiKey(String apiKey) {
        this.apiKey = apiKey;
    }
    
    public String getNotifyUrl() {
        return notifyUrl;
    }
    
    public void setNotifyUrl(String notifyUrl) {
        this.notifyUrl = notifyUrl;
    }
    
    public String getCertPath() {
        return certPath;
    }
    
    public void setCertPath(String certPath) {
        this.certPath = certPath;
    }
} 
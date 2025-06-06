package com.fortune.interfaces.dto.response;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.time.LocalDateTime;

/**
 * 用户信息响应
 * 
 * @author fortune
 * @since 2024-01-01
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserProfileResponse {
    
    /**
     * 用户ID
     */
    private Long userId;
    
    /**
     * 微信OpenID
     */
    private String openId;
    
    /**
     * 用户昵称
     */
    private String nickname;
    
    /**
     * 用户头像
     */
    private String avatar;
    
    /**
     * 手机号
     */
    private String phone;
    
    /**
     * VIP等级
     */
    private Integer vipLevel;
    
    /**
     * VIP过期时间
     */
    private LocalDateTime vipExpireTime;
    
    /**
     * 总分析次数
     */
    private Integer totalAnalysisCount;
    
    /**
     * 是否VIP
     */
    public Boolean getIsVip() {
        return vipLevel != null && vipLevel > 0 && 
               (vipExpireTime == null || vipExpireTime.isAfter(LocalDateTime.now()));
    }
} 
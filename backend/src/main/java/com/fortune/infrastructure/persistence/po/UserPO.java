package com.fortune.infrastructure.persistence.po;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.time.LocalDateTime;

/**
 * 用户持久化对象
 * 
 * @author fortune
 * @since 2024-01-01
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserPO {
    
    /**
     * 用户ID
     */
    private Long id;
    
    /**
     * 微信openid
     */
    private String openid;
    
    /**
     * 昵称
     */
    private String nickname;
    
    /**
     * 头像URL
     */
    private String avatarUrl;
    
    /**
     * 手机号
     */
    private String phone;
    
    /**
     * VIP等级：0-普通用户，1-月度VIP，2-年度VIP
     */
    private Integer vipLevel;
    
    /**
     * VIP过期时间
     */
    private LocalDateTime vipExpireTime;
    
    /**
     * 创建时间
     */
    private LocalDateTime createdTime;
    
    /**
     * 更新时间
     */
    private LocalDateTime updatedTime;
    
    /**
     * 删除标记：0-未删除，1-已删除
     */
    private Integer deleted;
} 
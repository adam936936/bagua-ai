package com.fortune.interfaces.dto.response;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

/**
 * 用户登录响应
 * 
 * @author fortune
 * @since 2024-01-01
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserLoginResponse {
    
    /**
     * 用户ID
     */
    private Long userId;
    
    /**
     * 微信OpenID
     */
    private String openId;
    
    /**
     * JWT Token
     */
    private String token;
    
    /**
     * 是否新用户
     */
    private Boolean isNewUser;
} 
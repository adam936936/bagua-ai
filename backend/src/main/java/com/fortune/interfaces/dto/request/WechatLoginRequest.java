package com.fortune.interfaces.dto.request;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import javax.validation.constraints.NotBlank;

/**
 * 微信登录请求
 * 
 * @author fortune
 * @since 2024-01-01
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class WechatLoginRequest {
    
    /**
     * 微信授权码
     */
    @NotBlank(message = "授权码不能为空")
    private String code;
    
    /**
     * 用户昵称（可选）
     */
    private String nickName;
    
    /**
     * 用户头像（可选）
     */
    private String avatar;
} 
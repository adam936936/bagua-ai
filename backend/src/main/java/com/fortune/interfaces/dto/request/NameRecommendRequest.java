package com.fortune.interfaces.dto.request;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;

/**
 * 姓名推荐请求
 * 
 * @author fortune
 * @since 2024-01-01
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class NameRecommendRequest {
    
    /**
     * 用户ID
     */
    @NotNull(message = "用户ID不能为空")
    private Long userId;
    
    /**
     * 五行缺失
     */
    @NotBlank(message = "五行缺失不能为空")
    private String wuXingLack;
    
    /**
     * 天干地支
     */
    @NotBlank(message = "天干地支不能为空")
    private String ganZhi;
    
    /**
     * 姓氏（可选）
     */
    private String surname;
} 
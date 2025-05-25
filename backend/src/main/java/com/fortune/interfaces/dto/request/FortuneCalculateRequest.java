package com.fortune.interfaces.dto.request;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Pattern;

/**
 * 命理计算请求
 * 
 * @author fortune
 * @since 2024-01-01
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class FortuneCalculateRequest {
    
    /**
     * 用户ID
     */
    @NotNull(message = "用户ID不能为空")
    private Long userId;
    
    /**
     * 出生日期（格式：yyyy-MM-dd）
     */
    @NotBlank(message = "出生日期不能为空")
    @Pattern(regexp = "^\\d{4}-\\d{2}-\\d{2}$", message = "出生日期格式不正确，应为yyyy-MM-dd")
    private String birthDate;
    
    /**
     * 出生时辰
     */
    @NotBlank(message = "出生时辰不能为空")
    @Pattern(regexp = "^(子时|丑时|寅时|卯时|辰时|巳时|午时|未时|申时|酉时|戌时|亥时)$", 
             message = "出生时辰格式不正确")
    private String birthTime;
    
    /**
     * 用户姓名（可选）
     */
    private String userName;
} 
package com.fortune.application.command;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

/**
 * 计算命理命令
 * 
 * @author fortune
 * @since 2024-01-01
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CalculateFortuneCommand {
    
    /**
     * 用户ID
     */
    private Long userId;
    
    /**
     * 出生日期
     */
    private String birthDate;
    
    /**
     * 出生时辰
     */
    private String birthTime;
    
    /**
     * 用户姓名
     */
    private String userName;
} 
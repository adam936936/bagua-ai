package com.fortune.application.command;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

/**
 * 推荐姓名命令
 * 
 * @author fortune
 * @since 2024-01-01
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RecommendNameCommand {
    
    /**
     * 用户ID
     */
    private Long userId;
    
    /**
     * 五行缺失
     */
    private String wuXingLack;
    
    /**
     * 天干地支
     */
    private String ganZhi;
    
    /**
     * 姓氏
     */
    private String surname;
} 
package com.fortune.interfaces.dto.response;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.time.LocalDateTime;

/**
 * VIP状态响应
 * 
 * @author fortune
 * @since 2024-01-01
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VipStatusResponse {
    
    /**
     * 用户ID
     */
    private Long userId;
    
    /**
     * 是否VIP
     */
    private Boolean isVip;
    
    /**
     * VIP等级
     */
    private Integer vipLevel;
    
    /**
     * VIP过期时间
     */
    private LocalDateTime vipExpireTime;
    
    /**
     * 剩余分析次数
     */
    private Integer remainingAnalysisCount;
    
    /**
     * 总分析次数
     */
    private Integer totalAnalysisCount;
} 
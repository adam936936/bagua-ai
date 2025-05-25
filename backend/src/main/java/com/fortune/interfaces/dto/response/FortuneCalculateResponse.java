package com.fortune.interfaces.dto.response;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 命理计算响应
 * 
 * @author fortune
 * @since 2024-01-01
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FortuneCalculateResponse {
    
    /**
     * 记录ID
     */
    private Long id;
    
    /**
     * 农历日期
     */
    private String lunar;
    
    /**
     * 天干地支
     */
    private String ganZhi;
    
    /**
     * 五行属性
     */
    private String wuXing;
    
    /**
     * 五行缺失
     */
    private String wuXingLack;
    
    /**
     * 生肖
     */
    private String shengXiao;
    
    /**
     * AI分析结果
     */
    private String aiAnalysis;
    
    /**
     * 姓名分析结果
     */
    private String nameAnalysis;
    
    /**
     * AI推荐姓名列表
     */
    private List<NameRecommendationResponse> nameRecommendations;
    
    /**
     * 创建时间
     */
    private LocalDateTime createTime;
} 
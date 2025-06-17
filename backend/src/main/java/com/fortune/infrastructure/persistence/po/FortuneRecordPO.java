package com.fortune.infrastructure.persistence.po;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.time.LocalDateTime;

/**
 * 命理记录持久化对象
 * 
 * @author fortune
 * @since 2024-01-01
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class FortuneRecordPO {
    
    /**
     * 记录ID
     */
    private Long id;
    
    /**
     * 用户ID
     */
    private Long userId;
    
    /**
     * 出生日期
     */
    private String birthDate;
    
    /**
     * 出生时间
     */
    private String birthTime;
    
    /**
     * 用户姓名
     */
    private String userName;
    
    /**
     * 农历日期
     */
    private String lunarDate;
    
    /**
     * 干支
     */
    private String ganZhi;
    
    /**
     * 五行分析
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
     * 姓名分析
     */
    private String nameAnalysis;
    
    /**
     * 姓名推荐
     */
    private String nameRecommendations;
    
    /**
     * 创建时间
     */
    private LocalDateTime createTime;
    
    /**
     * 更新时间
     */
    private LocalDateTime updateTime;
    
    /**
     * 删除标记：0-未删除，1-已删除
     */
    private Integer deleted;
} 
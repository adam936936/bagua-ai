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
     * 姓名
     */
    private String name;
    
    /**
     * 性别：1-男，2-女
     */
    private Integer gender;
    
    /**
     * 出生年
     */
    private Integer birthYear;
    
    /**
     * 出生月
     */
    private Integer birthMonth;
    
    /**
     * 出生日
     */
    private Integer birthDay;
    
    /**
     * 出生时辰
     */
    private Integer birthHour;
    
    /**
     * 农历年
     */
    private Integer lunarYear;
    
    /**
     * 农历月
     */
    private Integer lunarMonth;
    
    /**
     * 农历日
     */
    private Integer lunarDay;
    
    /**
     * 干支
     */
    private String ganZhi;
    
    /**
     * 生肖
     */
    private String shengXiao;
    
    /**
     * 五行分析
     */
    private String wuXingAnalysis;
    
    /**
     * AI分析结果
     */
    private String aiAnalysis;
    
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
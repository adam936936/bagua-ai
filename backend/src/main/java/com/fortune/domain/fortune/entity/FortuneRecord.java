package com.fortune.domain.fortune.entity;

import com.fortune.domain.fortune.valueobject.*;
import com.fortune.domain.shared.valueobject.BaseId;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 命理记录聚合根
 * 
 * @author fortune
 * @since 2024-01-01
 */
@Data
@NoArgsConstructor
public class FortuneRecord {
    
    /**
     * 记录ID
     */
    private BaseId id;
    
    /**
     * 用户ID
     */
    private Long userId;
    
    /**
     * 出生信息
     */
    private BirthInfo birthInfo;
    
    /**
     * 农历日期
     */
    private LunarDate lunarDate;
    
    /**
     * 天干地支
     */
    private GanZhi ganZhi;
    
    /**
     * 五行分析
     */
    private WuXingAnalysis wuXingAnalysis;
    
    /**
     * 生肖
     */
    private ShengXiao shengXiao;
    
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
    private List<NameRecommendation> nameRecommendations;
    
    /**
     * 创建时间
     */
    private LocalDateTime createTime;
    
    /**
     * 构造函数
     */
    public FortuneRecord(Long userId, BirthInfo birthInfo) {
        this.id = BaseId.generate();
        this.userId = userId;
        this.birthInfo = birthInfo;
        this.createTime = LocalDateTime.now();
    }
    
    /**
     * 设置命理计算结果
     */
    public void setFortuneResult(LunarDate lunarDate, GanZhi ganZhi, 
                                WuXingAnalysis wuXingAnalysis, ShengXiao shengXiao) {
        this.lunarDate = lunarDate;
        this.ganZhi = ganZhi;
        this.wuXingAnalysis = wuXingAnalysis;
        this.shengXiao = shengXiao;
    }
    
    /**
     * 设置AI分析结果
     */
    public void setAiAnalysis(String aiAnalysis) {
        this.aiAnalysis = aiAnalysis;
    }
    
    /**
     * 设置姓名分析结果
     */
    public void setNameAnalysis(String nameAnalysis) {
        this.nameAnalysis = nameAnalysis;
    }
    
    /**
     * 设置AI推荐姓名
     */
    public void setNameRecommendations(List<NameRecommendation> nameRecommendations) {
        this.nameRecommendations = nameRecommendations;
    }
    
    /**
     * 检查是否包含完整的命理信息
     */
    public boolean hasCompleteFortuneInfo() {
        return lunarDate != null && ganZhi != null && 
               wuXingAnalysis != null && shengXiao != null;
    }
    
    /**
     * 检查是否有AI分析结果
     */
    public boolean hasAiAnalysis() {
        return aiAnalysis != null && !aiAnalysis.trim().isEmpty();
    }
    
    /**
     * 检查是否有姓名推荐
     */
    public boolean hasNameRecommendations() {
        return nameRecommendations != null && !nameRecommendations.isEmpty();
    }
} 
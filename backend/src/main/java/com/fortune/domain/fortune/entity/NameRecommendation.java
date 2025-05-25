package com.fortune.domain.fortune.entity;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

/**
 * 姓名推荐实体
 * 
 * @author fortune
 * @since 2024-01-01
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class NameRecommendation {
    
    /**
     * 推荐姓名
     */
    private String name;
    
    /**
     * 推荐理由
     */
    private String reason;
    
    /**
     * 评分（1-100）
     */
    private Integer score;
    
    /**
     * 五行属性
     */
    private String wuXing;
} 
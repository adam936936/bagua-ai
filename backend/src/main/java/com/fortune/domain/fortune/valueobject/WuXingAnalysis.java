package com.fortune.domain.fortune.valueobject;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.util.Map;
import java.util.List;

/**
 * 五行分析值对象
 * 
 * @author fortune
 * @since 2024-01-01
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WuXingAnalysis {
    
    /**
     * 五行统计 (金、木、水、火、土的个数)
     */
    private Map<String, Integer> wuXingCount;
    
    /**
     * 主要五行属性
     */
    private String primaryWuXing;
    
    /**
     * 缺失的五行
     */
    private List<String> lackingWuXing;
    
    /**
     * 过旺的五行
     */
    private List<String> excessiveWuXing;
    
    /**
     * 五行平衡度评分 (0-100)
     */
    private Integer balanceScore;
    
    /**
     * 分析描述
     */
    private String description;
    
    /**
     * 获取缺失五行的字符串表示
     */
    public String getLackingWuXingString() {
        if (lackingWuXing == null || lackingWuXing.isEmpty()) {
            return "无";
        }
        return String.join("、", lackingWuXing);
    }
    
    /**
     * 获取五行属性的字符串表示
     */
    public String getWuXingString() {
        if (wuXingCount == null || wuXingCount.isEmpty()) {
            return "未知";
        }
        
        StringBuilder sb = new StringBuilder();
        wuXingCount.forEach((element, count) -> {
            if (count > 0) {
                sb.append(element).append(count).append("个 ");
            }
        });
        
        return sb.toString().trim();
    }
    
    /**
     * 判断是否五行平衡
     */
    public boolean isBalanced() {
        return balanceScore != null && balanceScore >= 70;
    }
} 
package com.fortune.domain.fortune.valueobject;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

/**
 * 天干地支值对象
 * 
 * @author fortune
 * @since 2024-01-01
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class GanZhi {
    
    /**
     * 年柱
     */
    private String yearPillar;
    
    /**
     * 月柱
     */
    private String monthPillar;
    
    /**
     * 日柱
     */
    private String dayPillar;
    
    /**
     * 时柱
     */
    private String hourPillar;
    
    /**
     * 格式化显示完整八字
     */
    public String format() {
        return String.format("%s %s %s %s", yearPillar, monthPillar, dayPillar, hourPillar);
    }
    
    /**
     * 创建天干地支
     */
    public static GanZhi of(String yearPillar, String monthPillar, String dayPillar, String hourPillar) {
        GanZhi ganZhi = new GanZhi();
        ganZhi.yearPillar = yearPillar;
        ganZhi.monthPillar = monthPillar;
        ganZhi.dayPillar = dayPillar;
        ganZhi.hourPillar = hourPillar;
        return ganZhi;
    }
    
    /**
     * 从字符串解析
     */
    public static GanZhi parse(String ganZhiStr) {
        if (ganZhiStr == null || ganZhiStr.trim().isEmpty()) {
            return new GanZhi();
        }
        
        String[] parts = ganZhiStr.trim().split("\\s+");
        if (parts.length >= 4) {
            GanZhi ganZhi = new GanZhi();
            ganZhi.yearPillar = parts[0];
            ganZhi.monthPillar = parts[1];
            ganZhi.dayPillar = parts[2];
            ganZhi.hourPillar = parts[3];
            return ganZhi;
        }
        
        return new GanZhi();
    }
} 
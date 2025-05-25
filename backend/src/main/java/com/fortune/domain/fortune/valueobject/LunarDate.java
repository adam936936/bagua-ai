package com.fortune.domain.fortune.valueobject;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

/**
 * 农历日期值对象
 * 
 * @author fortune
 * @since 2024-01-01
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class LunarDate {
    
    /**
     * 农历年
     */
    private Integer year;
    
    /**
     * 农历月
     */
    private Integer month;
    
    /**
     * 农历日
     */
    private Integer day;
    
    /**
     * 是否闰月
     */
    private Boolean isLeapMonth;
    
    /**
     * 农历年份天干地支
     */
    private String yearGanZhi;
    
    /**
     * 农历月份天干地支
     */
    private String monthGanZhi;
    
    /**
     * 农历日期天干地支
     */
    private String dayGanZhi;
    
    /**
     * 格式化显示
     */
    public String format() {
        String leapPrefix = isLeapMonth ? "闰" : "";
        return String.format("农历%d年%s%d月%d日", year, leapPrefix, month, day);
    }
    
    /**
     * 创建农历日期
     */
    public static LunarDate of(Integer year, Integer month, Integer day, Boolean isLeapMonth) {
        LunarDate lunarDate = new LunarDate();
        lunarDate.year = year;
        lunarDate.month = month;
        lunarDate.day = day;
        lunarDate.isLeapMonth = isLeapMonth;
        return lunarDate;
    }
} 
package com.fortune.infrastructure.utils;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.Map;
import java.util.Arrays;
import java.util.List;
import java.util.ArrayList;

/**
 * 命理计算工具类
 * 
 * @author fortune
 * @since 2024-01-01
 */
public class FortuneUtils {
    
    // 天干
    private static final String[] TIAN_GAN = {
        "甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"
    };
    
    // 地支
    private static final String[] DI_ZHI = {
        "子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"
    };
    
    // 生肖
    private static final String[] SHENG_XIAO = {
        "鼠", "牛", "虎", "兔", "龙", "蛇", "马", "羊", "猴", "鸡", "狗", "猪"
    };
    
    // 天干五行
    private static final Map<String, String> TIAN_GAN_WU_XING = new HashMap<>();
    static {
        TIAN_GAN_WU_XING.put("甲", "木");
        TIAN_GAN_WU_XING.put("乙", "木");
        TIAN_GAN_WU_XING.put("丙", "火");
        TIAN_GAN_WU_XING.put("丁", "火");
        TIAN_GAN_WU_XING.put("戊", "土");
        TIAN_GAN_WU_XING.put("己", "土");
        TIAN_GAN_WU_XING.put("庚", "金");
        TIAN_GAN_WU_XING.put("辛", "金");
        TIAN_GAN_WU_XING.put("壬", "水");
        TIAN_GAN_WU_XING.put("癸", "水");
    }
    
    // 地支五行
    private static final Map<String, String> DI_ZHI_WU_XING = new HashMap<>();
    static {
        DI_ZHI_WU_XING.put("子", "水");
        DI_ZHI_WU_XING.put("丑", "土");
        DI_ZHI_WU_XING.put("寅", "木");
        DI_ZHI_WU_XING.put("卯", "木");
        DI_ZHI_WU_XING.put("辰", "土");
        DI_ZHI_WU_XING.put("巳", "火");
        DI_ZHI_WU_XING.put("午", "火");
        DI_ZHI_WU_XING.put("未", "土");
        DI_ZHI_WU_XING.put("申", "金");
        DI_ZHI_WU_XING.put("酉", "金");
        DI_ZHI_WU_XING.put("戌", "土");
        DI_ZHI_WU_XING.put("亥", "水");
    }
    
    // 时辰对应地支
    private static final Map<String, String> SHI_CHEN_DI_ZHI = new HashMap<>();
    static {
        SHI_CHEN_DI_ZHI.put("子时", "子");
        SHI_CHEN_DI_ZHI.put("丑时", "丑");
        SHI_CHEN_DI_ZHI.put("寅时", "寅");
        SHI_CHEN_DI_ZHI.put("卯时", "卯");
        SHI_CHEN_DI_ZHI.put("辰时", "辰");
        SHI_CHEN_DI_ZHI.put("巳时", "巳");
        SHI_CHEN_DI_ZHI.put("午时", "午");
        SHI_CHEN_DI_ZHI.put("未时", "未");
        SHI_CHEN_DI_ZHI.put("申时", "申");
        SHI_CHEN_DI_ZHI.put("酉时", "酉");
        SHI_CHEN_DI_ZHI.put("戌时", "戌");
        SHI_CHEN_DI_ZHI.put("亥时", "亥");
    }
    
    /**
     * 阳历转农历（简化版本）
     */
    public static String solarToLunar(LocalDate solarDate) {
        // 这里使用简化的转换逻辑，实际应该使用专业的农历转换算法
        int year = solarDate.getYear();
        int month = solarDate.getMonthValue();
        int day = solarDate.getDayOfMonth();
        
        // 简化处理：假设农历比阳历晚约一个月
        int lunarMonth = month - 1;
        int lunarYear = year;
        if (lunarMonth <= 0) {
            lunarMonth = 12;
            lunarYear = year - 1;
        }
        
        return String.format("农历%d年%d月%d日", lunarYear, lunarMonth, day);
    }
    
    /**
     * 计算天干地支
     */
    public static String calculateGanZhi(LocalDate birthDate, String birthTime) {
        int year = birthDate.getYear();
        int month = birthDate.getMonthValue();
        int day = birthDate.getDayOfMonth();
        
        // 计算年柱
        String yearPillar = getYearPillar(year);
        
        // 计算月柱（简化）
        String monthPillar = getMonthPillar(year, month);
        
        // 计算日柱（简化）
        String dayPillar = getDayPillar(year, month, day);
        
        // 计算时柱
        String hourPillar = getHourPillar(birthTime, dayPillar);
        
        return String.format("%s %s %s %s", yearPillar, monthPillar, dayPillar, hourPillar);
    }
    
    /**
     * 分析五行
     */
    public static Map<String, Object> analyzeWuXing(String ganZhi) {
        Map<String, Object> result = new HashMap<>();
        Map<String, Integer> wuXingCount = new HashMap<>();
        
        // 初始化五行计数
        wuXingCount.put("金", 0);
        wuXingCount.put("木", 0);
        wuXingCount.put("水", 0);
        wuXingCount.put("火", 0);
        wuXingCount.put("土", 0);
        
        // 解析天干地支
        String[] parts = ganZhi.split("\\s+");
        for (String part : parts) {
            if (part.length() >= 2) {
                String tianGan = part.substring(0, 1);
                String diZhi = part.substring(1, 2);
                
                // 统计天干五行
                String tianGanWuXing = TIAN_GAN_WU_XING.get(tianGan);
                if (tianGanWuXing != null) {
                    wuXingCount.put(tianGanWuXing, wuXingCount.get(tianGanWuXing) + 1);
                }
                
                // 统计地支五行
                String diZhiWuXing = DI_ZHI_WU_XING.get(diZhi);
                if (diZhiWuXing != null) {
                    wuXingCount.put(diZhiWuXing, wuXingCount.get(diZhiWuXing) + 1);
                }
            }
        }
        
        // 找出主要五行
        String primaryWuXing = wuXingCount.entrySet().stream()
                .max(Map.Entry.comparingByValue())
                .map(Map.Entry::getKey)
                .orElse("未知");
        
        // 找出缺失的五行
        List<String> lackingWuXing = new ArrayList<>();
        for (Map.Entry<String, Integer> entry : wuXingCount.entrySet()) {
            if (entry.getValue() == 0) {
                lackingWuXing.add(entry.getKey());
            }
        }
        
        // 构建五行属性字符串
        StringBuilder wuXingStr = new StringBuilder();
        for (Map.Entry<String, Integer> entry : wuXingCount.entrySet()) {
            if (entry.getValue() > 0) {
                wuXingStr.append(entry.getKey()).append(entry.getValue()).append("个 ");
            }
        }
        
        result.put("wuXing", wuXingStr.toString().trim());
        result.put("wuXingLack", String.join("、", lackingWuXing));
        result.put("primaryWuXing", primaryWuXing);
        result.put("wuXingCount", wuXingCount);
        
        return result;
    }
    
    /**
     * 获取生肖
     */
    public static String getShengXiao(int year) {
        // 1900年是鼠年
        int index = (year - 1900) % 12;
        return SHENG_XIAO[index];
    }
    
    /**
     * 计算年柱
     */
    private static String getYearPillar(int year) {
        // 以1900年庚子年为基准
        int tianGanIndex = (year - 1900) % 10;
        int diZhiIndex = (year - 1900) % 12;
        return TIAN_GAN[tianGanIndex] + DI_ZHI[diZhiIndex];
    }
    
    /**
     * 计算月柱（简化）
     */
    private static String getMonthPillar(int year, int month) {
        // 简化计算，实际应该根据节气
        int tianGanIndex = (year * 12 + month) % 10;
        int diZhiIndex = (month - 1) % 12;
        return TIAN_GAN[tianGanIndex] + DI_ZHI[diZhiIndex];
    }
    
    /**
     * 计算日柱（简化）
     */
    private static String getDayPillar(int year, int month, int day) {
        // 简化计算，实际应该使用万年历
        int totalDays = year * 365 + month * 30 + day;
        int tianGanIndex = totalDays % 10;
        int diZhiIndex = totalDays % 12;
        return TIAN_GAN[tianGanIndex] + DI_ZHI[diZhiIndex];
    }
    
    /**
     * 计算时柱
     */
    private static String getHourPillar(String birthTime, String dayPillar) {
        String diZhi = SHI_CHEN_DI_ZHI.get(birthTime);
        if (diZhi == null) {
            diZhi = "子"; // 默认子时
        }
        
        // 根据日干推算时干（简化）
        String dayTianGan = dayPillar.substring(0, 1);
        int dayTianGanIndex = Arrays.asList(TIAN_GAN).indexOf(dayTianGan);
        int hourTianGanIndex = (dayTianGanIndex * 2) % 10;
        
        return TIAN_GAN[hourTianGanIndex] + diZhi;
    }
} 
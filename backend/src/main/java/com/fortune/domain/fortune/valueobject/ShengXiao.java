package com.fortune.domain.fortune.valueobject;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

/**
 * 生肖值对象
 * 
 * @author fortune
 * @since 2024-01-01
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ShengXiao {
    
    /**
     * 生肖名称
     */
    private String name;
    
    /**
     * 生肖对应的地支
     */
    private String earthlyBranch;
    
    /**
     * 生肖五行属性
     */
    private String wuXing;
    
    /**
     * 生肖特征描述
     */
    private String characteristics;
    
    /**
     * 创建生肖
     */
    public static ShengXiao of(String name) {
        ShengXiao shengXiao = new ShengXiao();
        shengXiao.name = name;
        
        // 设置对应的地支和五行
        switch (name) {
            case "鼠":
                shengXiao.earthlyBranch = "子";
                shengXiao.wuXing = "水";
                shengXiao.characteristics = "机智灵活，适应能力强";
                break;
            case "牛":
                shengXiao.earthlyBranch = "丑";
                shengXiao.wuXing = "土";
                shengXiao.characteristics = "勤劳踏实，责任心强";
                break;
            case "虎":
                shengXiao.earthlyBranch = "寅";
                shengXiao.wuXing = "木";
                shengXiao.characteristics = "勇敢果断，领导能力强";
                break;
            case "兔":
                shengXiao.earthlyBranch = "卯";
                shengXiao.wuXing = "木";
                shengXiao.characteristics = "温和善良，心思细腻";
                break;
            case "龙":
                shengXiao.earthlyBranch = "辰";
                shengXiao.wuXing = "土";
                shengXiao.characteristics = "气势磅礴，志向远大";
                break;
            case "蛇":
                shengXiao.earthlyBranch = "巳";
                shengXiao.wuXing = "火";
                shengXiao.characteristics = "智慧深邃，洞察力强";
                break;
            case "马":
                shengXiao.earthlyBranch = "午";
                shengXiao.wuXing = "火";
                shengXiao.characteristics = "热情奔放，自由不羁";
                break;
            case "羊":
                shengXiao.earthlyBranch = "未";
                shengXiao.wuXing = "土";
                shengXiao.characteristics = "温顺善良，富有同情心";
                break;
            case "猴":
                shengXiao.earthlyBranch = "申";
                shengXiao.wuXing = "金";
                shengXiao.characteristics = "聪明机敏，多才多艺";
                break;
            case "鸡":
                shengXiao.earthlyBranch = "酉";
                shengXiao.wuXing = "金";
                shengXiao.characteristics = "勤奋认真，注重细节";
                break;
            case "狗":
                shengXiao.earthlyBranch = "戌";
                shengXiao.wuXing = "土";
                shengXiao.characteristics = "忠诚可靠，正义感强";
                break;
            case "猪":
                shengXiao.earthlyBranch = "亥";
                shengXiao.wuXing = "水";
                shengXiao.characteristics = "善良朴实，知足常乐";
                break;
            default:
                shengXiao.earthlyBranch = "未知";
                shengXiao.wuXing = "未知";
                shengXiao.characteristics = "未知";
                break;
        }
        
        return shengXiao;
    }
} 
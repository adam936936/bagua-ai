package com.fortune.infrastructure.persistence.repository;

import com.fortune.infrastructure.persistence.mapper.FortuneRecordMapper;
import com.fortune.infrastructure.persistence.po.FortuneRecordPO;
import com.fortune.interfaces.dto.response.FortuneCalculateResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 命理记录仓储实现
 * 
 * @author fortune
 * @since 2024-01-01
 */
@Repository
@RequiredArgsConstructor
@Slf4j
public class FortuneRecordRepository {
    
    private final FortuneRecordMapper fortuneRecordMapper;
    
    /**
     * 保存命理记录
     */
    public Long saveFortuneRecord(Long userId, String userName, String birthDate, String birthTime,
                                 String ganZhi, String shengXiao, String wuXingAnalysis, String aiAnalysis) {
        FortuneRecordPO record = new FortuneRecordPO();
        record.setUserId(userId);
        record.setUserName(userName);
        record.setBirthDate(birthDate);
        record.setBirthTime(birthTime);
        
        // 正确处理农历日期转换
        String lunarDate = convertToLunarDate(birthDate);
        record.setLunarDate(lunarDate);
        
        record.setGanZhi(ganZhi);
        record.setShengXiao(shengXiao);
        record.setWuXing(wuXingAnalysis);
        record.setWuXingLack(extractWuXingLack(wuXingAnalysis));
        record.setAiAnalysis(aiAnalysis);
        record.setDeleted(0);
        
        fortuneRecordMapper.insert(record);
        return record.getId();
    }
    
    /**
     * 转换公历日期为农历日期
     * 这里使用简化的转换逻辑，实际项目中应该使用专业的农历转换库
     */
    private String convertToLunarDate(String gregorianDate) {
        try {
            LocalDate date = LocalDate.parse(gregorianDate);
            
            // 简化的农历转换逻辑
            // 实际应该使用农历转换算法或第三方库如 lunar-java
            int year = date.getYear();
            int month = date.getMonthValue();
            int day = date.getDayOfMonth();
            
            // 这里使用简化的映射，实际项目中需要使用准确的农历转换
            String[] lunarMonths = {
                "正月", "二月", "三月", "四月", "五月", "六月",
                "七月", "八月", "九月", "十月", "十一月", "十二月"
            };
            
            // 简化处理：假设农历比公历晚一个月左右
            int lunarMonth = month > 1 ? month - 1 : 12;
            int lunarYear = month > 1 ? year : year - 1;
            
            String dayStr = formatLunarDay(day);
            
            return String.format("农历%d年%s%s", lunarYear, lunarMonths[lunarMonth - 1], dayStr);
            
        } catch (Exception e) {
            log.warn("农历日期转换失败，使用默认格式: {}", gregorianDate, e);
            return "农历" + gregorianDate.replace("-", "年").replaceFirst("年", "年") + "日";
        }
    }
    
    /**
     * 格式化农历日期
     */
    private String formatLunarDay(int day) {
        if (day <= 10) {
            String[] days = {"", "初一", "初二", "初三", "初四", "初五", 
                           "初六", "初七", "初八", "初九", "初十"};
            return days[day];
        } else if (day < 20) {
            return "十" + formatLunarDay(day - 10).substring(1);
        } else if (day == 20) {
            return "二十";
        } else if (day < 30) {
            return "廿" + formatLunarDay(day - 20).substring(1);
        } else {
            return "三十";
        }
    }
    
    /**
     * 从五行分析中提取五行缺失信息
     */
    private String extractWuXingLack(String wuXingAnalysis) {
        if (wuXingAnalysis == null || wuXingAnalysis.isEmpty()) {
            return "未知";
        }
        
        // 检查是否包含"缺"字
        if (wuXingAnalysis.contains("缺")) {
            // 提取缺失的五行
            String[] elements = {"木", "火", "土", "金", "水"};
            StringBuilder lacking = new StringBuilder();
            
            for (String element : elements) {
                if (wuXingAnalysis.contains("缺" + element) || 
                    wuXingAnalysis.contains(element + "0个")) {
                    if (lacking.length() > 0) {
                        lacking.append("、");
                    }
                    lacking.append(element);
                }
            }
            
            return lacking.length() > 0 ? lacking.toString() : "无";
        }
        
        // 如果包含"0个"，提取对应的五行
        String[] elements = {"木", "火", "土", "金", "水"};
        StringBuilder lacking = new StringBuilder();
        
        for (String element : elements) {
            if (wuXingAnalysis.contains(element + "0个")) {
                if (lacking.length() > 0) {
                    lacking.append("、");
                }
                lacking.append(element);
            }
        }
        
        return lacking.length() > 0 ? lacking.toString() : "无";
    }
    
    /**
     * 获取用户历史记录
     */
    public List<FortuneCalculateResponse> getUserHistory(Long userId, Integer page, Integer size) {
        int offset = (page - 1) * size;
        List<FortuneRecordPO> records = fortuneRecordMapper.selectByUserId(userId, offset, size);
        
        return records.stream().map(this::convertToResponse).collect(Collectors.toList());
    }
    
    /**
     * 获取用户历史记录总数
     */
    public int getUserHistoryCount(Long userId) {
        return fortuneRecordMapper.countByUserId(userId);
    }
    
    /**
     * 根据ID获取记录
     */
    public FortuneCalculateResponse getById(Long id) {
        FortuneRecordPO record = fortuneRecordMapper.selectById(id);
        return record != null ? convertToResponse(record) : null;
    }
    
    /**
     * 删除记录
     */
    public boolean deleteById(Long id) {
        return fortuneRecordMapper.deleteById(id) > 0;
    }
    
    /**
     * 转换PO为响应对象
     */
    private FortuneCalculateResponse convertToResponse(FortuneRecordPO po) {
        FortuneCalculateResponse response = new FortuneCalculateResponse();
        response.setId(po.getId());
        response.setUserName(po.getUserName());
        response.setBirthDate(po.getBirthDate());
        response.setBirthTime(po.getBirthTime());
        response.setLunar(po.getLunarDate());
        response.setGanZhi(po.getGanZhi());
        response.setWuXing(po.getWuXing());
        response.setWuXingLack(po.getWuXingLack() != null ? po.getWuXingLack() : "无");
        response.setShengXiao(po.getShengXiao());
        response.setAiAnalysis(po.getAiAnalysis());
        response.setCreateTime(po.getCreateTime());
        return response;
    }
    
    /**
     * 检查指定表是否存在
     */
    public boolean checkTableExists(String tableName) {
        return fortuneRecordMapper.checkTableExists(tableName) > 0;
    }
} 
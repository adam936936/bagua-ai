package com.fortune.infrastructure.persistence.repository;

import com.fortune.infrastructure.persistence.mapper.FortuneRecordMapper;
import com.fortune.infrastructure.persistence.po.FortuneRecordPO;
import com.fortune.interfaces.dto.response.FortuneCalculateResponse;
import lombok.RequiredArgsConstructor;
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
public class FortuneRecordRepository {
    
    private final FortuneRecordMapper fortuneRecordMapper;
    
    /**
     * 保存命理记录
     */
    public Long saveFortuneRecord(Long userId, String userName, String birthDate, String birthTime,
                                 String ganZhi, String shengXiao, String wuXingAnalysis, String aiAnalysis) {
        FortuneRecordPO record = new FortuneRecordPO();
        record.setUserId(userId);
        record.setName(userName);
        record.setGender(1); // 默认男性，实际应该从请求中获取
        
        // 解析出生日期
        LocalDate birth = LocalDate.parse(birthDate);
        record.setBirthYear(birth.getYear());
        record.setBirthMonth(birth.getMonthValue());
        record.setBirthDay(birth.getDayOfMonth());
        
        // 解析时辰（简化处理）
        record.setBirthHour(parseTimeToHour(birthTime));
        
        record.setGanZhi(ganZhi);
        record.setShengXiao(shengXiao);
        record.setWuXingAnalysis(wuXingAnalysis);
        record.setAiAnalysis(aiAnalysis);
        record.setDeleted(0);
        
        fortuneRecordMapper.insert(record);
        return record.getId();
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
        response.setUserName(po.getName());
        response.setBirthDate(String.format("%d-%02d-%02d", po.getBirthYear(), po.getBirthMonth(), po.getBirthDay()));
        response.setBirthTime(formatHourToTime(po.getBirthHour()));
        response.setLunar(formatLunar(po.getBirthYear(), po.getBirthMonth(), po.getBirthDay()));
        response.setGanZhi(po.getGanZhi());
        response.setWuXing(po.getWuXingAnalysis());
        response.setWuXingLack(""); // 从五行分析中提取，这里简化处理
        response.setShengXiao(po.getShengXiao());
        response.setAiAnalysis(po.getAiAnalysis());
        response.setCreateTime(po.getCreatedTime());
        return response;
    }
    
    /**
     * 解析时辰为小时
     */
    private Integer parseTimeToHour(String birthTime) {
        if (birthTime == null) return null;
        
        switch (birthTime) {
            case "子时": return 0;
            case "丑时": return 2;
            case "寅时": return 4;
            case "卯时": return 6;
            case "辰时": return 8;
            case "巳时": return 10;
            case "午时": return 12;
            case "未时": return 14;
            case "申时": return 16;
            case "酉时": return 18;
            case "戌时": return 20;
            case "亥时": return 22;
            default: return 0;
        }
    }
    
    /**
     * 将小时转换为时辰格式
     */
    private String formatHourToTime(Integer hour) {
        if (hour == null) return "未知时辰";
        
        switch (hour) {
            case 0: return "子时";
            case 2: return "丑时";
            case 4: return "寅时";
            case 6: return "卯时";
            case 8: return "辰时";
            case 10: return "巳时";
            case 12: return "午时";
            case 14: return "未时";
            case 16: return "申时";
            case 18: return "酉时";
            case 20: return "戌时";
            case 22: return "亥时";
            default: return "子时";
        }
    }
    
    /**
     * 格式化农历显示
     */
    private String formatLunar(Integer year, Integer month, Integer day) {
        if (year == null || month == null || day == null) {
            return "农历信息未知";
        }
        
        String[] lunarMonths = {"正月", "二月", "三月", "四月", "五月", "六月", 
                               "七月", "八月", "九月", "十月", "十一月", "十二月"};
        
        String monthStr = month > 0 && month <= 12 ? lunarMonths[month - 1] : "未知月";
        String dayStr = day < 10 ? "初" + day : 
                       day < 20 ? "十" + (day - 10) : 
                       day == 20 ? "二十" : "廿" + (day - 20);
        
        return String.format("农历%d年%s%s", year, monthStr, dayStr);
    }
} 
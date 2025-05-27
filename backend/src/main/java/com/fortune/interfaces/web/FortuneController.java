package com.fortune.interfaces.web;

import com.fortune.application.service.FortuneApplicationService;
import com.fortune.infrastructure.persistence.repository.FortuneRecordRepository;
import com.fortune.interfaces.dto.response.ApiResponse;
import com.fortune.interfaces.dto.response.FortuneCalculateResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 命理控制器
 * 
 * @author fortune
 * @since 2024-01-01
 */
@RestController
@RequestMapping("/fortune")
@RequiredArgsConstructor
@Slf4j
public class FortuneController {
    
    private final FortuneApplicationService fortuneApplicationService;
    private final FortuneRecordRepository fortuneRecordRepository;
    
    /**
     * 获取今日运势
     */
    @GetMapping("/today-fortune")
    public ApiResponse<String> getTodayFortune() {
        log.info("获取今日运势");
        
        try {
            String fortune = fortuneApplicationService.getTodayFortune();
            return ApiResponse.success(fortune);
        } catch (Exception e) {
            log.error("获取今日运势失败", e);
            return ApiResponse.error("获取今日运势失败：" + e.getMessage());
        }
    }
    
    /**
     * 八字测算
     */
    @PostMapping("/calculate")
    public ApiResponse<FortuneCalculateResponse> calculate(@RequestBody Map<String, Object> request) {
        log.info("开始八字测算，请求参数：{}", request);
        
        try {
            Long userId = Long.valueOf(request.get("userId").toString());
            String userName = (String) request.get("userName");
            String birthDate = (String) request.get("birthDate");
            String birthTime = (String) request.get("birthTime");
            
            // 调用应用服务进行计算（这里需要修改应用服务以支持数据库保存）
            // 暂时使用TestFortuneController的逻辑
            Map<String, Object> result = calculateFortune(userName, birthDate, birthTime);
            
            // 保存到数据库
            Long recordId = fortuneRecordRepository.saveFortuneRecord(
                userId, userName, birthDate, birthTime,
                (String) result.get("ganZhi"),
                (String) result.get("shengXiao"),
                (String) result.get("wuXing"),
                (String) result.get("aiAnalysis")
            );
            
            // 构建响应
            FortuneCalculateResponse response = new FortuneCalculateResponse();
            response.setId(recordId);
            response.setUserName(userName);
            response.setBirthDate(birthDate);
            response.setBirthTime(birthTime);
            response.setLunar((String) result.get("lunar"));
            response.setGanZhi((String) result.get("ganZhi"));
            response.setWuXing((String) result.get("wuXing"));
            response.setWuXingLack((String) result.get("wuXingLack"));
            response.setShengXiao((String) result.get("shengXiao"));
            response.setAiAnalysis((String) result.get("aiAnalysis"));
            response.setCreateTime(java.time.LocalDateTime.now());
            
            return ApiResponse.success(response);
            
        } catch (Exception e) {
            log.error("八字测算失败", e);
            return ApiResponse.error("八字测算失败：" + e.getMessage());
        }
    }
    
    /**
     * 获取用户历史记录
     */
    @GetMapping("/history/{userId}")
    public ApiResponse<Map<String, Object>> getHistory(@PathVariable Long userId,
                                                      @RequestParam(defaultValue = "1") Integer page,
                                                      @RequestParam(defaultValue = "10") Integer size) {
        log.info("获取用户历史记录，用户ID：{}，页码：{}，大小：{}", userId, page, size);
        
        try {
            List<FortuneCalculateResponse> records = fortuneRecordRepository.getUserHistory(userId, page, size);
            int total = fortuneRecordRepository.getUserHistoryCount(userId);
            
            Map<String, Object> data = new HashMap<>();
            data.put("list", records);
            data.put("total", total);
            data.put("page", page);
            data.put("size", size);
            data.put("totalPages", (total + size - 1) / size);
            
            return ApiResponse.success(data);
            
        } catch (Exception e) {
            log.error("获取用户历史记录失败，用户ID：{}", userId, e);
            return ApiResponse.error("获取历史记录失败：" + e.getMessage());
        }
    }
    
    /**
     * 删除历史记录
     */
    @DeleteMapping("/history/{recordId}")
    public ApiResponse<Void> deleteHistory(@PathVariable Long recordId) {
        log.info("删除历史记录，记录ID：{}", recordId);
        
        try {
            boolean success = fortuneRecordRepository.deleteById(recordId);
            if (success) {
                return ApiResponse.success();
            } else {
                return ApiResponse.error("删除失败，记录不存在");
            }
        } catch (Exception e) {
            log.error("删除历史记录失败，记录ID：{}", recordId, e);
            return ApiResponse.error("删除历史记录失败：" + e.getMessage());
        }
    }
    
    /**
     * 获取AI推荐姓名
     */
    @PostMapping("/recommend-names")
    public ApiResponse<java.util.List<String>> getRecommendNames(@RequestBody Map<String, Object> request) {
        log.info("获取AI推荐姓名，请求参数：{}", request);
        
        try {
            String userName = (String) request.get("userName");
            String birthDate = (String) request.get("birthDate");
            String birthTime = (String) request.get("birthTime");
            String wuXingLack = (String) request.get("wuXingLack");
            
            // 生成推荐姓名
            java.util.List<String> recommendedNames = generateRecommendNames(userName, birthDate, birthTime, wuXingLack);
            
            return ApiResponse.success(recommendedNames);
            
        } catch (Exception e) {
            log.error("获取AI推荐姓名失败", e);
            return ApiResponse.error("获取推荐姓名失败：" + e.getMessage());
        }
    }
    
    /**
     * 计算命理信息（临时方法，后续应该整合到应用服务中）
     */
    private Map<String, Object> calculateFortune(String userName, String birthDate, String birthTime) {
        // 这里复用TestFortuneController的计算逻辑
        // 实际应该重构到应用服务中
        
        java.time.LocalDate birth = java.time.LocalDate.parse(birthDate);
        int year = birth.getYear();
        int month = birth.getMonthValue();
        int day = birth.getDayOfMonth();
        
        Map<String, Object> result = new HashMap<>();
        
        // 简化的八字计算
        String ganZhi = calculateGanZhi(year, month, day, birthTime);
        String shengXiao = calculateShengXiao(year);
        String lunar = calculateLunar(year, month, day);
        String wuXing = "木2个 火1个 土2个 金1个 水2个"; // 简化处理
        String wuXingLack = "无"; // 简化处理
        String aiAnalysis = generateSimpleAnalysis(userName, ganZhi, shengXiao);
        
        result.put("ganZhi", ganZhi);
        result.put("shengXiao", shengXiao);
        result.put("lunar", lunar);
        result.put("wuXing", wuXing);
        result.put("wuXingLack", wuXingLack);
        result.put("aiAnalysis", aiAnalysis);
        
        return result;
    }
    
    private String calculateGanZhi(int year, int month, int day, String birthTime) {
        // 简化的干支计算
        String[] tianGan = {"甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"};
        String[] diZhi = {"子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"};
        
        int yearIndex = (year - 4) % 60;
        String yearGan = tianGan[yearIndex % 10];
        String yearZhi = diZhi[yearIndex % 12];
        
        int monthIndex = (month - 1) % 12;
        String monthGan = tianGan[(yearIndex * 2 + month) % 10];
        String monthZhi = diZhi[monthIndex];
        
        int dayIndex = (year * 365 + month * 30 + day) % 60;
        String dayGan = tianGan[dayIndex % 10];
        String dayZhi = diZhi[dayIndex % 12];
        
        String timeZhi = getTimeZhi(birthTime);
        int timeZhiIndex = java.util.Arrays.asList(diZhi).indexOf(timeZhi);
        String timeGan = tianGan[(dayIndex * 2 + timeZhiIndex) % 10];
        
        return String.format("%s%s %s%s %s%s %s%s", 
                           yearGan, yearZhi, monthGan, monthZhi, 
                           dayGan, dayZhi, timeGan, timeZhi);
    }
    
    private String getTimeZhi(String birthTime) {
        Map<String, String> timeMap = new HashMap<>();
        timeMap.put("子时", "子"); timeMap.put("丑时", "丑"); timeMap.put("寅时", "寅"); timeMap.put("卯时", "卯");
        timeMap.put("辰时", "辰"); timeMap.put("巳时", "巳"); timeMap.put("午时", "午"); timeMap.put("未时", "未");
        timeMap.put("申时", "申"); timeMap.put("酉时", "酉"); timeMap.put("戌时", "戌"); timeMap.put("亥时", "亥");
        return timeMap.getOrDefault(birthTime, "子");
    }
    
    private String calculateShengXiao(int year) {
        String[] shengXiao = {"鼠", "牛", "虎", "兔", "龙", "蛇", "马", "羊", "猴", "鸡", "狗", "猪"};
        return shengXiao[(year - 4) % 12];
    }
    
    private String calculateLunar(int year, int month, int day) {
        String[] lunarMonths = {"正月", "二月", "三月", "四月", "五月", "六月", 
                               "七月", "八月", "九月", "十月", "十一月", "十二月"};
        int lunarMonth = (month + 10) % 12;
        int lunarDay = (day + 15) % 30 + 1;
        return String.format("农历%d年%s%s", year, lunarMonths[lunarMonth], 
                           lunarDay < 10 ? "初" + lunarDay : 
                           lunarDay < 20 ? "十" + (lunarDay - 10) : 
                           lunarDay == 20 ? "二十" : "廿" + (lunarDay - 20));
    }
    
    private String generateSimpleAnalysis(String userName, String ganZhi, String shengXiao) {
        return String.format("%s，根据您的八字分析：\n\n" +
                           "您的天干地支为%s，生肖为%s。\n\n" +
                           "性格特点：您性格温和，待人真诚，具有很强的责任心和上进心。\n\n" +
                           "事业发展：事业运势较好，建议稳扎稳打，循序渐进。\n\n" +
                           "财运状况：财运平稳，正财运较好，建议理性投资。\n\n" +
                           "感情婚姻：感情运势良好，建议多沟通理解，真诚待人。\n\n" +
                           "人生建议：保持积极乐观的心态，多学习充实自己。",
                           userName, ganZhi, shengXiao);
    }
    
    /**
     * 生成推荐姓名
     */
    private java.util.List<String> generateRecommendNames(String userName, String birthDate, String birthTime, String wuXingLack) {
        java.util.List<String> firstNames = new java.util.ArrayList<>();
        
        // 提取用户姓氏（取第一个字符）
        String surname = userName != null && !userName.isEmpty() ? userName.substring(0, 1) : "李";
        
        // 根据五行缺失生成推荐名字（只取名字部分）
        if (wuXingLack != null && !wuXingLack.isEmpty() && !"无".equals(wuXingLack)) {
            if (wuXingLack.contains("木")) {
                firstNames.add("梓轩");
                firstNames.add("林峰");
                firstNames.add("森茂");
            } else if (wuXingLack.contains("火")) {
                firstNames.add("炎彬");
                firstNames.add("焱辉");
                firstNames.add("烨华");
            } else if (wuXingLack.contains("土")) {
                firstNames.add("坤宇");
                firstNames.add("培杰");
                firstNames.add("垚鑫");
            } else if (wuXingLack.contains("金")) {
                firstNames.add("锦程");
                firstNames.add("铭轩");
                firstNames.add("钰涵");
            } else if (wuXingLack.contains("水")) {
                firstNames.add("浩然");
                firstNames.add("润泽");
                firstNames.add("清源");
            }
        }
        
        // 如果没有缺失或者没有匹配到，提供通用推荐
        if (firstNames.isEmpty()) {
            firstNames.add("瑞祥");
            firstNames.add("嘉豪");
            firstNames.add("志远");
        }
        
        // 组合姓氏和名字，只返回3个
        java.util.List<String> fullNames = new java.util.ArrayList<>();
        for (int i = 0; i < Math.min(3, firstNames.size()); i++) {
            fullNames.add(surname + firstNames.get(i));
        }
        
        return fullNames;
    }
} 
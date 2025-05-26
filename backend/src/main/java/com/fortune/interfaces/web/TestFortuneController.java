package com.fortune.interfaces.web;

import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;
import java.util.Arrays;
import java.util.List;
import java.util.ArrayList;
import java.util.Date;

@RestController
@RequestMapping("/fortune")
public class TestFortuneController {
    
    // 天干
    private static final String[] TIAN_GAN = {"甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"};
    
    // 地支
    private static final String[] DI_ZHI = {"子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"};
    
    // 生肖
    private static final String[] SHENG_XIAO = {"鼠", "牛", "虎", "兔", "龙", "蛇", "马", "羊", "猴", "鸡", "狗", "猪"};
    
    // 五行
    private static final String[] WU_XING = {"木", "火", "土", "金", "水"};
    
    // 时辰对应地支
    private static final Map<String, String> TIME_TO_DIZHI = new HashMap<String, String>() {{
        put("子时", "子"); put("丑时", "丑"); put("寅时", "寅"); put("卯时", "卯");
        put("辰时", "辰"); put("巳时", "巳"); put("午时", "午"); put("未时", "未");
        put("申时", "申"); put("酉时", "酉"); put("戌时", "戌"); put("亥时", "亥");
    }};
    
    // 百家姓常用姓氏
    private static final String[] COMMON_SURNAMES = {"李", "王", "张", "刘", "陈", "杨", "赵", "黄"};
    
    // 模拟历史记录存储
    private static final Map<String, List<Map<String, Object>>> USER_HISTORY = new HashMap<>();
    
    @GetMapping("/today-fortune")
    public Map<String, Object> getTodayFortune() {
        Map<String, Object> result = new HashMap<>();
        result.put("code", 200);
        result.put("message", "success");
        result.put("data", "今日运势：大吉大利，万事如意！财运亨通，事业顺利，感情美满，健康平安。");
        result.put("timestamp", System.currentTimeMillis());
        return result;
    }
    
    @PostMapping("/calculate")
    public Map<String, Object> calculate(@RequestBody Map<String, Object> request) {
        Map<String, Object> result = new HashMap<>();
        result.put("code", 200);
        result.put("message", "success");
        
        String userName = (String) request.get("userName");
        String birthDate = (String) request.get("birthDate");
        String birthTime = (String) request.get("birthTime");
        
        // 解析出生日期
        LocalDate birth = LocalDate.parse(birthDate);
        int year = birth.getYear();
        int month = birth.getMonthValue();
        int day = birth.getDayOfMonth();
        
        // 计算八字
        Map<String, Object> baziResult = calculateBazi(year, month, day, birthTime);
        
        Map<String, Object> data = new HashMap<>();
        data.put("userName", userName);
        data.put("birthDate", birthDate);
        data.put("birthTime", birthTime);
        
        // 农历信息（简化计算）
        data.put("lunar", calculateLunar(year, month, day));
        
        // 生肖
        data.put("shengXiao", calculateShengXiao(year));
        
        // 八字信息
        data.put("ganZhi", baziResult.get("ganZhi"));
        data.put("tianGan", baziResult.get("tianGan"));
        data.put("diZhi", baziResult.get("diZhi"));
        
        // 五行分析
        Map<String, Object> wuxingAnalysis = analyzeWuXing(baziResult);
        data.put("wuXing", wuxingAnalysis.get("wuXing"));
        data.put("wuXingLack", wuxingAnalysis.get("lack"));
        data.put("wuXingStrong", wuxingAnalysis.get("strong"));
        
        // AI分析报告
        data.put("aiAnalysis", generateAiAnalysis(userName, baziResult, wuxingAnalysis));
        
        // 其他信息
        data.put("luckyNumbers", calculateLuckyNumbers(baziResult));
        data.put("luckyColors", calculateLuckyColors(wuxingAnalysis));
        data.put("suggestion", generateSuggestion(wuxingAnalysis));
        
        result.put("data", data);
        result.put("timestamp", System.currentTimeMillis());
        return result;
    }
    
    private Map<String, Object> calculateBazi(int year, int month, int day, String birthTime) {
        Map<String, Object> result = new HashMap<>();
        
        // 年柱计算（简化）
        int yearIndex = (year - 4) % 60;
        String yearGan = TIAN_GAN[yearIndex % 10];
        String yearZhi = DI_ZHI[yearIndex % 12];
        
        // 月柱计算（简化）
        int monthIndex = (month - 1) % 12;
        String monthGan = TIAN_GAN[(yearIndex * 2 + month) % 10];
        String monthZhi = DI_ZHI[monthIndex];
        
        // 日柱计算（简化）
        int dayIndex = (year * 365 + month * 30 + day) % 60;
        String dayGan = TIAN_GAN[dayIndex % 10];
        String dayZhi = DI_ZHI[dayIndex % 12];
        
        // 时柱计算
        String timeZhi = TIME_TO_DIZHI.getOrDefault(birthTime, "子");
        int timeZhiIndex = Arrays.asList(DI_ZHI).indexOf(timeZhi);
        String timeGan = TIAN_GAN[(dayIndex * 2 + timeZhiIndex) % 10];
        
        String ganZhi = yearGan + yearZhi + " " + monthGan + monthZhi + " " + dayGan + dayZhi + " " + timeGan + timeZhi;
        
        result.put("ganZhi", ganZhi);
        result.put("tianGan", Arrays.asList(yearGan, monthGan, dayGan, timeGan));
        result.put("diZhi", Arrays.asList(yearZhi, monthZhi, dayZhi, timeZhi));
        result.put("year", yearGan + yearZhi);
        result.put("month", monthGan + monthZhi);
        result.put("day", dayGan + dayZhi);
        result.put("time", timeGan + timeZhi);
        
        return result;
    }
    
    private String calculateLunar(int year, int month, int day) {
        // 简化的农历计算，实际应该使用专业的农历转换算法
        String[] lunarMonths = {"正月", "二月", "三月", "四月", "五月", "六月", 
                               "七月", "八月", "九月", "十月", "十一月", "十二月"};
        int lunarMonth = (month + 10) % 12;
        int lunarDay = (day + 15) % 30 + 1;
        return String.format("%s%s", lunarMonths[lunarMonth], 
                           lunarDay < 10 ? "初" + lunarDay : 
                           lunarDay < 20 ? "十" + (lunarDay - 10) : 
                           lunarDay == 20 ? "二十" : "廿" + (lunarDay - 20));
    }
    
    private String calculateShengXiao(int year) {
        return SHENG_XIAO[(year - 4) % 12];
    }
    
    private Map<String, Object> analyzeWuXing(Map<String, Object> baziResult) {
        Map<String, Object> result = new HashMap<>();
        
        // 天干五行对应
        Map<String, String> ganWuXing = new HashMap<String, String>() {{
            put("甲", "木"); put("乙", "木"); put("丙", "火"); put("丁", "火");
            put("戊", "土"); put("己", "土"); put("庚", "金"); put("辛", "金");
            put("壬", "水"); put("癸", "水");
        }};
        
        // 地支五行对应
        Map<String, String> zhiWuXing = new HashMap<String, String>() {{
            put("子", "水"); put("丑", "土"); put("寅", "木"); put("卯", "木");
            put("辰", "土"); put("巳", "火"); put("午", "火"); put("未", "土");
            put("申", "金"); put("酉", "金"); put("戌", "土"); put("亥", "水");
        }};
        
        @SuppressWarnings("unchecked")
        List<String> tianGan = (List<String>) baziResult.get("tianGan");
        @SuppressWarnings("unchecked")
        List<String> diZhi = (List<String>) baziResult.get("diZhi");
        
        // 统计五行
        Map<String, Integer> wuxingCount = new HashMap<>();
        for (String wx : WU_XING) {
            wuxingCount.put(wx, 0);
        }
        
        // 统计天干五行
        for (String gan : tianGan) {
            String wx = ganWuXing.get(gan);
            if (wx != null) {
                wuxingCount.put(wx, wuxingCount.get(wx) + 1);
            }
        }
        
        // 统计地支五行
        for (String zhi : diZhi) {
            String wx = zhiWuXing.get(zhi);
            if (wx != null) {
                wuxingCount.put(wx, wuxingCount.get(wx) + 1);
            }
        }
        
        // 找出缺失和旺盛的五行
        String lack = "";
        String strong = "";
        int minCount = Integer.MAX_VALUE;
        int maxCount = 0;
        
        for (Map.Entry<String, Integer> entry : wuxingCount.entrySet()) {
            if (entry.getValue() == 0) {
                lack += entry.getKey();
            }
            if (entry.getValue() < minCount) {
                minCount = entry.getValue();
            }
            if (entry.getValue() > maxCount) {
                maxCount = entry.getValue();
                strong = entry.getKey();
            }
        }
        
        if (lack.isEmpty()) {
            for (Map.Entry<String, Integer> entry : wuxingCount.entrySet()) {
                if (entry.getValue() == minCount) {
                    lack = entry.getKey();
                    break;
                }
            }
        }
        
        result.put("wuXing", wuxingCount);
        result.put("lack", lack);
        result.put("strong", strong);
        
        return result;
    }
    
    private String generateAiAnalysis(String userName, Map<String, Object> baziResult, Map<String, Object> wuxingAnalysis) {
        StringBuilder analysis = new StringBuilder();
        
        analysis.append(userName).append("，根据您的八字分析：\n\n");
        analysis.append("【八字信息】\n");
        analysis.append("八字：").append(baziResult.get("ganZhi")).append("\n");
        analysis.append("年柱：").append(baziResult.get("year")).append("\n");
        analysis.append("月柱：").append(baziResult.get("month")).append("\n");
        analysis.append("日柱：").append(baziResult.get("day")).append("\n");
        analysis.append("时柱：").append(baziResult.get("time")).append("\n\n");
        
        analysis.append("【五行分析】\n");
        String lack = (String) wuxingAnalysis.get("lack");
        String strong = (String) wuxingAnalysis.get("strong");
        
        if (!lack.isEmpty()) {
            analysis.append("五行缺：").append(lack).append("\n");
            analysis.append("建议：可通过佩戴").append(getWuxingColor(lack)).append("色饰品或从事相关行业来补充").append(lack).append("元素。\n");
        }
        
        if (!strong.isEmpty()) {
            analysis.append("五行旺：").append(strong).append("\n");
            analysis.append("优势：").append(getWuxingAdvantage(strong)).append("\n");
        }
        
        analysis.append("\n【性格特征】\n");
        analysis.append(getPersonalityAnalysis(strong, lack));
        
        analysis.append("\n【运势建议】\n");
        analysis.append("今年整体运势平稳，适合稳扎稳打。在事业上要把握机会，在感情上要真诚待人。");
        analysis.append("建议多行善事，积德行善，必有好报。");
        
        return analysis.toString();
    }
    
    private String getWuxingColor(String wuxing) {
        Map<String, String> colors = new HashMap<String, String>() {{
            put("木", "绿"); put("火", "红"); put("土", "黄"); put("金", "白"); put("水", "黑");
        }};
        return colors.getOrDefault(wuxing, "");
    }
    
    private String getWuxingAdvantage(String wuxing) {
        Map<String, String> advantages = new HashMap<String, String>() {{
            put("木", "富有创造力，善于成长发展，具有仁慈之心");
            put("火", "热情开朗，具有领导才能，善于表达");
            put("土", "稳重踏实，值得信赖，具有包容心");
            put("金", "意志坚强，做事果断，具有正义感");
            put("水", "聪明智慧，适应能力强，善于变通");
        }};
        return advantages.getOrDefault(wuxing, "");
    }
    
    private String getPersonalityAnalysis(String strong, String lack) {
        StringBuilder personality = new StringBuilder();
        
        if (!strong.isEmpty()) {
            personality.append("您的性格中").append(strong).append("元素较强，");
            personality.append(getWuxingAdvantage(strong)).append("。");
        }
        
        if (!lack.isEmpty()) {
            personality.append("但").append(lack).append("元素相对较弱，建议在日常生活中多培养相关特质。");
        }
        
        return personality.toString();
    }
    
    private int[] calculateLuckyNumbers(Map<String, Object> baziResult) {
        // 根据八字计算幸运数字（简化算法）
        String ganZhi = (String) baziResult.get("ganZhi");
        int hash = ganZhi.hashCode();
        return new int[]{
            Math.abs(hash % 10) + 1,
            Math.abs((hash / 10) % 10) + 1,
            Math.abs((hash / 100) % 10) + 1,
            Math.abs((hash / 1000) % 10) + 1,
            Math.abs((hash / 10000) % 10) + 1
        };
    }
    
    private String[] calculateLuckyColors(Map<String, Object> wuxingAnalysis) {
        String lack = (String) wuxingAnalysis.get("lack");
        String strong = (String) wuxingAnalysis.get("strong");
        
        Map<String, String[]> wuxingColors = new HashMap<String, String[]>() {{
            put("木", new String[]{"绿色", "青色", "翠绿"});
            put("火", new String[]{"红色", "橙色", "紫色"});
            put("土", new String[]{"黄色", "棕色", "土黄"});
            put("金", new String[]{"白色", "金色", "银色"});
            put("水", new String[]{"黑色", "蓝色", "深蓝"});
        }};
        
        if (!lack.isEmpty() && wuxingColors.containsKey(lack)) {
            return wuxingColors.get(lack);
        } else if (!strong.isEmpty() && wuxingColors.containsKey(strong)) {
            return wuxingColors.get(strong);
        }
        
        return new String[]{"金色", "蓝色", "白色"};
    }
    
    private String generateSuggestion(Map<String, Object> wuxingAnalysis) {
        String lack = (String) wuxingAnalysis.get("lack");
        
        if (!lack.isEmpty()) {
            Map<String, String> suggestions = new HashMap<String, String>() {{
                put("木", "建议多接触大自然，从事创意类工作，培养耐心和包容心。");
                put("火", "建议多参与社交活动，培养热情和积极的态度，适合从事教育或销售工作。");
                put("土", "建议培养稳重的性格，从事实业或管理工作，注重诚信和责任感。");
                put("金", "建议培养果断的决策能力，从事金融或技术工作，注重原则和正义。");
                put("水", "建议多学习新知识，培养灵活的思维，适合从事研究或咨询工作。");
            }};
            return suggestions.getOrDefault(lack, "建议保持平和心态，多行善事，积德行善。");
        }
        
        return "您的五行较为平衡，建议继续保持，多行善事，积德行善。";
    }
    
    @GetMapping("/test")
    public Map<String, Object> test() {
        Map<String, Object> result = new HashMap<>();
        result.put("message", "Test endpoint working!");
        result.put("timestamp", System.currentTimeMillis());
        return result;
    }
    
    @PostMapping("/recommend-names")
    public Map<String, Object> recommendNames(@RequestBody Map<String, Object> request) {
        Map<String, Object> result = new HashMap<>();
        result.put("code", 200);
        result.put("message", "success");
        
        String surname = (String) request.get("surname");
        String wuXingLack = (String) request.get("wuXingLack");
        String gender = (String) request.get("gender");
        
        // 根据五行缺失推荐姓名
        List<Map<String, Object>> names = new ArrayList<>();
        
        // 根据五行缺失生成推荐姓名
        String[] maleNames = {"浩然", "志强", "建华", "明辉", "俊杰"};
        String[] femaleNames = {"雅静", "美丽", "婷婷", "晓雯", "思琪"};
        String[] namePool = "男".equals(gender) ? maleNames : femaleNames;
        
        for (int i = 0; i < 3; i++) {
            Map<String, Object> nameInfo = new HashMap<>();
            nameInfo.put("name", surname + namePool[i % namePool.length]);
            nameInfo.put("score", 85 + (i * 5));
            nameInfo.put("meaning", "此名寓意美好，五行搭配合理");
            names.add(nameInfo);
        }
        
        result.put("data", names);
        return result;
    }
    
    @GetMapping("/common-surnames")
    public Map<String, Object> getCommonSurnames() {
        Map<String, Object> result = new HashMap<>();
        result.put("code", 200);
        result.put("message", "success");
        result.put("data", COMMON_SURNAMES);
        return result;
    }
    
    @GetMapping("/history/{userId}")
    public Map<String, Object> getHistory(@PathVariable String userId, 
                                        @RequestParam(defaultValue = "1") int page,
                                        @RequestParam(defaultValue = "10") int size) {
        Map<String, Object> result = new HashMap<>();
        result.put("code", 200);
        result.put("message", "success");
        
        // 获取用户历史记录
        List<Map<String, Object>> userHistory = USER_HISTORY.getOrDefault(userId, new ArrayList<>());
        
        // 分页处理
        int start = (page - 1) * size;
        int end = Math.min(start + size, userHistory.size());
        List<Map<String, Object>> pageData = new ArrayList<>();
        
        if (start < userHistory.size()) {
            pageData = userHistory.subList(start, end);
        }
        
        Map<String, Object> data = new HashMap<>();
        data.put("list", pageData);
        data.put("total", userHistory.size());
        data.put("page", page);
        data.put("size", size);
        
        result.put("data", data);
        return result;
    }
    
    @PostMapping("/save-history")
    public Map<String, Object> saveHistory(@RequestBody Map<String, Object> request) {
        Map<String, Object> result = new HashMap<>();
        result.put("code", 200);
        result.put("message", "success");
        
        String userId = (String) request.get("userId");
        Map<String, Object> historyItem = new HashMap<>();
        historyItem.put("id", System.currentTimeMillis());
        historyItem.put("userName", request.get("userName"));
        historyItem.put("birthDate", request.get("birthDate"));
        historyItem.put("birthTime", request.get("birthTime"));
        historyItem.put("result", request.get("result"));
        historyItem.put("createTime", new Date());
        
        // 保存到用户历史记录
        USER_HISTORY.computeIfAbsent(userId, k -> new ArrayList<>()).add(0, historyItem);
        
        // 限制历史记录数量（最多保存100条）
        List<Map<String, Object>> userHistory = USER_HISTORY.get(userId);
        if (userHistory.size() > 100) {
            userHistory.subList(100, userHistory.size()).clear();
        }
        
        result.put("data", historyItem);
        return result;
    }
} 
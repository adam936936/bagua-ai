package com.fortune.infrastructure.external;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.fortune.interfaces.dto.response.NameRecommendationResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.time.Duration;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * DeepSeek AI服务
 * 
 * @author fortune
 * @since 2024-01-01
 */
@Slf4j
@Service
public class DeepSeekService {
    
    @Value("${fortune.deepseek.api-url}")
    private String apiUrl;
    
    @Value("${fortune.deepseek.api-key}")
    private String apiKey;
    
    @Value("${fortune.deepseek.model}")
    private String model;
    
    @Value("${fortune.deepseek.max-tokens}")
    private Integer maxTokens;
    
    @Value("${fortune.deepseek.temperature}")
    private Double temperature;
    
    @Value("${fortune.deepseek.mock-mode:false}")
    private Boolean mockMode;
    
    private final RestTemplate restTemplate;
    
    // 今日运势缓存
    private final Map<String, String> todayFortuneCache = new ConcurrentHashMap<>();
    private String lastFortuneCacheDate = "";
    
    public DeepSeekService() {
        this.restTemplate = new RestTemplate();
        // 设置超时时间为5秒
        this.restTemplate.getMessageConverters().forEach(converter -> {
            if (converter instanceof org.springframework.http.converter.StringHttpMessageConverter) {
                ((org.springframework.http.converter.StringHttpMessageConverter) converter).setDefaultCharset(java.nio.charset.StandardCharsets.UTF_8);
            }
        });
    }
    
    /**
     * 生成命理分析
     */
    public String generateFortuneAnalysis(String ganZhi, String wuXing, String wuXingLack, String shengXiao) {
        System.out.println("调用DeepSeek生成命理分析，天干地支：" + ganZhi + "，五行：" + wuXing + "，五行缺失：" + wuXingLack + "，生肖：" + shengXiao);
        
        String prompt = buildFortuneAnalysisPrompt(ganZhi, wuXing, wuXingLack, shengXiao);
        
        try {
            String response = callDeepSeekApi(prompt);
            System.out.println("DeepSeek命理分析响应：" + response);
            return response;
        } catch (Exception e) {
            System.err.println("调用DeepSeek生成命理分析失败: " + e.getMessage());
            return generateDefaultFortuneAnalysis(ganZhi, wuXing, wuXingLack, shengXiao);
        }
    }
    
    /**
     * 生成姓名推荐
     */
    public List<NameRecommendationResponse> generateNameRecommendations(String wuXingLack, String ganZhi, String surname) {
        System.out.println("调用DeepSeek生成姓名推荐，五行缺失：" + wuXingLack + "，天干地支：" + ganZhi + "，姓氏：" + surname);
        
        String prompt = buildNameRecommendationPrompt(wuXingLack, ganZhi, surname);
        
        try {
            String response = callDeepSeekApi(prompt);
            System.out.println("DeepSeek姓名推荐响应：" + response);
            return parseNameRecommendations(response);
        } catch (Exception e) {
            System.err.println("调用DeepSeek生成姓名推荐失败: " + e.getMessage());
            return generateDefaultNameRecommendations(wuXingLack, surname);
        }
    }
    
    /**
     * 生成今日运势（带缓存）
     */
    public String getTodayFortune() {
        System.out.println("调用DeepSeek生成今日运势");
        
        String today = LocalDate.now().toString();
        
        // 检查缓存
        if (today.equals(lastFortuneCacheDate) && todayFortuneCache.containsKey(today)) {
            System.out.println("使用今日运势缓存");
            return todayFortuneCache.get(today);
        }
        
        // 清理过期缓存
        if (!today.equals(lastFortuneCacheDate)) {
            todayFortuneCache.clear();
            lastFortuneCacheDate = today;
        }
        
        String prompt = "请生成一段今日运势分析，包含事业、财运、感情、健康等方面的建议，语言要温馨正面，字数控制在200字以内。";
        
        try {
            String response = callDeepSeekApiWithTimeout(prompt, 5000); // 5秒超时
            System.out.println("DeepSeek今日运势响应：" + response);
            
            // 缓存结果
            todayFortuneCache.put(today, response);
            return response;
        } catch (Exception e) {
            System.err.println("调用DeepSeek生成今日运势失败: " + e.getMessage());
            String defaultFortune = generateDefaultTodayFortune();
            
            // 缓存默认结果
            todayFortuneCache.put(today, defaultFortune);
            return defaultFortune;
        }
    }
    
    /**
     * 调用DeepSeek API（带超时）
     */
    private String callDeepSeekApiWithTimeout(String prompt, int timeoutMs) {
        // 如果启用模拟模式，直接返回模拟数据
        if (mockMode) {
            System.out.println("模拟模式：跳过DeepSeek API调用");
            return generateMockResponse(prompt);
        }
        
        // 构建请求体
        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("model", model);
        requestBody.put("max_tokens", maxTokens);
        requestBody.put("temperature", temperature);
        
        List<Map<String, String>> messages = new ArrayList<>();
        Map<String, String> message = new HashMap<>();
        message.put("role", "user");
        message.put("content", prompt);
        messages.add(message);
        requestBody.put("messages", messages);
        
        // 设置请求头
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(apiKey);
        
        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);
        
        // 创建带超时的RestTemplate
        RestTemplate timeoutRestTemplate = new RestTemplate();
        timeoutRestTemplate.setRequestFactory(new org.springframework.http.client.SimpleClientHttpRequestFactory() {{
            setConnectTimeout(timeoutMs);
            setReadTimeout(timeoutMs);
        }});
        
        // 发送请求
        ResponseEntity<String> response = timeoutRestTemplate.postForEntity(apiUrl, entity, String.class);
        
        if (response.getStatusCode() == HttpStatus.OK) {
            JSONObject jsonResponse = JSON.parseObject(response.getBody());
            JSONArray choices = jsonResponse.getJSONArray("choices");
            if (choices != null && choices.size() > 0) {
                JSONObject choice = choices.getJSONObject(0);
                JSONObject messageObj = choice.getJSONObject("message");
                return messageObj.getString("content");
            }
        }
        
        throw new RuntimeException("DeepSeek API调用失败");
    }
    
    /**
     * 调用DeepSeek API
     */
    private String callDeepSeekApi(String prompt) {
        return callDeepSeekApiWithTimeout(prompt, 30000); // 默认30秒超时
    }
    
    /**
     * 生成默认今日运势
     */
    private String generateDefaultTodayFortune() {
        String[] fortunes = {
            "【今日运势】🌟\n\n**事业**：今天思维敏捷，适合处理复杂问题，团队合作顺利，有望获得上级认可。\n\n**财运**：正财运佳，可能有意外收入，但需谨慎投资，避免冲动消费。\n\n**感情**：单身者桃花运旺，有机会遇到心仪对象；有伴者感情稳定，适合深入交流。\n\n**健康**：精神状态良好，注意劳逸结合，适量运动有助身心健康。\n\n✨ **幸运提示**：保持积极心态，好运自然来！",
            "【今日运势】🌞\n\n**事业**：今天灵感充沛，适合推进创意项目，团队合作也会格外顺利。保持开放心态，机会可能来自意想不到的地方。\n\n**财运**：小有惊喜的一天，或许有额外收入或礼物。但消费需理性，避免冲动购物，长远规划更有利。\n\n**感情**：单身者易遇暖心互动，不妨主动表达好感；有伴侣者适合安排浪漫约会，细节最能打动人心。\n\n**健康**：注意劳逸结合，久坐后记得伸展身体。午后一杯花茶能舒缓压力，保持好心情是关键。\n\n✨ **幸运小贴士**：微笑会为你吸引好运，今天记得多分享快乐哦！",
            "【今日运势】🍀\n\n**事业**：今天你充满能量，适合推进重要项目，团队合作会带来惊喜。保持积极沟通，灵感可能在不经意间闪现。\n\n**财运**：财务上有小惊喜，可能是额外收入或意外节省。理性消费的同时，不妨犒劳自己一下。\n\n**感情**：单身者有机会遇到有趣的人，放松心态展现真我。有伴者适合制造浪漫，小小举动能让感情升温。\n\n**健康**：注意劳逸结合，久坐后记得活动身体。一杯温水、一段散步，都能让你焕发活力。\n\n✨ **幸运小贴士**：今天适合穿亮色衣物，笑容会为你吸引好运！"
        };
        
        // 根据日期选择不同的运势
        int index = LocalDate.now().getDayOfYear() % fortunes.length;
        return fortunes[index];
    }
    
    /**
     * 生成模拟响应
     */
    private String generateMockResponse(String prompt) {
        if (prompt.contains("今日运势")) {
            return "【今日运势】🌟\n\n**事业**：今天思维敏捷，适合处理复杂问题，团队合作顺利，有望获得上级认可。\n\n**财运**：正财运佳，可能有意外收入，但需谨慎投资，避免冲动消费。\n\n**感情**：单身者桃花运旺，有机会遇到心仪对象；有伴者感情稳定，适合深入交流。\n\n**健康**：精神状态良好，注意劳逸结合，适量运动有助身心健康。\n\n✨ **幸运提示**：保持积极心态，好运自然来！";
        } else if (prompt.contains("命理分析")) {
            return "### 1. 性格特点\n您性格温和善良，心思细腻，富有同情心。具有很强的直觉力和洞察力，善于理解他人，人际关系和谐。\n\n### 2. 事业发展\n适合从事文化、教育、咨询或服务类工作。具备领导才能，但更适合幕后策划。建议发挥创意优势，稳步发展。\n\n### 3. 财运状况\n财运平稳，正财运较好，适合稳健投资。中年后财富积累会更加顺利，建议合理规划财务。\n\n### 4. 感情婚姻\n感情运势良好，容易获得异性好感。建议真诚待人，注重精神层面的交流，婚姻生活会很幸福。\n\n### 5. 健康状况\n整体健康状况良好，需注意情绪管理，保持规律作息，适度运动增强体质。\n\n### 6. 人生建议\n发挥自身优势，保持学习心态，多与正能量的人交往，人生道路会越走越宽广。";
        } else if (prompt.contains("推荐") && prompt.contains("姓名")) {
            // 从prompt中提取姓氏
            String surname = "李"; // 默认姓氏
            if (prompt.contains("姓氏：")) {
                int start = prompt.indexOf("姓氏：") + 3;
                int end = prompt.indexOf("\n", start);
                if (end == -1) end = prompt.length();
                surname = prompt.substring(start, end).trim();
            }
            
            return String.format("[\n" +
                "  {\n" +
                "    \"name\": \"%s瑞祥\",\n" +
                "    \"reason\": \"瑞祥寓意吉祥如意，五行属金，能够补充缺失的五行，带来好运\",\n" +
                "    \"score\": 88,\n" +
                "    \"wuXing\": \"金\"\n" +
                "  },\n" +
                "  {\n" +
                "    \"name\": \"%s嘉豪\",\n" +
                "    \"reason\": \"嘉豪寓意品德高尚、气度不凡，五行属木，有助于平衡五行\",\n" +
                "    \"score\": 85,\n" +
                "    \"wuXing\": \"木\"\n" +
                "  },\n" +
                "  {\n" +
                "    \"name\": \"%s志远\",\n" +
                "    \"reason\": \"志远寓意志向远大，五行属火，能够增强事业运势\",\n" +
                "    \"score\": 87,\n" +
                "    \"wuXing\": \"火\"\n" +
                "  }\n" +
                "]", surname, surname, surname);
        } else {
            return "感谢您的咨询，这是一个模拟响应。在实际应用中，这里会返回AI生成的专业内容。";
        }
    }
    
    /**
     * 构建命理分析提示词
     */
    private String buildFortuneAnalysisPrompt(String ganZhi, String wuXing, String wuXingLack, String shengXiao) {
        return String.format(
            "请根据以下八字信息进行专业的命理分析：\n" +
            "天干地支：%s\n" +
            "五行属性：%s\n" +
            "五行缺失：%s\n" +
            "生肖：%s\n\n" +
            "请从以下几个方面进行分析：\n" +
            "1. 性格特点\n" +
            "2. 事业发展\n" +
            "3. 财运状况\n" +
            "4. 感情婚姻\n" +
            "5. 健康状况\n" +
            "6. 人生建议\n\n" +
            "要求：语言通俗易懂，积极正面，字数控制在300字以内。",
            ganZhi, wuXing, wuXingLack, shengXiao
        );
    }
    
    /**
     * 构建姓名推荐提示词
     */
    private String buildNameRecommendationPrompt(String wuXingLack, String ganZhi, String surname) {
        String surnameText = (surname != null && !surname.isEmpty()) ? "姓氏：" + surname : "不限姓氏";
        
        return String.format(
            "请根据以下信息推荐3个适合的姓名：\n" +
            "五行缺失：%s\n" +
            "天干地支：%s\n" +
            "%s\n\n" +
            "要求：\n" +
            "1. 推荐的名字要能补充缺失的五行\n" +
            "2. 寓意要美好积极\n" +
            "3. 读音要朗朗上口\n" +
            "4. 请按照以下JSON格式返回：\n" +
            "[\n" +
            "  {\n" +
            "    \"name\": \"推荐姓名\",\n" +
            "    \"reason\": \"推荐理由\",\n" +
            "    \"score\": 评分(1-100),\n" +
            "    \"wuXing\": \"五行属性\"\n" +
            "  }\n" +
            "]",
            wuXingLack, ganZhi, surnameText
        );
    }
    
    /**
     * 解析姓名推荐响应
     */
    private List<NameRecommendationResponse> parseNameRecommendations(String response) {
        try {
            // 清理响应文本，提取JSON部分
            String cleanedResponse = cleanJsonResponse(response);
            log.info("清理后的JSON响应: {}", cleanedResponse);
            
            // 尝试解析JSON格式的响应
            JSONArray jsonArray = JSON.parseArray(cleanedResponse);
            List<NameRecommendationResponse> recommendations = new ArrayList<>();
            
            for (int i = 0; i < jsonArray.size(); i++) {
                JSONObject item = jsonArray.getJSONObject(i);
                NameRecommendationResponse recommendation = NameRecommendationResponse.builder()
                        .name(item.getString("name"))
                        .reason(item.getString("reason"))
                        .score(item.getInteger("score"))
                        .wuXing(item.getString("wuXing"))
                        .build();
                recommendations.add(recommendation);
            }
            
            return recommendations;
        } catch (Exception e) {
            log.warn("解析姓名推荐响应失败，使用默认解析", e);
            return parseNameRecommendationsFromText(response);
        }
    }
    
    /**
     * 清理JSON响应，提取有效的JSON部分
     */
    private String cleanJsonResponse(String response) {
        if (response == null || response.trim().isEmpty()) {
            return "[]";
        }
        
        // 移除markdown代码块标记
        String cleaned = response.replaceAll("```json\\s*", "").replaceAll("```\\s*", "");
        
        // 查找JSON数组的开始和结束位置
        int startIndex = cleaned.indexOf('[');
        int endIndex = cleaned.lastIndexOf(']');
        
        if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
            cleaned = cleaned.substring(startIndex, endIndex + 1);
        }
        
        // 移除多余的空白字符和换行符
        cleaned = cleaned.replaceAll("\\s+", " ").trim();
        
        // 修复常见的JSON格式问题
        cleaned = cleaned.replaceAll(",\\s*}", "}"); // 移除对象末尾多余的逗号
        cleaned = cleaned.replaceAll(",\\s*]", "]");  // 移除数组末尾多余的逗号
        
        return cleaned;
    }
    
    /**
     * 从文本中解析姓名推荐
     */
    private List<NameRecommendationResponse> parseNameRecommendationsFromText(String response) {
        List<NameRecommendationResponse> recommendations = new ArrayList<>();
        
        // 简单的文本解析逻辑
        String[] lines = response.split("\n");
        for (String line : lines) {
            if (line.contains("推荐") || line.contains("姓名")) {
                NameRecommendationResponse recommendation = NameRecommendationResponse.builder()
                        .name("智慧")
                        .reason("寓意聪明智慧，五行属水，能够补充缺失的五行")
                        .score(85)
                        .wuXing("水")
                        .build();
                recommendations.add(recommendation);
                break;
            }
        }
        
        if (recommendations.isEmpty()) {
            recommendations.add(NameRecommendationResponse.builder()
                    .name("瑞祥")
                    .reason("寓意吉祥如意，五行平衡")
                    .score(88)
                    .wuXing("金")
                    .build());
        }
        
        return recommendations;
    }
    
    /**
     * 生成默认命理分析
     */
    private String generateDefaultFortuneAnalysis(String ganZhi, String wuXing, String wuXingLack, String shengXiao) {
        return String.format(
            "根据您的八字信息分析：\n\n" +
            "您的天干地支为%s，五行属性为%s，生肖为%s。\n\n" +
            "性格特点：您性格温和，待人真诚，具有很强的责任心和上进心。\n\n" +
            "事业发展：事业运势较好，适合从事与%s相关的行业，建议稳扎稳打，循序渐进。\n\n" +
            "财运状况：财运平稳，正财运较好，建议理性投资，避免投机。\n\n" +
            "感情婚姻：感情运势良好，建议多沟通理解，真诚待人。\n\n" +
            "健康状况：整体健康状况良好，注意%s方面的保养。\n\n" +
            "人生建议：保持积极乐观的心态，多学习充实自己，机会总是留给有准备的人。",
            ganZhi, wuXing, shengXiao, wuXing, 
            wuXingLack.isEmpty() ? "身体各方面" : wuXingLack + "相关器官"
        );
    }
    
    /**
     * 生成默认姓名推荐
     */
    private List<NameRecommendationResponse> generateDefaultNameRecommendations(String wuXingLack, String surname) {
        List<NameRecommendationResponse> recommendations = new ArrayList<>();
        
        // 如果没有提供姓氏，使用默认姓氏
        String actualSurname = (surname != null && !surname.isEmpty()) ? surname : "李";
        
        recommendations.add(NameRecommendationResponse.builder()
                .name(actualSurname + "瑞祥")
                .reason("瑞祥寓意吉祥如意，五行属金，能够补充缺失的五行，带来好运")
                .score(88)
                .wuXing("金")
                .build());
                
        recommendations.add(NameRecommendationResponse.builder()
                .name(actualSurname + "嘉豪")
                .reason("嘉豪寓意品德高尚、气度不凡，五行属木，有助于平衡五行")
                .score(85)
                .wuXing("木")
                .build());
                
        recommendations.add(NameRecommendationResponse.builder()
                .name(actualSurname + "志远")
                .reason("志远寓意志向远大，五行属火，能够增强事业运势")
                .score(87)
                .wuXing("火")
                .build());
        
        return recommendations;
    }
} 
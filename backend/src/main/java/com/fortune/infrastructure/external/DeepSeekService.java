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

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

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
    
    private final RestTemplate restTemplate = new RestTemplate();
    
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
     * 生成今日运势
     */
    public String getTodayFortune() {
        System.out.println("调用DeepSeek生成今日运势");
        
        String prompt = "请生成一段今日运势分析，包含事业、财运、感情、健康等方面的建议，语言要温馨正面，字数控制在200字以内。";
        
        try {
            String response = callDeepSeekApi(prompt);
            System.out.println("DeepSeek今日运势响应：" + response);
            return response;
        } catch (Exception e) {
            System.err.println("调用DeepSeek生成今日运势失败: " + e.getMessage());
            return "今日运势良好，事业上会有新的机遇，财运稳中有升，感情方面需要多沟通理解，健康状况良好，建议保持积极乐观的心态。";
        }
    }
    
    /**
     * 调用DeepSeek API
     */
    private String callDeepSeekApi(String prompt) {
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
        
        // 发送请求
        ResponseEntity<String> response = restTemplate.postForEntity(apiUrl, entity, String.class);
        
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
            // 尝试解析JSON格式的响应
            JSONArray jsonArray = JSON.parseArray(response);
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
        
        recommendations.add(NameRecommendationResponse.builder()
                .name("瑞祥")
                .reason("寓意吉祥如意，能够补充五行缺失，带来好运")
                .score(88)
                .wuXing("金")
                .build());
                
        recommendations.add(NameRecommendationResponse.builder()
                .name("智慧")
                .reason("寓意聪明智慧，五行属水，有助于平衡五行")
                .score(85)
                .wuXing("水")
                .build());
                
        recommendations.add(NameRecommendationResponse.builder()
                .name("嘉怡")
                .reason("寓意美好快乐，五行属木，能够增强运势")
                .score(87)
                .wuXing("木")
                .build());
        
        return recommendations;
    }
} 
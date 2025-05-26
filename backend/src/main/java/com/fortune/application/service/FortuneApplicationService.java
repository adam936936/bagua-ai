package com.fortune.application.service;

import com.fortune.application.command.CalculateFortuneCommand;
import com.fortune.application.command.RecommendNameCommand;
import com.fortune.domain.fortune.valueobject.BirthInfo;
import com.fortune.infrastructure.external.DeepSeekService;
import com.fortune.infrastructure.utils.FortuneUtils;
import com.fortune.interfaces.dto.response.FortuneCalculateResponse;
import com.fortune.interfaces.dto.response.NameRecommendationResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * 命理应用服务
 * 
 * @author fortune
 * @since 2024-01-01
 */
@Service
@RequiredArgsConstructor
public class FortuneApplicationService {
    
    private final DeepSeekService deepSeekService;
    
    /**
     * 计算命理信息
     */
    public FortuneCalculateResponse calculateFortune(CalculateFortuneCommand command) {
        System.out.println("开始计算命理信息，用户ID：" + command.getUserId());
        
        try {
            // 解析出生信息
            LocalDate birthDate = LocalDate.parse(command.getBirthDate());
            BirthInfo birthInfo = BirthInfo.of(birthDate, command.getBirthTime(), command.getUserName());
            
            // 计算农历
            String lunar = FortuneUtils.solarToLunar(birthDate);
            
            // 计算天干地支
            String ganZhi = FortuneUtils.calculateGanZhi(birthDate, command.getBirthTime());
            
            // 分析五行
            Map<String, Object> wuXingAnalysis = FortuneUtils.analyzeWuXing(ganZhi);
            String wuXing = (String) wuXingAnalysis.get("wuXing");
            String wuXingLack = (String) wuXingAnalysis.get("wuXingLack");
            
            // 获取生肖
            String shengXiao = FortuneUtils.getShengXiao(birthDate.getYear());
            
            // 调用AI分析
            String aiAnalysis = deepSeekService.generateFortuneAnalysis(ganZhi, wuXing, wuXingLack, shengXiao);
            
            // 构建响应
            FortuneCalculateResponse response = new FortuneCalculateResponse();
            response.setId(System.currentTimeMillis()); // 临时ID，实际应该保存到数据库
            response.setLunar(lunar);
            response.setGanZhi(ganZhi);
            response.setWuXing(wuXing);
            response.setWuXingLack(wuXingLack);
            response.setShengXiao(shengXiao);
            response.setAiAnalysis(aiAnalysis);
            response.setCreateTime(LocalDateTime.now());
            return response;
                    
        } catch (Exception e) {
            System.err.println("计算命理信息失败: " + e.getMessage());
            throw new RuntimeException("计算命理信息失败：" + e.getMessage());
        }
    }
    
    /**
     * AI推荐姓名
     */
    public List<NameRecommendationResponse> recommendNames(RecommendNameCommand command) {
        System.out.println("开始AI推荐姓名，用户ID：" + command.getUserId());
        
        try {
            // 调用AI生成姓名推荐
            List<NameRecommendationResponse> recommendations = deepSeekService.generateNameRecommendations(
                command.getWuXingLack(), command.getGanZhi(), command.getSurname());
            
            return recommendations;
            
        } catch (Exception e) {
            System.err.println("AI推荐姓名失败: " + e.getMessage());
            throw new RuntimeException("AI推荐姓名失败：" + e.getMessage());
        }
    }
    
    /**
     * 获取今日运势
     */
    public String getTodayFortune() {
        System.out.println("获取今日运势");
        
        try {
            return deepSeekService.getTodayFortune();
        } catch (Exception e) {
            System.err.println("获取今日运势失败: " + e.getMessage());
            throw new RuntimeException("获取今日运势失败：" + e.getMessage());
        }
    }
    
    /**
     * 获取用户历史记录
     */
    public List<FortuneCalculateResponse> getUserHistory(Long userId, Integer page, Integer size) {
        System.out.println("获取用户历史记录，用户ID：" + userId + "，页码：" + page + "，大小：" + size);
        
        try {
            // TODO: 实现真实的数据库查询
            // 这里返回模拟数据用于测试
            List<FortuneCalculateResponse> mockHistory = new ArrayList<>();
            
            // 生成一些模拟历史记录
            for (int i = 0; i < Math.min(size, 5); i++) {
                FortuneCalculateResponse record = new FortuneCalculateResponse();
                record.setId((long) (i + 1));
                record.setLunar("农历" + (2024 - i) + "年正月初一");
                record.setGanZhi("甲子年 丙寅月 戊申日 甲子时");
                record.setWuXing("木2个 火1个 土2个 金1个 水2个");
                record.setWuXingLack("无");
                record.setShengXiao("龙");
                record.setAiAnalysis("您的八字显示您是一个性格坚韧、意志坚强的人。事业方面会有不错的发展，财运稳中有升...");
                record.setCreateTime(java.time.LocalDateTime.now().minusDays(i));
                mockHistory.add(record);
            }
            
            return mockHistory;
            
        } catch (Exception e) {
            System.err.println("获取用户历史记录失败: " + e.getMessage());
            return new ArrayList<>();
        }
    }
} 
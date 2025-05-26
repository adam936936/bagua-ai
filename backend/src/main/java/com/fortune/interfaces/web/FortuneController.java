package com.fortune.interfaces.web;

import com.fortune.application.command.CalculateFortuneCommand;
import com.fortune.application.command.RecommendNameCommand;
import com.fortune.application.service.FortuneApplicationService;
import com.fortune.interfaces.dto.request.FortuneCalculateRequest;
import com.fortune.interfaces.dto.request.NameRecommendRequest;
import com.fortune.interfaces.dto.response.ApiResponse;
import com.fortune.interfaces.dto.response.FortuneCalculateResponse;
import com.fortune.interfaces.dto.response.NameRecommendationResponse;
import com.fortune.interfaces.assembler.FortuneAssembler;
// import io.swagger.annotations.Api;
// import io.swagger.annotations.ApiOperation;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.util.List;

/**
 * 命理计算控制器
 * 
 * @author fortune
 * @since 2024-01-01
 */
@RestController
@RequestMapping("/fortune")
// @Api(tags = "命理计算接口")
@Validated
@Slf4j
@RequiredArgsConstructor
public class FortuneController {
    
    private final FortuneApplicationService fortuneApplicationService;
    private final FortuneAssembler fortuneAssembler;
    
    /**
     * 计算命理信息
     */
    @PostMapping("/calculate")
    // @ApiOperation("计算命理信息")
    public ApiResponse<FortuneCalculateResponse> calculate(
            @Valid @RequestBody FortuneCalculateRequest request) {
        
        log.info("开始计算命理信息，请求参数：{}", request);
        
        try {
            // 转换为命令对象
            CalculateFortuneCommand command = fortuneAssembler.toCalculateCommand(request);
            
            // 执行命理计算
            FortuneCalculateResponse response = fortuneApplicationService.calculateFortune(command);
            
            log.info("命理计算完成，用户ID：{}", request.getUserId());
            return ApiResponse.success(response);
            
        } catch (Exception e) {
            log.error("命理计算失败，用户ID：{}，错误信息：{}", request.getUserId(), e.getMessage(), e);
            return ApiResponse.error("命理计算失败：" + e.getMessage());
        }
    }
    
    /**
     * AI推荐姓名
     */
    @PostMapping("/recommend-names")
    // @ApiOperation("AI推荐姓名")
    public ApiResponse<List<NameRecommendationResponse>> recommendNames(
            @Valid @RequestBody NameRecommendRequest request) {
        
        log.info("开始AI推荐姓名，请求参数：{}", request);
        
        try {
            // 转换为命令对象
            RecommendNameCommand command = fortuneAssembler.toRecommendCommand(request);
            
            // 执行姓名推荐
            List<NameRecommendationResponse> response = fortuneApplicationService.recommendNames(command);
            
            log.info("AI推荐姓名完成，用户ID：{}，推荐数量：{}", request.getUserId(), response.size());
            return ApiResponse.success(response);
            
        } catch (Exception e) {
            log.error("AI推荐姓名失败，用户ID：{}，错误信息：{}", request.getUserId(), e.getMessage(), e);
            return ApiResponse.error("AI推荐姓名失败：" + e.getMessage());
        }
    }
    
    /**
     * 获取今日运势
     */
    @GetMapping("/today-fortune")
    // @ApiOperation("获取今日运势")
    public ApiResponse<String> getTodayFortune() {
        
        log.info("获取今日运势");
        
        try {
            String todayFortune = fortuneApplicationService.getTodayFortune();
            return ApiResponse.success(todayFortune);
            
        } catch (Exception e) {
            log.error("获取今日运势失败，错误信息：{}", e.getMessage(), e);
            return ApiResponse.error("获取今日运势失败：" + e.getMessage());
        }
    }
    
    /**
     * 获取用户历史记录
     */
    @GetMapping("/history/{userId}")
    // @ApiOperation("获取用户历史记录")
    public ApiResponse<List<FortuneCalculateResponse>> getHistory(
            @PathVariable Long userId,
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "10") Integer size) {
        
        log.info("获取用户历史记录，用户ID：{}，页码：{}，大小：{}", userId, page, size);
        
        try {
            List<FortuneCalculateResponse> history = fortuneApplicationService.getUserHistory(userId, page, size);
            return ApiResponse.success(history);
            
        } catch (Exception e) {
            log.error("获取用户历史记录失败，用户ID：{}，错误信息：{}", userId, e.getMessage(), e);
            return ApiResponse.error("获取历史记录失败：" + e.getMessage());
        }
    }
    
    /**
     * 性能测试接口
     */
    @GetMapping("/performance-test")
    // @ApiOperation("性能测试接口")
    public ApiResponse<Object> performanceTest(
            @RequestParam(defaultValue = "100") Integer iterations,
            @RequestParam(defaultValue = "10") Integer delay) {
        
        log.info("开始性能测试，迭代次数：{}，延迟：{}ms", iterations, delay);
        
        long startTime = System.currentTimeMillis();
        
        try {
            // 模拟计算密集型操作
            for (int i = 0; i < iterations; i++) {
                // 模拟一些计算
                double result = 0;
                for (int j = 0; j < 1000; j++) {
                    result += Math.sqrt(j) * Math.sin(j);
                }
                
                // 模拟延迟
                if (delay > 0) {
                    Thread.sleep(delay);
                }
            }
            
            long endTime = System.currentTimeMillis();
            long duration = endTime - startTime;
            
            // 计算性能指标
            double avgTime = (double) duration / iterations;
            double throughput = (double) iterations / duration * 1000; // 每秒处理数
            
            // 创建结果对象
            java.util.Map<String, Object> result = new java.util.HashMap<>();
            result.put("iterations", iterations);
            result.put("delayMs", delay);
            result.put("totalTimeMs", duration);
            result.put("avgTimeMs", avgTime);
            result.put("throughputPerSec", throughput);
            result.put("status", "SUCCESS");
            result.put("timestamp", System.currentTimeMillis());
            
            log.info("性能测试完成，总耗时：{}ms，平均耗时：{}ms，吞吐量：{}/s", 
                    duration, String.format("%.2f", avgTime), String.format("%.2f", throughput));
            
            return ApiResponse.success(result);
            
        } catch (Exception e) {
            long endTime = System.currentTimeMillis();
            long duration = endTime - startTime;
            
            log.error("性能测试失败，耗时：{}ms，错误信息：{}", duration, e.getMessage(), e);
            
            // 创建错误结果对象
            java.util.Map<String, Object> errorResult = new java.util.HashMap<>();
            errorResult.put("iterations", iterations);
            errorResult.put("delayMs", delay);
            errorResult.put("totalTimeMs", duration);
            errorResult.put("status", "ERROR");
            errorResult.put("error", e.getMessage());
            errorResult.put("timestamp", System.currentTimeMillis());
            
            return ApiResponse.success(errorResult);
        }
    }
    
    /**
     * 网络联通性测试接口
     */
    @GetMapping("/connectivity-test")
    // @ApiOperation("网络联通性测试接口")
    public ApiResponse<Object> connectivityTest() {
        
        log.info("开始网络联通性测试");
        
        long startTime = System.currentTimeMillis();
        
        try {
            // 获取系统信息
            Runtime runtime = Runtime.getRuntime();
            long totalMemory = runtime.totalMemory();
            long freeMemory = runtime.freeMemory();
            long usedMemory = totalMemory - freeMemory;
            int availableProcessors = runtime.availableProcessors();
            
            // 获取JVM信息
            String javaVersion = System.getProperty("java.version");
            String osName = System.getProperty("os.name");
            String osVersion = System.getProperty("os.version");
            
            long endTime = System.currentTimeMillis();
            long responseTime = endTime - startTime;
            
            // 创建系统信息
            java.util.Map<String, Object> systemInfo = new java.util.HashMap<>();
            systemInfo.put("javaVersion", javaVersion);
            systemInfo.put("osName", osName);
            systemInfo.put("osVersion", osVersion);
            systemInfo.put("cpuCores", availableProcessors);
            
            // 创建内存信息
            java.util.Map<String, Object> memoryInfo = new java.util.HashMap<>();
            memoryInfo.put("totalMemoryMB", totalMemory / 1024 / 1024);
            memoryInfo.put("usedMemoryMB", usedMemory / 1024 / 1024);
            memoryInfo.put("freeMemoryMB", freeMemory / 1024 / 1024);
            memoryInfo.put("memoryUsagePercent", (double) usedMemory / totalMemory * 100);
            
            // 创建网络信息
            java.util.Map<String, Object> networkInfo = new java.util.HashMap<>();
            networkInfo.put("serverHost", "localhost");
            networkInfo.put("serverPort", 8080);
            networkInfo.put("protocol", "HTTP/1.1");
            networkInfo.put("method", "GET");
            
            // 创建结果对象
            java.util.Map<String, Object> result = new java.util.HashMap<>();
            result.put("status", "CONNECTED");
            result.put("responseTimeMs", responseTime);
            result.put("timestamp", System.currentTimeMillis());
            result.put("systemInfo", systemInfo);
            result.put("memoryInfo", memoryInfo);
            result.put("networkInfo", networkInfo);
            
            log.info("网络联通性测试完成，响应时间：{}ms", responseTime);
            return ApiResponse.success(result);
            
        } catch (Exception e) {
            long endTime = System.currentTimeMillis();
            long responseTime = endTime - startTime;
            
            log.error("网络联通性测试失败，响应时间：{}ms，错误信息：{}", responseTime, e.getMessage(), e);
            
            // 创建错误结果对象
            java.util.Map<String, Object> errorResult = new java.util.HashMap<>();
            errorResult.put("status", "ERROR");
            errorResult.put("responseTimeMs", responseTime);
            errorResult.put("error", e.getMessage());
            errorResult.put("timestamp", System.currentTimeMillis());
            
            return ApiResponse.success(errorResult);
        }
    }
} 
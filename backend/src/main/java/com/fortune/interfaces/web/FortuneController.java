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
@RequestMapping("/api/fortune")
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
} 
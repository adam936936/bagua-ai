package com.fortune.interfaces.web;

import com.fortune.application.service.WechatAuthService;
import com.fortune.infrastructure.persistence.mapper.UserMapper;
import com.fortune.infrastructure.persistence.po.UserPO;
import com.fortune.interfaces.dto.request.WechatLoginRequest;
import com.fortune.interfaces.dto.request.UserProfileRequest;
import com.fortune.interfaces.dto.response.ApiResponse;
import com.fortune.interfaces.dto.response.UserLoginResponse;
import com.fortune.interfaces.dto.response.UserProfileResponse;
import com.fortune.interfaces.dto.response.VipStatusResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * 用户管理控制器
 * 
 * @author fortune
 * @since 2024-01-01
 */
@RestController
@RequestMapping("/user")
@Validated
@Slf4j
@RequiredArgsConstructor
public class UserController {
    
    private final WechatAuthService wechatAuthService;
    private final UserMapper userMapper;
    
    /**
     * 微信小程序登录
     */
    @PostMapping("/login")
    public ApiResponse<Map<String, Object>> login(@Valid @RequestBody WechatLoginRequest request) {
        log.info("微信小程序登录，code：{}", request.getCode());
        
        try {
            // 调用微信认证服务
            Map<String, Object> result = wechatAuthService.login(
                request.getCode(), 
                request.getNickName(), 
                request.getAvatar()
            );
            
            log.info("微信登录成功，用户ID：{}", result.get("userId"));
            return ApiResponse.success(result);
            
        } catch (Exception e) {
            log.error("微信登录失败，错误信息：{}", e.getMessage(), e);
            return ApiResponse.error("登录失败：" + e.getMessage());
        }
    }
    
    /**
     * 获取用户信息
     */
    @GetMapping("/profile/{userId}")
    public ApiResponse<UserProfileResponse> getProfile(@PathVariable Long userId) {
        log.info("获取用户信息，用户ID：{}", userId);
        
        try {
            UserPO user = userMapper.findById(userId);
            if (user == null) {
                return ApiResponse.error("用户不存在");
            }
            
            UserProfileResponse response = UserProfileResponse.builder()
                    .userId(user.getId())
                    .openId(user.getOpenid())
                    .nickname(user.getNickname())
                    .avatar(user.getAvatarUrl())
                    .phone(user.getPhone())
                    .vipLevel(user.getVipLevel())
                    .vipExpireTime(user.getVipExpireTime())
                    .build();
            
            return ApiResponse.success(response);
            
        } catch (Exception e) {
            log.error("获取用户信息失败，用户ID：{}", userId, e);
            return ApiResponse.error("获取用户信息失败：" + e.getMessage());
        }
    }
    
    /**
     * 更新用户信息
     */
    @PutMapping("/profile")
    public ApiResponse<Void> updateProfile(@Valid @RequestBody UserProfileRequest request) {
        log.info("更新用户信息，用户ID：{}", request.getUserId());
        
        try {
            UserPO user = userMapper.findById(request.getUserId());
            if (user == null) {
                return ApiResponse.error("用户不存在");
            }
            
            // 更新用户信息
            if (request.getNickname() != null) {
                user.setNickname(request.getNickname());
            }
            if (request.getAvatar() != null) {
                user.setAvatarUrl(request.getAvatar());
            }
            if (request.getPhone() != null) {
                user.setPhone(request.getPhone());
            }
            user.setUpdatedTime(LocalDateTime.now());
            
            userMapper.updateById(user);
            
            log.info("更新用户信息成功，用户ID：{}", request.getUserId());
            return ApiResponse.success();
            
        } catch (Exception e) {
            log.error("更新用户信息失败，用户ID：{}", request.getUserId(), e);
            return ApiResponse.error("更新用户信息失败：" + e.getMessage());
        }
    }
    
    /**
     * 获取用户VIP状态
     */
    @GetMapping("/vip-status/{userId}")
    public ApiResponse<VipStatusResponse> getVipStatus(@PathVariable Long userId) {
        log.info("获取用户VIP状态，用户ID：{}", userId);
        
        try {
            UserPO user = userMapper.findById(userId);
            if (user == null) {
                return ApiResponse.error("用户不存在");
            }
            
            boolean isVip = user.getVipLevel() != null && user.getVipLevel() > 0;
            boolean isExpired = false;
            
            if (isVip && user.getVipExpireTime() != null) {
                isExpired = user.getVipExpireTime().isBefore(LocalDateTime.now());
            }
            
            VipStatusResponse response = VipStatusResponse.builder()
                    .isVip(isVip && !isExpired)
                    .vipLevel(user.getVipLevel())
                    .expireTime(user.getVipExpireTime())
                    .isExpired(isExpired)
                    .build();
            
            return ApiResponse.success(response);
            
        } catch (Exception e) {
            log.error("获取VIP状态失败，用户ID：{}", userId, e);
            return ApiResponse.error("获取VIP状态失败：" + e.getMessage());
        }
    }
    
    /**
     * 删除用户账户
     */
    @DeleteMapping("/{userId}")
    public ApiResponse<Void> deleteUser(@PathVariable Long userId) {
        log.info("删除用户账户，用户ID：{}", userId);
        
        try {
            UserPO user = userMapper.findById(userId);
            if (user == null) {
                return ApiResponse.error("用户不存在");
            }
            
            userMapper.deleteById(userId);
            
            log.info("删除用户账户成功，用户ID：{}", userId);
            return ApiResponse.success();
            
        } catch (Exception e) {
            log.error("删除用户账户失败，用户ID：{}", userId, e);
            return ApiResponse.error("删除用户账户失败：" + e.getMessage());
        }
    }
    
    /**
     * 获取用户统计信息
     */
    @GetMapping("/stats")
    public ApiResponse<Map<String, Object>> getUserStats() {
        log.info("获取用户统计信息");
        
        try {
            int totalUsers = userMapper.countUsers();
            
            Map<String, Object> stats = new HashMap<>();
            stats.put("totalUsers", totalUsers);
            stats.put("timestamp", System.currentTimeMillis());
            
            return ApiResponse.success(stats);
            
        } catch (Exception e) {
            log.error("获取用户统计信息失败", e);
            return ApiResponse.error("获取统计信息失败：" + e.getMessage());
        }
    }
} 
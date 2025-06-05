package com.fortune.application.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fortune.infrastructure.persistence.mapper.UserMapper;
import com.fortune.infrastructure.persistence.po.UserPO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * 微信认证服务
 * 
 * @author fortune
 * @since 2024-01-01
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class WechatAuthService {
    
    private final UserMapper userMapper;
    private final JwtTokenService jwtTokenService;
    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();
    
    @Value("${fortune.wechat.app-id}")
    private String appId;
    
    @Value("${fortune.wechat.app-secret}")
    private String appSecret;
    
    /**
     * 微信小程序登录
     */
    public Map<String, Object> login(String code, String nickName, String avatar) {
        try {
            log.info("开始微信小程序登录，code：{}", code);
            
            // 1. 通过code获取openid和session_key
            WechatAuthResult authResult = getOpenIdByCode(code);
            if (authResult == null || authResult.getOpenid() == null) {
                throw new RuntimeException("获取微信用户信息失败");
            }
            
            log.info("获取微信用户信息成功，openid：{}", authResult.getOpenid());
            
            // 2. 查询或创建用户
            UserPO user = userMapper.findByOpenId(authResult.getOpenid());
            boolean isNewUser = false;
            
            if (user == null) {
                // 创建新用户
                user = new UserPO();
                user.setOpenid(authResult.getOpenid());
                user.setNickname(nickName);
                user.setAvatarUrl(avatar);
                user.setVipLevel(0);
                user.setDeleted(0);
                user.setCreatedTime(LocalDateTime.now());
                user.setUpdatedTime(LocalDateTime.now());
                
                userMapper.insert(user);
                isNewUser = true;
                
                log.info("创建新用户成功，用户ID：{}，openid：{}", user.getId(), user.getOpenid());
            } else {
                // 更新用户信息
                if (nickName != null && !nickName.equals(user.getNickname())) {
                    user.setNickname(nickName);
                }
                if (avatar != null && !avatar.equals(user.getAvatarUrl())) {
                    user.setAvatarUrl(avatar);
                }
                user.setUpdatedTime(LocalDateTime.now());
                
                userMapper.updateById(user);
                
                log.info("更新用户信息成功，用户ID：{}，openid：{}", user.getId(), user.getOpenid());
            }
            
            // 3. 生成JWT token
            String token = jwtTokenService.generateToken(user.getId(), user.getOpenid());
            
            // 4. 构建响应
            Map<String, Object> result = new HashMap<>();
            result.put("userId", user.getId());
            result.put("openId", user.getOpenid());
            result.put("token", token);
            result.put("isNewUser", isNewUser);
            result.put("nickname", user.getNickname());
            result.put("avatar", user.getAvatarUrl());
            result.put("vipLevel", user.getVipLevel());
            result.put("vipExpireTime", user.getVipExpireTime());
            
            log.info("微信登录成功，用户ID：{}，是否新用户：{}", user.getId(), isNewUser);
            return result;
            
        } catch (Exception e) {
            log.error("微信登录失败", e);
            throw new RuntimeException("微信登录失败：" + e.getMessage());
        }
    }
    
    /**
     * 通过code获取微信openid
     */
    private WechatAuthResult getOpenIdByCode(String code) {
        try {
            String url = String.format(
                "https://api.weixin.qq.com/sns/jscode2session?appid=%s&secret=%s&js_code=%s&grant_type=authorization_code",
                appId, appSecret, code
            );
            
            log.info("调用微信API获取openid，URL：{}", url.replaceAll("secret=[^&]*", "secret=***"));
            
            String response = restTemplate.getForObject(url, String.class);
            log.info("微信API响应：{}", response);
            
            if (response == null) {
                throw new RuntimeException("微信API响应为空");
            }
            
            Map<String, Object> responseMap = objectMapper.readValue(response, Map.class);
            
            if (responseMap.containsKey("errcode")) {
                Integer errCode = (Integer) responseMap.get("errcode");
                String errMsg = (String) responseMap.get("errmsg");
                log.error("微信API返回错误，errcode：{}，errmsg：{}", errCode, errMsg);
                throw new RuntimeException("微信API错误：" + errMsg);
            }
            
            WechatAuthResult result = new WechatAuthResult();
            result.setOpenid((String) responseMap.get("openid"));
            result.setSessionKey((String) responseMap.get("session_key"));
            result.setUnionid((String) responseMap.get("unionid"));
            
            return result;
            
        } catch (Exception e) {
            log.error("调用微信API失败", e);
            throw new RuntimeException("调用微信API失败：" + e.getMessage());
        }
    }
    
    /**
     * 微信认证结果
     */
    public static class WechatAuthResult {
        private String openid;
        private String sessionKey;
        private String unionid;
        
        // Getters and Setters
        public String getOpenid() {
            return openid;
        }
        
        public void setOpenid(String openid) {
            this.openid = openid;
        }
        
        public String getSessionKey() {
            return sessionKey;
        }
        
        public void setSessionKey(String sessionKey) {
            this.sessionKey = sessionKey;
        }
        
        public String getUnionid() {
            return unionid;
        }
        
        public void setUnionid(String unionid) {
            this.unionid = unionid;
        }
    }
} 
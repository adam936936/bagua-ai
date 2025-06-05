package com.fortune.application.service;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.security.Key;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

/**
 * JWT令牌服务
 * 
 * @author fortune
 * @since 2024-01-01
 */
@Service
@Slf4j
public class JwtTokenService {
    
    @Value("${fortune.jwt.secret}")
    private String jwtSecret;
    
    @Value("${fortune.jwt.expiration}")
    private Long jwtExpiration;
    
    /**
     * 生成JWT令牌
     */
    public String generateToken(Long userId, String openId) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("userId", userId);
        claims.put("openId", openId);
        
        return createToken(claims, openId);
    }
    
    /**
     * 创建令牌
     */
    private String createToken(Map<String, Object> claims, String subject) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + jwtExpiration * 1000);
        
        Key key = Keys.hmacShaKeyFor(jwtSecret.getBytes());
        
        return Jwts.builder()
                .setClaims(claims)
                .setSubject(subject)
                .setIssuedAt(now)
                .setExpiration(expiryDate)
                .signWith(key, SignatureAlgorithm.HS256)
                .compact();
    }
    
    /**
     * 从令牌中获取用户ID
     */
    public Long getUserIdFromToken(String token) {
        Claims claims = getClaimsFromToken(token);
        return claims != null ? Long.valueOf(claims.get("userId").toString()) : null;
    }
    
    /**
     * 从令牌中获取OpenID
     */
    public String getOpenIdFromToken(String token) {
        Claims claims = getClaimsFromToken(token);
        return claims != null ? (String) claims.get("openId") : null;
    }
    
    /**
     * 从令牌中获取主题
     */
    public String getSubjectFromToken(String token) {
        Claims claims = getClaimsFromToken(token);
        return claims != null ? claims.getSubject() : null;
    }
    
    /**
     * 从令牌中获取过期时间
     */
    public Date getExpirationDateFromToken(String token) {
        Claims claims = getClaimsFromToken(token);
        return claims != null ? claims.getExpiration() : null;
    }
    
    /**
     * 从令牌中获取声明
     */
    private Claims getClaimsFromToken(String token) {
        try {
            Key key = Keys.hmacShaKeyFor(jwtSecret.getBytes());
            return Jwts.parserBuilder()
                    .setSigningKey(key)
                    .build()
                    .parseClaimsJws(token)
                    .getBody();
        } catch (JwtException | IllegalArgumentException e) {
            log.warn("JWT令牌解析失败：{}", e.getMessage());
            return null;
        }
    }
    
    /**
     * 验证令牌是否过期
     */
    public Boolean isTokenExpired(String token) {
        Date expiration = getExpirationDateFromToken(token);
        return expiration != null && expiration.before(new Date());
    }
    
    /**
     * 验证令牌
     */
    public Boolean validateToken(String token, String openId) {
        String tokenOpenId = getOpenIdFromToken(token);
        return (openId.equals(tokenOpenId) && !isTokenExpired(token));
    }
} 
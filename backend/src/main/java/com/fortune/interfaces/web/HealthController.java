package com.fortune.interfaces.web;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.http.ResponseEntity;

/**
 * 健康检查控制器
 * 提供API健康检查和数据库连接状态检查
 */
@RestController
public class HealthController {
    
    @Autowired
    private JdbcTemplate jdbcTemplate;
    
    /**
     * 简单健康检查
     */
    @GetMapping("/health")
    public String health() {
        return "healthy";
    }
    
    /**
     * 详细健康状态检查，包括数据库连接
     */
    @GetMapping("/health/status")
    public ResponseEntity<Map<String, Object>> healthStatus() {
        Map<String, Object> status = new HashMap<>();
        Map<String, Object> components = new HashMap<>();
        boolean isHealthy = true;
        
        // 检查数据库连接
        try {
            String dbVersion = jdbcTemplate.queryForObject("SELECT VERSION()", String.class);
            Map<String, Object> dbStatus = new HashMap<>();
            dbStatus.put("status", "UP");
            dbStatus.put("version", dbVersion);
            components.put("database", dbStatus);
        } catch (Exception e) {
            Map<String, Object> dbStatus = new HashMap<>();
            dbStatus.put("status", "DOWN");
            dbStatus.put("error", e.getMessage());
            components.put("database", dbStatus);
            isHealthy = false;
        }
        
        // 设置整体状态
        status.put("status", isHealthy ? "UP" : "DOWN");
        status.put("components", components);
        status.put("timestamp", System.currentTimeMillis());
        
        return ResponseEntity.ok(status);
    }
} 
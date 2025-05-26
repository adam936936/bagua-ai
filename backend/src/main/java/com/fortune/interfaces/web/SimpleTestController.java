package com.fortune.interfaces.web;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/simple")
public class SimpleTestController {
    
    @GetMapping("/hello")
    public Map<String, Object> hello() {
        Map<String, Object> result = new HashMap<>();
        result.put("message", "Hello from backend!");
        result.put("timestamp", System.currentTimeMillis());
        result.put("status", "success");
        return result;
    }
    
    @GetMapping("/fortune-test")
    public Map<String, Object> fortuneTest() {
        Map<String, Object> result = new HashMap<>();
        result.put("message", "今日运势：大吉大利，万事如意！");
        result.put("fortune", "财运亨通，事业顺利，感情美满");
        result.put("timestamp", System.currentTimeMillis());
        result.put("status", "success");
        return result;
    }
} 
package com.fortune.infrastructure.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.PathMatchConfigurer;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Web配置类
 * 
 * @author fortune
 * @since 2024-01-01
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {
    
    /**
     * 配置路径匹配规则
     * 由于context-path已经是/api，这里不再添加额外前缀
     */
    @Override
    public void configurePathMatch(PathMatchConfigurer configurer) {
        // 注释掉路径前缀配置，因为context-path已经是/api
        // configurer.addPathPrefix("/api", c -> c.getPackageName().startsWith("com.fortune.interfaces.web"));
    }
    
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                .allowedOriginPatterns("*")
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .allowCredentials(true)
                .maxAge(3600);
    }
} 
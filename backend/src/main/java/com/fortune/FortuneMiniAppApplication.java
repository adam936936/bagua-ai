package com.fortune;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;

/**
 * AI八卦运势小程序启动类
 * 
 * @author fortune
 * @since 2024-01-01
 */
@SpringBootApplication
@MapperScan("com.fortune.infrastructure.persistence")
@EnableAsync
public class FortuneMiniAppApplication {

    public static void main(String[] args) {
        SpringApplication.run(FortuneMiniAppApplication.class, args);
        System.out.println("AI八卦运势小程序启动成功！");
    }
} 
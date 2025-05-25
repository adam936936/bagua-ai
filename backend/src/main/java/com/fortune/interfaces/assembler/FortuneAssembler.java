package com.fortune.interfaces.assembler;

import com.fortune.application.command.CalculateFortuneCommand;
import com.fortune.application.command.RecommendNameCommand;
import com.fortune.interfaces.dto.request.FortuneCalculateRequest;
import com.fortune.interfaces.dto.request.NameRecommendRequest;
import org.springframework.stereotype.Component;

/**
 * 命理对象转换器
 * 
 * @author fortune
 * @since 2024-01-01
 */
@Component
public class FortuneAssembler {
    
    /**
     * 转换为计算命理命令
     */
    public CalculateFortuneCommand toCalculateCommand(FortuneCalculateRequest request) {
        CalculateFortuneCommand command = new CalculateFortuneCommand();
        command.setUserId(request.getUserId());
        command.setBirthDate(request.getBirthDate());
        command.setBirthTime(request.getBirthTime());
        command.setUserName(request.getUserName());
        return command;
    }
    
    /**
     * 转换为推荐姓名命令
     */
    public RecommendNameCommand toRecommendCommand(NameRecommendRequest request) {
        RecommendNameCommand command = new RecommendNameCommand();
        command.setUserId(request.getUserId());
        command.setWuXingLack(request.getWuXingLack());
        command.setGanZhi(request.getGanZhi());
        command.setSurname(request.getSurname());
        return command;
    }
} 
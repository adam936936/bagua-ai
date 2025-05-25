package com.fortune.domain.shared.valueobject;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

/**
 * 基础ID值对象
 * 
 * @author fortune
 * @since 2024-01-01
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class BaseId {
    
    /**
     * ID值
     */
    private Long value;
    
    /**
     * 创建新的ID
     */
    public static BaseId of(Long value) {
        BaseId baseId = new BaseId();
        baseId.value = value;
        return baseId;
    }
    
    /**
     * 生成新的ID
     */
    public static BaseId generate() {
        BaseId baseId = new BaseId();
        baseId.value = System.currentTimeMillis();
        return baseId;
    }
} 
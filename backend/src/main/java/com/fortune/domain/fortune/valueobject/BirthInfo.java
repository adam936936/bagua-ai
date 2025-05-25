package com.fortune.domain.fortune.valueobject;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import javax.validation.constraints.NotNull;
import javax.validation.constraints.Pattern;
import java.time.LocalDate;
import java.util.Objects;

/**
 * 出生信息值对象
 * 
 * @author fortune
 * @since 2024-01-01
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class BirthInfo {
    
    /**
     * 出生日期
     */
    private LocalDate birthDate;
    
    /**
     * 出生时辰
     */
    private String birthTime;
    
    /**
     * 用户姓名
     */
    private String userName;
    
    /**
     * 性别 (可选)
     */
    private String gender;
    
    /**
     * 出生地点 (可选)
     */
    private String birthPlace;
    
    /**
     * 创建出生信息
     */
    public static BirthInfo of(LocalDate birthDate, String birthTime, String userName) {
        BirthInfo birthInfo = new BirthInfo();
        birthInfo.birthDate = birthDate;
        birthInfo.birthTime = birthTime;
        birthInfo.userName = userName;
        return birthInfo;
    }
    
    /**
     * 验证出生信息是否有效
     */
    public boolean isValid() {
        if (birthDate == null || birthTime == null) {
            return false;
        }
        
        // 检查出生日期是否在合理范围内（1900年到当前年份）
        LocalDate minDate = LocalDate.of(1900, 1, 1);
        LocalDate maxDate = LocalDate.now();
        
        return !birthDate.isBefore(minDate) && !birthDate.isAfter(maxDate);
    }
    
    /**
     * 获取出生年份
     */
    public int getBirthYear() {
        return birthDate.getYear();
    }
    
    /**
     * 获取出生月份
     */
    public int getBirthMonth() {
        return birthDate.getMonthValue();
    }
    
    /**
     * 获取出生日
     */
    public int getBirthDay() {
        return birthDate.getDayOfMonth();
    }
    
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        BirthInfo birthInfo = (BirthInfo) o;
        return Objects.equals(birthDate, birthInfo.birthDate) &&
               Objects.equals(birthTime, birthInfo.birthTime) &&
               Objects.equals(userName, birthInfo.userName);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(birthDate, birthTime, userName);
    }
    
    @Override
    public String toString() {
        return String.format("BirthInfo{birthDate=%s, birthTime='%s', userName='%s'}", 
                           birthDate, birthTime, userName);
    }
} 
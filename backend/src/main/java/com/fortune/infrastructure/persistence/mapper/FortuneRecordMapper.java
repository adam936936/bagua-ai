package com.fortune.infrastructure.persistence.mapper;

import com.fortune.infrastructure.persistence.po.FortuneRecordPO;
import org.apache.ibatis.annotations.*;

import java.util.List;

/**
 * 命理记录Mapper
 * 
 * @author fortune
 * @since 2024-01-01
 */
@Mapper
public interface FortuneRecordMapper {
    
    /**
     * 插入命理记录
     */
    @Insert("INSERT INTO t_fortune_record (user_id, name, gender, birth_year, birth_month, birth_day, birth_hour, " +
            "gan_zhi, sheng_xiao, wu_xing_analysis, ai_analysis, created_time, updated_time) " +
            "VALUES (#{userId}, #{name}, #{gender}, #{birthYear}, #{birthMonth}, #{birthDay}, #{birthHour}, " +
            "#{ganZhi}, #{shengXiao}, #{wuXingAnalysis}, #{aiAnalysis}, NOW(), NOW())")
    @Options(useGeneratedKeys = true, keyProperty = "id")
    int insert(FortuneRecordPO record);
    
    /**
     * 根据用户ID查询历史记录（分页）
     */
    @Select("SELECT * FROM t_fortune_record WHERE user_id = #{userId} AND deleted = 0 " +
            "ORDER BY created_time DESC LIMIT #{offset}, #{limit}")
    List<FortuneRecordPO> selectByUserId(@Param("userId") Long userId, 
                                        @Param("offset") int offset, 
                                        @Param("limit") int limit);
    
    /**
     * 统计用户历史记录总数
     */
    @Select("SELECT COUNT(*) FROM t_fortune_record WHERE user_id = #{userId} AND deleted = 0")
    int countByUserId(@Param("userId") Long userId);
    
    /**
     * 根据ID查询记录
     */
    @Select("SELECT * FROM t_fortune_record WHERE id = #{id} AND deleted = 0")
    FortuneRecordPO selectById(@Param("id") Long id);
    
    /**
     * 删除记录（逻辑删除）
     */
    @Update("UPDATE t_fortune_record SET deleted = 1, updated_time = NOW() WHERE id = #{id}")
    int deleteById(@Param("id") Long id);
} 
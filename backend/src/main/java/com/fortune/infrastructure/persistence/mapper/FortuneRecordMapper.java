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
    @Insert("INSERT INTO t_fortune_record (user_id, user_name, birth_date, birth_time, lunar_date, " +
            "gan_zhi, wu_xing, wu_xing_lack, sheng_xiao, ai_analysis, deleted) " +
            "VALUES (#{userId}, #{userName}, #{birthDate}, #{birthTime}, #{lunarDate}, " +
            "#{ganZhi}, #{wuXing}, #{wuXingLack}, #{shengXiao}, #{aiAnalysis}, #{deleted})")
    @Options(useGeneratedKeys = true, keyProperty = "id")
    int insert(FortuneRecordPO record);
    
    /**
     * 根据用户ID查询历史记录（分页）
     */
    @Select("SELECT * FROM t_fortune_record WHERE user_id = #{userId} AND deleted = 0 " +
            "ORDER BY create_time DESC LIMIT #{offset}, #{limit}")
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
    @Update("UPDATE t_fortune_record SET deleted = 1, update_time = NOW() WHERE id = #{id}")
    int deleteById(@Param("id") Long id);
    
    /**
     * 检查表是否存在
     */
    @Select("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = #{tableName}")
    int checkTableExists(@Param("tableName") String tableName);
} 
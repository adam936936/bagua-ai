package com.fortune.infrastructure.persistence.mapper;

import com.fortune.infrastructure.persistence.po.UserPO;
import org.apache.ibatis.annotations.*;

import java.util.List;

/**
 * 用户数据访问接口
 * 
 * @author fortune
 * @since 2024-01-01
 */
@Mapper
public interface UserMapper {
    
    /**
     * 插入用户
     */
    @Insert("INSERT INTO t_users (openid, nickname, avatar_url, phone, vip_level, vip_expire_time, created_time, updated_time, deleted) " +
            "VALUES (#{openid}, #{nickname}, #{avatarUrl}, #{phone}, #{vipLevel}, #{vipExpireTime}, #{createdTime}, #{updatedTime}, #{deleted})")
    @Options(useGeneratedKeys = true, keyProperty = "id")
    int insert(UserPO user);
    
    /**
     * 根据OpenID查询用户
     */
    @Select("SELECT * FROM t_users WHERE openid = #{openid} AND deleted = 0")
    UserPO findByOpenId(String openid);
    
    /**
     * 根据ID查询用户
     */
    @Select("SELECT * FROM t_users WHERE id = #{id} AND deleted = 0")
    UserPO findById(Long id);
    
    /**
     * 更新用户信息
     */
    @Update("UPDATE t_users SET nickname = #{nickname}, avatar_url = #{avatarUrl}, phone = #{phone}, " +
            "vip_level = #{vipLevel}, vip_expire_time = #{vipExpireTime}, updated_time = #{updatedTime} " +
            "WHERE id = #{id}")
    int updateById(UserPO user);
    
    /**
     * 更新用户VIP信息
     */
    @Update("UPDATE t_users SET vip_level = #{vipLevel}, vip_expire_time = #{vipExpireTime}, updated_time = NOW() " +
            "WHERE id = #{id}")
    int updateVipInfo(@Param("id") Long id, @Param("vipLevel") Integer vipLevel, @Param("vipExpireTime") java.time.LocalDateTime vipExpireTime);
    
    /**
     * 删除用户（逻辑删除）
     */
    @Update("UPDATE t_users SET deleted = 1, updated_time = NOW() WHERE id = #{id}")
    int deleteById(Long id);
    
    /**
     * 获取用户列表（分页）
     */
    @Select("SELECT * FROM t_users WHERE deleted = 0 ORDER BY created_time DESC LIMIT #{offset}, #{limit}")
    List<UserPO> findUserList(@Param("offset") int offset, @Param("limit") int limit);
    
    /**
     * 统计用户总数
     */
    @Select("SELECT COUNT(*) FROM t_users WHERE deleted = 0")
    int countUsers();
} 
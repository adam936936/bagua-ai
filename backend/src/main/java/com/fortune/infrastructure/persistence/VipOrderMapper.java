package com.fortune.infrastructure.persistence;

import com.fortune.domain.model.VipOrder;
import org.apache.ibatis.annotations.*;

import java.util.List;

/**
 * VIP订单数据访问接口
 */
@Mapper
public interface VipOrderMapper {

    @Insert("INSERT INTO vip_orders (user_id, order_no, plan_type, amount, status, payment_method, expire_time, created_time, updated_time) " +
            "VALUES (#{userId}, #{orderNo}, #{planType}, #{amount}, #{status}, #{paymentMethod}, #{expireTime}, NOW(), NOW())")
    @Options(useGeneratedKeys = true, keyProperty = "id")
    int insert(VipOrder vipOrder);

    @Select("SELECT * FROM vip_orders WHERE order_no = #{orderNo} AND deleted = 0")
    VipOrder findByOrderNo(String orderNo);

    @Select("SELECT * FROM vip_orders WHERE user_id = #{userId} AND deleted = 0 ORDER BY created_time DESC")
    List<VipOrder> findByUserId(Long userId);

    @Select("SELECT * FROM vip_orders WHERE user_id = #{userId} AND status = 'paid' AND expire_time > NOW() AND deleted = 0 ORDER BY expire_time DESC LIMIT 1")
    VipOrder findActiveVipByUserId(Long userId);

    @Update("UPDATE vip_orders SET status = #{status}, transaction_id = #{transactionId}, updated_time = NOW() WHERE order_no = #{orderNo}")
    int updatePaymentStatus(@Param("orderNo") String orderNo, @Param("status") String status, @Param("transactionId") String transactionId);

    @Update("UPDATE vip_orders SET status = #{status}, updated_time = NOW() WHERE order_no = #{orderNo}")
    int updateStatus(@Param("orderNo") String orderNo, @Param("status") String status);

    @Select("SELECT COUNT(*) FROM vip_orders WHERE user_id = #{userId} AND status = 'paid' AND expire_time > NOW() AND deleted = 0")
    int countActiveVip(Long userId);
} 
<template>
  <view class="container">
    <view class="header">
      <text class="title">VIP会员</text>
      <text class="subtitle">解锁更多精准分析功能</text>
    </view>
    
    <view class="vip-cards">
      <view class="vip-card" v-for="(plan, index) in vipPlans" :key="index" 
            :class="{ 'popular': plan.popular }" @click="selectPlan(plan)">
        <view class="plan-badge" v-if="plan.popular">推荐</view>
        <view class="plan-name">{{ plan.name }}</view>
        <view class="plan-price">
          <text class="price">¥{{ plan.price }}</text>
          <text class="period">{{ plan.period }}</text>
        </view>
        <view class="plan-features">
          <view class="feature" v-for="feature in plan.features" :key="feature">
            <text class="feature-text">✓ {{ feature }}</text>
          </view>
        </view>
      </view>
    </view>
    
    <view class="current-status" v-if="userVipInfo.isVip">
      <view class="status-card">
        <text class="status-title">当前VIP状态</text>
        <text class="status-info">有效期至：{{ userVipInfo.expireDate }}</text>
      </view>
    </view>
    
    <view class="benefits">
      <view class="benefits-title">VIP特权</view>
      <view class="benefit-list">
        <view class="benefit-item">
          <text class="benefit-icon">🔮</text>
          <text class="benefit-text">无限次数分析</text>
        </view>
        <view class="benefit-item">
          <text class="benefit-icon">🎯</text>
          <text class="benefit-text">专业详细报告</text>
        </view>
        <view class="benefit-item">
          <text class="benefit-icon">💎</text>
          <text class="benefit-text">AI起名服务</text>
        </view>
        <view class="benefit-item">
          <text class="benefit-icon">📊</text>
          <text class="benefit-text">历史记录保存</text>
        </view>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref } from 'vue'

const vipPlans = ref([
  {
    name: '月度会员',
    price: 19.9,
    period: '/月',
    popular: false,
    features: ['无限次分析', '详细报告', 'AI起名']
  },
  {
    name: '年度会员',
    price: 199,
    period: '/年',
    popular: true,
    features: ['无限次分析', '详细报告', 'AI起名', '专属客服', '优先体验新功能']
  },
  {
    name: '单次分析',
    price: 9.9,
    period: '/次',
    popular: false,
    features: ['单次详细分析', '完整报告']
  }
])

const userVipInfo = ref({
  isVip: false,
  expireDate: ''
})

const selectPlan = (plan: any) => {
  uni.showModal({
    title: '确认购买',
    content: `确认购买${plan.name}（¥${plan.price}）？`,
    success: (res) => {
      if (res.confirm) {
        // 模拟支付流程
        uni.showLoading({
          title: '支付中...'
        })
        
        setTimeout(() => {
          uni.hideLoading()
          uni.showToast({
            title: '购买成功',
            icon: 'success'
          })
          
          // 更新VIP状态
          userVipInfo.value.isVip = true
          const expireDate = new Date()
          if (plan.period === '/月') {
            expireDate.setMonth(expireDate.getMonth() + 1)
          } else if (plan.period === '/年') {
            expireDate.setFullYear(expireDate.getFullYear() + 1)
          }
          userVipInfo.value.expireDate = expireDate.toLocaleDateString()
        }, 2000)
      }
    }
  })
}
</script>

<style scoped>
.container {
  padding: 40rpx;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  min-height: 100vh;
}

.header {
  text-align: center;
  margin-bottom: 60rpx;
}

.title {
  font-size: 48rpx;
  color: white;
  font-weight: bold;
  margin-bottom: 10rpx;
}

.subtitle {
  font-size: 28rpx;
  color: rgba(255,255,255,0.8);
}

.vip-cards {
  margin-bottom: 40rpx;
}

.vip-card {
  background: white;
  border-radius: 20rpx;
  padding: 40rpx;
  margin-bottom: 20rpx;
  position: relative;
  box-shadow: 0 10rpx 30rpx rgba(0,0,0,0.1);
}

.vip-card.popular {
  border: 4rpx solid #ff6b6b;
  transform: scale(1.02);
}

.plan-badge {
  position: absolute;
  top: -10rpx;
  right: 20rpx;
  background: #ff6b6b;
  color: white;
  padding: 10rpx 20rpx;
  border-radius: 20rpx;
  font-size: 24rpx;
}

.plan-name {
  font-size: 36rpx;
  font-weight: bold;
  color: #333;
  margin-bottom: 20rpx;
}

.plan-price {
  display: flex;
  align-items: baseline;
  margin-bottom: 30rpx;
}

.price {
  font-size: 48rpx;
  font-weight: bold;
  color: #667eea;
}

.period {
  font-size: 28rpx;
  color: #666;
  margin-left: 10rpx;
}

.plan-features {
  margin-bottom: 20rpx;
}

.feature {
  margin-bottom: 15rpx;
}

.feature-text {
  font-size: 28rpx;
  color: #333;
}

.current-status {
  margin-bottom: 40rpx;
}

.status-card {
  background: rgba(255,255,255,0.9);
  border-radius: 15rpx;
  padding: 30rpx;
  text-align: center;
}

.status-title {
  font-size: 32rpx;
  font-weight: bold;
  color: #333;
  margin-bottom: 10rpx;
}

.status-info {
  font-size: 28rpx;
  color: #666;
}

.benefits {
  background: rgba(255,255,255,0.9);
  border-radius: 20rpx;
  padding: 40rpx;
}

.benefits-title {
  font-size: 36rpx;
  font-weight: bold;
  color: #333;
  margin-bottom: 30rpx;
  text-align: center;
}

.benefit-list {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20rpx;
}

.benefit-item {
  display: flex;
  align-items: center;
  padding: 20rpx;
  background: #f8f9fa;
  border-radius: 10rpx;
}

.benefit-icon {
  font-size: 32rpx;
  margin-right: 15rpx;
}

.benefit-text {
  font-size: 28rpx;
  color: #333;
}
</style> 
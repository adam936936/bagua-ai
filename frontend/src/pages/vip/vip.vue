<template>
  <view class="container">
    <view class="header">
      <text class="title">VIP会员</text>
      <text class="subtitle">解锁更多专业功能</text>
    </view>
    
    <view class="vip-status" v-if="vipStore.isVip">
      <view class="vip-badge">
        <view class="vip-icon-bg">
          <text class="vip-icon">👑</text>
        </view>
        <view class="vip-info">
          <text class="vip-text">VIP会员</text>
          <text class="vip-plan">{{ getPlanName(vipStore.vipPlanType) }}</text>
        </view>
      </view>
      <text class="vip-expire">有效期至：{{ vipStore.formattedExpireTime }}</text>
    </view>
    
    <view class="privileges">
      <text class="privileges-title">VIP特权</text>
      <view class="privilege-grid">
        <view class="privilege-card">
          <view class="privilege-icon bg-purple">🔮</view>
          <text class="privilege-name">无限次分析</text>
          <text class="privilege-desc">每日不限次数的八字命理分析</text>
          <text class="privilege-status" :class="{ active: vipStore.isVip }">
            {{ vipStore.isVip ? '已开通' : '未开通' }}
          </text>
        </view>
        
        <view class="privilege-card">
          <view class="privilege-icon bg-blue">🤖</view>
          <text class="privilege-name">AI深度解读</text>
          <text class="privilege-desc">更详细的AI个性分析报告</text>
          <text class="privilege-status" :class="{ active: vipStore.isVip }">
            {{ vipStore.isVip ? '已开通' : '未开通' }}
          </text>
        </view>
        
        <view class="privilege-card">
          <view class="privilege-icon bg-green">✨</view>
          <text class="privilege-name">专属起名</text>
          <text class="privilege-desc">基于五行缺失的专业起名服务</text>
          <text class="privilege-status" :class="{ active: vipStore.isVip }">
            {{ vipStore.isVip ? '已开通' : '未开通' }}
          </text>
        </view>
        
        <view class="privilege-card">
          <view class="privilege-icon bg-orange">📊</view>
          <text class="privilege-name">历史记录</text>
          <text class="privilege-desc">无限保存分析历史记录</text>
          <text class="privilege-status" :class="{ active: vipStore.isVip }">
            {{ vipStore.isVip ? '已开通' : '未开通' }}
          </text>
        </view>
      </view>
    </view>
    
    <view class="pricing" v-if="!vipStore.isVip">
      <view class="plan-selection">
        <text class="pricing-title">选择套餐</text>
        <view class="pricing-list">
          <view 
            class="pricing-item" 
            :class="{ selected: selectedPlan === 'monthly' }"
            @tap="selectPlan('monthly')"
          >
            <view class="plan-header">
              <text class="plan-name">{{ getDisplayPlans.monthly.name }}</text>
              <text class="plan-badge" v-if="selectedPlan === 'monthly'">推荐</text>
            </view>
            <text class="plan-price">¥{{ getDisplayPlans.monthly.price }}<text class="plan-unit">/月</text></text>
            <text class="plan-desc">适合偶尔使用的用户</text>
          </view>
          
          <view 
            class="pricing-item popular" 
            :class="{ selected: selectedPlan === 'yearly' }"
            @tap="selectPlan('yearly')"
          >
            <view class="plan-header">
              <text class="plan-name">{{ getDisplayPlans.yearly.name }}</text>
              <text class="plan-badge">最划算</text>
            </view>
            <text class="plan-price">¥{{ getDisplayPlans.yearly.price }}<text class="plan-unit">/年</text></text>
            <text class="plan-desc">相当于每月{{ (getDisplayPlans.yearly.price / 12).toFixed(1) }}元，节省60%</text>
            <text class="plan-original">原价 ¥{{ (getDisplayPlans.monthly.price * 12).toFixed(1) }}</text>
          </view>
          
          <view 
            class="pricing-item" 
            :class="{ selected: selectedPlan === 'lifetime' }"
            @tap="selectPlan('lifetime')"
          >
            <view class="plan-header">
              <text class="plan-name">{{ getDisplayPlans.lifetime.name }}</text>
              <text class="plan-badge" v-if="selectedPlan === 'lifetime'">推荐</text>
            </view>
            <text class="plan-price">¥{{ getDisplayPlans.lifetime.price }}<text class="plan-unit">/终身</text></text>
            <text class="plan-desc">一次购买，终身享受</text>
          </view>
        </view>
        
        <view class="plan-actions">
          <button 
            class="purchase-btn" 
            @tap="purchase" 
            :disabled="!selectedPlan || vipStore.loading"
            :loading="vipStore.loading"
          >
            {{ vipStore.loading ? '处理中...' : '立即开通VIP' }}
          </button>
        </view>
      </view>
    </view>
    
    <view class="contact" v-if="vipStore.isVip">
      <text class="contact-title">专属服务</text>
      <button class="contact-btn" @tap="contactService">联系专属客服</button>
      <button class="orders-btn" @tap="viewOrders">查看订单记录</button>
    </view>
    
    <view class="loading-overlay" v-if="vipStore.loading">
      <view class="loading-content">
        <view class="loading-spinner"></view>
        <text class="loading-text">处理中...</text>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useVipStore } from '@/store/modules/vip'

const vipStore = useVipStore()
const selectedPlan = ref('yearly')
const showPlans = ref(true) // 默认显示套餐选择

// 默认套餐数据（防止后端数据加载失败）
const defaultPlans = {
  monthly: { name: '月度会员', price: 19.90 },
  yearly: { name: '年度会员', price: 99.90 },
  lifetime: { name: '终身会员', price: 199.90 }
}

// 获取显示的套餐数据（优先使用后端数据，否则使用默认数据）
const getDisplayPlans = computed(() => {
  const hasBackendData = Object.keys(vipStore.vipPlans).length > 0
  if (hasBackendData) {
    return vipStore.vipPlans
  }
  return defaultPlans
})

onMounted(async () => {
  try {
    await Promise.all([
      vipStore.loadVipStatus(),
      vipStore.loadVipPlans()
    ])
  } catch (error) {
    console.error('加载VIP数据失败:', error)
    // 即使加载失败，也使用默认数据
  }
})

// 移除了showPlanSelection和hidePlanSelection方法，因为现在默认显示套餐

const selectPlan = (plan: string) => {
  selectedPlan.value = plan
}

const getPlanName = (planType?: string) => {
  if (!planType) return ''
  const planNames = {
    monthly: '月度会员',
    yearly: '年度会员',
    lifetime: '终身会员'
  }
  return planNames[planType] || planType
}

const purchase = async () => {
  if (!selectedPlan.value) {
    uni.showToast({
      title: '请选择套餐',
      icon: 'none'
    })
    return
  }
  
  try {
    const planName = getPlanName(selectedPlan.value)
    const planPrice = getDisplayPlans.value[selectedPlan.value]?.price || 0
    
    const result = await uni.showModal({
      title: '开通VIP',
      content: `确认开通${planName}？\n价格：¥${planPrice}`,
      confirmText: '确认支付',
      cancelText: '取消'
    })
    
    if (result.confirm) {
      await vipStore.purchaseVip(selectedPlan.value, true)
      
      uni.showToast({
        title: 'VIP开通成功！',
        icon: 'success',
        duration: 2000
      })
    }
  } catch (error) {
    console.error('购买VIP失败:', error)
    uni.showToast({
      title: error.message || '开通失败，请重试',
      icon: 'none',
      duration: 2000
    })
  }
}

const contactService = () => {
  uni.showModal({
    title: '专属客服',
    content: '客服微信：fortune-ai\n工作时间：9:00-21:00\n\n感谢您成为VIP会员！',
    showCancel: false,
    confirmText: '知道了'
  })
}

const viewOrders = async () => {
  try {
    await vipStore.loadUserOrders()
    
    if (vipStore.userOrders.length === 0) {
      uni.showToast({
        title: '暂无订单记录',
        icon: 'none'
      })
      return
    }
    
    const orderList = vipStore.userOrders.map(order => 
      `订单号：${order.orderNo}\n套餐：${getPlanName(order.planType)}\n金额：¥${order.amount}`
    ).join('\n\n')
    
    uni.showModal({
      title: '订单记录',
      content: orderList,
      showCancel: false,
      confirmText: '知道了'
    })
  } catch (error) {
    console.error('获取订单失败:', error)
    uni.showToast({
      title: '获取订单失败',
      icon: 'none'
    })
  }
}
</script>

<style lang="scss" scoped>
.container {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 40rpx 0 0 0;
}

.header {
  text-align: center;
  margin-bottom: 30rpx;
  padding-top: 40rpx;
  
  .title {
    display: block;
    font-size: 56rpx;
    font-weight: bold;
    color: white;
    margin-bottom: 10rpx;
  }
  
  .subtitle {
    display: block;
    font-size: 28rpx;
    color: rgba(255, 255, 255, 0.8);
  }
}

.vip-status {
  background: rgba(255, 255, 255, 0.95);
  border-radius: 20rpx;
  padding: 40rpx;
  margin: 0 32rpx 32rpx 32rpx;
  box-shadow: 0 8rpx 32rpx rgba(0, 0, 0, 0.1);
  
  .vip-badge {
    display: flex;
    align-items: center;
    margin-bottom: 20rpx;
    
    .vip-icon-bg {
      width: 80rpx;
      height: 80rpx;
      border-radius: 50%;
      background: linear-gradient(135deg, #ffd700 0%, #ffed4e 100%);
      display: flex;
      align-items: center;
      justify-content: center;
      margin-right: 20rpx;
      
      .vip-icon {
        font-size: 40rpx;
        color: #8b4513;
      }
    }
    
    .vip-info {
      flex: 1;
      
      .vip-text {
        display: block;
        font-size: 32rpx;
        font-weight: bold;
        color: #333;
        margin-bottom: 5rpx;
      }
      
      .vip-plan {
        display: block;
        font-size: 24rpx;
        color: #666;
      }
    }
  }
  
  .vip-expire {
    display: block;
    font-size: 28rpx;
    color: #666;
    text-align: center;
  }
}

.privileges {
  background: #f7f9fb;
  border-radius: 24rpx;
  margin: 0 32rpx 32rpx 32rpx;
  padding: 32rpx 0 20rpx 0;
  
  .privileges-title {
    display: block;
    font-size: 32rpx;
    font-weight: bold;
    color: #333;
    margin-bottom: 25rpx;
    text-align: center;
  }
  
  .privilege-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 24rpx;
    padding: 0 32rpx;
    
    .privilege-card {
      background: #fff;
      border-radius: 24rpx;
      box-shadow: 0 2rpx 12rpx rgba(0,0,0,0.06);
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 32rpx 20rpx 24rpx 20rpx;
      text-align: center;
      
      .privilege-icon {
        width: 60rpx;
        height: 60rpx;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 28rpx;
        color: #fff;
        margin-bottom: 16rpx;
        font-weight: bold;
      }
      
      .bg-purple { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }
      .bg-blue { background: linear-gradient(135deg, #43a3f7 0%, #38b6ff 100%); }
      .bg-green { background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%); }
      .bg-orange { background: linear-gradient(135deg, #ffb347 0%, #ff7e5f 100%); }
      
      .privilege-name {
        font-size: 24rpx;
        font-weight: 600;
        color: #222;
        margin-bottom: 8rpx;
      }
      
      .privilege-desc {
        font-size: 20rpx;
        color: #888;
        line-height: 1.4;
        margin-bottom: 12rpx;
      }
      
      .privilege-status {
        font-size: 20rpx;
        color: #ccc;
        padding: 6rpx 12rpx;
        border-radius: 10rpx;
        background: #f5f5f5;
        
        &.active {
          color: #4caf50;
          background: #e8f5e8;
        }
      }
    }
  }
}

.pricing {
  background: rgba(255, 255, 255, 0.95);
  border-radius: 20rpx;
  padding: 40rpx;
  margin: 0 32rpx 32rpx 32rpx;
  box-shadow: 0 8rpx 32rpx rgba(0, 0, 0, 0.1);
  
  .select-plan-section {
    text-align: center;
    margin-bottom: 20rpx;
    
    .select-plan-btn,
    .purchase-btn {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      border: none;
      border-radius: 50rpx;
      padding: 20rpx 40rpx;
      font-size: 28rpx;
      margin-bottom: 15rpx;
      width: 100%;
      
      &:last-child {
        margin-bottom: 0;
      }
    }
  }
  
  .plan-selection {
    .pricing-title {
      display: block;
      font-size: 32rpx;
      font-weight: bold;
      color: #333;
      margin-bottom: 25rpx;
      text-align: center;
    }
    
    .pricing-list {
      .pricing-item {
        border: 3rpx solid #e0e0e0;
        border-radius: 16rpx;
        padding: 25rpx;
        margin-bottom: 20rpx;
        position: relative;
        transition: all 0.3s ease;
        
        &.selected {
          border-color: #667eea;
          background: #f8f9ff;
        }
        
        &.popular {
          border-color: #ff6b6b;
          
          &::before {
            content: '推荐';
            position: absolute;
            top: -10rpx;
            right: 20rpx;
            background: #ff6b6b;
            color: white;
            font-size: 20rpx;
            padding: 4rpx 12rpx;
            border-radius: 8rpx;
          }
        }
        
        .plan-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 15rpx;
          
          .plan-name {
            font-size: 28rpx;
            font-weight: bold;
            color: #333;
          }
          
          .plan-badge {
            background: #667eea;
            color: white;
            font-size: 20rpx;
            padding: 4rpx 12rpx;
            border-radius: 8rpx;
          }
        }
        
        .plan-price {
          font-size: 36rpx;
          font-weight: bold;
          color: #667eea;
          margin-bottom: 10rpx;
          
          .plan-unit {
            font-size: 24rpx;
            color: #999;
          }
        }
        
        .plan-desc {
          font-size: 24rpx;
          color: #666;
          margin-bottom: 8rpx;
        }
        
        .plan-original {
          font-size: 22rpx;
          color: #999;
          text-decoration: line-through;
        }
      }
    }
    
    .plan-actions {
      margin-top: 30rpx;
      
      .purchase-btn {
        width: 100%;
        background: linear-gradient(90deg, #7f7fd5 0%, #86a8e7 50%, #91eac9 100%);
        color: #fff;
        border: none;
        border-radius: 60rpx;
        font-size: 32rpx;
        font-weight: 600;
        padding: 24rpx 0;
        box-shadow: 0 4rpx 24rpx rgba(118, 75, 162, 0.10);
        letter-spacing: 2rpx;
        
        &:disabled {
          opacity: 0.6;
        }
        
        &:active {
          transform: scale(0.97);
          opacity: 0.92;
        }
      }
    }
  }
}

.contact {
  background: rgba(255, 255, 255, 0.95);
  border-radius: 20rpx;
  padding: 40rpx;
  margin: 0 32rpx 32rpx 32rpx;
  box-shadow: 0 8rpx 32rpx rgba(0, 0, 0, 0.1);
  
  .contact-title {
    display: block;
    font-size: 32rpx;
    font-weight: bold;
    color: #333;
    margin-bottom: 25rpx;
    text-align: center;
  }
  
  .contact-btn,
  .orders-btn {
    width: 100%;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    border: none;
    border-radius: 15rpx;
    padding: 20rpx;
    font-size: 28rpx;
    font-weight: bold;
    margin-bottom: 15rpx;
    
    &:last-child {
      margin-bottom: 0;
    }
  }
  
  .orders-btn {
    background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
  }
}

.loading-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
  
  .loading-content {
    background: white;
    border-radius: 20rpx;
    padding: 40rpx;
    text-align: center;
    
    .loading-spinner {
      width: 60rpx;
      height: 60rpx;
      border: 4rpx solid #f3f3f3;
      border-top: 4rpx solid #667eea;
      border-radius: 50%;
      animation: spin 1s linear infinite;
      margin: 0 auto 20rpx;
    }
    
    .loading-text {
      font-size: 28rpx;
      color: #666;
    }
  }
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
</style> 
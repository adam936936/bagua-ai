<template>
  <view class="container">
    <view class="header">
      <text class="title">VIP会员</text>
      <text class="subtitle">解锁更多专业功能</text>
    </view>
    
    <view class="vip-status" v-if="isVip">
      <view class="vip-badge">
        <text class="vip-icon">👑</text>
        <text class="vip-text">VIP会员</text>
      </view>
      <text class="vip-expire">有效期至：{{ vipExpireDate }}</text>
    </view>
    
    <view class="privileges">
      <text class="privileges-title">VIP特权</text>
      <view class="privilege-list">
        <view class="privilege-item">
          <text class="privilege-icon">🔮</text>
          <view class="privilege-content">
            <text class="privilege-name">无限次分析</text>
            <text class="privilege-desc">每日不限次数的八字命理分析</text>
          </view>
          <text class="privilege-status" :class="{ active: isVip }">
            {{ isVip ? '已开通' : '未开通' }}
          </text>
        </view>
        
        <view class="privilege-item">
          <text class="privilege-icon">🤖</text>
          <view class="privilege-content">
            <text class="privilege-name">AI深度解读</text>
            <text class="privilege-desc">更详细的AI个性分析报告</text>
          </view>
          <text class="privilege-status" :class="{ active: isVip }">
            {{ isVip ? '已开通' : '未开通' }}
          </text>
        </view>
        
        <view class="privilege-item">
          <text class="privilege-icon">✨</text>
          <view class="privilege-content">
            <text class="privilege-name">专属起名</text>
            <text class="privilege-desc">基于五行缺失的专业起名服务</text>
          </view>
          <text class="privilege-status" :class="{ active: isVip }">
            {{ isVip ? '已开通' : '未开通' }}
          </text>
        </view>
        
        <view class="privilege-item">
          <text class="privilege-icon">📊</text>
          <view class="privilege-content">
            <text class="privilege-name">历史记录</text>
            <text class="privilege-desc">无限保存分析历史记录</text>
          </view>
          <text class="privilege-status" :class="{ active: isVip }">
            {{ isVip ? '已开通' : '未开通' }}
          </text>
        </view>
        
        <view class="privilege-item">
          <text class="privilege-icon">🎯</text>
          <view class="privilege-content">
            <text class="privilege-name">专属客服</text>
            <text class="privilege-desc">一对一专业命理咨询服务</text>
          </view>
          <text class="privilege-status" :class="{ active: isVip }">
            {{ isVip ? '已开通' : '未开通' }}
          </text>
        </view>
      </view>
    </view>
    
    <view class="pricing" v-if="!isVip">
      <text class="pricing-title">选择套餐</text>
      <view class="pricing-list">
        <view 
          class="pricing-item" 
          :class="{ selected: selectedPlan === 'monthly' }"
          @tap="selectPlan('monthly')"
        >
          <view class="plan-header">
            <text class="plan-name">月度会员</text>
            <text class="plan-badge" v-if="selectedPlan === 'monthly'">推荐</text>
          </view>
          <text class="plan-price">¥19.9<text class="plan-unit">/月</text></text>
          <text class="plan-desc">适合偶尔使用的用户</text>
        </view>
        
        <view 
          class="pricing-item popular" 
          :class="{ selected: selectedPlan === 'yearly' }"
          @tap="selectPlan('yearly')"
        >
          <view class="plan-header">
            <text class="plan-name">年度会员</text>
            <text class="plan-badge">最划算</text>
          </view>
          <text class="plan-price">¥99.9<text class="plan-unit">/年</text></text>
          <text class="plan-desc">相当于每月8.3元，节省60%</text>
          <text class="plan-original">原价 ¥238.8</text>
        </view>
        
        <view 
          class="pricing-item" 
          :class="{ selected: selectedPlan === 'lifetime' }"
          @tap="selectPlan('lifetime')"
        >
          <view class="plan-header">
            <text class="plan-name">终身会员</text>
            <text class="plan-badge" v-if="selectedPlan === 'lifetime'">推荐</text>
          </view>
          <text class="plan-price">¥199.9<text class="plan-unit">/终身</text></text>
          <text class="plan-desc">一次购买，终身享受</text>
        </view>
      </view>
      
      <button class="purchase-btn" @tap="purchase" :disabled="!selectedPlan">
        立即开通VIP
      </button>
    </view>
    
    <view class="contact" v-if="isVip">
      <text class="contact-title">专属服务</text>
      <button class="contact-btn" @tap="contactService">联系专属客服</button>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useUserStore } from '@/store/modules/user'

const userStore = useUserStore()

const selectedPlan = ref('yearly')

const isVip = computed(() => userStore.isVip)
const vipExpireDate = computed(() => {
  if (!userStore.vipExpireTime) return ''
  const date = new Date(userStore.vipExpireTime)
  return `${date.getFullYear()}年${(date.getMonth() + 1).toString().padStart(2, '0')}月${date.getDate().toString().padStart(2, '0')}日`
})

const selectPlan = (plan: string) => {
  selectedPlan.value = plan
}

const purchase = () => {
  if (!selectedPlan.value) return
  
  // 这里应该调用微信支付
  uni.showModal({
    title: '开通VIP',
    content: `确认开通${getPlanName(selectedPlan.value)}？`,
    confirmText: '确认支付',
    cancelText: '取消',
    success: (res) => {
      if (res.confirm) {
        // 模拟支付成功
        uni.showLoading({
          title: '支付中...',
          mask: true
        })
        
        setTimeout(() => {
          uni.hideLoading()
          userStore.setVip(true)
          uni.showToast({
            title: 'VIP开通成功',
            icon: 'success'
          })
        }, 2000)
      }
    }
  })
}

const getPlanName = (plan: string) => {
  const names = {
    monthly: '月度会员',
    yearly: '年度会员',
    lifetime: '终身会员'
  }
  return names[plan] || ''
}

const contactService = () => {
  uni.showModal({
    title: '专属客服',
    content: '客服微信：fortune-ai\n工作时间：9:00-21:00',
    showCancel: false,
    confirmText: '知道了'
  })
}
</script>

<style lang="scss" scoped>
.container {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 40rpx 30rpx;
}

.header {
  text-align: center;
  margin-bottom: 40rpx;
  
  .title {
    display: block;
    font-size: 48rpx;
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
  background: linear-gradient(135deg, #ffd700 0%, #ffed4e 100%);
  border-radius: 20rpx;
  padding: 30rpx;
  text-align: center;
  margin-bottom: 40rpx;
  
  .vip-badge {
    display: flex;
    align-items: center;
    justify-content: center;
    margin-bottom: 15rpx;
    
    .vip-icon {
      font-size: 40rpx;
      margin-right: 10rpx;
    }
    
    .vip-text {
      font-size: 32rpx;
      font-weight: bold;
      color: #333;
    }
  }
  
  .vip-expire {
    font-size: 24rpx;
    color: #666;
  }
}

.privileges {
  background: white;
  border-radius: 20rpx;
  padding: 40rpx;
  margin-bottom: 40rpx;
  
  .privileges-title {
    display: block;
    font-size: 32rpx;
    font-weight: bold;
    color: #333;
    margin-bottom: 30rpx;
    text-align: center;
  }
  
  .privilege-list {
    .privilege-item {
      display: flex;
      align-items: center;
      padding: 25rpx 0;
      border-bottom: 1rpx solid #f0f0f0;
      
      &:last-child {
        border-bottom: none;
      }
      
      .privilege-icon {
        font-size: 40rpx;
        margin-right: 20rpx;
      }
      
      .privilege-content {
        flex: 1;
        
        .privilege-name {
          display: block;
          font-size: 28rpx;
          font-weight: bold;
          color: #333;
          margin-bottom: 5rpx;
        }
        
        .privilege-desc {
          display: block;
          font-size: 24rpx;
          color: #999;
        }
      }
      
      .privilege-status {
        font-size: 24rpx;
        color: #999;
        
        &.active {
          color: #667eea;
          font-weight: bold;
        }
      }
    }
  }
}

.pricing {
  background: white;
  border-radius: 20rpx;
  padding: 40rpx;
  margin-bottom: 40rpx;
  
  .pricing-title {
    display: block;
    font-size: 32rpx;
    font-weight: bold;
    color: #333;
    margin-bottom: 30rpx;
    text-align: center;
  }
  
  .pricing-list {
    margin-bottom: 40rpx;
    
    .pricing-item {
      border: 2rpx solid #e0e0e0;
      border-radius: 15rpx;
      padding: 30rpx;
      margin-bottom: 20rpx;
      position: relative;
      
      &.selected {
        border-color: #667eea;
        background: #f8f9ff;
      }
      
      &.popular {
        border-color: #ffd700;
        background: linear-gradient(135deg, #fff9e6 0%, #fffbf0 100%);
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
          padding: 5rpx 10rpx;
          border-radius: 10rpx;
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
        display: block;
        font-size: 24rpx;
        color: #666;
        margin-bottom: 5rpx;
      }
      
      .plan-original {
        display: block;
        font-size: 20rpx;
        color: #999;
        text-decoration: line-through;
      }
    }
  }
  
  .purchase-btn {
    width: 100%;
    height: 80rpx;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    border: none;
    border-radius: 15rpx;
    font-size: 32rpx;
    font-weight: bold;
    
    &[disabled] {
      opacity: 0.6;
      background: #ccc;
    }
  }
}

.contact {
  background: white;
  border-radius: 20rpx;
  padding: 40rpx;
  text-align: center;
  
  .contact-title {
    display: block;
    font-size: 32rpx;
    font-weight: bold;
    color: #333;
    margin-bottom: 30rpx;
  }
  
  .contact-btn {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    border: none;
    border-radius: 15rpx;
    padding: 20rpx 40rpx;
    font-size: 28rpx;
    font-weight: bold;
  }
}
</style> 
<template>
  <view class="container">
    <view class="header">
      <text class="title">AI八卦运势</text>
      <text class="subtitle">传统命理 × 现代AI</text>
    </view>
    
    <view class="today-fortune">
      <view class="fortune-header">
        <text class="fortune-title">🌟 今日运势</text>
        <text class="fortune-date">{{ currentDate }}</text>
      </view>
      <text class="fortune-content">{{ todayFortune }}</text>
    </view>
    
    <view class="quick-actions">
      <view class="action-card" @tap="goToCalculate">
        <view class="action-icon">🔮</view>
        <text class="action-title">八字测算</text>
        <text class="action-desc">专业八字命理分析</text>
      </view>
      
      <view class="action-card" @tap="goToNameRecommend">
        <view class="action-icon">✨</view>
        <text class="action-title">AI起名</text>
        <text class="action-desc">智能推荐好名字</text>
      </view>
    </view>
    
    <view class="features">
      <text class="features-title">核心功能</text>
      <view class="feature-list">
        <view class="feature-item">
          <text class="feature-icon">🎯</text>
          <text class="feature-text">精准八字分析</text>
        </view>
        <view class="feature-item">
          <text class="feature-icon">🤖</text>
          <text class="feature-text">AI智能解读</text>
        </view>
        <view class="feature-item">
          <text class="feature-icon">📊</text>
          <text class="feature-text">五行缺失分析</text>
        </view>
        <view class="feature-item">
          <text class="feature-icon">💎</text>
          <text class="feature-text">姓名推荐</text>
        </view>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useFortuneStore } from '@/store/modules/fortune'

const fortuneStore = useFortuneStore()

const currentDate = ref('')
const todayFortune = computed(() => fortuneStore.todayFortune || '今日运势良好，万事如意！')

onMounted(async () => {
  // 设置当前日期
  const now = new Date()
  const year = now.getFullYear()
  const month = (now.getMonth() + 1).toString().padStart(2, '0')
  const day = now.getDate().toString().padStart(2, '0')
  currentDate.value = `${year}年${month}月${day}日`
  
  // 加载今日运势
  try {
    await fortuneStore.loadTodayFortune()
  } catch (error) {
    console.error('加载今日运势失败:', error)
  }
})

const goToCalculate = () => {
  uni.navigateTo({
    url: '/pages/calculate/calculate'
  })
}

const goToNameRecommend = () => {
  uni.navigateTo({
    url: '/pages/name-recommend/name-recommend'
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
  margin-bottom: 60rpx;
  padding-top: 40rpx;
  
  .title {
    display: block;
    font-size: 56rpx;
    font-weight: bold;
    color: white;
    margin-bottom: 15rpx;
  }
  
  .subtitle {
    display: block;
    font-size: 28rpx;
    color: rgba(255, 255, 255, 0.8);
  }
}

.today-fortune {
  background: rgba(255, 255, 255, 0.95);
  border-radius: 20rpx;
  padding: 40rpx;
  margin-bottom: 40rpx;
  box-shadow: 0 8rpx 32rpx rgba(0, 0, 0, 0.1);
  
  .fortune-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 25rpx;
    
    .fortune-title {
      font-size: 32rpx;
      font-weight: bold;
      color: #333;
    }
    
    .fortune-date {
      font-size: 24rpx;
      color: #999;
    }
  }
  
  .fortune-content {
    display: block;
    font-size: 28rpx;
    line-height: 1.8;
    color: #666;
  }
}

.quick-actions {
  display: flex;
  gap: 20rpx;
  margin-bottom: 40rpx;
  
  .action-card {
    flex: 1;
    background: rgba(255, 255, 255, 0.95);
    border-radius: 20rpx;
    padding: 40rpx 30rpx;
    text-align: center;
    box-shadow: 0 8rpx 32rpx rgba(0, 0, 0, 0.1);
    
    .action-icon {
      font-size: 60rpx;
      margin-bottom: 20rpx;
    }
    
    .action-title {
      display: block;
      font-size: 32rpx;
      font-weight: bold;
      color: #333;
      margin-bottom: 10rpx;
    }
    
    .action-desc {
      display: block;
      font-size: 24rpx;
      color: #999;
    }
  }
}

.features {
  background: rgba(255, 255, 255, 0.95);
  border-radius: 20rpx;
  padding: 40rpx;
  box-shadow: 0 8rpx 32rpx rgba(0, 0, 0, 0.1);
  
  .features-title {
    display: block;
    font-size: 32rpx;
    font-weight: bold;
    color: #333;
    margin-bottom: 30rpx;
    text-align: center;
  }
  
  .feature-list {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 25rpx;
    
    .feature-item {
      display: flex;
      align-items: center;
      
      .feature-icon {
        font-size: 36rpx;
        margin-right: 15rpx;
      }
      
      .feature-text {
        font-size: 28rpx;
        color: #666;
      }
    }
  }
}
</style> 
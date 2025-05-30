<template>
  <view class="container">
    <view class="header">
      <text class="title">AI八卦运势</text>
      <text class="subtitle">专业命理分析，智能起名推荐</text>
    </view>
    
    <view class="today-fortune">
      <view class="fortune-header">
        <text class="fortune-title">今日运势</text>
      </view>
      <view v-if="fortuneLoading" class="fortune-loading">
        <text class="fortune-loading-text">正在获取今日运势...</text>
        <view class="fortune-loading-bar">
          <view class="fortune-loading-bar-inner"></view>
        </view>
      </view>
      <text v-else-if="todayFortune" class="fortune-content">{{ todayFortune }}</text>
      <button class="fortune-btn" @tap="onTodayFortuneClick">点击获取今日运势</button>
    </view>

    <view class="features">
      <view class="feature-grid">
        <view class="feature-card" @tap="goToCalculate">
          <view class="feature-icon bg-orange">八</view>
          <text class="feature-title">八字测算</text>
          <text class="feature-desc">专业命理分析</text>
        </view>
        <view class="feature-card" @tap="goToNameRecommend">
          <view class="feature-icon bg-green">名</view>
          <text class="feature-title">AI起名</text>
          <text class="feature-desc">智能姓名推荐</text>
        </view>
        <view class="feature-card" @tap="goToHistory">
          <view class="feature-icon bg-blue">史</view>
          <text class="feature-title">历史记录</text>
          <text class="feature-desc">查看测算历史</text>
        </view>
        <view class="feature-card" @tap="goToVip">
          <view class="feature-icon bg-pink">VIP</view>
          <text class="feature-title">会员中心</text>
          <text class="feature-desc">解锁更多功能</text>
        </view>
      </view>
    </view>

    <view class="start-action">
      <button class="start-btn" @tap="goToCalculate">开始免费测算</button>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useFortuneStore } from '@/store/modules/fortune'

const fortuneStore = useFortuneStore()

const currentDate = ref('')
const todayFortune = computed(() => fortuneStore.todayFortune)
const fortuneLoading = ref(false)

onMounted(() => {
  // 设置当前日期
  const now = new Date()
  const year = now.getFullYear()
  const month = (now.getMonth() + 1).toString().padStart(2, '0')
  const day = now.getDate().toString().padStart(2, '0')
  currentDate.value = `${year}年${month}月${day}日`
  // 不再自动请求今日运势
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

const goToHistory = async () => {
  try {
    await fortuneStore.loadHistory()
    uni.navigateTo({ url: '/pages/history/history' })
  } catch (e) {
    uni.showToast({ title: '加载历史失败', icon: 'none' })
  }
}

const goToVip = () => {
  uni.navigateTo({ url: '/pages/vip/vip' })
}

const onTodayFortuneClick = async () => {
  // 如果已经有运势内容，不重复请求
  if (todayFortune.value && !fortuneLoading.value) {
    return
  }
  
  fortuneLoading.value = true
  try {
    // 添加最小加载时间，避免闪烁
    const [result] = await Promise.all([
      fortuneStore.loadTodayFortune(),
      new Promise(resolve => setTimeout(resolve, 800))
    ])
    
    if (!todayFortune.value) {
      uni.showToast({ 
        title: '获取运势失败，请稍后重试', 
        icon: 'none',
        duration: 2000
      })
    }
  } catch (e) {
    console.error('获取今日运势失败:', e)
    uni.showToast({ 
      title: '网络异常，请检查网络连接', 
      icon: 'none',
      duration: 2000
    })
  } finally {
    fortuneLoading.value = false
  }
}
</script>

<style lang="scss" scoped>
.container {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 40rpx 0 60rpx 0;
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
    color: rgba(255, 255, 255, 0.9);
  }
}

.today-fortune {
  background: rgba(255, 255, 255, 0.95);
  border-radius: 20rpx;
  padding: 40rpx;
  margin: 0 32rpx 32rpx 32rpx;
  box-shadow: 0 8rpx 32rpx rgba(0, 0, 0, 0.1);
  
  .fortune-header {
    margin-bottom: 20rpx;
    
    .fortune-title {
      font-size: 32rpx;
      font-weight: bold;
      color: #333;
    }
  }
  
  .fortune-loading {
    margin-bottom: 20rpx;
    
    .fortune-loading-text {
      font-size: 26rpx;
      color: #888;
      margin-bottom: 10rpx;
      display: block;
    }
    
    .fortune-loading-bar {
      width: 100%;
      height: 18rpx;
      background: #e0e7ff;
      border-radius: 9rpx;
      overflow: hidden;
      
      .fortune-loading-bar-inner {
        width: 60%;
        height: 100%;
        background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
        border-radius: 9rpx;
        animation: loadingBar 1.2s infinite linear alternate;
      }
    }
  }
  
  .fortune-content {
    display: block;
    font-size: 28rpx;
    line-height: 1.8;
    color: #666;
    margin-bottom: 20rpx;
  }
  
  .fortune-btn {
    width: 100%;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    border: none;
    border-radius: 15rpx;
    font-size: 28rpx;
    font-weight: bold;
    padding: 20rpx 0;
    margin-top: 10rpx;
  }
}

@keyframes loadingBar {
  0% { width: 30%; }
  100% { width: 90%; }
}

.features {
  background: rgba(255, 255, 255, 0.95);
  border-radius: 20rpx;
  margin: 0 32rpx 32rpx 32rpx;
  padding: 32rpx;
  box-shadow: 0 8rpx 32rpx rgba(0, 0, 0, 0.1);
  
  .feature-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 24rpx;
  }
  
  .feature-card {
    background: #fff;
    border-radius: 16rpx;
    box-shadow: 0 4rpx 16rpx rgba(0,0,0,0.08);
    display: flex;
    flex-direction: column;
    align-items: center;
    padding: 32rpx 16rpx;
    
    .feature-icon {
      width: 80rpx;
      height: 80rpx;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 40rpx;
      color: #fff;
      margin-bottom: 16rpx;
      font-weight: bold;
    }
    
    .bg-orange { 
      background: linear-gradient(135deg, #ffb347 0%, #ff7e5f 100%); 
    }
    
    .bg-green { 
      background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%); 
    }
    
    .bg-blue { 
      background: linear-gradient(135deg, #43a3f7 0%, #38b6ff 100%); 
    }
    
    .bg-pink { 
      background: linear-gradient(135deg, #ff6a88 0%, #ff99ac 100%); 
    }
    
    .feature-title {
      font-size: 28rpx;
      font-weight: 600;
      color: #222;
      margin-bottom: 8rpx;
    }
    
    .feature-desc {
      font-size: 22rpx;
      color: #888;
      text-align: center;
    }
  }
}

.start-action {
  width: 100%;
  margin: 48rpx 0 0 0;
  display: flex;
  justify-content: center;
  
  .start-btn {
    width: 600rpx;
    height: 100rpx;
    background: linear-gradient(135deg, #ff6a88 0%, #ff99ac 100%);
    color: white;
    border: none;
    border-radius: 50rpx;
    font-size: 32rpx;
    font-weight: bold;
    box-shadow: 0 8rpx 24rpx rgba(255, 106, 136, 0.4);
  }
}
</style> 
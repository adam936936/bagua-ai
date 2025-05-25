<template>
  <view class="index-page">
    <!-- 头部区域 -->
    <view class="header">
      <view class="header-bg"></view>
      <view class="header-content">
        <text class="app-title">AI八卦运势</text>
        <text class="app-subtitle">专业命理分析，智能起名推荐</text>
      </view>
    </view>

    <!-- 今日运势卡片 -->
    <view class="today-fortune-card">
      <view class="card-header">
        <text class="card-title">今日运势</text>
        <text class="card-date">{{ todayDate }}</text>
      </view>
      <view class="fortune-content">
        <text v-if="todayFortune" class="fortune-text">{{ todayFortune }}</text>
        <text v-else class="fortune-loading">正在获取今日运势...</text>
      </view>
      <button class="refresh-btn" @click="refreshTodayFortune" :disabled="loading">
        <text>{{ loading ? '刷新中...' : '刷新运势' }}</text>
      </button>
    </view>

    <!-- 功能导航 -->
    <view class="function-nav">
      <view class="nav-title">
        <text class="title-text">核心功能</text>
      </view>
      <view class="nav-grid">
        <view class="nav-item" @click="goToCalculate">
          <view class="nav-icon calculate-icon">
            <text class="icon-text">八</text>
          </view>
          <text class="nav-label">八字测算</text>
          <text class="nav-desc">专业命理分析</text>
        </view>
        
        <view class="nav-item" @click="goToNameRecommend">
          <view class="nav-icon name-icon">
            <text class="icon-text">名</text>
          </view>
          <text class="nav-label">AI起名</text>
          <text class="nav-desc">智能姓名推荐</text>
        </view>
        
        <view class="nav-item" @click="goToHistory">
          <view class="nav-icon history-icon">
            <text class="icon-text">史</text>
          </view>
          <text class="nav-label">历史记录</text>
          <text class="nav-desc">查看测算历史</text>
        </view>
        
        <view class="nav-item" @click="goToVip">
          <view class="nav-icon vip-icon">
            <text class="icon-text">VIP</text>
          </view>
          <text class="nav-label">会员中心</text>
          <text class="nav-desc">解锁更多功能</text>
        </view>
      </view>
    </view>

    <!-- 开始测算按钮 -->
    <view class="start-section">
      <button class="start-btn" @click="startCalculation">
        <text class="btn-text">开始免费测算</text>
      </button>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useFortuneStore } from '@/store/modules/fortune'
import { formatDate } from '@/utils/date'

// 状态管理
const fortuneStore = useFortuneStore()

// 响应式数据
const loading = ref(false)
const todayFortune = ref('')
const todayDate = ref(formatDate(new Date(), 'MM月DD日'))

// 页面加载
onMounted(() => {
  loadTodayFortune()
})

// 加载今日运势
const loadTodayFortune = async () => {
  try {
    const fortune = await fortuneStore.getTodayFortune()
    todayFortune.value = fortune
  } catch (error) {
    console.error('获取今日运势失败:', error)
    todayFortune.value = '今日运势良好，事业上会有新的机遇，财运稳中有升，感情方面需要多沟通理解，健康状况良好，建议保持积极乐观的心态。'
  }
}

// 刷新今日运势
const refreshTodayFortune = async () => {
  if (loading.value) return
  
  loading.value = true
  try {
    await loadTodayFortune()
    uni.showToast({
      title: '运势已刷新',
      icon: 'success'
    })
  } catch (error) {
    uni.showToast({
      title: '刷新失败',
      icon: 'error'
    })
  } finally {
    loading.value = false
  }
}

// 开始测算
const startCalculation = () => {
  goToCalculate()
}

// 页面跳转
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

const goToHistory = () => {
  uni.switchTab({
    url: '/pages/history/history'
  })
}

const goToVip = () => {
  uni.switchTab({
    url: '/pages/vip/vip'
  })
}
</script>

<style lang="scss" scoped>
.index-page {
  min-height: 100vh;
  background: #f5f7fa;
}

.header {
  position: relative;
  height: 400rpx;
  overflow: hidden;
}

.header-bg {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.header-content {
  position: relative;
  z-index: 2;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  padding: 0 40rpx;
}

.app-title {
  font-size: 56rpx;
  font-weight: bold;
  color: #fff;
  margin-bottom: 16rpx;
  text-shadow: 0 2rpx 4rpx rgba(0, 0, 0, 0.3);
}

.app-subtitle {
  font-size: 28rpx;
  color: rgba(255, 255, 255, 0.9);
  text-align: center;
}

.today-fortune-card {
  margin: -80rpx 40rpx 40rpx;
  background: #fff;
  border-radius: 24rpx;
  padding: 40rpx;
  box-shadow: 0 8rpx 32rpx rgba(0, 0, 0, 0.1);
  position: relative;
  z-index: 3;
}

.card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 24rpx;
}

.card-title {
  font-size: 36rpx;
  font-weight: bold;
  color: #333;
}

.card-date {
  font-size: 24rpx;
  color: #666;
}

.fortune-content {
  margin-bottom: 32rpx;
}

.fortune-text {
  font-size: 28rpx;
  line-height: 1.6;
  color: #555;
}

.fortune-loading {
  font-size: 28rpx;
  color: #999;
  font-style: italic;
}

.refresh-btn {
  width: 100%;
  height: 72rpx;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border: none;
  border-radius: 36rpx;
  font-size: 28rpx;
  color: #fff;
  
  &:disabled {
    background: #ccc;
  }
}

.function-nav {
  margin: 0 40rpx 40rpx;
}

.nav-title {
  margin-bottom: 32rpx;
}

.title-text {
  font-size: 36rpx;
  font-weight: bold;
  color: #333;
}

.nav-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24rpx;
}

.nav-item {
  background: #fff;
  border-radius: 20rpx;
  padding: 40rpx 24rpx;
  text-align: center;
  box-shadow: 0 4rpx 16rpx rgba(0, 0, 0, 0.08);
  transition: all 0.3s ease;
  
  &:active {
    transform: translateY(2rpx);
    box-shadow: 0 2rpx 8rpx rgba(0, 0, 0, 0.12);
  }
}

.nav-icon {
  width: 80rpx;
  height: 80rpx;
  border-radius: 40rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 16rpx;
}

.calculate-icon {
  background: linear-gradient(135deg, #ff6b6b 0%, #ee5a24 100%);
}

.name-icon {
  background: linear-gradient(135deg, #4ecdc4 0%, #44a08d 100%);
}

.history-icon {
  background: linear-gradient(135deg, #45b7d1 0%, #96c93d 100%);
}

.vip-icon {
  background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
}

.icon-text {
  font-size: 32rpx;
  font-weight: bold;
  color: #fff;
}

.nav-label {
  display: block;
  font-size: 28rpx;
  font-weight: 500;
  color: #333;
  margin-bottom: 8rpx;
}

.nav-desc {
  display: block;
  font-size: 22rpx;
  color: #666;
}

.start-section {
  padding: 0 40rpx 40rpx;
}

.start-btn {
  width: 100%;
  height: 96rpx;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border: none;
  border-radius: 48rpx;
  box-shadow: 0 8rpx 24rpx rgba(102, 126, 234, 0.4);
}

.btn-text {
  font-size: 32rpx;
  font-weight: bold;
  color: #fff;
}
</style> 
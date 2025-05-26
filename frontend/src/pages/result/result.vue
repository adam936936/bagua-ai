<template>
  <view class="container">
    <view class="header">
      <text class="title">分析结果</text>
    </view>
    
    <view class="result-card" v-if="!loading">
      <view class="user-info">
        <text class="name">{{ userInfo.name }}</text>
        <text class="birth">{{ userInfo.birthDate }} {{ userInfo.birthTime }}</text>
      </view>
      
      <view class="analysis-section">
        <view class="section-title">基础信息</view>
        <view class="info-grid">
          <view class="info-item">
            <text class="info-label">农历</text>
            <text class="info-value">{{ result.lunar || '计算中...' }}</text>
          </view>
          <view class="info-item">
            <text class="info-label">生肖</text>
            <text class="info-value">{{ result.shengXiao || '计算中...' }}</text>
          </view>
        </view>
      </view>
      
      <view class="analysis-section">
        <view class="section-title">AI分析</view>
        <view class="analysis-content">
          <text class="analysis-text">{{ result.aiAnalysis || '正在生成分析报告...' }}</text>
        </view>
      </view>
      
      <view class="action-buttons">
        <button class="btn secondary" @click="goBack">返回修改</button>
        <button class="btn primary" @click="saveResult">保存结果</button>
      </view>
    </view>
    
    <view class="loading" v-else>
      <text class="loading-text">正在分析中...</text>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, onLoad } from 'vue'

const loading = ref(true)
const userInfo = ref({
  name: '',
  birthDate: '',
  birthTime: ''
})

const result = ref({
  lunar: '',
  shengXiao: '',
  aiAnalysis: ''
})

onLoad((options: any) => {
  userInfo.value = {
    name: options.name || '',
    birthDate: options.birthDate || '',
    birthTime: options.birthTime || ''
  }
  
  // 模拟API调用
  setTimeout(() => {
    result.value = {
      lunar: '癸卯年 甲子月 乙丑日',
      shengXiao: '兔',
      aiAnalysis: '您的性格温和善良，具有很强的直觉力和创造力。在事业上适合从事艺术、教育或服务行业。财运方面需要注意理财规划，感情运势较为稳定。建议多关注健康，保持良好的作息习惯。'
    }
    loading.value = false
  }, 2000)
})

const goBack = () => {
  uni.navigateBack()
}

const saveResult = () => {
  uni.showToast({
    title: '保存成功',
    icon: 'success'
  })
  
  setTimeout(() => {
    uni.navigateTo({
      url: '/pages/history/history'
    })
  }, 1500)
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
  margin-bottom: 40rpx;
}

.title {
  font-size: 48rpx;
  color: white;
  font-weight: bold;
}

.result-card {
  background: white;
  border-radius: 20rpx;
  padding: 40rpx;
  box-shadow: 0 10rpx 30rpx rgba(0,0,0,0.1);
}

.user-info {
  text-align: center;
  padding-bottom: 40rpx;
  border-bottom: 2rpx solid #f0f0f0;
  margin-bottom: 40rpx;
}

.name {
  display: block;
  font-size: 36rpx;
  font-weight: bold;
  color: #333;
  margin-bottom: 10rpx;
}

.birth {
  font-size: 28rpx;
  color: #666;
}

.analysis-section {
  margin-bottom: 40rpx;
}

.section-title {
  font-size: 32rpx;
  font-weight: bold;
  color: #333;
  margin-bottom: 20rpx;
}

.info-grid {
  display: flex;
  gap: 20rpx;
}

.info-item {
  flex: 1;
  background: #f8f9fa;
  padding: 20rpx;
  border-radius: 10rpx;
  text-align: center;
}

.info-label {
  display: block;
  font-size: 24rpx;
  color: #666;
  margin-bottom: 10rpx;
}

.info-value {
  font-size: 28rpx;
  font-weight: bold;
  color: #333;
}

.analysis-content {
  background: #f8f9fa;
  padding: 30rpx;
  border-radius: 10rpx;
}

.analysis-text {
  font-size: 28rpx;
  line-height: 1.6;
  color: #333;
}

.action-buttons {
  display: flex;
  gap: 20rpx;
  margin-top: 40rpx;
}

.btn {
  flex: 1;
  height: 80rpx;
  border: none;
  border-radius: 10rpx;
  font-size: 30rpx;
  font-weight: bold;
}

.btn.primary {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.btn.secondary {
  background: #f0f0f0;
  color: #666;
}

.loading {
  text-align: center;
  padding: 100rpx 0;
}

.loading-text {
  font-size: 32rpx;
  color: white;
}
</style> 
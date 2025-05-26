<template>
  <view class="container">
    <view class="header">
      <text class="title">个性分析</text>
      <text class="subtitle">基于AI技术的个性特征分析</text>
    </view>
    
    <view class="form-card">
      <view class="form-section">
        <text class="section-title">基本信息</text>
        <view class="form-item">
          <text class="label">姓名</text>
          <input class="input" v-model="formData.userName" placeholder="请输入您的姓名" />
        </view>
        
        <view class="form-item">
          <text class="label">出生日期</text>
          <picker mode="date" :value="formData.birthDate" @change="onDateChange">
            <view class="picker">
              {{ formData.birthDate || '请选择出生日期' }}
            </view>
          </picker>
        </view>
        
        <view class="form-item">
          <text class="label">出生时辰</text>
          <picker :range="timeOptions" :value="timeIndex" @change="onTimeChange">
            <view class="picker">
              {{ timeOptions[timeIndex] || '请选择出生时辰' }}
            </view>
          </picker>
        </view>
      </view>
      
      <button class="calculate-btn" @click="onCalculate" :disabled="!canCalculate || loading">
        {{ loading ? '分析中...' : '开始分析' }}
      </button>
    </view>
    
    <view class="result-card" v-if="result">
      <view class="result-header">
        <text class="result-title">分析结果</text>
      </view>
      
      <view class="result-content">
        <view class="basic-info">
          <view class="info-item">
            <text class="info-label">农历</text>
            <text class="info-value">{{ result.lunar }}</text>
          </view>
          <view class="info-item">
            <text class="info-label">生肖</text>
            <text class="info-value">{{ result.shengXiao }}</text>
          </view>
        </view>
        
        <view class="analysis-section">
          <text class="analysis-title">AI分析报告</text>
          <text class="analysis-text">{{ result.aiAnalysis }}</text>
        </view>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { fortuneApi } from '@/api/fortune'

const loading = ref(false)
const timeIndex = ref(0)
const formData = ref({
  userName: '',
  birthDate: '',
  birthTime: ''
})

const result = ref(null)

const timeOptions = [
  '子时(23:00-01:00)', '丑时(01:00-03:00)', '寅时(03:00-05:00)',
  '卯时(05:00-07:00)', '辰时(07:00-09:00)', '巳时(09:00-11:00)',
  '午时(11:00-13:00)', '未时(13:00-15:00)', '申时(15:00-17:00)',
  '酉时(17:00-19:00)', '戌时(19:00-21:00)', '亥时(21:00-23:00)'
]

const canCalculate = computed(() => {
  return formData.value.userName && formData.value.birthDate && formData.value.birthTime
})

const onDateChange = (e: any) => {
  formData.value.birthDate = e.detail.value
}

const onTimeChange = (e: any) => {
  timeIndex.value = e.detail.value
  formData.value.birthTime = timeOptions[e.detail.value].split('(')[0]
}

const onCalculate = async () => {
  if (!canCalculate.value) {
    uni.showToast({
      title: '请完善信息',
      icon: 'none'
    })
    return
  }
  
  loading.value = true
  
  try {
    const response = await fortuneApi.calculate({
      birthDate: formData.value.birthDate,
      birthTime: formData.value.birthTime,
      userName: formData.value.userName
    })
    
    result.value = response
    
    uni.showToast({
      title: '分析完成',
      icon: 'success'
    })
  } catch (error) {
    console.error('分析失败:', error)
    uni.showToast({
      title: '分析失败，请重试',
      icon: 'none'
    })
  } finally {
    loading.value = false
  }
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

.form-card {
  background: white;
  border-radius: 20rpx;
  padding: 40rpx;
  margin-bottom: 40rpx;
  box-shadow: 0 10rpx 30rpx rgba(0,0,0,0.1);
}

.form-section {
  margin-bottom: 40rpx;
}

.section-title {
  font-size: 32rpx;
  font-weight: bold;
  color: #333;
  margin-bottom: 30rpx;
}

.form-item {
  margin-bottom: 30rpx;
}

.label {
  display: block;
  font-size: 28rpx;
  color: #333;
  margin-bottom: 15rpx;
  font-weight: 500;
}

.input, .picker {
  width: 100%;
  height: 80rpx;
  border: 2rpx solid #e0e0e0;
  border-radius: 10rpx;
  padding: 0 20rpx;
  font-size: 28rpx;
  background: #f9f9f9;
  display: flex;
  align-items: center;
}

.calculate-btn {
  width: 100%;
  height: 80rpx;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 10rpx;
  font-size: 32rpx;
  font-weight: bold;
}

.calculate-btn:disabled {
  background: #ccc;
}

.result-card {
  background: white;
  border-radius: 20rpx;
  padding: 40rpx;
  box-shadow: 0 10rpx 30rpx rgba(0,0,0,0.1);
}

.result-header {
  text-align: center;
  margin-bottom: 30rpx;
}

.result-title {
  font-size: 36rpx;
  font-weight: bold;
  color: #333;
}

.basic-info {
  display: flex;
  gap: 20rpx;
  margin-bottom: 30rpx;
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

.analysis-section {
  background: #f8f9fa;
  padding: 30rpx;
  border-radius: 10rpx;
}

.analysis-title {
  display: block;
  font-size: 28rpx;
  font-weight: bold;
  color: #333;
  margin-bottom: 20rpx;
}

.analysis-text {
  font-size: 26rpx;
  line-height: 1.6;
  color: #333;
}
</style>
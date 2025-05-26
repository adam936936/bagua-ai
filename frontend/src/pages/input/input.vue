<template>
  <view class="container">
    <view class="header">
      <text class="title">请输入您的信息</text>
    </view>
    
    <view class="form">
      <view class="form-item">
        <text class="label">姓名</text>
        <input class="input" v-model="fortuneStore.userName" placeholder="请输入您的姓名" />
      </view>
      <view class="form-item">
        <text class="label">出生日期</text>
        <picker mode="date" :value="fortuneStore.birthDate" @change="onDateChange">
          <view class="picker">
            {{ fortuneStore.birthDate || '请选择出生日期' }}
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
      <button class="submit-btn" @click="onSubmit" :disabled="!fortuneStore.canCalculate || fortuneStore.loading">
        {{ fortuneStore.loading ? '分析中...' : '开始分析' }}
      </button>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'
import { useFortuneStore } from '@/store/modules/fortune'
import { onLoad } from '@dcloudio/uni-app'

const fortuneStore = useFortuneStore()
const timeIndex = ref(0)
const timeOptions = [
  '子时(23:00-01:00)', '丑时(01:00-03:00)', '寅时(03:00-05:00)',
  '卯时(05:00-07:00)', '辰时(07:00-09:00)', '巳时(09:00-11:00)',
  '午时(11:00-13:00)', '未时(13:00-15:00)', '申时(15:00-17:00)',
  '酉时(17:00-19:00)', '戌时(19:00-21:00)', '亥时(21:00-23:00)'
]

const onDateChange = (e: any) => {
  fortuneStore.birthDate = e.detail.value
}

const onTimeChange = (e: any) => {
  timeIndex.value = e.detail.value
  fortuneStore.birthTime = timeOptions[e.detail.value]
}

const onSubmit = async () => {
  if (!fortuneStore.canCalculate) {
    uni.showToast({
      title: '请完善信息',
      icon: 'none'
    })
    return
  }
  await fortuneStore.doCalculate()
  uni.navigateTo({ url: '/pages/result/result' })
}

onLoad(() => {
  fortuneStore.resetInput()
  timeIndex.value = 0
})
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
}

.form {
  background: white;
  border-radius: 20rpx;
  padding: 40rpx;
  box-shadow: 0 10rpx 30rpx rgba(0,0,0,0.1);
}

.form-item {
  margin-bottom: 40rpx;
}

.label {
  display: block;
  font-size: 32rpx;
  color: #333;
  margin-bottom: 20rpx;
  font-weight: 500;
}

.input, .picker {
  width: 100%;
  height: 80rpx;
  border: 2rpx solid #e0e0e0;
  border-radius: 10rpx;
  padding: 0 20rpx;
  font-size: 30rpx;
  background: #f9f9f9;
  display: flex;
  align-items: center;
}

.submit-btn {
  width: 100%;
  height: 80rpx;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 10rpx;
  font-size: 32rpx;
  font-weight: bold;
  margin-top: 40rpx;
}

.submit-btn:disabled {
  background: #ccc;
}
</style> 
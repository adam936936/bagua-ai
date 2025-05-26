<template>
  <view class="app">
    <!-- 应用根组件 -->
  </view>
</template>

<script setup lang="ts">
import { onLaunch, onShow, onHide } from '@dcloudio/uni-app'

onLaunch(() => {
  console.log('App Launch')
  // 应用启动时的逻辑
})

onShow(() => {
  console.log('App Show')
  // 应用显示时的逻辑
})

onHide(() => {
  console.log('App Hide')
  // 应用隐藏时的逻辑
})
</script>

<style lang="scss">
/* 全局样式 */
.app {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
}

/* 通用样式重置 */
page {
  background-color: #f5f5f5;
  font-size: 28rpx;
  line-height: 1.6;
}

/* 通用按钮样式 */
.btn {
  border-radius: 8rpx;
  font-size: 28rpx;
  padding: 20rpx 40rpx;
  border: none;
  cursor: pointer;
}

.btn-primary {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.btn-secondary {
  background: #f0f0f0;
  color: #666;
}

/* 通用表单样式 */
.form-item {
  margin-bottom: 30rpx;
}

.form-label {
  display: block;
  font-size: 28rpx;
  color: #333;
  margin-bottom: 15rpx;
  font-weight: 500;
}

.form-input {
  width: 100%;
  height: 80rpx;
  border: 2rpx solid #e0e0e0;
  border-radius: 10rpx;
  padding: 0 20rpx;
  font-size: 28rpx;
  background: #f9f9f9;
}
</style> 
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
@import './styles/common.scss';

.app {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
}
</style> 
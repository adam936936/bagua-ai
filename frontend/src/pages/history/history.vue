<template>
  <view class="container">
    <view class="header">
      <text class="title">历史记录</text>
    </view>
    
    <view class="history-list" v-if="historyList.length > 0">
      <view class="history-item" v-for="(item, index) in historyList" :key="index" 
            @click="viewDetail(item)">
        <view class="item-header">
          <text class="name">{{ item.name }}</text>
          <text class="date">{{ item.date }}</text>
        </view>
        <view class="item-content">
          <text class="birth-info">{{ item.birthDate }} {{ item.birthTime }}</text>
          <text class="preview">{{ item.preview }}</text>
        </view>
        <view class="item-footer">
          <text class="zodiac">{{ item.zodiac }}</text>
          <view class="actions">
            <text class="action-btn" @click.stop="shareResult(item)">分享</text>
            <text class="action-btn delete" @click.stop="deleteItem(index)">删除</text>
          </view>
        </view>
      </view>
    </view>
    
    <view class="empty-state" v-else>
      <text class="empty-icon">📝</text>
      <text class="empty-text">暂无历史记录</text>
      <button class="start-btn" @click="startAnalysis">开始分析</button>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'

const historyList = ref([
  {
    name: '张三',
    date: '2024-01-15',
    birthDate: '1990-05-20',
    birthTime: '午时',
    zodiac: '马',
    preview: '性格温和善良，具有很强的直觉力和创造力...'
  },
  {
    name: '李四',
    date: '2024-01-10',
    birthDate: '1995-08-15',
    birthTime: '申时',
    zodiac: '猪',
    preview: '聪明机智，善于沟通，事业运势较好...'
  }
])

onMounted(() => {
  // 从本地存储加载历史记录
  loadHistory()
})

const loadHistory = () => {
  try {
    const stored = uni.getStorageSync('fortune_history')
    if (stored) {
      historyList.value = JSON.parse(stored)
    }
  } catch (e) {
    console.error('加载历史记录失败:', e)
  }
}

const viewDetail = (item: any) => {
  // 跳转到详情页面
  uni.navigateTo({
    url: `/pages/result/result?name=${item.name}&birthDate=${item.birthDate}&birthTime=${item.birthTime}`
  })
}

const shareResult = (item: any) => {
  uni.showActionSheet({
    itemList: ['分享给朋友', '保存到相册'],
    success: (res) => {
      if (res.tapIndex === 0) {
        // 分享给朋友
        uni.showToast({
          title: '分享功能开发中',
          icon: 'none'
        })
      } else if (res.tapIndex === 1) {
        // 保存到相册
        uni.showToast({
          title: '保存成功',
          icon: 'success'
        })
      }
    }
  })
}

const deleteItem = (index: number) => {
  uni.showModal({
    title: '确认删除',
    content: '确定要删除这条记录吗？',
    success: (res) => {
      if (res.confirm) {
        historyList.value.splice(index, 1)
        // 保存到本地存储
        uni.setStorageSync('fortune_history', JSON.stringify(historyList.value))
        uni.showToast({
          title: '删除成功',
          icon: 'success'
        })
      }
    }
  })
}

const startAnalysis = () => {
  uni.switchTab({
    url: '/pages/index/index'
  })
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

.history-list {
  margin-bottom: 40rpx;
}

.history-item {
  background: white;
  border-radius: 20rpx;
  padding: 30rpx;
  margin-bottom: 20rpx;
  box-shadow: 0 10rpx 30rpx rgba(0,0,0,0.1);
}

.item-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20rpx;
}

.name {
  font-size: 32rpx;
  font-weight: bold;
  color: #333;
}

.date {
  font-size: 24rpx;
  color: #666;
}

.item-content {
  margin-bottom: 20rpx;
}

.birth-info {
  display: block;
  font-size: 28rpx;
  color: #666;
  margin-bottom: 10rpx;
}

.preview {
  font-size: 26rpx;
  color: #999;
  line-height: 1.4;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.item-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.zodiac {
  background: #667eea;
  color: white;
  padding: 8rpx 16rpx;
  border-radius: 20rpx;
  font-size: 24rpx;
}

.actions {
  display: flex;
  gap: 20rpx;
}

.action-btn {
  font-size: 26rpx;
  color: #667eea;
  padding: 10rpx 20rpx;
  border: 2rpx solid #667eea;
  border-radius: 20rpx;
}

.action-btn.delete {
  color: #ff6b6b;
  border-color: #ff6b6b;
}

.empty-state {
  text-align: center;
  padding: 100rpx 0;
}

.empty-icon {
  font-size: 120rpx;
  margin-bottom: 40rpx;
}

.empty-text {
  display: block;
  font-size: 32rpx;
  color: rgba(255,255,255,0.8);
  margin-bottom: 60rpx;
}

.start-btn {
  background: white;
  color: #667eea;
  border: none;
  border-radius: 50rpx;
  padding: 20rpx 60rpx;
  font-size: 30rpx;
  font-weight: bold;
}
</style> 
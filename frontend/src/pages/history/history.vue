<template>
  <view class="container">
    <view class="header">
      <text class="title">历史记录</text>
      <text class="subtitle">查看您的分析历史</text>
    </view>
    
    <view class="history-list" v-if="historyList.length > 0">
      <view 
        class="history-item" 
        v-for="(item, index) in historyList" 
        :key="index"
        @tap="viewDetail(item)"
      >
        <view class="item-header">
          <text class="item-name">{{ item.userName }}</text>
          <text class="item-date">{{ formatDate(item.createTime) }}</text>
        </view>
        <view class="item-info">
          <text class="birth-info">{{ item.birthDate }} {{ item.birthTime }}</text>
          <text class="zodiac">{{ item.result?.shengXiao }}</text>
        </view>
        <view class="item-preview">
          <text class="preview-text">{{ getPreviewText(item.result?.aiAnalysis) }}</text>
        </view>
      </view>
    </view>
    
    <view class="empty-state" v-else-if="!loading">
      <view class="empty-icon">📝</view>
      <text class="empty-text">暂无分析记录</text>
      <text class="empty-desc">快去进行您的第一次命理分析吧</text>
      <button class="go-analyze-btn" @tap="goToAnalyze">立即分析</button>
    </view>
    
    <view class="loading-state" v-if="loading">
      <text class="loading-text">加载中...</text>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useFortuneStore } from '@/store/modules/fortune'

const fortuneStore = useFortuneStore()

const loading = ref(false)
const historyList = computed(() => fortuneStore.historyList)

onMounted(async () => {
  await loadHistory()
})

const loadHistory = async () => {
  loading.value = true
  try {
    await fortuneStore.loadHistory()
  } catch (error) {
    console.error('加载历史记录失败:', error)
    uni.showToast({
      title: '加载失败',
      icon: 'none'
    })
  } finally {
    loading.value = false
  }
}

const formatDate = (dateStr: string) => {
  if (!dateStr) return ''
  const date = new Date(dateStr)
  const month = (date.getMonth() + 1).toString().padStart(2, '0')
  const day = date.getDate().toString().padStart(2, '0')
  const hour = date.getHours().toString().padStart(2, '0')
  const minute = date.getMinutes().toString().padStart(2, '0')
  return `${month}-${day} ${hour}:${minute}`
}

const getPreviewText = (text: string) => {
  if (!text) return '暂无分析内容'
  return text.length > 50 ? text.substring(0, 50) + '...' : text
}

const viewDetail = (item: any) => {
  // 将历史记录设置为当前结果
  fortuneStore.result = item.result
  fortuneStore.userName = item.userName
  fortuneStore.birthDate = item.birthDate
  fortuneStore.birthTime = item.birthTime
  
  // 跳转到结果页面
  uni.navigateTo({
    url: '/pages/result/result'
  })
}

const goToAnalyze = () => {
  uni.navigateTo({
    url: '/pages/calculate/calculate'
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

.history-list {
  .history-item {
    background: white;
    border-radius: 15rpx;
    padding: 30rpx;
    margin-bottom: 20rpx;
    box-shadow: 0 4rpx 20rpx rgba(0, 0, 0, 0.1);
    
    .item-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 15rpx;
      
      .item-name {
        font-size: 32rpx;
        font-weight: bold;
        color: #333;
      }
      
      .item-date {
        font-size: 24rpx;
        color: #999;
      }
    }
    
    .item-info {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 15rpx;
      
      .birth-info {
        font-size: 26rpx;
        color: #666;
      }
      
      .zodiac {
        font-size: 26rpx;
        color: #667eea;
        font-weight: 500;
      }
    }
    
    .item-preview {
      .preview-text {
        font-size: 24rpx;
        color: #999;
        line-height: 1.5;
      }
    }
  }
}

.empty-state {
  text-align: center;
  padding: 100rpx 0;
  
  .empty-icon {
    font-size: 120rpx;
    margin-bottom: 30rpx;
  }
  
  .empty-text {
    display: block;
    font-size: 32rpx;
    color: white;
    font-weight: bold;
    margin-bottom: 15rpx;
  }
  
  .empty-desc {
    display: block;
    font-size: 26rpx;
    color: rgba(255, 255, 255, 0.8);
    margin-bottom: 40rpx;
  }
  
  .go-analyze-btn {
    background: white;
    color: #667eea;
    border: none;
    border-radius: 50rpx;
    padding: 20rpx 40rpx;
    font-size: 28rpx;
    font-weight: bold;
  }
}

.loading-state {
  text-align: center;
  padding: 100rpx 0;
  
  .loading-text {
    font-size: 28rpx;
    color: rgba(255, 255, 255, 0.8);
  }
}
</style> 
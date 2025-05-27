<template>
  <view class="container">
    <view class="header">
      <text class="title">历史记录</text>
      <text class="subtitle">查看您的分析历史</text>
    </view>
    
    <!-- 统计信息 -->
    <view class="stats-card" v-if="historyPagination.total > 0">
      <view class="stats-item">
        <text class="stats-number">{{ historyPagination.total }}</text>
        <text class="stats-label">总记录数</text>
      </view>
      <view class="stats-divider"></view>
      <view class="stats-item">
        <text class="stats-number">{{ historyPagination.page }}</text>
        <text class="stats-label">当前页</text>
      </view>
      <view class="stats-divider"></view>
      <view class="stats-item">
        <text class="stats-number">{{ historyPagination.totalPages }}</text>
        <text class="stats-label">总页数</text>
      </view>
    </view>
    
    <!-- 历史记录列表 -->
    <view class="history-list" v-if="historyList.length > 0">
      <view 
        class="history-item" 
        v-for="(item, index) in historyList" 
        :key="item.id"
        @tap="viewDetail(item)"
      >
        <view class="item-header">
          <view class="name-section">
            <text class="item-name">{{ item.userName }}</text>
            <text class="item-zodiac">{{ item.shengXiao }}</text>
          </view>
          <text class="item-date">{{ formatDate(item.createTime) }}</text>
        </view>
        
        <view class="item-birth">
          <text class="birth-label">出生信息：</text>
          <text class="birth-value">{{ item.birthDate }} {{ item.birthTime }}</text>
        </view>
        
        <view class="item-lunar">
          <text class="lunar-label">农历：</text>
          <text class="lunar-value">{{ item.lunar }}</text>
        </view>
        
        <view class="item-bazi">
          <text class="bazi-label">八字：</text>
          <text class="bazi-value">{{ item.ganZhi }}</text>
        </view>
        
        <view class="item-wuxing" v-if="item.wuXing">
          <text class="wuxing-label">五行：</text>
          <text class="wuxing-value">{{ item.wuXing }}</text>
          <text class="wuxing-lack" v-if="item.wuXingLack">（缺{{ item.wuXingLack }}）</text>
        </view>
        
        <view class="item-preview">
          <text class="preview-label">AI分析：</text>
          <text class="preview-text">{{ getPreviewText(item.aiAnalysis) }}</text>
        </view>
        
        <view class="item-footer">
          <text class="view-detail">点击查看详情 →</text>
        </view>
      </view>
    </view>
    
    <!-- 分页组件 -->
    <view class="pagination" v-if="historyPagination.totalPages > 1">
      <button 
        class="page-btn" 
        :class="{ disabled: historyPagination.page <= 1 }"
        :disabled="historyPagination.page <= 1"
        @tap="loadPage(historyPagination.page - 1)"
      >
        上一页
      </button>
      
      <view class="page-info">
        <text class="page-text">{{ historyPagination.page }} / {{ historyPagination.totalPages }}</text>
      </view>
      
      <button 
        class="page-btn" 
        :class="{ disabled: historyPagination.page >= historyPagination.totalPages }"
        :disabled="historyPagination.page >= historyPagination.totalPages"
        @tap="loadPage(historyPagination.page + 1)"
      >
        下一页
      </button>
    </view>
    
    <!-- 空状态 -->
    <view class="empty-state" v-else-if="!loading && historyList.length === 0">
      <view class="empty-icon">📝</view>
      <text class="empty-text">暂无分析记录</text>
      <text class="empty-desc">快去进行您的第一次命理分析吧</text>
      <button class="go-analyze-btn" @tap="goToAnalyze">立即分析</button>
    </view>
    
    <!-- 加载状态 -->
    <view class="loading-state" v-if="loading">
      <view class="loading-spinner"></view>
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
const historyPagination = computed(() => fortuneStore.historyPagination)

onMounted(async () => {
  await loadPage(1)
})

const loadPage = async (page: number) => {
  if (loading.value) return
  
  loading.value = true
  try {
    await fortuneStore.loadHistory(page, 10)
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
  const year = date.getFullYear()
  const month = (date.getMonth() + 1).toString().padStart(2, '0')
  const day = date.getDate().toString().padStart(2, '0')
  const hour = date.getHours().toString().padStart(2, '0')
  const minute = date.getMinutes().toString().padStart(2, '0')
  return `${year}-${month}-${day} ${hour}:${minute}`
}

const getPreviewText = (text: string) => {
  if (!text) return '暂无分析内容'
  return text.length > 60 ? text.substring(0, 60) + '...' : text
}

const viewDetail = (item: any) => {
  // 将历史记录数据转换为结果格式
  const resultData = {
    id: item.id,
    userName: item.userName,
    birthDate: item.birthDate,
    birthTime: item.birthTime,
    createTime: item.createTime,
    lunar: item.lunar,
    ganZhi: item.ganZhi,
    shengXiao: item.shengXiao,
    wuXing: item.wuXing,
    wuXingLack: item.wuXingLack,
    aiAnalysis: item.aiAnalysis
  }
  
  // 设置到store中
  fortuneStore.result = resultData
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
  padding: 40rpx 30rpx 120rpx;
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

.stats-card {
  background: white;
  border-radius: 20rpx;
  padding: 30rpx;
  margin-bottom: 30rpx;
  display: flex;
  justify-content: space-around;
  align-items: center;
  box-shadow: 0 8rpx 32rpx rgba(0, 0, 0, 0.1);
  
  .stats-item {
    text-align: center;
    flex: 1;
    
    .stats-number {
      display: block;
      font-size: 36rpx;
      font-weight: bold;
      color: #667eea;
      margin-bottom: 8rpx;
    }
    
    .stats-label {
      display: block;
      font-size: 24rpx;
      color: #666;
    }
  }
  
  .stats-divider {
    width: 2rpx;
    height: 60rpx;
    background: #f0f0f0;
    margin: 0 20rpx;
  }
}

.history-list {
  .history-item {
    background: white;
    border-radius: 20rpx;
    padding: 30rpx;
    margin-bottom: 20rpx;
    box-shadow: 0 8rpx 32rpx rgba(0, 0, 0, 0.1);
    position: relative;
    
    .item-header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 20rpx;
      
      .name-section {
        display: flex;
        align-items: center;
        gap: 15rpx;
        
        .item-name {
          font-size: 32rpx;
          font-weight: bold;
          color: #333;
        }
        
        .item-zodiac {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          font-size: 22rpx;
          padding: 6rpx 12rpx;
          border-radius: 12rpx;
        }
      }
      
      .item-date {
        font-size: 24rpx;
        color: #999;
      }
    }
    
    .item-birth,
    .item-lunar,
    .item-bazi,
    .item-wuxing {
      display: flex;
      align-items: center;
      margin-bottom: 12rpx;
      
      .birth-label,
      .lunar-label,
      .bazi-label,
      .wuxing-label {
        font-size: 26rpx;
        color: #666;
        min-width: 120rpx;
      }
      
      .birth-value,
      .lunar-value,
      .bazi-value,
      .wuxing-value {
        font-size: 26rpx;
        color: #333;
        font-weight: 500;
      }
      
      .wuxing-lack {
        font-size: 24rpx;
        color: #ff6b6b;
        margin-left: 10rpx;
      }
    }
    
    .item-preview {
      margin-top: 20rpx;
      padding-top: 20rpx;
      border-top: 2rpx solid #f5f5f5;
      
      .preview-label {
        font-size: 26rpx;
        color: #666;
        display: block;
        margin-bottom: 8rpx;
      }
      
      .preview-text {
        font-size: 24rpx;
        color: #999;
        line-height: 1.6;
        display: block;
      }
    }
    
    .item-footer {
      margin-top: 20rpx;
      text-align: right;
      
      .view-detail {
        font-size: 24rpx;
        color: #667eea;
      }
    }
  }
}

.pagination {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 20rpx;
  margin-top: 40rpx;
  
  .page-btn {
    background: white;
    color: #667eea;
    border: 2rpx solid #667eea;
    border-radius: 25rpx;
    padding: 15rpx 30rpx;
    font-size: 26rpx;
    
    &.disabled {
      opacity: 0.5;
      background: #f5f5f5;
      color: #ccc;
      border-color: #e0e0e0;
    }
  }
  
  .page-info {
    background: white;
    border-radius: 25rpx;
    padding: 15rpx 25rpx;
    
    .page-text {
      font-size: 26rpx;
      color: #333;
      font-weight: 500;
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
  
  .loading-spinner {
    width: 60rpx;
    height: 60rpx;
    border: 4rpx solid rgba(255, 255, 255, 0.3);
    border-top: 4rpx solid white;
    border-radius: 50%;
    animation: spin 1s linear infinite;
    margin: 0 auto 20rpx;
  }
  
  .loading-text {
    font-size: 28rpx;
    color: rgba(255, 255, 255, 0.8);
  }
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
</style> 
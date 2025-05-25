<template>
  <view class="name-recommend-page">
    <!-- 页面标题 -->
    <view class="page-header">
      <text class="page-title">AI智能起名</text>
      <text class="page-subtitle">基于五行命理，为您推荐最适合的姓名</text>
    </view>

    <!-- 输入区域 -->
    <view class="input-container">
      <view class="input-item">
        <text class="input-label">姓氏</text>
        <input 
          class="input-field" 
          v-model="formData.surname" 
          placeholder="请输入姓氏（可选）"
          maxlength="2"
        />
      </view>
      
      <view class="info-display">
        <view class="info-item">
          <text class="info-label">五行缺失</text>
          <text class="info-value">{{ formData.wuXingLack || '无' }}</text>
        </view>
        <view class="info-item">
          <text class="info-label">天干地支</text>
          <text class="info-value">{{ formData.ganZhi }}</text>
        </view>
      </view>

      <button 
        class="recommend-btn" 
        :disabled="loading"
        @click="handleRecommend"
      >
        <text v-if="loading">AI分析中...</text>
        <text v-else>获取推荐姓名</text>
      </button>
    </view>

    <!-- 推荐结果 -->
    <view v-if="recommendations.length > 0" class="result-container">
      <view class="result-header">
        <text class="result-title">推荐姓名</text>
        <text class="result-subtitle">以下是根据您的命理信息推荐的姓名</text>
      </view>

      <view class="name-list">
        <view 
          v-for="(item, index) in recommendations" 
          :key="index"
          class="name-item"
          @click="handleSelectName(item)"
        >
          <view class="name-header">
            <view class="name-info">
              <text class="name-text">{{ item.name }}</text>
              <view class="name-meta">
                <text class="wu-xing">{{ item.wuXing }}</text>
                <text class="score">{{ item.score }}分</text>
              </view>
            </view>
            <view class="name-action">
              <text class="action-text">选择</text>
            </view>
          </view>
          <view class="name-reason">
            <text class="reason-text">{{ item.reason }}</text>
          </view>
        </view>
      </view>
    </view>

    <!-- 空状态 -->
    <view v-else-if="!loading && hasSearched" class="empty-state">
      <text class="empty-text">暂无推荐结果</text>
      <text class="empty-subtitle">请检查输入信息后重试</text>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, onLoad } from 'vue'
import { useFortuneStore } from '@/store/modules/fortune'
import type { NameRecommendRequest, NameRecommendationResponse } from '@/types/fortune'

// 状态管理
const fortuneStore = useFortuneStore()

// 响应式数据
const loading = ref(false)
const hasSearched = ref(false)
const recommendations = ref<NameRecommendationResponse[]>([])

// 表单数据
const formData = ref<NameRecommendRequest>({
  userId: 1, // 临时用户ID
  wuXingLack: '',
  ganZhi: '',
  surname: ''
})

// 页面加载
onLoad((options: any) => {
  if (options.wuXingLack) {
    formData.value.wuXingLack = options.wuXingLack
  }
  if (options.ganZhi) {
    formData.value.ganZhi = options.ganZhi
  }
})

// 获取推荐
const handleRecommend = async () => {
  if (loading.value) return

  loading.value = true
  hasSearched.value = true
  
  try {
    const response = await fortuneStore.recommendNames(formData.value)
    recommendations.value = response
    
    if (response.length === 0) {
      uni.showToast({
        title: '暂无推荐结果',
        icon: 'none'
      })
    } else {
      uni.showToast({
        title: '推荐完成',
        icon: 'success'
      })
    }
  } catch (error) {
    console.error('推荐失败:', error)
    uni.showToast({
      title: '推荐失败，请重试',
      icon: 'error'
    })
  } finally {
    loading.value = false
  }
}

// 选择姓名
const handleSelectName = (item: NameRecommendationResponse) => {
  uni.showModal({
    title: '确认选择',
    content: `您选择了姓名：${item.name}`,
    success: (res) => {
      if (res.confirm) {
        uni.showToast({
          title: '已选择该姓名',
          icon: 'success'
        })
        
        // 可以在这里保存选择的姓名或进行其他操作
        setTimeout(() => {
          uni.navigateBack()
        }, 1500)
      }
    }
  })
}
</script>

<style lang="scss" scoped>
.name-recommend-page {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 20rpx;
}

.page-header {
  text-align: center;
  padding: 60rpx 0 40rpx;
  
  .page-title {
    display: block;
    font-size: 48rpx;
    font-weight: bold;
    color: #fff;
    margin-bottom: 20rpx;
  }
  
  .page-subtitle {
    display: block;
    font-size: 28rpx;
    color: rgba(255, 255, 255, 0.8);
  }
}

.input-container {
  background: #fff;
  border-radius: 20rpx;
  padding: 40rpx;
  margin-bottom: 40rpx;
  box-shadow: 0 10rpx 30rpx rgba(0, 0, 0, 0.1);
}

.input-item {
  margin-bottom: 40rpx;
}

.input-label {
  display: block;
  font-size: 32rpx;
  font-weight: 500;
  color: #333;
  margin-bottom: 20rpx;
}

.input-field {
  width: 100%;
  height: 88rpx;
  padding: 0 24rpx;
  border: 2rpx solid #e5e5e5;
  border-radius: 12rpx;
  font-size: 30rpx;
  color: #333;
  background: #fff;
  
  &:focus {
    border-color: #667eea;
  }
}

.info-display {
  display: flex;
  gap: 24rpx;
  margin-bottom: 40rpx;
}

.info-item {
  flex: 1;
  padding: 24rpx;
  background: #f8f9fa;
  border-radius: 12rpx;
  text-align: center;
}

.info-label {
  display: block;
  font-size: 24rpx;
  color: #666;
  margin-bottom: 8rpx;
}

.info-value {
  display: block;
  font-size: 28rpx;
  font-weight: 500;
  color: #333;
}

.recommend-btn {
  width: 100%;
  height: 88rpx;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border: none;
  border-radius: 12rpx;
  font-size: 32rpx;
  font-weight: 500;
  color: #fff;
  
  &:disabled {
    background: #ccc;
    color: #999;
  }
}

.result-container {
  background: #fff;
  border-radius: 20rpx;
  padding: 40rpx;
  box-shadow: 0 10rpx 30rpx rgba(0, 0, 0, 0.1);
}

.result-header {
  text-align: center;
  margin-bottom: 40rpx;
}

.result-title {
  display: block;
  font-size: 36rpx;
  font-weight: bold;
  color: #333;
  margin-bottom: 12rpx;
}

.result-subtitle {
  display: block;
  font-size: 26rpx;
  color: #666;
}

.name-list {
  display: flex;
  flex-direction: column;
  gap: 24rpx;
}

.name-item {
  padding: 32rpx;
  background: #f8f9fa;
  border-radius: 16rpx;
  border: 2rpx solid transparent;
  transition: all 0.3s ease;
  
  &:active {
    border-color: #667eea;
    background: #f0f4ff;
  }
}

.name-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16rpx;
}

.name-info {
  flex: 1;
}

.name-text {
  display: block;
  font-size: 36rpx;
  font-weight: bold;
  color: #333;
  margin-bottom: 8rpx;
}

.name-meta {
  display: flex;
  align-items: center;
  gap: 16rpx;
}

.wu-xing {
  padding: 4rpx 12rpx;
  background: #667eea;
  color: #fff;
  font-size: 22rpx;
  border-radius: 12rpx;
}

.score {
  font-size: 24rpx;
  font-weight: 500;
  color: #ff6b6b;
}

.name-action {
  padding: 12rpx 24rpx;
  background: #667eea;
  border-radius: 20rpx;
}

.action-text {
  font-size: 26rpx;
  color: #fff;
}

.name-reason {
  padding-top: 16rpx;
  border-top: 1rpx solid #e5e5e5;
}

.reason-text {
  font-size: 26rpx;
  line-height: 1.5;
  color: #666;
}

.empty-state {
  text-align: center;
  padding: 120rpx 40rpx;
  background: #fff;
  border-radius: 20rpx;
  box-shadow: 0 10rpx 30rpx rgba(0, 0, 0, 0.1);
}

.empty-text {
  display: block;
  font-size: 32rpx;
  color: #999;
  margin-bottom: 16rpx;
}

.empty-subtitle {
  display: block;
  font-size: 26rpx;
  color: #ccc;
}
</style> 
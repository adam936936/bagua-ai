<template>
  <view class="container">
    <view class="header">
      <text class="title">八字测算</text>
      <text class="subtitle">输入您的基本信息，获取专业命理分析</text>
    </view>
    
    <view class="form-card">
      <view class="form-item">
        <text class="form-label">姓名</text>
        <input 
          class="form-input" 
          v-model="userName" 
          placeholder="请输入您的姓名"
          maxlength="10"
        />
      </view>
      
      <view class="form-item">
        <text class="form-label">出生日期</text>
        <picker 
          mode="date" 
          :value="birthDate" 
          @change="onDateChange"
          :end="maxDate"
        >
          <view class="form-input picker-input">
            {{ birthDate || '请选择出生日期' }}
          </view>
        </picker>
      </view>
      
      <view class="form-item">
        <text class="form-label">出生时辰</text>
        <picker 
          :range="timeOptions" 
          :value="timeIndex" 
          @change="onTimeChange"
        >
          <view class="form-input picker-input">
            {{ birthTime || '请选择出生时辰' }}
          </view>
        </picker>
      </view>
      
      <view class="tips">
        <text class="tips-title">💡 温馨提示</text>
        <text class="tips-content">
          准确的出生时间对命理分析非常重要，请尽量提供精确的时辰信息。
        </text>
      </view>
      
      <button 
        class="calculate-btn" 
        :class="{ disabled: !canCalculate || loading }"
        :disabled="!canCalculate || loading"
        @tap="onCalculate"
      >
        {{ loading ? '正在分析中...' : '开始分析' }}
      </button>
    </view>
    
    <view class="analysis-count" v-if="!isVip">
      <text class="count-text">今日剩余分析次数：{{ remainingCount }}</text>
      <text class="vip-tip" @tap="goToVip">升级VIP享受无限次分析</text>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useFortuneStore } from '@/store/modules/fortune'
import { useUserStore } from '@/store/modules/user'

const fortuneStore = useFortuneStore()
const userStore = useUserStore()

// 表单数据
const userName = ref('')
const birthDate = ref('')
const birthTime = ref('')
const timeIndex = ref(-1)

// 计算属性
const canCalculate = computed(() => {
  return userName.value && birthDate.value && birthTime.value
})

const loading = computed(() => fortuneStore.loading)
const isVip = computed(() => userStore.isVip)
const remainingCount = computed(() => userStore.remainingAnalysisCount)

// 最大日期（今天）
const maxDate = ref('')

// 时辰选项
const timeOptions = [
  '子时 (23:00-01:00)',
  '丑时 (01:00-03:00)', 
  '寅时 (03:00-05:00)',
  '卯时 (05:00-07:00)',
  '辰时 (07:00-09:00)',
  '巳时 (09:00-11:00)',
  '午时 (11:00-13:00)',
  '未时 (13:00-15:00)',
  '申时 (15:00-17:00)',
  '酉时 (17:00-19:00)',
  '戌时 (19:00-21:00)',
  '亥时 (21:00-23:00)'
]

onMounted(() => {
  // 设置最大日期为今天
  const today = new Date()
  const year = today.getFullYear()
  const month = (today.getMonth() + 1).toString().padStart(2, '0')
  const day = today.getDate().toString().padStart(2, '0')
  maxDate.value = `${year}-${month}-${day}`
  
  // 从store恢复数据
  userName.value = fortuneStore.userName
  birthDate.value = fortuneStore.birthDate
  birthTime.value = fortuneStore.birthTime
})

// 日期选择
const onDateChange = (e: any) => {
  birthDate.value = e.detail.value
  fortuneStore.birthDate = e.detail.value
}

// 时辰选择
const onTimeChange = (e: any) => {
  timeIndex.value = e.detail.value
  birthTime.value = timeOptions[e.detail.value]
  fortuneStore.birthTime = timeOptions[e.detail.value]
}

// 开始分析
const onCalculate = async () => {
  if (!canCalculate.value || loading.value) return
  
  // 检查分析次数
  if (!isVip.value && remainingCount.value <= 0) {
    uni.showModal({
      title: '分析次数不足',
      content: '今日免费分析次数已用完，是否升级VIP享受无限次分析？',
      confirmText: '升级VIP',
      cancelText: '取消',
      success: (res) => {
        if (res.confirm) {
          goToVip()
        }
      }
    })
    return
  }
  
  // 更新store数据
  fortuneStore.userName = userName.value
  fortuneStore.birthDate = birthDate.value
  fortuneStore.birthTime = birthTime.value
  
  try {
    // 显示加载提示
    uni.showLoading({
      title: '正在分析中...',
      mask: true
    })
    
    // 调用分析接口
    await fortuneStore.doCalculate()
    
    // 检查分析结果
    if (fortuneStore.result) {
      // 隐藏加载提示
      uni.hideLoading()
      
      // 分析成功，跳转到结果页面
      uni.navigateTo({
        url: '/pages/result/result'
      })
    } else {
      // 隐藏加载提示
      uni.hideLoading()
      throw new Error('分析结果为空')
    }
  } catch (error) {
    console.error('分析失败:', error)
    // 确保隐藏加载提示
    uni.hideLoading()
    
    uni.showModal({
      title: '分析失败',
      content: '分析过程中出现错误，请检查网络连接后重试',
      showCancel: false,
      confirmText: '确定'
    })
  }
}

// 跳转到VIP页面
const goToVip = () => {
  uni.switchTab({
    url: '/pages/vip/vip'
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

.form-card {
  background: white;
  border-radius: 20rpx;
  padding: 40rpx;
  box-shadow: 0 8rpx 32rpx rgba(0, 0, 0, 0.1);
}

.form-item {
  margin-bottom: 40rpx;
  
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
    color: #333;
    
    &.picker-input {
      display: flex;
      align-items: center;
      color: #666;
    }
  }
}

.tips {
  background: #f8f9ff;
  border-radius: 10rpx;
  padding: 25rpx;
  margin-bottom: 40rpx;
  
  .tips-title {
    display: block;
    font-size: 28rpx;
    color: #667eea;
    font-weight: bold;
    margin-bottom: 10rpx;
  }
  
  .tips-content {
    display: block;
    font-size: 24rpx;
    color: #666;
    line-height: 1.6;
  }
}

.calculate-btn {
  width: 100%;
  height: 80rpx;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 15rpx;
  font-size: 32rpx;
  font-weight: bold;
  
  &.disabled {
    opacity: 0.6;
    background: #ccc;
  }
}

.analysis-count {
  text-align: center;
  margin-top: 30rpx;
  
  .count-text {
    display: block;
    font-size: 24rpx;
    color: rgba(255, 255, 255, 0.8);
    margin-bottom: 10rpx;
  }
  
  .vip-tip {
    display: block;
    font-size: 24rpx;
    color: #ffd700;
    text-decoration: underline;
  }
}
</style> 
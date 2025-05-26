<template>
  <view class="container">
    <view class="header">
      <text class="title">AI起名</text>
      <text class="subtitle">基于五行缺失的智能起名推荐</text>
    </view>
    
    <view class="form-card">
      <!-- 百家姓选择 -->
      <view class="form-section">
        <text class="section-title">选择姓氏</text>
        <view class="surname-grid">
          <view 
            class="surname-item" 
            v-for="(surname, index) in commonSurnames" 
            :key="index"
            :class="{ selected: selectedSurname === surname }"
            @tap="selectSurname(surname)"
          >
            {{ surname }}
          </view>
        </view>
        <view class="custom-surname">
          <input 
            class="surname-input" 
            v-model="customSurname" 
            placeholder="或输入其他姓氏"
            maxlength="2"
            @input="onCustomSurnameInput"
          />
        </view>
      </view>
      
      <!-- 性别选择 -->
      <view class="form-section">
        <text class="section-title">选择性别</text>
        <view class="gender-options">
          <view 
            class="gender-item" 
            :class="{ selected: selectedGender === 'male' }"
            @tap="selectGender('male')"
          >
            <text class="gender-icon">👦</text>
            <text class="gender-text">男孩</text>
          </view>
          <view 
            class="gender-item" 
            :class="{ selected: selectedGender === 'female' }"
            @tap="selectGender('female')"
          >
            <text class="gender-icon">👧</text>
            <text class="gender-text">女孩</text>
          </view>
        </view>
      </view>
      
      <!-- 八字信息显示 -->
      <view class="form-section" v-if="hasFortuneData">
        <text class="section-title">八字信息</text>
        <view class="fortune-info">
          <view class="info-row">
            <text class="info-label">天干地支：</text>
            <text class="info-value">{{ ganZhi || '暂无数据' }}</text>
          </view>
          <view class="info-row">
            <text class="info-label">五行缺失：</text>
            <text class="info-value">{{ wuXingLack || '暂无数据' }}</text>
          </view>
        </view>
        <text class="info-tip">💡 AI将根据您的五行缺失推荐合适的姓名</text>
      </view>
      
      <!-- 无八字数据提示 -->
      <view class="form-section" v-else>
        <view class="no-data-tip">
          <text class="tip-icon">⚠️</text>
          <text class="tip-text">暂无八字数据，请先进行八字分析</text>
          <button class="go-analyze-btn" @tap="goToAnalyze">立即分析</button>
        </view>
      </view>
      
      <!-- 推荐按钮 -->
      <button 
        class="recommend-btn" 
        :class="{ disabled: !canRecommend || loading }"
        :disabled="!canRecommend || loading"
        @tap="getRecommendNames"
      >
        {{ loading ? '推荐中...' : '获取AI推荐姓名' }}
      </button>
    </view>
    
    <!-- 推荐结果 -->
    <view class="result-card" v-if="recommendedNames.length > 0">
      <text class="result-title">💎 AI推荐姓名</text>
      <view class="names-list">
        <view 
          class="name-item" 
          v-for="(name, index) in recommendedNames" 
          :key="index"
          :class="{ selected: selectedName === name }"
          @tap="selectName(name)"
        >
          <text class="name-text">{{ name }}</text>
          <text class="name-check" v-if="selectedName === name">✓</text>
        </view>
      </view>
      <view class="result-actions">
        <button class="action-btn secondary" @tap="getRecommendNames">重新推荐</button>
        <button class="action-btn primary" @tap="saveName" :disabled="!selectedName">保存选择</button>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useFortuneStore } from '@/store/modules/fortune'

const fortuneStore = useFortuneStore()

// 常用姓氏
const commonSurnames = ref(['李', '王', '张', '刘', '陈', '杨', '赵', '黄'])

// 表单数据
const selectedSurname = ref('')
const customSurname = ref('')
const selectedGender = ref('')
const selectedName = ref('')

// 计算属性
const currentSurname = computed(() => customSurname.value || selectedSurname.value)
const hasFortuneData = computed(() => !!fortuneStore.result)
const ganZhi = computed(() => fortuneStore.result?.ganZhi)
const wuXingLack = computed(() => fortuneStore.result?.wuXingLack)
const recommendedNames = computed(() => fortuneStore.recommendedNames)
const loading = computed(() => fortuneStore.loading)

const canRecommend = computed(() => {
  return currentSurname.value && selectedGender.value && hasFortuneData.value
})

onMounted(async () => {
  // 加载常用姓氏
  try {
    await fortuneStore.loadCommonSurnames()
    if (fortuneStore.commonSurnames.length > 0) {
      commonSurnames.value = fortuneStore.commonSurnames
    }
  } catch (error) {
    console.error('加载常用姓氏失败:', error)
  }
})

// 选择姓氏
const selectSurname = (surname: string) => {
  selectedSurname.value = surname
  customSurname.value = ''
}

// 自定义姓氏输入
const onCustomSurnameInput = () => {
  if (customSurname.value) {
    selectedSurname.value = ''
  }
}

// 选择性别
const selectGender = (gender: string) => {
  selectedGender.value = gender
}

// 选择姓名
const selectName = (name: string) => {
  selectedName.value = name
}

// 获取推荐姓名
const getRecommendNames = async () => {
  if (!canRecommend.value || loading.value) return
  
  try {
    const params = {
      surname: currentSurname.value,
      gender: selectedGender.value,
      wuXingLack: wuXingLack.value
    }
    
    await fortuneStore.loadRecommendNames(params)
    selectedName.value = '' // 重置选择
    
    if (recommendedNames.value.length === 0) {
      uni.showToast({
        title: '暂无推荐结果',
        icon: 'none'
      })
    }
  } catch (error) {
    console.error('获取推荐姓名失败:', error)
    uni.showToast({
      title: '推荐失败，请重试',
      icon: 'none'
    })
  }
}

// 保存选择
const saveName = () => {
  if (!selectedName.value) return
  
  uni.showModal({
    title: '保存成功',
    content: `已保存推荐姓名：${selectedName.value}`,
    showCancel: false,
    confirmText: '确定',
    success: () => {
      // 可以跳转到其他页面或执行其他操作
    }
  })
}

// 跳转到分析页面
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

.form-card {
  background: white;
  border-radius: 20rpx;
  padding: 40rpx;
  margin-bottom: 40rpx;
}

.form-section {
  margin-bottom: 40rpx;
  
  &:last-child {
    margin-bottom: 0;
  }
  
  .section-title {
    display: block;
    font-size: 28rpx;
    font-weight: bold;
    color: #333;
    margin-bottom: 20rpx;
  }
}

.surname-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 15rpx;
  margin-bottom: 20rpx;
  
  .surname-item {
    height: 80rpx;
    border: 2rpx solid #e0e0e0;
    border-radius: 10rpx;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 28rpx;
    color: #666;
    background: #f9f9f9;
    
    &.selected {
      border-color: #667eea;
      background: #f8f9ff;
      color: #667eea;
      font-weight: bold;
    }
  }
}

.custom-surname {
  .surname-input {
    width: 100%;
    height: 80rpx;
    border: 2rpx solid #e0e0e0;
    border-radius: 10rpx;
    padding: 0 20rpx;
    font-size: 28rpx;
    background: #f9f9f9;
  }
}

.gender-options {
  display: flex;
  gap: 20rpx;
  
  .gender-item {
    flex: 1;
    height: 100rpx;
    border: 2rpx solid #e0e0e0;
    border-radius: 15rpx;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    background: #f9f9f9;
    
    &.selected {
      border-color: #667eea;
      background: #f8f9ff;
    }
    
    .gender-icon {
      font-size: 40rpx;
      margin-bottom: 5rpx;
    }
    
    .gender-text {
      font-size: 24rpx;
      color: #666;
      
      .selected & {
        color: #667eea;
        font-weight: bold;
      }
    }
  }
}

.fortune-info {
  background: #f8f9ff;
  border-radius: 10rpx;
  padding: 25rpx;
  margin-bottom: 15rpx;
  
  .info-row {
    display: flex;
    margin-bottom: 10rpx;
    
    &:last-child {
      margin-bottom: 0;
    }
    
    .info-label {
      font-size: 26rpx;
      color: #666;
      min-width: 140rpx;
    }
    
    .info-value {
      font-size: 26rpx;
      color: #333;
      font-weight: 500;
    }
  }
}

.info-tip {
  display: block;
  font-size: 24rpx;
  color: #667eea;
  line-height: 1.5;
}

.no-data-tip {
  text-align: center;
  padding: 40rpx 0;
  
  .tip-icon {
    font-size: 60rpx;
    margin-bottom: 20rpx;
  }
  
  .tip-text {
    display: block;
    font-size: 28rpx;
    color: #666;
    margin-bottom: 30rpx;
  }
  
  .go-analyze-btn {
    background: #667eea;
    color: white;
    border: none;
    border-radius: 25rpx;
    padding: 15rpx 30rpx;
    font-size: 26rpx;
  }
}

.recommend-btn {
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

.result-card {
  background: white;
  border-radius: 20rpx;
  padding: 40rpx;
  
  .result-title {
    display: block;
    font-size: 32rpx;
    font-weight: bold;
    color: #333;
    margin-bottom: 30rpx;
    text-align: center;
  }
  
  .names-list {
    margin-bottom: 40rpx;
    
    .name-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 25rpx;
      border: 2rpx solid #e0e0e0;
      border-radius: 15rpx;
      margin-bottom: 15rpx;
      background: #f9f9f9;
      
      &:last-child {
        margin-bottom: 0;
      }
      
      &.selected {
        border-color: #667eea;
        background: #f8f9ff;
      }
      
      .name-text {
        font-size: 32rpx;
        color: #333;
        font-weight: 500;
        
        .selected & {
          color: #667eea;
          font-weight: bold;
        }
      }
      
      .name-check {
        font-size: 28rpx;
        color: #667eea;
        font-weight: bold;
      }
    }
  }
  
  .result-actions {
    display: flex;
    gap: 20rpx;
    
    .action-btn {
      flex: 1;
      height: 70rpx;
      border: none;
      border-radius: 15rpx;
      font-size: 28rpx;
      font-weight: bold;
      
      &.secondary {
        background: #f0f0f0;
        color: #666;
      }
      
      &.primary {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        
        &[disabled] {
          opacity: 0.6;
          background: #ccc;
        }
      }
    }
  }
}
</style> 
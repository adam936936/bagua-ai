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
      
      <!-- 出生日期选择 -->
      <view class="form-section">
        <text class="section-title">出生日期</text>
        <picker 
          mode="date" 
          :value="birthDate" 
          @change="onDateChange"
          :end="maxDate"
        >
          <view class="date-input">
            {{ birthDate || '请选择出生日期' }}
          </view>
        </picker>
      </view>
      
      <!-- 出生时辰选择 -->
      <view class="form-section">
        <text class="section-title">出生时辰</text>
        <picker 
          mode="selector" 
          :range="timeOptions" 
          :value="selectedTimeIndex"
          @change="onTimeChange"
        >
          <view class="time-input">
            {{ selectedTime || '请选择出生时辰' }}
          </view>
        </picker>
        <text class="time-tip">💡 精确的出生时辰对五行分析至关重要，影响天干地支排盘</text>
      </view>
      
      <!-- 五行分析说明 -->
      <view class="form-section">
        <text class="section-title">🔮 五行起名原理</text>
        <view class="principle-card">
          <text class="principle-text">根据出生年月日时推算天干地支，分析五行（金木水火土）的强弱，通过姓名中的字来补足五行缺失，达到五行平衡，助运人生。</text>
        </view>
      </view>
      
      <!-- 推荐按钮 -->
      <button 
        class="recommend-btn" 
        :class="{ disabled: !canRecommend || loading }"
        :disabled="!canRecommend || loading"
        @tap="getRecommendNames"
      >
        {{ loading ? '分析五行推荐中...' : '🎯 获取AI五行起名' }}
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
const birthDate = ref('')
const selectedName = ref('')
const selectedTimeIndex = ref(-1)
const selectedTime = ref('')

// 时辰选项
const timeOptions = ref([
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
])

// 最大日期（今天）
const maxDate = ref('')

// 计算属性
const currentSurname = computed(() => customSurname.value || selectedSurname.value)
const recommendedNames = computed(() => fortuneStore.recommendedNames)
const loading = computed(() => fortuneStore.loading)

const canRecommend = computed(() => {
  return currentSurname.value && selectedGender.value && birthDate.value && selectedTime.value
})

onMounted(async () => {
  // 设置最大日期为今天
  const today = new Date()
  const year = today.getFullYear()
  const month = (today.getMonth() + 1).toString().padStart(2, '0')
  const day = today.getDate().toString().padStart(2, '0')
  maxDate.value = `${year}-${month}-${day}`
  
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

// 日期选择
const onDateChange = (e: any) => {
  birthDate.value = e.detail.value
}

// 时辰选择
const onTimeChange = (e: any) => {
  const index = e.detail.value
  selectedTimeIndex.value = index
  selectedTime.value = timeOptions.value[index]
}

// 选择姓名
const selectName = (name: string) => {
  selectedName.value = name
}

// 获取推荐姓名
const getRecommendNames = async () => {
  if (!canRecommend.value || loading.value) return
  
  try {
    // 根据出生日期计算五行缺失
    const birthInfo = parseBirthDate(birthDate.value)
    const hourInfo = parseTimeInfo(selectedTime.value)
    
    const params = {
      surname: currentSurname.value,
      gender: selectedGender.value === 'male' ? 1 : 0,
      birthYear: birthInfo.year,
      birthMonth: birthInfo.month,
      birthDay: birthInfo.day,
      birthHour: hourInfo.hour
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

// 解析出生日期
const parseBirthDate = (dateStr: string) => {
  const [year, month, day] = dateStr.split('-').map(Number)
  return { year, month, day }
}

// 解析时辰信息
const parseTimeInfo = (timeStr: string) => {
  const timeMap: { [key: string]: number } = {
    '子时': 0, '丑时': 1, '寅时': 2, '卯时': 3,
    '辰时': 4, '巳时': 5, '午时': 6, '未时': 7,
    '申时': 8, '酉时': 9, '戌时': 10, '亥时': 11
  }
  
  const timeName = timeStr.split(' ')[0]
  return { hour: timeMap[timeName] || 0 }
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

.date-input {
  width: 100%;
  height: 80rpx;
  border: 2rpx solid #e0e0e0;
  border-radius: 10rpx;
  padding: 0 20rpx;
  font-size: 28rpx;
  background: #f9f9f9;
  display: flex;
  align-items: center;
  color: #333;
  
  &:empty::before {
    content: '请选择出生日期';
    color: #999;
  }
}

.date-tip {
  display: block;
  font-size: 24rpx;
  color: #667eea;
  margin-top: 10rpx;
  line-height: 1.5;
}

.time-input {
  width: 100%;
  height: 80rpx;
  border: 2rpx solid #e0e0e0;
  border-radius: 10rpx;
  padding: 0 20rpx;
  font-size: 28rpx;
  background: #f9f9f9;
  display: flex;
  align-items: center;
  color: #333;
  
  &:empty::before {
    content: '请选择出生时辰';
    color: #999;
  }
}

.time-tip {
  display: block;
  font-size: 24rpx;
  color: #667eea;
  margin-top: 10rpx;
  line-height: 1.5;
}

.principle-card {
  background: linear-gradient(135deg, #f8f9ff 0%, #e8f2ff 100%);
  border: 2rpx solid #667eea;
  border-radius: 15rpx;
  padding: 25rpx;
  margin-top: 15rpx;
  
  .principle-text {
    font-size: 26rpx;
    color: #4a5568;
    line-height: 1.6;
    text-align: justify;
  }
}

.recommend-btn {
  width: 100%;
  height: 90rpx;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 15rpx;
  font-size: 32rpx;
  font-weight: bold;
  
  &.disabled {
    background: #ccc;
    color: #999;
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
    text-align: center;
    margin-bottom: 30rpx;
  }
}

.names-list {
  margin-bottom: 30rpx;
  
  .name-item {
    height: 80rpx;
    border: 2rpx solid #e0e0e0;
    border-radius: 10rpx;
    margin-bottom: 15rpx;
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0 25rpx;
    background: #f9f9f9;
    
    &.selected {
      border-color: #667eea;
      background: #f8f9ff;
    }
    
    .name-text {
      font-size: 28rpx;
      color: #333;
      font-weight: 500;
    }
    
    .name-check {
      font-size: 24rpx;
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
    height: 80rpx;
    border: none;
    border-radius: 10rpx;
    font-size: 28rpx;
    font-weight: bold;
    
    &.secondary {
      background: #f0f0f0;
      color: #666;
    }
    
    &.primary {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      
      &:disabled {
        background: #ccc;
        color: #999;
      }
    }
  }
}
</style> 
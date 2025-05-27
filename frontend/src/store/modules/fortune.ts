import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { fortuneApi } from '@/api/fortune'
import { useUserStore } from './user'

export const useFortuneStore = defineStore('fortune', () => {
  // 用户输入
  const userName = ref('')
  const birthDate = ref('')
  const birthTime = ref('')

  // 分析结果
  const result = ref<any>(null)
  const todayFortune = ref('')
  const historyList = ref<any[]>([])
  const historyPagination = ref({
    total: 0,
    page: 1,
    size: 10,
    totalPages: 0
  })
  const recommendedNames = ref<string[]>([])
  const isVip = ref(false)
  const loading = ref(false)

  // 计算是否可以提交
  const canCalculate = computed(() => {
    return userName.value && birthDate.value && birthTime.value
  })

  // 命理分析
  async function doCalculate() {
    const userStore = useUserStore()
    
    // 检查是否可以进行分析
    if (!userStore.canAnalyze) {
      uni.showToast({
        title: '今日分析次数已用完，请升级VIP',
        icon: 'none'
      })
      return
    }
    
    loading.value = true
    try {
      const response = await fortuneApi.calculate({
        userId: userStore.getCurrentUserId,
        userName: userName.value,
        birthDate: birthDate.value,
        birthTime: birthTime.value
      })
      
      console.log('API响应:', response)
      
      // 检查响应是否成功
      if (response && response.code === 200 && response.data) {
        result.value = response.data
        console.log('分析结果:', result.value)
        
        // 消耗分析次数
        userStore.consumeAnalysisCount()
        
        // 刷新历史记录（后端calculate接口已自动保存）
        await loadHistory(1) // 重新加载第一页
      } else {
        console.error('API响应格式错误:', response)
        throw new Error(response?.message || '分析失败')
      }
    } catch (error) {
      console.error('分析失败:', error)
      result.value = null
      uni.showToast({
        title: '分析失败，请重试',
        icon: 'none'
      })
      throw error // 重新抛出错误，让调用方知道失败了
    } finally {
      loading.value = false
    }
  }

  // 获取今日运势
  async function getTodayFortune() {
    try {
      const response = await fortuneApi.getTodayFortune()
      // 正确提取data字段
      const fortune = response.data || '今日运势良好，万事如意！'
      todayFortune.value = fortune
      return fortune
    } catch (error) {
      console.error('获取今日运势失败:', error)
      const defaultFortune = '今日运势良好，万事如意！'
      todayFortune.value = defaultFortune
      return defaultFortune
    }
  }

  // 加载今日运势到状态
  async function loadTodayFortune() {
    await getTodayFortune()
  }

  // 获取历史记录
  async function loadHistory(page: number = 1, size: number = 10) {
    const userStore = useUserStore()
    try {
      const userId = userStore.getCurrentUserId
      const response = await fortuneApi.getHistory(userId, page, size)
      
      console.log('历史记录API响应:', response)
      
      // 正确提取data字段
      if (response && response.code === 200 && response.data) {
        const data = response.data
        historyList.value = data.list || []
        historyPagination.value = {
          total: data.total || 0,
          page: data.page || 1,
          size: data.size || 10,
          totalPages: data.totalPages || 0
        }
        console.log('历史记录数据:', historyList.value)
        console.log('分页信息:', historyPagination.value)
      } else {
        historyList.value = []
        historyPagination.value = {
          total: 0,
          page: 1,
          size: 10,
          totalPages: 0
        }
      }
    } catch (error) {
      console.error('获取历史记录失败:', error)
      historyList.value = []
      historyPagination.value = {
        total: 0,
        page: 1,
        size: 10,
        totalPages: 0
      }
    }
  }

  // AI推荐姓名
  async function loadRecommendNames() {
    if (!result.value) return
    
    const userStore = useUserStore()
    loading.value = true
    try {
      const response = await fortuneApi.recommendNames({
        wuXingLack: result.value.wuXingLack || '无',
        ganZhi: result.value.ganZhi || '',
        surname: userName.value ? userName.value.charAt(0) : '李'
      })
      
      console.log('推荐姓名API响应:', response)
      
      // 后端返回的是字符串数组，直接使用
      if (response && response.code === 200 && response.data) {
        recommendedNames.value = Array.isArray(response.data) ? response.data : []
        console.log('推荐姓名:', recommendedNames.value)
      } else {
        recommendedNames.value = []
      }
    } catch (error) {
      console.error('获取推荐姓名失败:', error)
      recommendedNames.value = []
    } finally {
      loading.value = false
    }
  }

  // 重置输入
  function resetInput() {
    userName.value = ''
    birthDate.value = ''
    birthTime.value = ''
    result.value = null
    recommendedNames.value = []
  }

  return {
    userName,
    birthDate,
    birthTime,
    result,
    todayFortune,
    historyList,
    historyPagination,
    recommendedNames,
    isVip,
    loading,
    canCalculate,
    doCalculate,
    getTodayFortune,
    loadTodayFortune,
    loadHistory,
    loadRecommendNames,
    resetInput
  }
}) 
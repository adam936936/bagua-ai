import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { calculateFortune, getTodayFortune, getHistory, recommendNames } from '@/api/fortune'

export const useFortuneStore = defineStore('fortune', () => {
  // 用户输入
  const userName = ref('')
  const birthDate = ref('')
  const birthTime = ref('')

  // 分析结果
  const result = ref<any>(null)
  const todayFortune = ref('')
  const historyList = ref<any[]>([])
  const recommendedNames = ref<string[]>([])
  const isVip = ref(false)
  const loading = ref(false)

  // 计算是否可以提交
  const canCalculate = computed(() => {
    return userName.value && birthDate.value && birthTime.value
  })

  // 命理分析
  async function doCalculate() {
    loading.value = true
    try {
      const res = await calculateFortune({
        userName: userName.value,
        birthDate: birthDate.value,
        birthTime: birthTime.value
      })
      result.value = res
      // 可选：保存到历史
      await loadHistory()
    } finally {
      loading.value = false
    }
  }

  // 获取今日运势
  async function loadTodayFortune() {
    todayFortune.value = ''
    try {
      const res = await getTodayFortune()
      todayFortune.value = res || '今日运势良好，万事如意！'
    } catch {
      todayFortune.value = '今日运势良好，万事如意！'
    }
  }

  // 获取历史记录
  async function loadHistory() {
    try {
      const res = await getHistory(userName.value)
      historyList.value = res || []
    } catch {
      historyList.value = []
    }
  }

  // AI推荐姓名
  async function loadRecommendNames() {
    if (!result.value || !result.value.wuXingLack) return
    loading.value = true
    try {
      const names = await recommendNames({
        wuXingLack: result.value.wuXingLack,
        ganZhi: result.value.ganZhi,
        surname: userName.value ? userName.value.charAt(0) : '李'
      })
      recommendedNames.value = names || []
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
    recommendedNames,
    isVip,
    loading,
    canCalculate,
    doCalculate,
    loadTodayFortune,
    loadHistory,
    loadRecommendNames,
    resetInput
  }
}) 
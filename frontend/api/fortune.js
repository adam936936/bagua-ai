// api/fortune.js - uni-app版本
const { request } = require('../utils/request.js')

/**
 * 命理相关API
 */
const fortuneApi = {
  /**
   * 计算命理信息
   */
  async calculate(params) {
    try {
      const response = await request.post('/fortune/calculate', {
        name: params.userName,  // 修改为后端期望的字段名
        birthDate: params.birthDate,
        birthTime: params.birthTime,
        gender: params.gender || 'male'  // 添加默认性别
      })
      
      // 检查响应结构并返回正确的数据
      if (response.success && response.data) {
        return response.data
      } else {
        throw new Error(response.message || '计算失败')
      }
    } catch (error) {
      console.error('计算命理信息失败:', error)
      throw error
    }
  },

  /**
   * AI推荐姓名
   */
  async recommendNames(params) {
    try {
      const response = await request.post('/fortune/names', {
        surname: params.surname,
        gender: params.gender || 'male',
        birthDate: params.birthDate,
        birthTime: params.birthTime
      })
      
      if (response.success && response.data) {
        return response.data
      } else {
        throw new Error(response.message || '推荐失败')
      }
    } catch (error) {
      console.error('AI推荐姓名失败:', error)
      throw error
    }
  },

  /**
   * 获取今日运势
   */
  async getTodayFortune() {
    try {
      const response = await request.get('/fortune/today-fortune')
      
      if (response.success) {
        return response.data
      } else {
        throw new Error(response.message || '获取失败')
      }
    } catch (error) {
      console.error('获取今日运势失败:', error)
      throw error
    }
  },

  /**
   * 获取用户历史记录
   */
  async getHistory(userId, page = 1, size = 10) {
    try {
      const response = await request.get(`/fortune/history/${userId}`, {
        page,
        size
      })
      
      if (response.success && response.data) {
        return response.data
      } else {
        throw new Error(response.message || '获取失败')
      }
    } catch (error) {
      console.error('获取历史记录失败:', error)
      throw error
    }
  },

  /**
   * 生成用户ID（临时方案）
   */
  generateUserId() {
    let userId = uni.getStorageSync('userId')  // 使用uni-app API
    if (!userId) {
      userId = Date.now()
      uni.setStorageSync('userId', userId)  // 使用uni-app API
    }
    return userId
  }
}

module.exports = {
  fortuneApi
} 
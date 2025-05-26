// api/fortune.js
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
        userId: params.userId || this.generateUserId(),
        userName: params.userName,
        birthDate: params.birthDate,
        birthTime: params.birthTime
      })
      return response.data
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
      const response = await request.post('/fortune/recommend-names', {
        userId: params.userId || this.generateUserId(),
        wuXingLack: params.wuXingLack,
        ganZhi: params.ganZhi,
        surname: params.surname
      })
      return response.data
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
      return response.data
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
      return response.data
    } catch (error) {
      console.error('获取历史记录失败:', error)
      throw error
    }
  },

  /**
   * 生成用户ID（临时方案）
   */
  generateUserId() {
    let userId = wx.getStorageSync('userId')
    if (!userId) {
      userId = Date.now()
      wx.setStorageSync('userId', userId)
    }
    return userId
  }
}

module.exports = {
  fortuneApi
} 
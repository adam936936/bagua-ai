// utils/api-test.js
const { request } = require('./request.js')

/**
 * API连接测试工具
 */
const apiTest = {
  /**
   * 测试后端连接
   */
  async testConnection() {
    try {
      console.log('开始测试后端连接...')
      
      // 测试连通性
      const response = await request.get('/fortune/connectivity-test')
      
      console.log('后端连接测试成功:', response)
      
      wx.showToast({
        title: '后端连接正常',
        icon: 'success'
      })
      
      return true
      
    } catch (error) {
      console.error('后端连接测试失败:', error)
      
      wx.showModal({
        title: '连接失败',
        content: '无法连接到后端服务，请检查：\n1. 后端服务是否启动\n2. 网络连接是否正常\n3. API地址是否正确',
        showCancel: false
      })
      
      return false
    }
  },

  /**
   * 测试命理计算API
   */
  async testCalculateApi() {
    try {
      console.log('开始测试命理计算API...')
      
      const testData = {
        userId: 999999,
        userName: '测试用户',
        birthDate: '1990-01-01',
        birthTime: '午时'
      }
      
      const response = await request.post('/fortune/calculate', testData)
      
      console.log('命理计算API测试成功:', response)
      
      wx.showToast({
        title: 'API测试成功',
        icon: 'success'
      })
      
      return response.data
      
    } catch (error) {
      console.error('命理计算API测试失败:', error)
      
      wx.showToast({
        title: 'API测试失败',
        icon: 'none'
      })
      
      return null
    }
  },

  /**
   * 测试今日运势API
   */
  async testTodayFortuneApi() {
    try {
      console.log('开始测试今日运势API...')
      
      const response = await request.get('/fortune/today-fortune')
      
      console.log('今日运势API测试成功:', response)
      
      return response.data
      
    } catch (error) {
      console.error('今日运势API测试失败:', error)
      return null
    }
  }
}

module.exports = {
  apiTest
} 
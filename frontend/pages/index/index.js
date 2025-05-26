const { fortuneApi } = require('../../api/fortune.js')

Page({
  data: {
    todayFortune: '正在获取今日运势...',
    loading: false
  },

  onLoad: function (options) {
    console.log('首页加载完成')
    this.getTodayFortune()
  },

  onShow: function () {
    console.log('首页显示')
  },

  // 获取今日运势
  getTodayFortune: async function() {
    try {
      const fortune = await fortuneApi.getTodayFortune()
      this.setData({
        todayFortune: fortune || '今日运势良好，万事如意！'
      })
    } catch (error) {
      console.error('获取今日运势失败:', error)
      this.setData({
        todayFortune: '今日运势良好，万事如意！'
      })
    }
  },

  // 跳转到信息输入页面
  goToInput: function() {
    wx.navigateTo({
      url: '/pages/input/input'
    })
  },

  // 跳转到详细计算页面
  goToCalculate: function() {
    wx.switchTab({
      url: '/pages/calculate/calculate'
    })
  },

  // 跳转到历史记录页面
  goToHistory: function() {
    wx.switchTab({
      url: '/pages/history/history'
    })
  },

  // 跳转到VIP页面
  goToVip: function() {
    wx.switchTab({
      url: '/pages/vip/vip'
    })
  },

  // 刷新今日运势
  refreshFortune: function() {
    this.setData({ loading: true })
    this.getTodayFortune().finally(() => {
      this.setData({ loading: false })
    })
  }
}) 
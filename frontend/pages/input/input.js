const { fortuneApi } = require('../../api/fortune.js')

Page({
  data: {
    loading: false,
    formData: {
      userName: '',
      birthDate: '',
      birthTime: ''
    },
    timeIndex: 0,
    timeOptions: [
      '子时(23:00-01:00)', '丑时(01:00-03:00)', '寅时(03:00-05:00)',
      '卯时(05:00-07:00)', '辰时(07:00-09:00)', '巳时(09:00-11:00)',
      '午时(11:00-13:00)', '未时(13:00-15:00)', '申时(15:00-17:00)',
      '酉时(17:00-19:00)', '戌时(19:00-21:00)', '亥时(21:00-23:00)'
    ]
  },

  onLoad: function (options) {
    console.log('快速分析页面加载完成')
  },

  // 姓名输入
  onNameInput: function(e) {
    this.setData({
      'formData.userName': e.detail.value
    })
  },

  // 日期选择
  onDateChange: function(e) {
    this.setData({
      'formData.birthDate': e.detail.value
    })
  },

  // 时辰选择
  onTimeChange: function(e) {
    const index = e.detail.value
    const timeText = this.data.timeOptions[index].split('(')[0]
    this.setData({
      timeIndex: index,
      'formData.birthTime': timeText
    })
  },

  // 快速分析
  onQuickAnalysis: async function() {
    const { userName, birthDate, birthTime } = this.data.formData
    
    if (!userName || !birthDate || !birthTime) {
      wx.showToast({
        title: '请完善信息',
        icon: 'none'
      })
      return
    }
    
    this.setData({ loading: true })
    
    try {
      const result = await fortuneApi.calculate({
        userName,
        birthDate,
        birthTime
      })
      
      // 跳转到结果页面
      wx.navigateTo({
        url: `/pages/result/result?data=${encodeURIComponent(JSON.stringify(result))}`
      })
      
    } catch (error) {
      console.error('快速分析失败:', error)
      this.setData({ loading: false })
      
      wx.showToast({
        title: '分析失败，请重试',
        icon: 'none'
      })
    }
  },

  // 跳转到详细分析
  goToDetailAnalysis: function() {
    wx.switchTab({
      url: '/pages/calculate/calculate'
    })
  }
}) 
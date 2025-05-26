const { fortuneApi } = require('../../api/fortune.js')

Page({
  data: {
    result: null,
    loading: false,
    showRecommendNames: false,
    recommendedNames: []
  },

  onLoad: function (options) {
    console.log('结果页面加载完成')
    
    // 获取传递的数据
    if (options.data) {
      try {
        const result = JSON.parse(decodeURIComponent(options.data))
        this.setData({ result })
        console.log('分析结果:', result)
      } catch (error) {
        console.error('解析结果数据失败:', error)
        wx.showToast({
          title: '数据解析失败',
          icon: 'none'
        })
      }
    }
  },

  // 获取AI推荐姓名
  getRecommendNames: async function() {
    const { result } = this.data
    if (!result || !result.wuXingLack) {
      wx.showToast({
        title: '缺少五行信息',
        icon: 'none'
      })
      return
    }

    this.setData({ loading: true })

    try {
      const names = await fortuneApi.recommendNames({
        wuXingLack: result.wuXingLack,
        ganZhi: result.ganZhi,
        surname: result.userName ? result.userName.charAt(0) : '李'
      })

      this.setData({
        recommendedNames: names || [],
        showRecommendNames: true,
        loading: false
      })

    } catch (error) {
      console.error('获取推荐姓名失败:', error)
      this.setData({ loading: false })
      
      wx.showToast({
        title: '获取推荐失败',
        icon: 'none'
      })
    }
  },

  // 分享结果
  shareResult: function() {
    wx.showActionSheet({
      itemList: ['分享给朋友', '保存到相册', '复制文本'],
      success: (res) => {
        if (res.tapIndex === 0) {
          // 分享给朋友
          this.shareToFriend()
        } else if (res.tapIndex === 1) {
          // 保存到相册
          this.saveToAlbum()
        } else if (res.tapIndex === 2) {
          // 复制文本
          this.copyText()
        }
      }
    })
  },

  // 分享给朋友
  shareToFriend: function() {
    const { result } = this.data
    wx.showShareMenu({
      withShareTicket: true,
      menus: ['shareAppMessage', 'shareTimeline']
    })
    
    wx.showToast({
      title: '请点击右上角分享',
      icon: 'none'
    })
  },

  // 保存到相册
  saveToAlbum: function() {
    wx.showToast({
      title: '保存功能开发中',
      icon: 'none'
    })
  },

  // 复制文本
  copyText: function() {
    const { result } = this.data
    if (!result) return

    const text = `【AI个性分析报告】
姓名：${result.userName}
农历：${result.lunar}
生肖：${result.shengXiao}
AI分析：${result.aiAnalysis}`

    wx.setClipboardData({
      data: text,
      success: () => {
        wx.showToast({
          title: '复制成功',
          icon: 'success'
        })
      }
    })
  },

  // 重新分析
  reAnalysis: function() {
    wx.navigateBack()
  },

  // 查看历史
  viewHistory: function() {
    wx.switchTab({
      url: '/pages/history/history'
    })
  },

  // 返回首页
  goHome: function() {
    wx.switchTab({
      url: '/pages/index/index'
    })
  },

  // 分享给朋友时的自定义分享内容
  onShareAppMessage: function() {
    const { result } = this.data
    return {
      title: `我的AI个性分析报告 - ${result?.userName || ''}`,
      path: '/pages/index/index',
      imageUrl: '/images/share-bg.jpg'
    }
  }
}) 
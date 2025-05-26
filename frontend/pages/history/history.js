const { fortuneApi } = require('../../api/fortune.js')

Page({
  data: {
    historyList: [],
    loading: false,
    page: 1,
    hasMore: true
  },

  onLoad: function (options) {
    console.log('历史记录页面加载完成')
    this.loadHistory()
  },

  onShow: function() {
    // 每次显示页面时刷新数据
    this.refreshHistory()
  },

  // 加载历史记录
  loadHistory: async function() {
    if (this.data.loading || !this.data.hasMore) return
    
    this.setData({ loading: true })
    
    try {
      const userId = fortuneApi.generateUserId()
      const history = await fortuneApi.getHistory(userId, this.data.page, 10)
      
      if (history && history.length > 0) {
        this.setData({
          historyList: this.data.page === 1 ? history : [...this.data.historyList, ...history],
          page: this.data.page + 1,
          hasMore: history.length === 10
        })
      } else {
        this.setData({ hasMore: false })
      }
      
    } catch (error) {
      console.error('加载历史记录失败:', error)
      wx.showToast({
        title: '加载失败',
        icon: 'none'
      })
    } finally {
      this.setData({ loading: false })
    }
  },

  // 刷新历史记录
  refreshHistory: function() {
    this.setData({
      historyList: [],
      page: 1,
      hasMore: true
    })
    this.loadHistory()
  },

  // 查看详情
  viewDetail: function(e) {
    const item = e.currentTarget.dataset.item
    wx.navigateTo({
      url: `/pages/result/result?data=${encodeURIComponent(JSON.stringify(item))}`
    })
  },

  // 分享结果
  shareResult: function(e) {
    const item = e.currentTarget.dataset.item
    wx.showActionSheet({
      itemList: ['分享给朋友', '保存到相册'],
      success: (res) => {
        if (res.tapIndex === 0) {
          // 分享给朋友
          wx.showToast({
            title: '分享功能开发中',
            icon: 'none'
          })
        } else if (res.tapIndex === 1) {
          // 保存到相册
          wx.showToast({
            title: '保存成功',
            icon: 'success'
          })
        }
      }
    })
  },

  // 删除记录
  deleteItem: function(e) {
    const index = e.currentTarget.dataset.index
    wx.showModal({
      title: '确认删除',
      content: '确定要删除这条记录吗？',
      success: (res) => {
        if (res.confirm) {
          const historyList = this.data.historyList
          historyList.splice(index, 1)
          this.setData({ historyList })
          
          wx.showToast({
            title: '删除成功',
            icon: 'success'
          })
        }
      }
    })
  },

  // 开始分析
  startAnalysis: function() {
    wx.switchTab({
      url: '/pages/calculate/calculate'
    })
  },

  // 下拉刷新
  onPullDownRefresh: function() {
    this.refreshHistory()
    wx.stopPullDownRefresh()
  },

  // 上拉加载更多
  onReachBottom: function() {
    this.loadHistory()
  }
}) 
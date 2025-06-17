<template>
  <view class="container">
    <view class="header">
      <text class="title">分析结果</text>
      <text class="subtitle">您的AI个性分析报告</text>
      <!-- 右上角分享按钮 -->
      <view class="share-menu" v-if="result" @tap="toggleShareMenu">
        <view class="share-dots">
          <view class="dot"></view>
          <view class="dot"></view>
          <view class="dot"></view>
        </view>
        <!-- 分享下拉菜单 -->
        <view class="share-dropdown" v-if="showShareMenu">
          <view class="share-item" @tap="shareToFriend">
            <text class="share-icon">📱</text>
            <text class="share-text">分享给朋友</text>
          </view>
          <view class="share-item" @tap="generateQRCode">
            <text class="share-icon">📷</text>
            <text class="share-text">生成二维码</text>
          </view>
          <view class="share-item" @tap="saveToAlbum">
            <text class="share-icon">💾</text>
            <text class="share-text">保存图片</text>
          </view>
        </view>
      </view>
    </view>
    
    <view class="result-card" v-if="result">
      <view class="user-info">
        <text class="user-name">{{ result.userName }}</text>
        <text class="birth-info">{{ result.birthDate }} {{ result.birthTime }}</text>
        <text class="test-time">测算时间：{{ formatTestTime(result.createTime) }}</text>
      </view>
      
      <view class="basic-info">
        <view class="info-item">
          <text class="info-label">农历</text>
          <text class="info-value">{{ result.lunar }}</text>
        </view>
        <view class="info-item">
          <text class="info-label">生肖</text>
          <text class="info-value">{{ result.shengXiao }}</text>
        </view>
        <view class="info-item" v-if="result.ganZhi">
          <text class="info-label">八字</text>
          <text class="info-value">{{ result.ganZhi }}</text>
        </view>
        <view class="info-item" v-if="result.wuXingLack">
          <text class="info-label">五行缺失</text>
          <text class="info-value">{{ result.wuXingLack }}</text>
        </view>
      </view>
      
      <view class="analysis-section">
        <text class="analysis-title">🤖 AI分析报告</text>
        <text class="analysis-content">{{ result.aiAnalysis }}</text>
      </view>
      
      <view class="recommend-section" v-if="result.wuXingLack">
        <button class="recommend-btn" @tap="getRecommendNames" :disabled="loading">
          {{ loading ? '获取中...' : '获取AI推荐姓名' }}
        </button>
      </view>
      
      <view class="names-section" v-if="showRecommendNames && recommendedNames.length > 0">
        <text class="names-title">💎 AI推荐姓名</text>
        <view class="names-list">
          <view class="name-item" v-for="(item, index) in recommendedNames" :key="index">
            {{ item }}
          </view>
        </view>
      </view>
    </view>
    
    <view class="no-result" v-else>
      <text class="no-result-text">暂无分析结果，请先进行分析</text>
      <button class="back-btn" @tap="goHome">返回首页</button>
    </view>
    
    <!-- 重新设计的底部按钮 -->
    <view class="bottom-actions" v-if="result">
      <button class="btn-left secondary" @tap="reAnalysis">
        <text class="btn-icon">🔄</text>
        <text class="btn-text">重新分析</text>
      </button>
      <button class="btn-right primary" @tap="saveResult">
        <text class="btn-icon">💾</text>
        <text class="btn-text">保存结果</text>
      </button>
    </view>
    
    <!-- 二维码弹窗 -->
    <view class="qr-modal" v-if="showQRCode" @tap="closeQRCode">
      <view class="qr-content" @tap.stop="stopPropagation">
        <view class="qr-header">
          <text class="qr-title">分享二维码</text>
          <text class="qr-close" @tap="closeQRCode">✕</text>
        </view>
        <view class="qr-code">
          <image class="qr-image" :src="qrCodeUrl" mode="aspectFit"></image>
        </view>
        <text class="qr-tip">长按保存二维码，分享给朋友</text>
      </view>
    </view>
    
    <canvas canvas-id="resultCanvas" id="resultCanvas" style="width:750rpx;height:1200rpx;position:absolute;left:-9999rpx;top:-9999rpx;z-index:-1;"></canvas>
  </view>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useFortuneStore } from '@/store/modules/fortune'

const fortuneStore = useFortuneStore()

// 响应式数据
const result = computed(() => fortuneStore.result)
const recommendedNames = computed(() => fortuneStore.recommendedNames)
const loading = computed(() => fortuneStore.loading)

// 本地状态
const showShareMenu = ref(false)
const showRecommendNames = ref(false)
const showQRCode = ref(false)
const qrCodeUrl = ref('/static/qrcode.png')

// 页面加载时检查是否有分析结果
onMounted(() => {
  // 确保隐藏任何可能残留的loading
  uni.hideLoading()
  
  console.log('Result页面加载，当前store:', {
    result: JSON.stringify(result.value),
    hasResult: !!result.value,
    userName: result.value?.userName,
    birthDate: result.value?.birthDate,
    birthTime: result.value?.birthTime,
    fullStoreResult: fortuneStore
  })
  
  // 如果没有分析结果，尝试从URL参数或缓存中恢复
  if (!result.value) {
    // 尝试从存储中恢复最后一次的分析结果
    try {
      const savedResult = uni.getStorageSync('lastFortuneResult')
      if (savedResult) {
        console.log('从缓存中恢复分析结果')
        fortuneStore.result = JSON.parse(savedResult)
        console.log('恢复后的结果:', fortuneStore.result)
      } else {
        console.error('缓存中没有找到分析结果数据')
        uni.showToast({
          title: '暂无分析结果，请先进行分析',
          icon: 'none'
        })
      }
    } catch (e) {
      console.error('恢复分析结果失败:', e)
      uni.showToast({
        title: '暂无分析结果，请先进行分析',
        icon: 'none'
      })
    }
  } else {
    // 有结果，保存到本地存储，以便后续可能的恢复
    uni.setStorageSync('lastFortuneResult', JSON.stringify(result.value))
  }
})

// 切换分享菜单
const toggleShareMenu = () => {
  showShareMenu.value = !showShareMenu.value
}

// 分享给朋友
const shareToFriend = () => {
  showShareMenu.value = false
  uni.showShareMenu({
    withShareTicket: true,
    success: () => {
      console.log('分享成功')
    },
    fail: (err) => {
      console.error('分享失败:', err)
      uni.showToast({
        title: '分享失败',
        icon: 'none'
      })
    }
  })
}

// 生成二维码
const generateQRCode = () => {
  showShareMenu.value = false
  // 这里应该调用后端API生成二维码
  // 暂时使用模拟数据
  qrCodeUrl.value = 'https://via.placeholder.com/200x200?text=QR+Code'
  showQRCode.value = true
}

// 保存到相册
const saveToAlbum = () => {
  showShareMenu.value = false
  uni.showToast({
    title: '保存功能开发中',
    icon: 'none'
  })
}

// 关闭二维码弹窗
const closeQRCode = () => {
  showQRCode.value = false
}

// 阻止事件冒泡
const stopPropagation = () => {
  // 阻止事件冒泡
}

// 获取推荐姓名
const getRecommendNames = async () => {
  try {
    await fortuneStore.loadRecommendNames()
    showRecommendNames.value = true
  } catch (error) {
    console.error('获取推荐姓名失败:', error)
    uni.showToast({
      title: '获取推荐姓名失败',
      icon: 'none'
    })
  }
}

// 重新分析
const reAnalysis = () => {
  uni.navigateTo({
    url: '/pages/calculate/calculate'
  })
}

// 保存结果
const saveResult = () => {
  uni.showLoading({ title: '生成图片中...' });
  const ctx = uni.createCanvasContext('resultCanvas');
  // 绘制白色背景
  ctx.setFillStyle('#fff');
  ctx.fillRect(0, 0, 750, 1200);
  // 绘制分析结果内容（这里只做简单示例，实际可根据页面内容调整位置和样式）
  ctx.setFontSize(36);
  ctx.setFillStyle('#764ba2');
  ctx.fillText('AI分析报告', 40, 80);
  ctx.setFontSize(28);
  ctx.setFillStyle('#333');
  ctx.fillText(result.value.userName || '', 40, 140);
  ctx.fillText(result.value.birthDate + ' ' + result.value.birthTime, 40, 190);
  ctx.fillText('八字：' + (result.value.ganZhi || ''), 40, 240);
  ctx.fillText('五行缺失：' + (result.value.wuXingLack || ''), 40, 290);
  ctx.setFontSize(24);
  ctx.setFillStyle('#666');
  ctx.fillText(result.value.aiAnalysis ? result.value.aiAnalysis.substring(0, 40) + '...' : '', 40, 340);
  // 绘制推荐姓名
  ctx.setFontSize(28);
  ctx.setFillStyle('#764ba2');
  ctx.fillText('AI推荐姓名：', 40, 400);
  let x = 200;
  let y = 400;
  (recommendedNames.value || []).forEach((name, idx) => {
    ctx.setFillStyle('#e0e7ff');
    ctx.fillRect(x, y - 28, 120, 40);
    ctx.setFillStyle('#764ba2');
    ctx.fillText(name, x + 10, y);
    x += 140;
    if (x > 600) { x = 200; y += 60; }
  });
  // 绘制二维码
  ctx.drawImage(qrCodeUrl.value, 550, 1050, 150, 150);
  ctx.draw(false, () => {
    uni.canvasToTempFilePath({
      canvasId: 'resultCanvas',
      success: (res) => {
        uni.saveImageToPhotosAlbum({
          filePath: res.tempFilePath,
          success: () => {
            uni.hideLoading();
            uni.showToast({ title: '已保存到相册', icon: 'success' });
          },
          fail: () => { uni.hideLoading(); }
        });
      },
      fail: () => { uni.hideLoading(); }
    });
  });
};

// 返回首页
const goHome = () => {
  uni.switchTab({
    url: '/pages/index/index'
  })
}

// 格式化测算时间
const formatTestTime = (timeStr: string) => {
  if (!timeStr) return ''
  const date = new Date(timeStr)
  const year = date.getFullYear()
  const month = (date.getMonth() + 1).toString().padStart(2, '0')
  const day = date.getDate().toString().padStart(2, '0')
  const hour = date.getHours().toString().padStart(2, '0')
  const minute = date.getMinutes().toString().padStart(2, '0')
  return `${year}-${month}-${day} ${hour}:${minute}`
}
</script>

<style lang="scss" scoped>
.container {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 40rpx 30rpx 120rpx;
}

.header {
  position: relative;
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
  
  .share-menu {
    position: absolute;
    top: 0;
    right: 0;
    
    .share-dots {
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 10rpx;
      
      .dot {
        width: 8rpx;
        height: 8rpx;
        background: white;
        border-radius: 50%;
        margin: 2rpx 0;
      }
    }
    
    .share-dropdown {
      position: absolute;
      top: 100%;
      right: 0;
      background: white;
      border-radius: 12rpx;
      box-shadow: 0 8rpx 32rpx rgba(0, 0, 0, 0.1);
      min-width: 200rpx;
      z-index: 100;
      
      .share-item {
        display: flex;
        align-items: center;
        padding: 20rpx;
        border-bottom: 1rpx solid #f0f0f0;
        
        &:last-child {
          border-bottom: none;
        }
        
        .share-icon {
          font-size: 32rpx;
          margin-right: 15rpx;
        }
        
        .share-text {
          font-size: 28rpx;
          color: #333;
        }
      }
    }
  }
}

.result-card {
  background: white;
  border-radius: 20rpx;
  padding: 40rpx;
  margin-bottom: 40rpx;
  box-shadow: 0 8rpx 32rpx rgba(0, 0, 0, 0.1);
}

.user-info {
  text-align: center;
  margin-bottom: 40rpx;
  padding-bottom: 30rpx;
  border-bottom: 2rpx solid #f0f0f0;
  
  .user-name {
    display: block;
    font-size: 36rpx;
    font-weight: bold;
    color: #333;
    margin-bottom: 10rpx;
  }
  
  .birth-info {
    display: block;
    font-size: 28rpx;
    color: #666;
    margin-bottom: 8rpx;
  }
  
  .test-time {
    display: block;
    font-size: 24rpx;
    color: #999;
  }
}

.basic-info {
  margin-bottom: 40rpx;
  
  .info-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 20rpx 0;
    border-bottom: 1rpx solid #f5f5f5;
    
    &:last-child {
      border-bottom: none;
    }
    
    .info-label {
      font-size: 28rpx;
      color: #666;
      font-weight: 500;
    }
    
    .info-value {
      font-size: 28rpx;
      color: #333;
      font-weight: bold;
    }
  }
}

.analysis-section {
  margin-bottom: 40rpx;
  
  .analysis-title {
    display: block;
    font-size: 32rpx;
    font-weight: bold;
    color: #333;
    margin-bottom: 20rpx;
  }
  
  .analysis-content {
    display: block;
    font-size: 28rpx;
    line-height: 1.8;
    color: #666;
  }
}

.recommend-section {
  text-align: center;
  margin-bottom: 40rpx;
  
  .recommend-btn {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    border: none;
    border-radius: 50rpx;
    padding: 20rpx 40rpx;
    font-size: 28rpx;
    
    &[disabled] {
      opacity: 0.6;
    }
  }
}

.names-section {
  margin-top: 40rpx;
  .names-title {
    font-size: 32rpx;
    font-weight: bold;
    color: #764ba2;
    margin-bottom: 20rpx;
    display: block;
    text-align: center;
  }
  .names-list {
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    gap: 24rpx 32rpx;
    margin-top: 10rpx;
  }
  .name-item {
    background: linear-gradient(135deg, #e0e7ff 0%, #f3e8ff 100%);
    color: #764ba2;
    font-size: 30rpx;
    font-weight: 500;
    border-radius: 32rpx;
    padding: 18rpx 38rpx;
    margin-bottom: 16rpx;
    box-shadow: 0 4rpx 16rpx rgba(118, 75, 162, 0.08);
    border: 1rpx solid #d1c4e9;
    text-align: center;
  }
}

.no-result {
  text-align: center;
  padding: 100rpx 0;
  
  .no-result-text {
    display: block;
    font-size: 32rpx;
    color: rgba(255, 255, 255, 0.8);
    margin-bottom: 40rpx;
  }
  
  .back-btn {
    background: white;
    color: #667eea;
    border: none;
    border-radius: 50rpx;
    padding: 20rpx 40rpx;
    font-size: 28rpx;
  }
}

.bottom-actions {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  display: flex;
  padding: 20rpx 30rpx;
  background: white;
  box-shadow: 0 -4rpx 20rpx rgba(0, 0, 0, 0.1);
  gap: 20rpx;
  
  .btn-left,
  .btn-right {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 25rpx;
    border-radius: 15rpx;
    border: none;
    font-size: 28rpx;
    
    .btn-icon {
      margin-right: 10rpx;
      font-size: 32rpx;
    }
    
    .btn-text {
      font-weight: 500;
    }
  }
  
  .secondary {
    background: #f0f0f0;
    color: #666;
  }
  
  .primary {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
  }
}

.qr-modal {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  
  .qr-content {
    background: white;
    border-radius: 20rpx;
    padding: 40rpx;
    margin: 0 40rpx;
    max-width: 500rpx;
    
    .qr-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 30rpx;
      
      .qr-title {
        font-size: 32rpx;
        font-weight: bold;
        color: #333;
      }
      
      .qr-close {
        font-size: 36rpx;
        color: #999;
        padding: 10rpx;
      }
    }
    
    .qr-code {
      text-align: center;
      margin-bottom: 30rpx;
      
      .qr-image {
        width: 300rpx;
        height: 300rpx;
        border: 2rpx solid #f0f0f0;
        border-radius: 10rpx;
      }
    }
    
    .qr-tip {
      display: block;
      text-align: center;
      font-size: 24rpx;
      color: #999;
    }
  }
}
</style> 
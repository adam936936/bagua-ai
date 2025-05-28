<template>
  <view class="container">
    <view class="header">
      <text class="title">个人中心</text>
      <text class="subtitle">管理您的账户信息</text>
    </view>
    
    <!-- 用户信息卡片 -->
    <view class="user-card">
      <view class="user-avatar">
        <image 
          :src="userInfo.avatar || '/static/default-avatar.png'" 
          class="avatar-img"
          @click="chooseAvatar"
        />
        <view class="avatar-edit-btn">
          <text class="edit-icon">📷</text>
        </view>
      </view>
      <view class="user-info">
        <view class="user-name">
          {{ userInfo.nickname || '用户' + (userInfo.id ? userInfo.id.toString().slice(-4) : '0000') }}
        </view>
        <view class="user-id">ID: {{ userInfo.id || '未登录' }}</view>
      </view>
    </view>

    <!-- VIP状态卡片 -->
    <view class="vip-card" :class="{ 'vip-active': vipStatus.isVip }">
      <view class="vip-header">
        <view class="vip-title">
          <text class="vip-icon">👑</text>
          <text class="vip-text">{{ vipStatus.isVip ? 'VIP会员' : '普通用户' }}</text>
        </view>
        <view class="vip-action" @click="goToVip">
          <text>{{ vipStatus.isVip ? '管理' : '开通' }}</text>
          <text class="iconfont icon-arrow-right"></text>
        </view>
      </view>
      
      <view v-if="vipStatus.isVip" class="vip-info">
        <view class="vip-expire">
          <text class="expire-label">到期时间：</text>
          <text class="expire-time">{{ formattedExpireTime }}</text>
        </view>
        <view class="vip-countdown" v-if="daysLeft > 0">
          <text class="countdown-text">剩余 {{ daysLeft }} 天</text>
        </view>
      </view>
      
      <view v-else class="vip-benefits">
        <text class="benefits-text">开通VIP享受更多精准测算服务</text>
      </view>
    </view>

    <!-- 功能菜单 -->
    <view class="features">
      <view class="feature-grid">
        <view class="feature-card" @click="goToOrders">
          <view class="feature-icon bg-blue">📋</view>
          <text class="feature-title">我的订单</text>
          <text class="feature-desc">查看订单记录</text>
        </view>
        
        <view class="feature-card" @click="goToHistory">
          <view class="feature-icon bg-green">📜</view>
          <text class="feature-title">测算历史</text>
          <text class="feature-desc">查看测算记录</text>
        </view>
        
        <view class="feature-card" @click="goToSettings">
          <view class="feature-icon bg-orange">⚙️</view>
          <text class="feature-title">设置</text>
          <text class="feature-desc">账户设置</text>
        </view>
        
        <view class="feature-card" @click="contactService">
          <view class="feature-icon bg-pink">💬</view>
          <text class="feature-title">联系客服</text>
          <text class="feature-desc">在线客服</text>
        </view>
      </view>
    </view>

    <!-- 昵称编辑弹窗 - 已移至设置页面 -->
    <!-- 
    <uni-popup ref="nicknamePopup" type="center">
      <view class="nickname-popup">
        <view class="popup-title">修改昵称</view>
        <input 
          v-model="newNickname" 
          class="nickname-input" 
          placeholder="请输入新昵称"
          maxlength="20"
        />
        <view class="popup-buttons">
          <button class="cancel-btn" @click="cancelEdit">取消</button>
          <button class="confirm-btn" @click="saveNickname">确定</button>
        </view>
      </view>
    </uni-popup>
    -->
  </view>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useUserStore } from '@/store/modules/user'
import { useVipStore } from '@/store/modules/vip'

const userStore = useUserStore()
const vipStore = useVipStore()

// 响应式数据
const userInfo = computed(() => userStore.userInfo)
const vipStatus = computed(() => vipStore.vipStatus)
const formattedExpireTime = computed(() => vipStore.formattedExpireTime)
// 昵称编辑相关变量已移至设置页面
// const newNickname = ref('')
// const nicknamePopup = ref()

// 计算VIP剩余天数
const daysLeft = computed(() => {
  if (!vipStatus.value.expireTime) return 0
  const expireDate = new Date(vipStatus.value.expireTime)
  const now = new Date()
  const diffTime = expireDate.getTime() - now.getTime()
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
  return Math.max(0, diffDays)
})

// 页面加载时获取数据
onMounted(async () => {
  try {
    await Promise.all([
      vipStore.loadVipStatus(),
      userStore.loadUserInfo()
    ])
  } catch (error) {
    console.error('加载用户信息失败:', error)
  }
})

// 选择头像
const chooseAvatar = () => {
  uni.chooseImage({
    count: 1,
    sizeType: ['compressed'],
    sourceType: ['album', 'camera'],
    success: (res) => {
      const tempFilePath = res.tempFilePaths[0]
      // 这里应该上传头像到服务器
      uploadAvatar(tempFilePath)
    }
  })
}

// 上传头像
const uploadAvatar = async (filePath: string) => {
  try {
    uni.showLoading({ title: '上传中...' })
    // 模拟上传
    setTimeout(() => {
      userStore.updateAvatar(filePath)
      uni.hideLoading()
      uni.showToast({ title: '头像更新成功' })
    }, 1000)
  } catch (error) {
    uni.hideLoading()
    uni.showToast({ title: '上传失败', icon: 'error' })
  }
}

// 昵称编辑功能已移至设置页面
/*
// 编辑昵称
const editNickname = () => {
  newNickname.value = userInfo.value.nickname || ''
  nicknamePopup.value.open()
}

// 保存昵称
const saveNickname = async () => {
  if (!newNickname.value.trim()) {
    uni.showToast({ title: '昵称不能为空', icon: 'error' })
    return
  }
  
  try {
    await userStore.updateNickname(newNickname.value.trim())
    nicknamePopup.value.close()
    uni.showToast({ title: '昵称更新成功' })
  } catch (error) {
    uni.showToast({ title: '更新失败', icon: 'error' })
  }
}

// 取消编辑
const cancelEdit = () => {
  nicknamePopup.value.close()
}
*/

// 导航方法
const goToVip = () => {
  uni.navigateTo({ url: '/pages/vip/vip' })
}

const goToOrders = () => {
  uni.navigateTo({ url: '/pages/orders/orders' })
}

const goToHistory = () => {
  uni.navigateTo({ url: '/pages/history/history' })
}

const goToSettings = () => {
  uni.showToast({ title: '功能开发中', icon: 'none' })
}

const contactService = () => {
  uni.showModal({
    title: '联系客服',
    content: '客服微信：fortune-ai\n工作时间：9:00-18:00',
    showCancel: false
  })
}

const aboutApp = () => {
  uni.showModal({
    title: '关于我们',
    content: 'AI八卦运势小程序 v1.0.0\n专业的AI算命服务平台',
    showCancel: false
  })
}
</script>

<style lang="scss" scoped>
.container {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 40rpx 0 0 0;
}

.header {
  text-align: center;
  margin-bottom: 30rpx;
  padding-top: 40rpx;
  
  .title {
    display: block;
    font-size: 56rpx;
    font-weight: bold;
    color: white;
    margin-bottom: 10rpx;
  }
  
  .subtitle {
    display: block;
    font-size: 28rpx;
    color: rgba(255, 255, 255, 0.8);
  }
}

.user-card {
  background: rgba(255, 255, 255, 0.95);
  border-radius: 20rpx;
  padding: 40rpx;
  margin: 0 32rpx 32rpx 32rpx;
  display: flex;
  align-items: center;
  box-shadow: 0 8rpx 32rpx rgba(0, 0, 0, 0.1);
}

.user-avatar {
  position: relative;
  margin-right: 30rpx;
}

.avatar-img {
  width: 120rpx;
  height: 120rpx;
  border-radius: 60rpx;
  border: 4rpx solid #fff;
  box-shadow: 0 4rpx 16rpx rgba(0, 0, 0, 0.1);
}

.avatar-edit-btn {
  position: absolute;
  bottom: 0;
  right: 0;
  width: 40rpx;
  height: 40rpx;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 18rpx;
  box-shadow: 0 2rpx 8rpx rgba(0, 0, 0, 0.2);
}

.user-info {
  flex: 1;
}

.user-name {
  font-size: 36rpx;
  font-weight: bold;
  color: #333;
  margin-bottom: 10rpx;
  display: flex;
  align-items: center;
  
  /* 编辑图标样式已移至设置页面 */
  /*
  .icon-edit {
    margin-left: 10rpx;
    font-size: 24rpx;
    color: #999;
  }
  */
}

.user-id {
  font-size: 24rpx;
  color: #999;
}

.vip-card {
  background: rgba(255, 255, 255, 0.95);
  border-radius: 20rpx;
  padding: 40rpx;
  margin: 0 32rpx 32rpx 32rpx;
  box-shadow: 0 8rpx 32rpx rgba(0, 0, 0, 0.1);
  
  &.vip-active {
    background: linear-gradient(135deg, #ffd700 0%, #ffb347 100%);
    color: #333;
  }
}

.vip-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20rpx;
}

.vip-title {
  display: flex;
  align-items: center;
  
  .vip-icon {
    font-size: 32rpx;
    margin-right: 10rpx;
  }
  
  .vip-text {
    font-size: 32rpx;
    font-weight: bold;
  }
}

.vip-action {
  display: flex;
  align-items: center;
  color: #667eea;
  font-size: 28rpx;
  
  .icon-arrow-right {
    margin-left: 5rpx;
    font-size: 24rpx;
  }
}

.vip-info {
  .vip-expire {
    font-size: 26rpx;
    margin-bottom: 10rpx;
    
    .expire-label {
      color: #666;
    }
    
    .expire-time {
      color: #333;
      font-weight: bold;
    }
  }
  
  .vip-countdown {
    .countdown-text {
      background: rgba(255, 255, 255, 0.8);
      padding: 8rpx 16rpx;
      border-radius: 20rpx;
      font-size: 24rpx;
      color: #333;
    }
  }
}

.vip-benefits {
  .benefits-text {
    font-size: 26rpx;
    color: #666;
  }
}

.features {
  background: #f7f9fb;
  border-radius: 24rpx;
  margin: 0 32rpx 0 32rpx;
  padding: 32rpx 0 20rpx 0;
  box-shadow: none;
  
  .feature-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 32rpx 24rpx;
    padding: 0 32rpx;
  }
  
  .feature-card {
    background: #fff;
    border-radius: 24rpx;
    box-shadow: 0 2rpx 12rpx rgba(0,0,0,0.06);
    display: flex;
    flex-direction: column;
    align-items: center;
    padding: 38rpx 0 28rpx 0;
    
    .feature-icon {
      width: 80rpx;
      height: 80rpx;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 40rpx;
      color: #fff;
      margin-bottom: 18rpx;
      font-weight: bold;
    }
    
    .bg-orange { background: linear-gradient(135deg, #ffb347 0%, #ff7e5f 100%); }
    .bg-green { background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%); }
    .bg-blue { background: linear-gradient(135deg, #43a3f7 0%, #38b6ff 100%); }
    .bg-pink { background: linear-gradient(135deg, #ff6a88 0%, #ff99ac 100%); }
    
    .feature-title {
      font-size: 28rpx;
      font-weight: 600;
      color: #222;
      margin-bottom: 6rpx;
    }
    
    .feature-desc {
      font-size: 22rpx;
      color: #888;
    }
  }
}

/* 昵称编辑弹窗样式已移至设置页面 */
/*
.nickname-popup {
  background: white;
  border-radius: 20rpx;
  padding: 40rpx;
  width: 600rpx;
}

.popup-title {
  text-align: center;
  font-size: 32rpx;
  font-weight: bold;
  margin-bottom: 30rpx;
  color: #333;
}

.nickname-input {
  width: 100%;
  height: 80rpx;
  border: 2rpx solid #e0e0e0;
  border-radius: 10rpx;
  padding: 0 20rpx;
  font-size: 28rpx;
  margin-bottom: 30rpx;
}

.popup-buttons {
  display: flex;
  gap: 20rpx;
}

.cancel-btn, .confirm-btn {
  flex: 1;
  height: 80rpx;
  border-radius: 10rpx;
  font-size: 28rpx;
  border: none;
}

.cancel-btn {
  background: #f0f0f0;
  color: #666;
}

.confirm-btn {
  background: #667eea;
  color: white;
}
*/
</style> 
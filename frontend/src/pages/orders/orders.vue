<template>
  <view class="orders-container">
    <!-- 页面标题 -->
    <view class="page-header">
      <view class="header-title">我的订单</view>
      <view class="header-subtitle">查看您的购买记录</view>
    </view>

    <!-- 订单筛选 -->
    <view class="filter-section">
      <view class="filter-tabs">
        <view 
          v-for="(tab, index) in filterTabs" 
          :key="index"
          class="filter-tab"
          :class="{ active: currentFilter === tab.value }"
          @click="changeFilter(tab.value)"
        >
          {{ tab.label }}
        </view>
      </view>
    </view>

    <!-- 订单列表 -->
    <view class="orders-list">
      <view v-if="loading" class="loading-container">
        <uni-load-more status="loading" />
      </view>
      
      <view v-else-if="filteredOrders.length === 0" class="empty-container">
        <view class="empty-icon">📋</view>
        <view class="empty-text">暂无订单记录</view>
        <view class="empty-subtitle">快去购买VIP会员享受更多服务吧</view>
        <button class="go-vip-btn" @click="goToVip">立即开通VIP</button>
      </view>
      
      <view v-else>
        <view 
          v-for="order in filteredOrders" 
          :key="order.orderNo"
          class="order-item"
          @click="viewOrderDetail(order)"
        >
          <view class="order-header">
            <view class="order-info">
              <view class="order-no">订单号：{{ order.orderNo }}</view>
              <view class="order-time">{{ formatTime(order.createTime) }}</view>
            </view>
            <view class="order-status" :class="getStatusClass(order.status)">
              {{ getStatusText(order.status) }}
            </view>
          </view>
          
          <view class="order-content">
            <view class="product-info">
              <view class="product-icon">👑</view>
              <view class="product-details">
                <view class="product-name">{{ getPlanName(order.planType) }}</view>
                <view class="product-desc">{{ getPlanDesc(order.planType) }}</view>
              </view>
            </view>
            <view class="order-amount">¥{{ order.amount }}</view>
          </view>
          
          <view class="order-actions" v-if="order.status === 'pending'">
            <button class="cancel-btn" @click.stop="cancelOrder(order)">取消订单</button>
            <button class="pay-btn" @click.stop="payOrder(order)">立即支付</button>
          </view>
        </view>
      </view>
    </view>

    <!-- 加载更多 -->
    <view v-if="hasMore && !loading" class="load-more" @click="loadMore">
      <text>加载更多</text>
    </view>

    <!-- 订单详情弹窗 -->
    <uni-popup ref="orderDetailPopup" type="bottom">
      <view class="order-detail-popup">
        <view class="popup-header">
          <view class="popup-title">订单详情</view>
          <view class="popup-close" @click="closeOrderDetail">✕</view>
        </view>
        
        <view v-if="selectedOrder" class="order-detail-content">
          <view class="detail-section">
            <view class="section-title">订单信息</view>
            <view class="detail-item">
              <text class="detail-label">订单号：</text>
              <text class="detail-value">{{ selectedOrder.orderNo }}</text>
            </view>
            <view class="detail-item">
              <text class="detail-label">创建时间：</text>
              <text class="detail-value">{{ formatTime(selectedOrder.createTime) }}</text>
            </view>
            <view class="detail-item">
              <text class="detail-label">订单状态：</text>
              <text class="detail-value" :class="getStatusClass(selectedOrder.status)">
                {{ getStatusText(selectedOrder.status) }}
              </text>
            </view>
          </view>
          
          <view class="detail-section">
            <view class="section-title">商品信息</view>
            <view class="detail-item">
              <text class="detail-label">商品名称：</text>
              <text class="detail-value">{{ getPlanName(selectedOrder.planType) }}</text>
            </view>
            <view class="detail-item">
              <text class="detail-label">商品描述：</text>
              <text class="detail-value">{{ getPlanDesc(selectedOrder.planType) }}</text>
            </view>
            <view class="detail-item">
              <text class="detail-label">支付金额：</text>
              <text class="detail-value amount">¥{{ selectedOrder.amount }}</text>
            </view>
          </view>
          
          <view v-if="selectedOrder.payTime" class="detail-section">
            <view class="section-title">支付信息</view>
            <view class="detail-item">
              <text class="detail-label">支付时间：</text>
              <text class="detail-value">{{ formatTime(selectedOrder.payTime) }}</text>
            </view>
            <view class="detail-item">
              <text class="detail-label">支付方式：</text>
              <text class="detail-value">{{ selectedOrder.paymentMethod || '微信支付' }}</text>
            </view>
          </view>
        </view>
      </view>
    </uni-popup>
  </view>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useVipStore } from '@/store/modules/vip'
import { useUserStore } from '@/store/modules/user'

const vipStore = useVipStore()
const userStore = useUserStore()

// 响应式数据
const loading = ref(false)
const orders = ref<any[]>([])
const currentFilter = ref('all')
const hasMore = ref(true)
const page = ref(1)
const selectedOrder = ref(null)
const orderDetailPopup = ref()

// 筛选选项
const filterTabs = [
  { label: '全部', value: 'all' },
  { label: '待支付', value: 'pending' },
  { label: '已支付', value: 'paid' },
  { label: '已取消', value: 'cancelled' }
]

// 计算属性
const filteredOrders = computed(() => {
  if (currentFilter.value === 'all') {
    return orders.value
  }
  return orders.value.filter(order => order.status === currentFilter.value)
})

// 页面加载时获取订单列表
onMounted(() => {
  loadOrders()
})

// 加载订单列表
const loadOrders = async () => {
  try {
    loading.value = true
    await vipStore.loadUserOrders()
    // 模拟订单数据
    orders.value = [
      {
        orderNo: 'VIP202505280001',
        planType: 'monthly',
        amount: 19.90,
        status: 'paid',
        createTime: '2025-05-28 10:30:00',
        payTime: '2025-05-28 10:35:00',
        paymentMethod: '微信支付'
      },
      {
        orderNo: 'VIP202505270001',
        planType: 'yearly',
        amount: 99.90,
        status: 'pending',
        createTime: '2025-05-27 15:20:00'
      },
      {
        orderNo: 'VIP202505260001',
        planType: 'lifetime',
        amount: 199.90,
        status: 'cancelled',
        createTime: '2025-05-26 09:15:00'
      }
    ]
  } catch (error) {
    console.error('加载订单失败:', error)
    uni.showToast({ title: '加载失败', icon: 'error' })
  } finally {
    loading.value = false
  }
}

// 加载更多
const loadMore = async () => {
  if (loading.value || !hasMore.value) return
  
  try {
    loading.value = true
    page.value++
    // 这里应该调用API加载更多数据
    // 模拟没有更多数据
    hasMore.value = false
  } catch (error) {
    console.error('加载更多失败:', error)
  } finally {
    loading.value = false
  }
}

// 切换筛选条件
const changeFilter = (filter: string) => {
  currentFilter.value = filter
}

// 查看订单详情
const viewOrderDetail = (order: any) => {
  selectedOrder.value = order
  orderDetailPopup.value.open()
}

// 关闭订单详情
const closeOrderDetail = () => {
  orderDetailPopup.value.close()
}

// 支付订单
const payOrder = async (order: any) => {
  try {
    uni.showLoading({ title: '发起支付...' })
    await vipStore.initiatePayment(order.orderNo)
    uni.hideLoading()
    uni.showToast({ title: '支付成功' })
    // 刷新订单列表
    loadOrders()
  } catch (error) {
    uni.hideLoading()
    uni.showToast({ title: '支付失败', icon: 'error' })
  }
}

// 取消订单
const cancelOrder = (order: any) => {
  uni.showModal({
    title: '确认取消',
    content: '确定要取消这个订单吗？',
    success: (res) => {
      if (res.confirm) {
        // 这里应该调用取消订单API
        order.status = 'cancelled'
        uni.showToast({ title: '订单已取消' })
      }
    }
  })
}

// 跳转到VIP页面
const goToVip = () => {
  uni.navigateTo({ url: '/pages/vip/vip' })
}

// 格式化时间
const formatTime = (timeStr: string) => {
  if (!timeStr) return ''
  const date = new Date(timeStr)
  return `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')} ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`
}

// 获取套餐名称
const getPlanName = (planType: string) => {
  const planNames = {
    monthly: 'VIP月度会员',
    yearly: 'VIP年度会员',
    lifetime: 'VIP终身会员'
  }
  return planNames[planType] || '未知套餐'
}

// 获取套餐描述
const getPlanDesc = (planType: string) => {
  const planDescs = {
    monthly: '享受30天VIP特权服务',
    yearly: '享受365天VIP特权服务',
    lifetime: '永久享受VIP特权服务'
  }
  return planDescs[planType] || ''
}

// 获取状态文本
const getStatusText = (status: string) => {
  const statusTexts = {
    pending: '待支付',
    paid: '已支付',
    cancelled: '已取消',
    refunded: '已退款'
  }
  return statusTexts[status] || '未知状态'
}

// 获取状态样式类
const getStatusClass = (status: string) => {
  return `status-${status}`
}
</script>

<style lang="scss" scoped>
.orders-container {
  min-height: 100vh;
  background: #f8f9fa;
}

.page-header {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 40rpx 30rpx 60rpx;
  color: white;
}

.header-title {
  font-size: 40rpx;
  font-weight: bold;
  margin-bottom: 10rpx;
}

.header-subtitle {
  font-size: 26rpx;
  opacity: 0.8;
}

.filter-section {
  background: white;
  padding: 20rpx 30rpx;
  border-bottom: 1rpx solid #f0f0f0;
}

.filter-tabs {
  display: flex;
  gap: 40rpx;
}

.filter-tab {
  padding: 16rpx 24rpx;
  border-radius: 20rpx;
  font-size: 28rpx;
  color: #666;
  background: #f8f9fa;
  transition: all 0.3s;
  
  &.active {
    background: #667eea;
    color: white;
  }
}

.orders-list {
  padding: 20rpx;
}

.loading-container {
  padding: 40rpx;
  text-align: center;
}

.empty-container {
  text-align: center;
  padding: 100rpx 40rpx;
}

.empty-icon {
  font-size: 120rpx;
  margin-bottom: 30rpx;
}

.empty-text {
  font-size: 32rpx;
  color: #333;
  margin-bottom: 10rpx;
}

.empty-subtitle {
  font-size: 26rpx;
  color: #999;
  margin-bottom: 40rpx;
}

.go-vip-btn {
  background: #667eea;
  color: white;
  border: none;
  border-radius: 25rpx;
  padding: 20rpx 40rpx;
  font-size: 28rpx;
}

.order-item {
  background: white;
  border-radius: 20rpx;
  margin-bottom: 20rpx;
  padding: 30rpx;
  box-shadow: 0 4rpx 16rpx rgba(0, 0, 0, 0.1);
}

.order-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 20rpx;
}

.order-info {
  flex: 1;
}

.order-no {
  font-size: 28rpx;
  color: #333;
  margin-bottom: 8rpx;
}

.order-time {
  font-size: 24rpx;
  color: #999;
}

.order-status {
  padding: 8rpx 16rpx;
  border-radius: 12rpx;
  font-size: 24rpx;
  
  &.status-pending {
    background: #fff3cd;
    color: #856404;
  }
  
  &.status-paid {
    background: #d4edda;
    color: #155724;
  }
  
  &.status-cancelled {
    background: #f8d7da;
    color: #721c24;
  }
}

.order-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20rpx;
}

.product-info {
  display: flex;
  align-items: center;
  flex: 1;
}

.product-icon {
  font-size: 40rpx;
  margin-right: 20rpx;
}

.product-details {
  flex: 1;
}

.product-name {
  font-size: 30rpx;
  color: #333;
  font-weight: bold;
  margin-bottom: 8rpx;
}

.product-desc {
  font-size: 24rpx;
  color: #666;
}

.order-amount {
  font-size: 32rpx;
  color: #e74c3c;
  font-weight: bold;
}

.order-actions {
  display: flex;
  gap: 20rpx;
  justify-content: flex-end;
}

.cancel-btn, .pay-btn {
  padding: 16rpx 32rpx;
  border-radius: 20rpx;
  font-size: 26rpx;
  border: none;
}

.cancel-btn {
  background: #f8f9fa;
  color: #666;
}

.pay-btn {
  background: #667eea;
  color: white;
}

.load-more {
  text-align: center;
  padding: 40rpx;
  color: #666;
  font-size: 28rpx;
}

.order-detail-popup {
  background: white;
  border-radius: 20rpx 20rpx 0 0;
  max-height: 80vh;
  overflow-y: auto;
}

.popup-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 30rpx;
  border-bottom: 1rpx solid #f0f0f0;
}

.popup-title {
  font-size: 32rpx;
  font-weight: bold;
  color: #333;
}

.popup-close {
  font-size: 32rpx;
  color: #999;
  padding: 10rpx;
}

.order-detail-content {
  padding: 30rpx;
}

.detail-section {
  margin-bottom: 40rpx;
  
  &:last-child {
    margin-bottom: 0;
  }
}

.section-title {
  font-size: 30rpx;
  font-weight: bold;
  color: #333;
  margin-bottom: 20rpx;
  padding-bottom: 10rpx;
  border-bottom: 2rpx solid #667eea;
}

.detail-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16rpx 0;
  border-bottom: 1rpx solid #f8f9fa;
  
  &:last-child {
    border-bottom: none;
  }
}

.detail-label {
  font-size: 28rpx;
  color: #666;
}

.detail-value {
  font-size: 28rpx;
  color: #333;
  
  &.amount {
    color: #e74c3c;
    font-weight: bold;
  }
  
  &.status-pending {
    color: #856404;
  }
  
  &.status-paid {
    color: #155724;
  }
  
  &.status-cancelled {
    color: #721c24;
  }
}
</style> 
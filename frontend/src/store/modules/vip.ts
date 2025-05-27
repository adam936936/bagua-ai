import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { vipApi, type VipPlan, type VipOrder, type VipStatus } from '@/api/vip'
import { useUserStore } from './user'

export const useVipStore = defineStore('vip', () => {
  // 状态
  const vipStatus = ref<VipStatus>({ isVip: false })
  const vipPlans = ref<Record<string, VipPlan>>({})
  const userOrders = ref<VipOrder[]>([])
  const loading = ref(false)
  const currentOrder = ref<VipOrder | null>(null)

  // 计算属性
  const isVip = computed(() => vipStatus.value.isVip)
  const vipExpireTime = computed(() => vipStatus.value.expireTime)
  const vipPlanType = computed(() => vipStatus.value.planType)

  // 格式化到期时间
  const formattedExpireTime = computed(() => {
    if (!vipExpireTime.value) return ''
    const date = new Date(vipExpireTime.value)
    return `${date.getFullYear()}年${(date.getMonth() + 1).toString().padStart(2, '0')}月${date.getDate().toString().padStart(2, '0')}日`
  })

  // 获取VIP套餐信息
  async function loadVipPlans() {
    try {
      loading.value = true
      const plans = await vipApi.getPlans()
      vipPlans.value = plans
    } catch (error) {
      console.error('获取VIP套餐失败:', error)
      // 设置默认套餐数据，确保页面能正常显示
      vipPlans.value = {
        monthly: { price: 19.90, name: '月度会员' },
        yearly: { price: 99.90, name: '年度会员' },
        lifetime: { price: 199.90, name: '终身会员' }
      }
    } finally {
      loading.value = false
    }
  }

  // 获取用户VIP状态
  async function loadVipStatus() {
    const userStore = useUserStore()
    try {
      const userId = userStore.getCurrentUserId
      const status = await vipApi.getVipStatus(userId)
      vipStatus.value = status
    } catch (error) {
      console.error('获取VIP状态失败:', error)
    }
  }

  // 获取用户订单列表
  async function loadUserOrders() {
    const userStore = useUserStore()
    try {
      const userId = userStore.getCurrentUserId
      const orders = await vipApi.getUserOrders(userId)
      userOrders.value = orders
    } catch (error) {
      console.error('获取订单列表失败:', error)
    }
  }

  // 创建VIP订单
  async function createVipOrder(planType: string) {
    const userStore = useUserStore()
    try {
      loading.value = true
      const userId = userStore.getCurrentUserId
      const order = await vipApi.createOrder({ userId, planType })
      currentOrder.value = order
      return order
    } catch (error) {
      console.error('创建VIP订单失败:', error)
      throw error
    } finally {
      loading.value = false
    }
  }

  // 发起支付
  async function initiatePayment(orderNo: string) {
    try {
      loading.value = true
      
      // 获取用户openId（这里需要从微信登录获取）
      const openId = 'test_openid' // 实际应用中需要从微信登录获取
      
      const payParams = await vipApi.createPayOrder({ orderNo, openId })
      
      // 调用微信支付
      return new Promise((resolve, reject) => {
        uni.requestPayment({
          provider: 'wxpay',
          timeStamp: payParams.timeStamp,
          nonceStr: payParams.nonceStr,
          package: payParams.package,
          signType: payParams.signType,
          paySign: payParams.paySign,
          success: (res) => {
            console.log('支付成功:', res)
            // 刷新VIP状态
            loadVipStatus()
            resolve(res)
          },
          fail: (err) => {
            console.error('支付失败:', err)
            reject(err)
          }
        })
      })
    } catch (error) {
      console.error('发起支付失败:', error)
      throw error
    } finally {
      loading.value = false
    }
  }

  // 模拟支付（用于测试）
  async function mockPayment(orderNo: string) {
    try {
      loading.value = true
      await vipApi.mockPayment({ orderNo })
      // 刷新VIP状态
      await loadVipStatus()
      return true
    } catch (error) {
      console.error('模拟支付失败:', error)
      throw error
    } finally {
      loading.value = false
    }
  }

  // 购买VIP
  async function purchaseVip(planType: string, useMockPay = true) {
    try {
      // 1. 创建订单
      const order = await createVipOrder(planType)
      
      if (useMockPay) {
        // 2. 模拟支付（测试用）
        await mockPayment(order.orderNo)
        return true
      } else {
        // 2. 发起真实支付
        await initiatePayment(order.orderNo)
        return true
      }
    } catch (error) {
      console.error('购买VIP失败:', error)
      throw error
    }
  }

  // 重置状态
  function resetVipState() {
    vipStatus.value = { isVip: false }
    vipPlans.value = {}
    userOrders.value = []
    currentOrder.value = null
  }

  return {
    // 状态
    vipStatus,
    vipPlans,
    userOrders,
    loading,
    currentOrder,
    
    // 计算属性
    isVip,
    vipExpireTime,
    vipPlanType,
    formattedExpireTime,
    
    // 方法
    loadVipPlans,
    loadVipStatus,
    loadUserOrders,
    createVipOrder,
    initiatePayment,
    mockPayment,
    purchaseVip,
    resetVipState
  }
}) 
import { request } from '@/utils/request'

export interface VipPlan {
  price: number
  name: string
}

export interface VipOrder {
  orderNo: string
  amount: number
  planType: string
}

export interface VipStatus {
  isVip: boolean
  planType?: string
  expireTime?: string
}

export interface PayParams {
  appId: string
  timeStamp: string
  nonceStr: string
  package: string
  signType: string
  paySign: string
}

/**
 * VIP相关API
 */
export const vipApi = {
  /**
   * 获取VIP套餐价格
   */
  async getPlans(): Promise<Record<string, VipPlan>> {
    const response = await request.get('/vip/plans')
    return response.data
  },

  /**
   * 创建VIP订单
   */
  async createOrder(data: { userId: number; planType: string }): Promise<VipOrder> {
    const response = await request.post('/vip/create-order', data)
    return response.data
  },

  /**
   * 创建支付订单
   */
  async createPayOrder(data: { orderNo: string; openId: string }): Promise<PayParams> {
    const response = await request.post('/vip/pay', data)
    return response.data
  },

  /**
   * 获取用户VIP状态
   */
  async getVipStatus(userId: number): Promise<VipStatus> {
    const response = await request.get(`/vip/status/${userId}`)
    return response.data
  },

  /**
   * 获取用户订单列表
   */
  async getUserOrders(userId: number): Promise<VipOrder[]> {
    const response = await request.get(`/vip/orders/${userId}`)
    return response.data
  },

  /**
   * 模拟支付成功（仅用于测试）
   */
  async mockPayment(data: { orderNo: string }): Promise<string> {
    const response = await request.post('/vip/mock-pay', data)
    return response.data
  }
} 
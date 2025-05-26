import { request } from '@/utils/request'

/**
 * 用户登录请求参数
 */
export interface WechatLoginRequest {
  code: string
  nickName?: string
  avatar?: string
}

/**
 * 用户登录响应
 */
export interface UserLoginResponse {
  userId: number
  openId: string
  token: string
  isNewUser: boolean
}

/**
 * 用户信息响应
 */
export interface UserProfileResponse {
  userId: number
  nickName: string
  avatar: string
  isVip: boolean
  vipExpireTime?: string
  totalAnalysisCount: number
}

/**
 * VIP状态响应
 */
export interface VipStatusResponse {
  userId: number
  isVip: boolean
  vipLevel: number
  vipExpireTime?: string
  remainingAnalysisCount: number
  totalAnalysisCount: number
}

/**
 * 用户相关API
 */
export const userApi = {
  /**
   * 微信小程序登录
   */
  async login(params: WechatLoginRequest): Promise<UserLoginResponse> {
    const response = await request.post<UserLoginResponse>('/user/login', params)
    return response.data
  },
  
  /**
   * 获取用户信息
   */
  async getProfile(userId: number): Promise<UserProfileResponse> {
    const response = await request.get<UserProfileResponse>('/user/profile', { userId })
    return response.data
  },
  
  /**
   * 更新用户信息
   */
  async updateProfile(userId: number, nickName?: string, avatar?: string): Promise<void> {
    await request.put('/user/profile', {
      userId,
      nickName,
      avatar
    })
  },
  
  /**
   * 获取VIP状态
   */
  async getVipStatus(userId: number): Promise<VipStatusResponse> {
    const response = await request.get<VipStatusResponse>('/user/vip-status', { userId })
    return response.data
  },
  
  /**
   * VIP升级
   */
  async upgradeVip(userId: number, vipLevel: number): Promise<void> {
    await request.post('/user/upgrade-vip', null, {
      'Content-Type': 'application/x-www-form-urlencoded'
    })
  }
} 
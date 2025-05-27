import { request } from '@/utils/request'
import type { BirthInfo, FortuneResult, NameRecommendation, NameRecommendRequest } from '@/types/fortune'

/**
 * 命理相关API
 */
export const fortuneApi = {
  /**
   * 计算命理信息
   */
  async calculate(birthInfo: BirthInfo): Promise<any> {
    // 获取用户ID，如果没有则生成一个临时ID
    let userId = uni.getStorageSync('userId')
    if (!userId) {
      userId = Date.now() // 使用时间戳作为临时用户ID
      uni.setStorageSync('userId', userId)
    }
    
    const response = await request.post<any>('/fortune/calculate', {
      ...birthInfo,
      userId: Number(userId)
    })
    return response
  },
  
  /**
   * AI推荐姓名
   */
  async recommendNames(params: NameRecommendRequest): Promise<any> {
    // 获取用户ID
    let userId = uni.getStorageSync('userId')
    if (!userId) {
      userId = Date.now()
      uni.setStorageSync('userId', userId)
    }
    
    const response = await request.post<any>('/fortune/recommend-names', {
      ...params,
      userId: Number(userId)
    })
    return response
  },
  
  /**
   * 获取今日运势
   */
  async getTodayFortune(): Promise<any> {
    const response = await request.get<any>('/fortune/today-fortune')
    return response
  },
  
  /**
   * 获取用户历史记录
   */
  async getHistory(userId: number, page: number = 1, size: number = 10): Promise<any> {
    const response = await request.get<any>(`/fortune/history/${userId}`, {
      page,
      size
    })
    return response
  },


} 
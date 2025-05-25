import { request } from '@/utils/request'
import type { BirthInfo, FortuneResult, NameRecommendation, NameRecommendRequest } from '@/types/fortune'

/**
 * 命理相关API
 */
export const fortuneApi = {
  /**
   * 计算命理信息
   */
  async calculate(birthInfo: BirthInfo): Promise<FortuneResult> {
    const response = await request.post<FortuneResult>('/fortune/calculate', {
      ...birthInfo,
      userId: uni.getStorageSync('userId') || 0
    })
    return response.data
  },
  
  /**
   * AI推荐姓名
   */
  async recommendNames(params: NameRecommendRequest): Promise<NameRecommendation[]> {
    const response = await request.post<NameRecommendation[]>('/fortune/recommend-names', params)
    return response.data
  },
  
  /**
   * 获取今日运势
   */
  async getTodayFortune(): Promise<string> {
    const response = await request.get<string>('/fortune/today-fortune')
    return response.data
  },
  
  /**
   * 获取用户历史记录
   */
  async getHistory(userId: number, page: number = 1, size: number = 10): Promise<FortuneResult[]> {
    const response = await request.get<FortuneResult[]>(`/fortune/history/${userId}`, {
      page,
      size
    })
    return response.data
  }
} 
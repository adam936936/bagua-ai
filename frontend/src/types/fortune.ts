/**
 * 出生信息
 */
export interface BirthInfo {
  birthDate: string
  birthTime: string
  userName?: string
  userId?: number
}

/**
 * 命理计算结果
 */
export interface FortuneResult {
  lunar: string
  ganZhi: string
  wuXing: string
  wuXingLack: string
  shengXiao: string
  aiAnalysis: string
  nameAnalysis?: string
  nameRecommendations?: NameRecommendation[]
}

/**
 * 姓名推荐
 */
export interface NameRecommendation {
  name: string
  reason: string
  score?: number
}

/**
 * 姓名推荐请求参数
 */
export interface NameRecommendRequest {
  surname: string
  gender: number
  birthYear: number
  birthMonth: number
  birthDay: number
  birthHour?: number
  userId?: number
}

/**
 * 用户信息
 */
export interface UserInfo {
  id: number
  openid: string
  nickname: string
  avatarUrl: string
  isVip: boolean
  vipExpireTime?: string
}

/**
 * VIP产品类型
 */
export enum VipProductType {
  MONTHLY = 'MONTHLY',
  YEARLY = 'YEARLY',
  SINGLE = 'SINGLE'
}

/**
 * VIP产品信息
 */
export interface VipProduct {
  type: VipProductType
  name: string
  price: number
  originalPrice?: number
  duration: string
  features: string[]
  isPopular?: boolean
} 
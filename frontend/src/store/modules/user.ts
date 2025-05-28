import { defineStore } from 'pinia'
import { userApi, type UserLoginResponse, type UserProfileResponse, type VipStatusResponse } from '@/api/user'

interface UserState {
  // 用户基本信息
  userId: number | null
  openId: string
  token: string
  isLogin: boolean
  
  // 用户资料
  nickName: string
  avatar: string
  
  // VIP状态
  isVip: boolean
  vipLevel: number
  vipExpireTime: string | null
  remainingAnalysisCount: number
  totalAnalysisCount: number
  
  // 加载状态
  loading: boolean
}

export const useUserStore = defineStore('user', {
  state: (): UserState => ({
    userId: null,
    openId: '',
    token: '',
    isLogin: false,
    
    nickName: '',
    avatar: '',
    
    isVip: false,
    vipLevel: 0,
    vipExpireTime: null,
    remainingAnalysisCount: 3,
    totalAnalysisCount: 0,
    
    loading: false
  }),
  
  getters: {
    /**
     * 获取当前用户ID
     */
    getCurrentUserId(): number {
      if (this.userId) {
        return this.userId
      }
      
      // 从本地存储获取
      const storedUserId = uni.getStorageSync('userId')
      if (storedUserId) {
        this.userId = Number(storedUserId)
        return this.userId
      }
      
      // 生成临时用户ID
      const tempUserId = Date.now()
      this.userId = tempUserId
      uni.setStorageSync('userId', tempUserId)
      return tempUserId
    },
    
    /**
     * 获取用户信息对象
     */
    userInfo(): { id: number | null; nickname: string; avatar: string } {
      return {
        id: this.userId,
        nickname: this.nickName,
        avatar: this.avatar
      }
    },
    
    /**
     * 是否可以进行分析（检查次数限制）
     */
    canAnalyze(): boolean {
      // 开发阶段总是允许分析
      return true
      // return this.isVip || this.remainingAnalysisCount > 0
    }
  },
  
  actions: {
    /**
     * 微信登录
     */
    async login(code: string, nickName?: string, avatar?: string) {
      try {
        this.loading = true
        
        const response = await userApi.login({
          code,
          nickName,
          avatar
        })
        
        // 保存登录信息
        this.userId = response.userId
        this.openId = response.openId
        this.token = response.token
        this.isLogin = true
        
        // 保存到本地存储
        uni.setStorageSync('userId', response.userId)
        uni.setStorageSync('token', response.token)
        uni.setStorageSync('openId', response.openId)
        
        // 如果是新用户，更新用户信息
        if (response.isNewUser && (nickName || avatar)) {
          await this.updateProfile(nickName, avatar)
        }
        
        // 获取用户详细信息
        await this.fetchProfile()
        await this.fetchVipStatus()
        
        return response
        
      } catch (error) {
        console.error('登录失败:', error)
        throw error
      } finally {
        this.loading = false
      }
    },
    
    /**
     * 获取用户信息
     */
    async fetchProfile() {
      try {
        const userId = this.getCurrentUserId
        const profile = await userApi.getProfile(userId)
        
        this.nickName = profile.nickName
        this.avatar = profile.avatar
        this.isVip = profile.isVip
        this.vipExpireTime = profile.vipExpireTime || null
        this.totalAnalysisCount = profile.totalAnalysisCount
        
      } catch (error) {
        console.error('获取用户信息失败:', error)
      }
    },
    
    /**
     * 更新用户信息
     */
    async updateProfile(nickName?: string, avatar?: string) {
      try {
        const userId = this.getCurrentUserId
        await userApi.updateProfile(userId, nickName, avatar)
        
        // 更新本地状态
        if (nickName) this.nickName = nickName
        if (avatar) this.avatar = avatar
        
      } catch (error) {
        console.error('更新用户信息失败:', error)
        throw error
      }
    },
    
    /**
     * 获取VIP状态
     */
    async fetchVipStatus() {
      try {
        const userId = this.getCurrentUserId
        const vipStatus = await userApi.getVipStatus(userId)
        
        this.isVip = vipStatus.isVip
        this.vipLevel = vipStatus.vipLevel
        this.vipExpireTime = vipStatus.vipExpireTime || null
        this.remainingAnalysisCount = vipStatus.remainingAnalysisCount
        this.totalAnalysisCount = vipStatus.totalAnalysisCount
        
      } catch (error) {
        console.error('获取VIP状态失败:', error)
      }
    },
    
    /**
     * VIP升级
     */
    async upgradeVip(vipLevel: number) {
      try {
        const userId = this.getCurrentUserId
        await userApi.upgradeVip(userId, vipLevel)
        
        // 刷新VIP状态
        await this.fetchVipStatus()
        
      } catch (error) {
        console.error('VIP升级失败:', error)
        throw error
      }
    },
    
    /**
     * 消耗分析次数
     */
    consumeAnalysisCount() {
      if (!this.isVip && this.remainingAnalysisCount > 0) {
        this.remainingAnalysisCount--
      }
      this.totalAnalysisCount++
    },
    
    /**
     * 退出登录
     */
    logout() {
      // 清空状态
      this.userId = null
      this.openId = ''
      this.token = ''
      this.isLogin = false
      this.nickName = ''
      this.avatar = ''
      this.isVip = false
      this.vipLevel = 0
      this.vipExpireTime = null
      this.remainingAnalysisCount = 3
      this.totalAnalysisCount = 0
      
      // 清空本地存储
      uni.removeStorageSync('userId')
      uni.removeStorageSync('token')
      uni.removeStorageSync('openId')
    },
    
    /**
     * 初始化用户状态（从本地存储恢复）
     */
    async initUserState() {
      try {
        const token = uni.getStorageSync('token')
        const userId = uni.getStorageSync('userId')
        const openId = uni.getStorageSync('openId')
        
        if (token && userId) {
          this.token = token
          this.userId = Number(userId)
          this.openId = openId || ''
          this.isLogin = true
          
          // 获取最新的用户信息
          await this.fetchProfile()
          await this.fetchVipStatus()
        }
      } catch (error) {
        console.error('初始化用户状态失败:', error)
        // 如果初始化失败，清空本地存储
        this.logout()
      }
    },

    /**
     * 加载用户信息（用于个人中心）
     */
    async loadUserInfo() {
      await this.fetchProfile()
    },

    /**
     * 更新头像
     */
    async updateAvatar(avatar: string) {
      await this.updateProfile(undefined, avatar)
    },

    /**
     * 更新昵称
     */
    async updateNickname(nickname: string) {
      await this.updateProfile(nickname, undefined)
    }
  }
}) 
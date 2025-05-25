interface RequestConfig {
  url: string
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE'
  data?: any
  params?: any
  header?: any
}

interface ApiResponse<T = any> {
  code: number
  message: string
  data: T
  timestamp?: number
}

class Request {
  private baseURL = 'https://api.yourdomain.com/api'
  
  private getToken(): string {
    return uni.getStorageSync('token') || ''
  }
  
  private getHeader(customHeader?: any): any {
    return {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${this.getToken()}`,
      ...customHeader
    }
  }
  
  async request<T>(config: RequestConfig): Promise<ApiResponse<T>> {
    const { url, method = 'GET', data, params, header } = config
    
    return new Promise((resolve, reject) => {
      // 显示加载提示
      uni.showLoading({
        title: '加载中...',
        mask: true
      })
      
      uni.request({
        url: this.baseURL + url,
        method,
        data: method === 'GET' ? params : data,
        header: this.getHeader(header),
        success: (res: any) => {
          uni.hideLoading()
          
          if (res.statusCode === 200) {
            const response = res.data as ApiResponse<T>
            if (response.code === 200) {
              resolve(response)
            } else {
              uni.showToast({
                title: response.message || '请求失败',
                icon: 'none'
              })
              reject(new Error(response.message || '请求失败'))
            }
          } else {
            uni.showToast({
              title: `请求失败: ${res.statusCode}`,
              icon: 'none'
            })
            reject(new Error(`请求失败: ${res.statusCode}`))
          }
        },
        fail: (error) => {
          uni.hideLoading()
          uni.showToast({
            title: '网络错误',
            icon: 'none'
          })
          reject(error)
        }
      })
    })
  }
  
  async get<T>(url: string, params?: any, header?: any): Promise<ApiResponse<T>> {
    return this.request<T>({ url, method: 'GET', params, header })
  }
  
  async post<T>(url: string, data?: any, header?: any): Promise<ApiResponse<T>> {
    return this.request<T>({ url, method: 'POST', data, header })
  }
  
  async put<T>(url: string, data?: any, header?: any): Promise<ApiResponse<T>> {
    return this.request<T>({ url, method: 'PUT', data, header })
  }
  
  async delete<T>(url: string, params?: any, header?: any): Promise<ApiResponse<T>> {
    return this.request<T>({ url, method: 'DELETE', params, header })
  }
}

export const request = new Request()
export type { RequestConfig, ApiResponse } 
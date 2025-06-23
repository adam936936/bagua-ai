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
  // 生产环境 - 外网部署地址
  private baseURL = 'http://122.51.104.128:8888/api'
  
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
      
      console.log(`请求开始: ${method} ${this.baseURL + url}`, method === 'GET' ? params : data)
      
      uni.request({
        url: this.baseURL + url,
        method,
        data: method === 'GET' ? params : data,
        header: this.getHeader(header),
        success: (res: any) => {
          uni.hideLoading()
          
          console.log(`请求成功: ${method} ${url}`, res)
          
          if (res.statusCode === 200) {
            const response = res.data as ApiResponse<T>
            if (response.code === 200) {
              console.log(`业务逻辑处理成功: ${method} ${url}`, response)
              resolve(response)
            } else {
              console.error(`业务逻辑处理失败: ${method} ${url}`, response.message)
              uni.showToast({
                title: response.message || '请求失败',
                icon: 'none'
              })
              reject(new Error(response.message || '请求失败'))
            }
          } else {
            console.error(`HTTP请求失败: ${method} ${url}`, res.statusCode)
            uni.showToast({
              title: `请求失败: ${res.statusCode}`,
              icon: 'none'
            })
            reject(new Error(`请求失败: ${res.statusCode}`))
          }
        },
        fail: (error) => {
          uni.hideLoading()
          console.error(`请求错误: ${method} ${url}`, error)
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
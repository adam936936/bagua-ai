import { createSSRApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'

// 添加持久化插件
function setupPiniaPlugins() {
  // 简单的本地存储插件
  const piniaLocalStoragePlugin = ({ store }) => {
    // 从存储中恢复状态
    const storeId = store.$id
    const savedState = uni.getStorageSync(`pinia-${storeId}`)
    
    if (savedState) {
      try {
        store.$patch(JSON.parse(savedState))
      } catch (e) {
        console.error('恢复Pinia状态失败:', e)
        // 如果恢复失败，则清除存储的状态
        uni.removeStorageSync(`pinia-${storeId}`)
      }
    }
    
    // 监听状态变化，保存到存储
    store.$subscribe((mutation, state) => {
      // 使用 JSON.stringify 转换状态为字符串
      uni.setStorageSync(`pinia-${storeId}`, JSON.stringify(state))
    })
  }
  
  return piniaLocalStoragePlugin
}

export function createApp() {
  const app = createSSRApp(App)
  const pinia = createPinia()
  
  // 使用插件
  pinia.use(setupPiniaPlugins())
  
  app.use(pinia)
  
  return {
    app,
    pinia
  }
} 
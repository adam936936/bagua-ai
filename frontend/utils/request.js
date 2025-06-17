/**
 * 请求工具类 - uni-app版本
 */
const baseURL = 'http://localhost:8081/api'; // 修改为8081端口

const request = {
  /**
   * GET请求
   */
  async get(url, params = {}) {
    return this.request('GET', url, params);
  },

  /**
   * POST请求
   */
  async post(url, data = {}) {
    return this.request('POST', url, data);
  },

  /**
   * PUT请求
   */
  async put(url, data = {}) {
    return this.request('PUT', url, data);
  },

  /**
   * DELETE请求
   */
  async delete(url, params = {}) {
    return this.request('DELETE', url, params);
  },

  /**
   * 通用请求方法
   */
  request(method, url, data = {}) {
    return new Promise((resolve, reject) => {
      // 显示加载提示
      uni.showLoading({
        title: '加载中...',
        mask: true
      });

      console.log(`开始请求: ${method} ${baseURL + url}`, data);

      uni.request({
        url: baseURL + url,
        method,
        data,
        header: {
          'Content-Type': 'application/json'
        },
        success: (res) => {
          uni.hideLoading();
          
          console.log(`请求成功: ${method} ${url}`, res);
          
          if (res.statusCode === 200) {
            resolve(res.data);
          } else {
            console.error(`请求失败: ${method} ${url}, 状态码: ${res.statusCode}`);
            uni.showToast({
              title: `请求失败: ${res.statusCode}`,
              icon: 'none'
            });
            reject(new Error(`请求失败: ${res.statusCode}`));
          }
        },
        fail: (err) => {
          uni.hideLoading();
          console.error(`请求错误: ${method} ${url}`, err);
          uni.showToast({
            title: '网络错误',
            icon: 'none'
          });
          reject(err);
        }
      });
    });
  }
};

module.exports = {
  request
}; 
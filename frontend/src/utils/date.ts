/**
 * 日期格式化
 * @param date 日期对象
 * @param format 格式字符串，如 'YYYY-MM-DD'、'MM月DD日'
 */
export function formatDate(date: Date, format: string): string {
  const year = date.getFullYear()
  const month = date.getMonth() + 1
  const day = date.getDate()
  const hour = date.getHours()
  const minute = date.getMinutes()
  const second = date.getSeconds()
  
  const formatMap: Record<string, string> = {
    'YYYY': year.toString(),
    'MM': month.toString().padStart(2, '0'),
    'DD': day.toString().padStart(2, '0'),
    'HH': hour.toString().padStart(2, '0'),
    'mm': minute.toString().padStart(2, '0'),
    'ss': second.toString().padStart(2, '0')
  }
  
  let result = format
  Object.keys(formatMap).forEach(key => {
    result = result.replace(new RegExp(key, 'g'), formatMap[key])
  })
  
  return result
}

/**
 * 获取时辰列表
 */
export function getTimeOptions(): Array<{ label: string; value: string }> {
  return [
    { label: '子时 (23:00-01:00)', value: '子时' },
    { label: '丑时 (01:00-03:00)', value: '丑时' },
    { label: '寅时 (03:00-05:00)', value: '寅时' },
    { label: '卯时 (05:00-07:00)', value: '卯时' },
    { label: '辰时 (07:00-09:00)', value: '辰时' },
    { label: '巳时 (09:00-11:00)', value: '巳时' },
    { label: '午时 (11:00-13:00)', value: '午时' },
    { label: '未时 (13:00-15:00)', value: '未时' },
    { label: '申时 (15:00-17:00)', value: '申时' },
    { label: '酉时 (17:00-19:00)', value: '酉时' },
    { label: '戌时 (19:00-21:00)', value: '戌时' },
    { label: '亥时 (21:00-23:00)', value: '亥时' }
  ]
}

/**
 * 根据当前时间获取对应时辰
 */
export function getCurrentTimeSlot(): string {
  const hour = new Date().getHours()
  
  if (hour >= 23 || hour < 1) return '子时'
  if (hour >= 1 && hour < 3) return '丑时'
  if (hour >= 3 && hour < 5) return '寅时'
  if (hour >= 5 && hour < 7) return '卯时'
  if (hour >= 7 && hour < 9) return '辰时'
  if (hour >= 9 && hour < 11) return '巳时'
  if (hour >= 11 && hour < 13) return '午时'
  if (hour >= 13 && hour < 15) return '未时'
  if (hour >= 15 && hour < 17) return '申时'
  if (hour >= 17 && hour < 19) return '酉时'
  if (hour >= 19 && hour < 21) return '戌时'
  if (hour >= 21 && hour < 23) return '亥时'
  
  return '子时'
}

/**
 * 验证日期是否有效
 */
export function isValidDate(dateString: string): boolean {
  const date = new Date(dateString)
  const now = new Date()
  const minDate = new Date('1900-01-01')
  
  return date instanceof Date && 
         !isNaN(date.getTime()) && 
         date >= minDate && 
         date <= now
} 
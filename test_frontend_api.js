// 测试前端API调用
const API_BASE = 'http://localhost:8080/api';

// 时间转换函数
function convertTimeToChinese(time) {
    const hour = parseInt(time.split(':')[0]);
    const timeMap = {
        23: '子时', 0: '子时', 1: '丑时', 2: '丑时',
        3: '寅时', 4: '寅时', 5: '卯时', 6: '卯时',
        7: '辰时', 8: '辰时', 9: '巳时', 10: '巳时',
        11: '午时', 12: '午时', 13: '未时', 14: '未时',
        15: '申时', 16: '申时', 17: '酉时', 18: '酉时',
        19: '戌时', 20: '戌时', 21: '亥时', 22: '亥时'
    };
    return timeMap[hour] || '午时';
}

// 测试命理计算
async function testCalculateFortune() {
    const birthTime = '12:00';
    const chineseBirthTime = convertTimeToChinese(birthTime);
    
    const requestData = {
        userId: 1,
        name: '张三',
        birthDate: '1990-01-01',
        birthTime: chineseBirthTime,
        gender: 'MALE'
    };
    
    console.log('发送请求数据:', JSON.stringify(requestData, null, 2));
    
    try {
        const response = await fetch(`${API_BASE}/fortune/calculate`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(requestData)
        });
        
        const data = await response.json();
        
        if (data.code === 200) {
            const result = data.data;
            const formatted = `
姓名: ${requestData.name}
生日: ${requestData.birthDate}
农历: ${result.lunar}
天干地支: ${result.ganZhi}
五行属性: ${result.wuXing}
五行缺失: ${result.wuXingLack || '无'}
生肖: ${result.shengXiao}

AI分析:
${result.aiAnalysis}
            `;
            console.log('✅ 计算成功:');
            console.log(formatted);
        } else {
            console.log('❌ 错误:', data.message);
        }
    } catch (error) {
        console.log('❌ 请求失败:', error.message);
    }
}

// 如果是Node.js环境，需要导入fetch
if (typeof fetch === 'undefined') {
    console.log('请在浏览器控制台中运行此脚本，或安装node-fetch包');
} else {
    testCalculateFortune();
} 
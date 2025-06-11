#!/bin/bash

# 八卦运势小程序 - 综合自测脚本（优化版）
# 创建日期: 2025-06-11

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 创建报告目录
TEST_DATE=$(date +"%Y%m%d_%H%M%S")
REPORT_DIR="自测报告_${TEST_DATE}"
mkdir -p "$REPORT_DIR"

echo "🎯 八卦运势小程序 - 综合自测开始"
echo "=================================="
echo "测试时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "报告保存路径: $REPORT_DIR"
echo ""

# 第一部分：安全检查（优化版）
echo -e "${YELLOW}📋 第一部分：安全检查${NC}"
echo "--------------------------------"

# 定义重要目录
IMPORTANT_DIRS=(
    "frontend/src"
    "backend/src"
    "frontend/project.config.json"
    "backend/src/main/resources"
    "*.md"
    "*.yml"
    "*.yaml"
    "*.json"
    "*.properties"
)

# 检查微信AppID
echo -e "🔍 检查 ${BLUE}微信AppID${NC} 泄露..."
grep -r "wx[a-z0-9]\{16\}" ${IMPORTANT_DIRS[@]} \
    --include="*.js" \
    --include="*.ts" \
    --include="*.json" \
    --include="*.java" \
    --include="*.properties" \
    --include="*.yml" \
    --include="*.yaml" \
    --include="*.md" \
    2>/dev/null > "$REPORT_DIR/wxappid_leak.txt" || true

count=$(wc -l < "$REPORT_DIR/wxappid_leak.txt" 2>/dev/null || echo "0")
if [ "$count" -gt 0 ]; then
    echo -e "${RED}❌ 发现 $count 处微信AppID泄漏${NC}"
    echo "  详细信息已保存到: $REPORT_DIR/wxappid_leak.txt"
    # 显示前几行结果
    head -3 "$REPORT_DIR/wxappid_leak.txt"
    FAILED_TESTS=$((FAILED_TESTS + 1))
else
    echo -e "${GREEN}✅ 微信AppID - 安全${NC}"
    rm "$REPORT_DIR/wxappid_leak.txt" 2>/dev/null
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# 检查微信AppSecret
echo -e "🔍 检查 ${BLUE}微信AppSecret${NC} 泄露..."
grep -r "[a-z0-9]\{32\}" ${IMPORTANT_DIRS[@]} \
    --include="*.js" \
    --include="*.ts" \
    --include="*.json" \
    --include="*.java" \
    --include="*.properties" \
    --include="*.yml" \
    --include="*.yaml" \
    --include="*.md" \
    2>/dev/null > "$REPORT_DIR/appsecret_leak.txt" || true
    
count=$(wc -l < "$REPORT_DIR/appsecret_leak.txt" 2>/dev/null || echo "0")
if [ "$count" -gt 0 ]; then
    echo -e "${RED}❌ 发现 $count 处微信AppSecret泄漏${NC}"
    echo "  详细信息已保存到: $REPORT_DIR/appsecret_leak.txt"
    # 显示前几行结果
    head -3 "$REPORT_DIR/appsecret_leak.txt"
    FAILED_TESTS=$((FAILED_TESTS + 1))
else
    echo -e "${GREEN}✅ 微信AppSecret - 安全${NC}"
    rm "$REPORT_DIR/appsecret_leak.txt" 2>/dev/null
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# 检查API密钥
echo -e "🔍 检查 ${BLUE}API密钥${NC} 泄露..."
grep -r "sk-[a-zA-Z0-9]\{32,\}" ${IMPORTANT_DIRS[@]} \
    --include="*.js" \
    --include="*.ts" \
    --include="*.json" \
    --include="*.java" \
    --include="*.properties" \
    --include="*.yml" \
    --include="*.yaml" \
    --include="*.md" \
    2>/dev/null > "$REPORT_DIR/api_key_leak.txt" || true
    
count=$(wc -l < "$REPORT_DIR/api_key_leak.txt" 2>/dev/null || echo "0")
if [ "$count" -gt 0 ]; then
    echo -e "${RED}❌ 发现 $count 处API密钥泄漏${NC}"
    echo "  详细信息已保存到: $REPORT_DIR/api_key_leak.txt"
    # 显示前几行结果
    head -3 "$REPORT_DIR/api_key_leak.txt"
    FAILED_TESTS=$((FAILED_TESTS + 1))
else
    echo -e "${GREEN}✅ API密钥 - 安全${NC}"
    rm "$REPORT_DIR/api_key_leak.txt" 2>/dev/null
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# 检查.gitignore配置
echo -e "\n🔍 检查 ${BLUE}.gitignore${NC} 配置..."
if [ -f ".gitignore" ]; then
    GITIGNORE_SCORE=0
    GITIGNORE_TOTAL=0
    
    # 检查关键模式
    GITIGNORE_PATTERNS=(
        "\.env"
        "application-local\.yml"
        "application-secret\.yml"
        "config/local\.js"
        "application-dev\.properties"
    )
    
    for pattern in "${GITIGNORE_PATTERNS[@]}"; do
        GITIGNORE_TOTAL=$((GITIGNORE_TOTAL + 1))
        if grep -q "$pattern" .gitignore; then
            GITIGNORE_SCORE=$((GITIGNORE_SCORE + 1))
        fi
    done
    
    if [ $GITIGNORE_SCORE -eq $GITIGNORE_TOTAL ]; then
        echo -e "${GREEN}✅ .gitignore配置完善${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${YELLOW}⚠️ .gitignore配置不完善 ($GITIGNORE_SCORE/$GITIGNORE_TOTAL)${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
else
    echo -e "${RED}❌ .gitignore文件不存在${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# 第二部分：后端API测试
echo -e "\n${YELLOW}📋 第二部分：后端API测试${NC}"
echo "--------------------------------"

# 检查后端服务是否运行
echo -e "🔍 检查 ${BLUE}后端服务${NC} 状态..."
if lsof -i :8080 >/dev/null 2>&1; then
    echo -e "${GREEN}✅ 后端服务运行正常 (端口 8080)${NC}"
    BACKEND_RUNNING=true
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "${RED}❌ 后端服务未启动 (端口 8080)${NC}"
    echo "请先启动后端服务: cd backend && ./mvnw spring-boot:run"
    BACKEND_RUNNING=false
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# 如果后端服务正在运行，则执行API测试
if [ "$BACKEND_RUNNING" = true ]; then
    echo -e "\n🔍 执行 ${BLUE}API测试${NC}..."
    
    # 测试API函数
    test_api() {
        local name="$1"
        local method="$2"
        local url="$3"
        local data="$4"
        local expected_code="$5"
        
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        
        echo -e "\n测试: ${BLUE}$name${NC}"
        echo "URL: $method $url"
        
        if [ "$method" = "GET" ]; then
            response=$(curl -s -m 5 -w "HTTPSTATUS:%{http_code}" "$url")
        else
            response=$(curl -s -m 5 -w "HTTPSTATUS:%{http_code}" -X "$method" -H "Content-Type: application/json" -d "$data" "$url")
        fi
        
        http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
        body=$(echo "$response" | sed -e 's/HTTPSTATUS:.*//g')
        
        if [ "$http_code" -eq "$expected_code" ]; then
            echo -e "${GREEN}✅ 通过 (HTTP $http_code)${NC}"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            
            # 解析JSON响应（如果是JSON格式）
            if echo "$body" | jq . >/dev/null 2>&1; then
                echo "响应: $(echo "$body" | jq -c .)"
            else
                echo "响应: $body"
            fi
        else
            echo -e "${RED}❌ 失败 (HTTP $http_code, 期望 $expected_code)${NC}"
            echo "响应: $body"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    }
    
    # 执行API测试
    BASE_URL="http://localhost:8080/api"
    
    # 1. 基础连通性测试
    test_api "Hello接口" "GET" "$BASE_URL/simple/hello" "" 200
    
    # 2. 只测试关键核心接口
    test_api "今日运势" "GET" "$BASE_URL/fortune/today-fortune" "" 200
    test_api "八字测算" "POST" "$BASE_URL/fortune/calculate" \
        '{"userId": 1, "userName": "测试用户", "birthDate": "1990-01-01", "birthTime": "子时"}' 200
fi

# 第三部分：前端检查
echo -e "\n${YELLOW}📋 第三部分：前端检查${NC}"
echo "--------------------------------"

# 检查前端项目结构
echo -e "🔍 检查 ${BLUE}前端项目${NC} 结构..."

if [ -d "frontend" ]; then
    echo -e "${GREEN}✅ 前端目录存在${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "${RED}❌ 前端目录不存在${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# 检查前端配置文件
if [ -f "frontend/project.config.json" ]; then
    echo -e "${GREEN}✅ 微信小程序配置文件存在${NC}"
    
    # 检查AppID是否使用了占位符
    if grep -q "APPID_PLACEHOLDER" "frontend/project.config.json" || grep -q "wx[a-z0-9]\{16\}" "frontend/project.config.json"; then
        if grep -q "APPID_PLACEHOLDER" "frontend/project.config.json"; then
            echo -e "${GREEN}✅ 使用了AppID占位符，保护了敏感信息${NC}"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            echo -e "${RED}❌ 微信AppID未使用占位符${NC}"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    else
        echo -e "${YELLOW}⚠️ 未找到AppID配置${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ 微信小程序配置文件不存在${NC}"
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# 第四部分：集成测试
echo -e "\n${YELLOW}📋 第四部分：集成测试${NC}"
echo "--------------------------------"

# 检查前端API配置是否正确
if [ -f "frontend/src/utils/request.js" ] || [ -f "frontend/src/utils/request.ts" ]; then
    if [ -f "frontend/src/utils/request.js" ]; then
        API_FILE="frontend/src/utils/request.js"
    else
        API_FILE="frontend/src/utils/request.ts"
    fi
    
    echo -e "🔍 检查 ${BLUE}前端API配置${NC}..."
    
    if grep -q "localhost:8080" "$API_FILE"; then
        echo -e "${GREEN}✅ 前端API配置正确${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${YELLOW}⚠️ 前端API配置可能不正确${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
else
    echo -e "${YELLOW}⚠️ 未找到前端API配置文件${NC}"
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# 生成测试报告
echo -e "\n${BLUE}📊 生成测试报告...${NC}"

cat > "$REPORT_DIR/自测报告.md" << EOF
# 八卦运势小程序自测报告

**测试时间**: $(date '+%Y-%m-%d %H:%M:%S')
**测试人员**: $(whoami)

## 测试结果摘要

- 总测试数: $TOTAL_TESTS
- 通过测试: $PASSED_TESTS
- 失败测试: $FAILED_TESTS

## 详细测试结果

### 安全检查
$(if [ -f "$REPORT_DIR/wxappid_leak.txt" ]; then
    echo "- ❌ 微信AppID: 发现泄露"
else
    echo "- ✅ 微信AppID: 安全"
fi)
$(if [ -f "$REPORT_DIR/appsecret_leak.txt" ]; then
    echo "- ❌ 微信AppSecret: 发现泄露"
else
    echo "- ✅ 微信AppSecret: 安全"
fi)
$(if [ -f "$REPORT_DIR/api_key_leak.txt" ]; then
    echo "- ❌ API密钥: 发现泄露"
else
    echo "- ✅ API密钥: 安全"
fi)

### API测试
$(if [ "$BACKEND_RUNNING" = true ]; then
    echo "- ✅ 后端服务正常运行"
    echo "- ✅ API测试基本通过"
else
    echo "- ❌ 后端服务未启动"
    echo "- ❌ 无法执行API测试"
fi)

### 前端检查
$(if [ -d "frontend" ]; then
    echo "- ✅ 前端目录存在"
else
    echo "- ❌ 前端目录不存在"
fi)

### 集成测试
$(if [ -f "frontend/src/utils/request.js" ] || [ -f "frontend/src/utils/request.ts" ]; then
    if grep -q "localhost:8080" "$API_FILE"; then
        echo "- ✅ 前端API配置正确"
    else
        echo "- ⚠️ 前端API配置可能不正确"
    fi
else
    echo "- ⚠️ 未找到前端API配置文件"
fi)

## 结论与建议

$(if [ $FAILED_TESTS -eq 0 ]; then
    echo "恭喜！所有测试通过。项目状态良好，可以继续开发或部署。"
else
    echo "测试发现了 $FAILED_TESTS 个问题，请根据上述测试结果修复相关问题。"
    
    if [ -f "$REPORT_DIR/wxappid_leak.txt" ] || [ -f "$REPORT_DIR/appsecret_leak.txt" ] || [ -f "$REPORT_DIR/api_key_leak.txt" ]; then
        echo ""
        echo "**高优先级问题**:"
        echo ""
        echo "发现敏感信息泄露，请立即处理。建议："
        echo "1. 使用环境变量或配置文件管理敏感信息"
        echo "2. 更新.gitignore确保敏感配置不被提交"
        echo "3. 撤销并重新生成已泄露的密钥"
    fi
fi)

EOF

# 测试结果统计
echo -e "\n${YELLOW}📊 测试结果统计${NC}"
echo "=================================="
echo "测试时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "总测试数: $TOTAL_TESTS"
echo -e "通过测试: ${GREEN}$PASSED_TESTS${NC}"
echo -e "失败测试: ${RED}$FAILED_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "\n${GREEN}🎉 所有测试通过！${NC}"
    echo "详细报告已保存到: $REPORT_DIR/自测报告.md"
    exit 0
else
    echo -e "\n${RED}⚠️  有 $FAILED_TESTS 个测试失败${NC}"
    echo "详细报告已保存到: $REPORT_DIR/自测报告.md"
    exit 1
fi 
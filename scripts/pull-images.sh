#!/bin/bash

# AI八卦运势小程序 - Docker镜像拉取脚本
# 功能：智能尝试多个镜像源，确保镜像拉取成功

set -e

echo "🐳 开始拉取Docker镜像..."

# 定义镜像列表
IMAGES=(
    "mysql:8.0"
    "redis:6.2-alpine"
    "nginx:alpine"
    "openjdk:17-jre-slim"
)

# 定义镜像源列表（按优先级排序）
REGISTRIES=(
    ""  # Docker Hub 官方
    "dockerhub.azk8s.cn/library/"
    "reg-mirror.qiniu.com/library/"
    "registry.docker-cn.com/library/"
    "docker.mirrors.ustc.edu.cn/library/"
    "hub-mirror.c.163.com/library/"
)

# 函数：尝试拉取镜像
pull_image() {
    local image=$1
    local registry=$2
    local full_image="${registry}${image}"
    
    echo "尝试从 ${registry:-Docker Hub} 拉取 ${image}..."
    
    if docker pull "${full_image}"; then
        # 如果不是官方源，需要重新标记镜像
        if [ -n "$registry" ]; then
            echo "重新标记镜像: ${full_image} -> ${image}"
            docker tag "${full_image}" "${image}"
            docker rmi "${full_image}" 2>/dev/null || true
        fi
        echo "✅ 成功拉取: ${image}"
        return 0
    else
        echo "❌ 失败: ${full_image}"
        return 1
    fi
}

# 函数：拉取单个镜像（尝试所有源）
pull_image_with_fallback() {
    local image=$1
    
    echo "📦 开始拉取镜像: ${image}"
    
    # 检查镜像是否已存在
    if docker image inspect "${image}" >/dev/null 2>&1; then
        echo "✅ 镜像已存在: ${image}"
        return 0
    fi
    
    # 尝试各个镜像源
    for registry in "${REGISTRIES[@]}"; do
        if pull_image "${image}" "${registry}"; then
            return 0
        fi
        sleep 2  # 等待2秒后尝试下一个源
    done
    
    echo "❌ 所有镜像源都无法拉取: ${image}"
    return 1
}

# 主要拉取逻辑
main() {
    local failed_images=()
    
    echo "🔍 检查Docker服务状态..."
    if ! docker info >/dev/null 2>&1; then
        echo "❌ Docker服务未运行，请启动Docker"
        exit 1
    fi
    
    echo "🏃‍♂️ 开始拉取所有镜像..."
    
    for image in "${IMAGES[@]}"; do
        if ! pull_image_with_fallback "${image}"; then
            failed_images+=("${image}")
        fi
        echo ""
    done
    
    # 结果报告
    echo "📊 拉取结果报告:"
    echo "总镜像数: ${#IMAGES[@]}"
    echo "成功数量: $((${#IMAGES[@]} - ${#failed_images[@]}))"
    echo "失败数量: ${#failed_images[@]}"
    
    if [ ${#failed_images[@]} -gt 0 ]; then
        echo ""
        echo "❌ 失败的镜像:"
        for image in "${failed_images[@]}"; do
            echo "  - ${image}"
        done
        echo ""
        echo "💡 建议："
        echo "1. 检查网络连接"
        echo "2. 确认Docker镜像加速配置"
        echo "3. 尝试使用离线镜像方案"
        return 1
    else
        echo ""
        echo "🎉 所有镜像拉取成功！"
        echo "📋 拉取的镜像列表:"
        docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -E "(mysql|redis|nginx|openjdk)" || true
        return 0
    fi
}

# 执行主函数
main "$@" 
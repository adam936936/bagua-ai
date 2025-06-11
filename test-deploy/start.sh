#!/bin/bash
echo "🚀 启动AI八卦运势小程序..."
docker-compose --env-file .env.production up -d
echo "✅ 启动完成！访问地址: http://localhost"

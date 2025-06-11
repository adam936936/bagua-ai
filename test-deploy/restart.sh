#!/bin/bash
echo "🔄 重启AI八卦运势小程序..."
docker-compose down
docker-compose --env-file .env.production up -d
echo "✅ 重启完成！"

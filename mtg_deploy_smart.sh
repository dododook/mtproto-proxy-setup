#!/bin/bash

PORT=$1
if [ -z "$PORT" ]; then
  PORT=443
fi

echo "📦 开始部署 MTG Proxy（Rust 实现）on port $PORT..."

# 确保是 root 用户
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ 请使用 root 用户运行此脚本。"
  exit 1
fi

# 安装 Docker
if ! command -v docker &> /dev/null; then
  echo "📥 安装 Docker..."
  apt update && apt install -y docker.io
  systemctl enable docker
  systemctl start docker
else
  echo "✅ Docker 已安装。"
fi

# 安装 Docker Compose
if ! command -v docker-compose &> /dev/null; then
  echo "📥 安装 Docker Compose..."
  curl -SL https://github.com/docker/compose/releases/download/v2.24.7/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
else
  echo "✅ Docker Compose 已安装。"
fi

# 准备目录
mkdir -p /root/mtg_proxy
cd /root/mtg_proxy

# 生成 Secret
SECRET=$(docker run --rm nineseconds/mtg generate-secret tls | tr -d '
')

# 写入 docker-compose.yml
cat > docker-compose.yml <<EOF
version: '3'

services:
  mtg:
    image: nineseconds/mtg:2.1
    container_name: mtg
    ports:
      - "${PORT}:${PORT}"
    command: simple-run 0.0.0.0:${PORT} ${SECRET}
    restart: always
EOF

# 启动服务
docker-compose down
docker-compose up -d

# 输出连接信息
IP=$(curl -s ifconfig.me)
echo ""
echo "✅ MTG 代理部署成功！请使用以下链接连接 Telegram："
echo "tg://proxy?server=${IP}&port=${PORT}&secret=${SECRET}"

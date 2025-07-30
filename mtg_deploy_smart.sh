#!/bin/bash

echo "📦 开始部署 MTProto Proxy（MTG + FakeTLS）..."

# 检查是否为 root
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ 请使用 root 用户运行此脚本。"
  exit 1
fi

# 检查 443 端口是否已被占用
if lsof -i :443 | grep -q LISTEN; then
  echo "⚠️  端口 443 已被占用，请先释放该端口后再运行此脚本。"
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

# 准备部署目录
mkdir -p /root/mtg_proxy
cd /root/mtg_proxy

# 移除旧容器（如果有）
docker rm -f mtg 2>/dev/null || true

# 拉取最新镜像 & 生成合法 Secret
echo "🔐 生成合法的 FakeTLS Secret..."
SECRET=$(docker run --rm nineseconds/mtg generate-secret tls)

# 写入 docker-compose.yml
cat > docker-compose.yml <<EOF
version: '3'

services:
  mtg:
    image: nineseconds/mtg:2.1
    container_name: mtg
    ports:
      - "443:443"
    command: simple-run 0.0.0.0:443 $SECRET
    restart: always
EOF

# 启动代理容器
docker-compose up -d

# 显示运行状态
sleep 2
STATUS=$(docker inspect -f '{{.State.Status}}' mtg)

if [ "$STATUS" = "running" ]; then
  echo ""
  echo "✅ 部署成功！请使用以下链接连接 Telegram："
  echo ""
  echo "tg://proxy?server=$(curl -s ifconfig.me)&port=443&secret=$SECRET"
  echo ""
else
  echo "❌ 容器未能正常启动，请检查日志：docker logs mtg"
fi

#!/bin/bash

PORT=$1
if [ -z "$PORT" ]; then
  PORT=8443
fi

echo "📦 开始部署 alexbers MTProto Proxy（Python 版） on port $PORT..."

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
mkdir -p /root/mtproto-alexbers
cd /root/mtproto-alexbers

# 下载项目主文件
if [ ! -f mtprotoproxy.py ]; then
  echo "📥 拉取项目主程序..."
  git clone https://github.com/alexbers/mtprotoproxy.git /tmp/mtgsrc
  cp /tmp/mtgsrc/mtprotoproxy.py .
  rm -rf /tmp/mtgsrc
fi

# 写入 config.py
cat > config.py <<EOF
PORT = $PORT

USERS = {{
    "user1": "005ffbf2797b44f93a0bf11d8cef486a"
}}

AD_TAG = ""
EOF

# 写入 docker-compose.yml
cat > docker-compose.yml <<EOF
version: '3'

services:
  mtproxy:
    image: python:3.11
    container_name: mtprotoproxy
    working_dir: /app
    volumes:
      - .:/app
    ports:
      - "$PORT:$PORT"
    command: bash -c "pip install cryptography pycryptodome pyaes && python mtprotoproxy.py"
    restart: always
EOF

# 启动容器
docker-compose down
docker-compose up -d

# 输出链接
echo ""
echo "✅ 代理部署完成！请使用以下链接连接 Telegram："
echo "tg://proxy?server=$(curl -s ifconfig.me)&port=$PORT&secret=005ffbf2797b44f93a0bf11d8cef486a"

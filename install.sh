#!/bin/bash

echo "📦 Telegram MTProto Proxy 一键安装"
echo ""
echo "请选择你要安装的版本："
echo "1. MTG（高性能 Rust 实现，支持 FakeTLS）"
echo "2. alexbers（Python 实现，兼容性好）"
echo ""
read -p "请输入选项 [1/2]: " choice
echo ""

read -p "请输入你希望使用的端口（建议 443 或 8443 等未占用端口）: " custom_port

if ! [[ "$custom_port" =~ ^[0-9]+$ ]]; then
    echo "❌ 端口号必须是数字。"
    exit 1
fi

if [ "$choice" = "1" ]; then
    echo "🧰 下载并执行 MTG 安装脚本..."
    curl -sSL https://raw.githubusercontent.com/dododook/mtproto-proxy-setup/main/mtg_deploy_smart.sh | bash -s "$custom_port"
elif [ "$choice" = "2" ]; then
    echo "🧰 下载并执行 alexbers 安装脚本..."
    curl -sSL https://raw.githubusercontent.com/dododook/mtproto-proxy-setup/main/alexbers_deploy.sh | bash -s "$custom_port"
else
    echo "❌ 无效选项，退出。"
    exit 1
fi

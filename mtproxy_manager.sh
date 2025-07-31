
#!/bin/bash

BOT_TOKEN="8027310373:AAEuKPwgkvr3P-8b54GbKPaM5uU7hGWv71Q"
CHAT_ID="6252019930"

DEFAULT_DOMAINS=("cloudflare.com" "www.bing.com" "cdn.jsdelivr.net" "www.microsoft.com" "azure.microsoft.com")

function deploy_mtproxy() {
  read -p "请输入映射端口（默认443）: " MAPPED_PORT
  MAPPED_PORT=${MAPPED_PORT:-443}

  read -p "请输入 HTTP 映射端口（默认80）: " MAPPED_HTTP
  MAPPED_HTTP=${MAPPED_HTTP:-80}

  echo -e "可选伪装域名："
  for i in "${!DEFAULT_DOMAINS[@]}"; do
    echo "$((i+1)). ${DEFAULT_DOMAINS[$i]}"
  done
  read -p "请输入伪装域名编号或自定义域名（默认1）: " DOMAIN_CHOICE

  if [[ "$DOMAIN_CHOICE" =~ ^[1-9][0-9]*$ ]] && [ "$DOMAIN_CHOICE" -le ${#DEFAULT_DOMAINS[@]} ]; then
    DOMAIN="${DEFAULT_DOMAINS[$((DOMAIN_CHOICE-1))]}"
  elif [ -z "$DOMAIN_CHOICE" ]; then
    DOMAIN="${DEFAULT_DOMAINS[0]}"
  else
    DOMAIN="$DOMAIN_CHOICE"
  fi

  read -p "请输入自定义 secret（32位十六进制，留空随机生成）: " SECRET
  if [ -z "$SECRET" ]; then
    SECRET=$(openssl rand -hex 16)
    echo -e "[✔] 已随机生成 secret: $SECRET"
  fi

  docker rm -f mtproxy 2>/dev/null

  docker run -d --name mtproxy --restart=always \
    -e domain="$DOMAIN" \
    -e secret="$SECRET" \
    -e ip_white_list="IP" \
    -e provider=2 \
    -p ${MAPPED_HTTP}:80 \
    -p ${MAPPED_PORT}:443 \
    ellermister/mtproxy

  IP=$(curl -s ipv4.ip.sb)
  HEX_DOMAIN=$(echo -n $DOMAIN | xxd -ps -c 200)
  SECRET_FULL="ee${SECRET}${HEX_DOMAIN}"
  LINK="tg://proxy?server=${IP}&port=${MAPPED_PORT}&secret=${SECRET_FULL}"
  QR_LINK="https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${LINK}"
  WHITE_LIST_URL="http://${IP}:${MAPPED_HTTP}/add.php"

  echo -e "\n✅ MTProxy 已部署"
  echo -e "📡 链接: ${LINK}"
  echo -e "🧊 白名单激活: ${WHITE_LIST_URL}"
  echo -e "📷 二维码链接: ${QR_LINK}\n"

  curl -s -X POST https://api.telegram.org/bot${BOT_TOKEN}/sendMessage \
    -d chat_id="${CHAT_ID}" \
    -d text="✅ MTProxy 部署完成（白名单 ${MAPPED_PORT}）%0A🧊 白名单激活: ${WHITE_LIST_URL}%0A📡 链接: ${LINK}" \
    -d parse_mode="Markdown"
}

function uninstall_mtproxy() {
  echo -e "\033[1;33m正在停止并删除 MTProxy 容器...\033[0m"
  docker stop mtproxy >/dev/null 2>&1
  docker rm -f mtproxy >/dev/null 2>&1
  echo -e "\033[1;32m✅ 已卸载 MTProxy。\033[0m"
}

function count_all_connections() {
  echo -e "\n🔍 正在统计连接客户端总数..."
  count=$(ss -ntp state established '( sport = :8443 )' | grep -v 127.0.0.1 | grep -c ESTAB)
  echo -e "📶 当前总连接数：$count"
}

function count_telegram_clients() {
  echo -e "\n🔍 正在统计连接客户端 IP..."
  mapfile -t ip_list < <(ss -ntp state established '( sport = :8443 )' | awk '{print $5}' | cut -d: -f1 | sort | uniq -c)
  for ip in "${ip_list[@]}"; do
    echo "✅ $ip 个连接（可能是 Telegram 客户端）"
  done
}

echo -e "\n==== MTProxy 管理脚本（含连接识别） ===="
echo "1. 部署 MTProxy"
echo "2. 卸载 MTProxy"
echo "3. 退出"
echo "4. 查看连接总数"
echo "5. 查看 Telegram 客户端连接"
read -p "请输入操作选项 [1-5]: " choice

case $choice in
  1) deploy_mtproxy ;;
  2) uninstall_mtproxy ;;
  3) echo "已退出"; exit 0 ;;
  4) count_all_connections ;;
  5) count_telegram_clients ;;
  *) echo "无效输入"; exit 1 ;;
esac

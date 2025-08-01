#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'

echo -e "${GREEN}=========================================="
echo -e "===    MTProxy NGINX 管理工具 v5.2.9   ==="
echo -e "==========================================${RESET}"
echo -e "${YELLOW}作者：@yaoguangting  |  基于 ellermister/nginx-mtproxy${RESET}\n"

echo -e "请选择您想要执行的操作："
echo -e "  1. 安装 MTProxy"
echo -e "  2. 卸载 MTProxy"
echo -e "  3. 重启 MTProxy"
echo -e "  4. 停止 MTProxy"
echo -e "  5. 启动 MTProxy"
echo -e "  6. 更新脚本"
echo -e "  7. 退出"
echo "------------------------------------------"
read -rp "请输入选项 [1-7]: " menu

check_port() {
  if lsof -iTCP:"$1" -sTCP:LISTEN -t >/dev/null ; then
    echo -e "${RED}⚠️  端口 $1 已被占用，请更换端口后重试。${RESET}"
    exit 1
  fi
}

case "$menu" in
  1)
    echo -e "\n>>> 正在准备安装 MTProxy..."
    read -e -p "请输入连接端口 (默认: 443): " port
    [[ -z "${port}" ]] && port="443"
    check_port "$port"

    read -e -p "请输入密码 (默认: 自动生成): " secret
    [[ -z "${secret}" ]] && secret=$(cat /proc/sys/kernel/random/uuid | sed 's/-//g') && echo -e "  已自动生成密码：${secret}"

    echo -e "请选择伪装域名："
    echo "1. azure.microsoft.com"
    echo "2. www.microsoft.com"
    echo "3. cdn.cloudflare.com"
    echo "4. www.google.com"
    echo "5. 自定义输入"
    read -rp "请输入选项 [1-5] (默认1): " domain_choice
    case $domain_choice in
      2) domain="www.microsoft.com" ;;
      3) domain="cdn.cloudflare.com" ;;
      4) domain="www.google.com" ;;
      5)
        read -rp "请输入自定义域名: " domain
        [[ -z "${domain}" ]] && domain="azure.microsoft.com"
        ;;
      *) domain="azure.microsoft.com" ;;
    esac

    read -rp "是否需要设置 TAG 标签? (y/N): " use_tag
    [[ -z "${use_tag}" ]] && use_tag="N"

    echo -e ">>> 正在安装依赖 Docker..."
    echo y | bash <(curl -L -s https://cdn.jsdelivr.net/gh/xb0or/nginx-mtproxy@main/docker.sh)

    if [[ "$use_tag" =~ ^[Yy]$ ]]; then
      read -rp "请输入 TAG 标签: " tag
      docker run --name nginx-mtproxy -d -e tag="$tag" -e secret="$secret" -e domain="$domain" -p 80:80 -p $port:$port ellermister/nginx-mtproxy:latest
    else
      docker run --name nginx-mtproxy -d -e secret="$secret" -e domain="$domain" -p 80:80 -p $port:$port ellermister/nginx-mtproxy:latest
    fi

    echo -e ">>> 正在设置容器开机自启..."
    docker update --restart=always nginx-mtproxy

    public_ip=$(curl -s ipv4.ip.sb || curl -s ipinfo.io/ip)
    domain_hex=$(echo -n "$domain" | xxd -ps | tr -d '\n')
    client_secret="ee${secret}${domain_hex}"

    echo -e "${GREEN}============== 安装完成 ==============${RESET}"
    echo -e "服务器IP：${RED}$public_ip${RESET}"
    echo -e "服务器端口：${RED}$port${RESET}"
    echo -e "MTProxy Secret：${RED}$client_secret${RESET}"
    echo -e "TG认证地址：http://${public_ip}:80/add.php"
    echo -e "TG一键链接：tg://proxy?server=${public_ip}&port=${port}&secret=${client_secret}"
    ;;
  2)
    echo -e ">>> 正在卸载 MTProxy..."
    docker rm -f nginx-mtproxy && echo -e "${GREEN}✅ 卸载成功！${RESET}" || echo -e "${YELLOW}容器未运行或已被删除。${RESET}"
    ;;
  3)
    docker restart nginx-mtproxy && echo -e "${GREEN}✅ 已重启 MTProxy${RESET}" || echo -e "${RED}❌ 容器不存在${RESET}"
    ;;
  4)
    docker stop nginx-mtproxy && echo -e "${YELLOW}⏸️ 已停止 MTProxy${RESET}" || echo -e "${RED}❌ 容器不存在${RESET}"
    ;;
  5)
    docker start nginx-mtproxy && echo -e "${GREEN}▶️ 已启动 MTProxy${RESET}" || echo -e "${RED}❌ 容器不存在${RESET}"
    ;;
  6)
    echo -e "🔄 正在更新脚本..."
    curl -sSL https://raw.githubusercontent.com/dododook/mtproto-proxy-setup/main/mtproxy_menu.sh -o "$0" && \
    echo -e "${GREEN}✅ 脚本已更新，请重新运行。${RESET}" && exit 0
    ;;
  7)
    echo -e "👋 再见！"
    exit 0
    ;;
  *)
    echo -e "${RED}无效选项，请输入 1-7 的数字。${RESET}"
    ;;
esac

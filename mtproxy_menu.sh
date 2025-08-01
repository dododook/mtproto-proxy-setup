#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin

# ========== 颜色定义 ==========
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[36m"
RESET="\033[0m"

# ========== 菜单显示 ==========
while true; do
clear
echo -e "${GREEN}==========================================${RESET}"
echo -e "${GREEN}===        MTProxy NGINX 管理工具 v5.3.5    ===${RESET}"
echo -e "${GREEN}==========================================${RESET}"
echo -e "${YELLOW}作者：@yaoguangting  |  基于 ellermister/nginx-mtproxy 🍥${RESET}\n"

echo -e "请选择您想要执行的操作："
echo -e "  1. 安装 MTProxy"
echo -e "  2. 卸载 MTProxy"
echo -e "  3. 重启 MTProxy"
echo -e "  4. 停止 MTProxy"
echo -e "  5. 启动 MTProxy"
echo -e "  6. 更新脚本"
echo -e "  7. 退出"
echo -e "------------------------------------------"
read -rp "请输入选项 [1-7]: " menu

case "$menu" in
1)
  echo -e "\n>>> 正在准备安装 MTProxy..."

  read -e -p "请输入连接端口 (默认: 443): " port
  [[ -z "${port}" ]] && port="443"

  read -e -p "请输入密码 (默认: 自动生成): " secret
  if [[ -z "${secret}" ]]; then
    secret=$(cat /proc/sys/kernel/random/uuid | sed 's/-//g')
    echo -e "  已自动生成密码：${secret}"
  fi

  echo -e "\n可选伪装域名："
  echo "  1. azure.microsoft.com"
  echo "  2. www.bing.com"
  echo "  3. www.cloudflare.com"
  echo "  4. 自定义域名"
  read -rp "请选择伪装域名 [1-4] (默认1): " dsel
  case "$dsel" in
    2) domain="www.bing.com" ;;
    3) domain="www.cloudflare.com" ;;
    4) read -e -p "请输入自定义伪装域名: " domain ;;
    *) domain="azure.microsoft.com" ;;
  esac

  read -rp "是否需要设置 TAG 标签? (y/N 默认: N): " settag
  [[ -z "${settag}" ]] && settag="N"
  case $settag in
    [yY][eE][sS]|[yY])
      read -e -p "请输入 TAG: " tag
      [[ -z "${tag}" ]] && echo "未输入 TAG，继续安装..." ;;
  esac

  echo -e "\n正在安装依赖: Docker..."
  bash <(curl -fsSL https://cdn.jsdelivr.net/gh/xb0or/nginx-mtproxy@main/docker.sh)

  echo -e "\n正在安装 nginx-mtproxy 容器..."
  docker rm -f nginx-mtproxy >/dev/null 2>&1
  if [[ "$settag" =~ ^[yY]$ && -n "$tag" ]]; then
    docker run --name nginx-mtproxy -d -e tag="$tag" -e secret="$secret" -e domain="$domain" -p 80:80 -p ${port}:${port} ellermister/nginx-mtproxy:latest
  else
    docker run --name nginx-mtproxy -d -e secret="$secret" -e domain="$domain" -p 80:80 -p ${port}:${port} ellermister/nginx-mtproxy:latest
  fi

  echo -e "\n正在设置容器开机自启..."
  docker update --restart=always nginx-mtproxy

  public_ip=$(curl -s http://ipv4.icanhazip.com)
  [[ -z "$public_ip" ]] && public_ip=$(curl -s ipinfo.io/ip --ipv4)
  domain_hex=$(echo -n "$domain" | xxd -ps | tr -d '\n')
  client_secret="ee${secret}${domain_hex}"

  echo -e "\n============== 安装完成 =============="
  echo -e "服务器IP：${RED}${public_ip}${RESET}"
  echo -e "服务器端口：${RED}${port}${RESET}"
  echo -e "MTProxy Secret：${RED}${client_secret}${RESET}"
  echo -e "TG认证地址：http://${public_ip}:80/add.php"
  echo -e "TG一键链接：tg://proxy?server=${public_ip}&port=${port}&secret=${client_secret}"
  echo -e "注意：如果你使用的是默认端口 443，日志中可能显示 8443，为镜像内部映射，请以此处提示为准。"
  ;;
2)
  echo -e "\n>>> 正在卸载 MTProxy..."
  docker stop nginx-mtproxy >/dev/null 2>&1
  docker rm -f nginx-mtproxy >/dev/null 2>&1
  echo -e "✅ 卸载完成！"
  ;;
3) docker restart nginx-mtproxy && echo -e "✅ 已重启 nginx-mtproxy" ;;
4) docker stop nginx-mtproxy && echo -e "✅ 已停止 nginx-mtproxy" ;;
5) docker start nginx-mtproxy && echo -e "✅ 已启动 nginx-mtproxy" ;;
6)
  echo -e "🔄 正在更新脚本..."
  curl -fsSL https://raw.githubusercontent.com/dododook/mtproto-proxy-setup/main/mtproxy_menu.sh -o "$0"
  echo -e "✅ 脚本已更新为最新版，重新加载..."
  exec bash "$0"
  ;;
7)
  echo "Bye!" && exit 0
  ;;
*)
  echo -e "${RED}无效选项，请重新输入！${RESET}"
  ;;
esac
echo -e "\n按任意键返回主菜单..."
read -n 1 -s
done

#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

echo -e "${GREEN}========== MTProxy NGINX 管理工具 ==========${RESET}"
echo -e "${YELLOW}作者：@yaoguangting ｜ 基于 ellermister/nginx-mtproxy${RESET}\n"

echo -e "请选择操作："
echo -e "1. 安装 MTProxy"
echo -e "2. 卸载 MTProxy"
echo -e "3. 重启 MTProxy"
echo -e "4. 停止 MTProxy"
echo -e "5. 启动 MTProxy"
echo -e "6. 更新脚本"
echo -e "7. 退出"
read -rp "请输入选项 [1-7]: " menu

case $menu in
1)
  read -e -p "请输入链接端口(默认443): " port
  [[ -z "${port}" ]] && port="443"

  read -e -p "请输入密码(默认随机生成): " secret
  if [[ -z "${secret}" ]]; then
    secret=$(cat /proc/sys/kernel/random/uuid | sed 's/-//g')
    echo -e "密码："
    echo -e "$secret"
  fi

  echo "请选择伪装域名："
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
    5) read -rp "请输入自定义伪装域名: " domain ;;
    *) domain="azure.microsoft.com" ;;
  esac

  read -rp "你需要TAG标签吗 (Y/N，默认N): " chrony_install
  [[ -z ${chrony_install} ]] && chrony_install="N"
  case $chrony_install in
  [yY][eE][sS] | [yY])
    read -e -p "请输入TAG: " tag
    if [[ -z "${tag}" ]]; then
      echo "请输入TAG"
    fi
    echo -e "正在安装依赖: Docker..."
    echo y | bash <(curl -L -s https://raw.githubusercontent.com/xb0or/nginx-mtproxy/main/docker.sh)
    echo -e "正在安装nginx-mtproxy..."
    docker run --name nginx-mtproxy -d -e tag="$tag" -e secret="$secret" -e domain="$domain" -p 80:80 -p $port:$port ellermister/nginx-mtproxy:latest
    ;;
  *)
    echo -e "正在安装依赖: Docker..."
    echo y | bash <(curl -L -s https://cdn.jsdelivr.net/gh/xb0or/nginx-mtproxy@main/docker.sh)
    echo -e "正在安装nginx-mtproxy..."
    docker run --name nginx-mtproxy -d -e secret="$secret" -e domain="$domain" -p 80:80 -p $port:$port ellermister/nginx-mtproxy:latest
    ;;
  esac

  echo -e "正在设置容器开机自启..."
  docker update --restart=always nginx-mtproxy

  public_ip=$(curl -s http://ipv4.icanhazip.com)
  [ -z "$public_ip" ] && public_ip=$(curl -s ipinfo.io/ip --ipv4)
  domain_hex=$(xxd -pu <<< $domain | sed 's/0a//g')
  client_secret="ee${secret}${domain_hex}"

  echo -e "${GREEN}============== 安装完成 ==============${RESET}"
  echo -e "服务器IP：\033[31m$public_ip\033[0m"
  echo -e "服务器端口：\033[31m$port\033[0m"
  echo -e "MTProxy Secret:  \033[31m$client_secret\033[0m"
  echo -e "TG认证地址：http://${public_ip}:80/add.php"
  echo -e "TG一键链接: tg://proxy?server=${public_ip}&port=${port}&secret=${client_secret}"
  echo -e "${YELLOW}注意：如果你使用的是默认端口 443，日志中可能显示 8443，为镜像内部映射，请以此处提示为准。${RESET}"
  echo -e "如需查看日志，请执行：docker logs nginx-mtproxy"
  ;;
2)
  if docker ps -a --format '{{.Names}}' | grep -q '^nginx-mtproxy$'; then
    docker rm -f nginx-mtproxy
    echo -e "${GREEN}MTProxy 容器已成功卸载${RESET}"
  else
    echo -e "${YELLOW}未检测到 nginx-mtproxy 容器，无需卸载${RESET}"
  fi
  read -rp "按回车返回菜单..."
  ;;
3)
  echo -e "${YELLOW}正在重启 MTProxy...${RESET}"
  docker restart nginx-mtproxy
  echo -e "${GREEN}MTProxy 已重启${RESET}"
  ;;
4)
  echo -e "${YELLOW}正在停止 MTProxy...${RESET}"
  docker stop nginx-mtproxy
  echo -e "${GREEN}MTProxy 已停止${RESET}"
  ;;
5)
  echo -e "${YELLOW}正在启动 MTProxy...${RESET}"
  docker start nginx-mtproxy
  echo -e "${GREEN}MTProxy 已启动${RESET}"
  ;;
6)
  echo -e "🔄 正在更新脚本..."
  curl -o mtproxy_menu.sh https://raw.githubusercontent.com/dododook/mtproto-proxy-setup/main/mtproxy_menu.sh && chmod +x mtproxy_menu.sh
  echo -e "✅ 脚本已更新，请重新运行。"
  ;;
7)
  exit 0
  ;;
*)
  echo -e "${YELLOW}无效的选项，请重新运行脚本。${RESET}"
  ;;
esac

#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin

# 颜色定义
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${GREEN}========== MTProxy NGINX 管理工具 ==========${RESET}"
echo -e "${YELLOW}作者：@yaoguangting ｜ 基于 ellermister/nginx-mtproxy${RESET}\n"

echo -e "请选择操作："
echo -e "1. 安装 MTProxy"
echo -e "2. 卸载 MTProxy"
echo -e "3. 退出"
read -rp "请输入选项 [1-3]: " menu

case $menu in
1)
  echo -e "\n${GREEN}========== 开始安装 MTProxy ==========${RESET}"

  read -e -p "请输入链接端口 [默认443]: " port
  [[ -z "${port}" ]] && port="443"

  read -e -p "请输入密码 [默认随机生成]: " secret
  if [[ -z "${secret}" ]]; then
    secret=$(cat /proc/sys/kernel/random/uuid | sed 's/-//g')
    echo -e "已生成随机密码：${YELLOW}$secret${RESET}"
  fi

  echo -e "\n请选择伪装域名："
  echo -e "1) azure.microsoft.com"
  echo -e "2) www.microsoft.com"
  echo -e "3) www.bing.com"
  echo -e "4) www.cloudflare.com"
  echo -e "5) cdn.jsdelivr.net"
  echo -e "6) www.google.com"
  echo -e "7) 自定义输入"
  read -rp "请输入序号 [默认1]: " domain_choice

  case "$domain_choice" in
    2) domain="www.microsoft.com" ;;
    3) domain="www.bing.com" ;;
    4) domain="www.cloudflare.com" ;;
    5) domain="cdn.jsdelivr.net" ;;
    6) domain="www.google.com" ;;
    7)
      read -rp "请输入自定义域名: " domain
      [[ -z "$domain" ]] && domain="azure.microsoft.com"
      ;;
    *) domain="azure.microsoft.com" ;;
  esac

  read -rp "你需要TAG标签吗 (Y/N): " enable_tag
  [[ -z ${enable_tag} ]] && enable_tag="N"

  if docker ps -a | grep -q nginx-mtproxy; then
      echo -e "${YELLOW}检测到已存在 nginx-mtproxy 容器，正在删除...${RESET}"
      docker rm -f nginx-mtproxy >/dev/null 2>&1
  fi

  echo -e "${GREEN}正在安装依赖: Docker...${RESET}"
  echo y | bash <(curl -L -s https://raw.githubusercontent.com/xb0or/nginx-mtproxy/main/docker.sh)

  echo -e "${GREEN}正在安装 nginx-mtproxy 容器...${RESET}"

  if [[ "${enable_tag}" =~ ^[Yy] ]]; then
    while true; do
      read -e -p "请输入TAG: " tag
      if [[ -n "${tag}" ]]; then
        break
      else
        echo -e "${RED}TAG 不能为空，请重新输入。${RESET}"
      fi
    done
    docker run --name nginx-mtproxy -d -e tag="$tag" -e secret="$secret" -e domain="$domain" -p 80:80 -p $port:8443 ellermister/nginx-mtproxy:latest
  else
    docker run --name nginx-mtproxy -d -e secret="$secret" -e domain="$domain" -p 80:80 -p $port:8443 ellermister/nginx-mtproxy:latest
  fi

  echo -e "${GREEN}正在设置容器开机自启...${RESET}"
  docker update --restart=always nginx-mtproxy

  public_ip=$(curl -s http://ipv4.icanhazip.com)
  [ -z "$public_ip" ] && public_ip=$(curl -s ipinfo.io/ip --ipv4)

  if ! command -v xxd &> /dev/null; then
    echo -e "${YELLOW}未检测到 xxd，正在尝试安装...${RESET}"
    apt-get update -y && apt-get install -y xxd
  fi

  if command -v xxd &> /dev/null; then
    domain_hex=$(xxd -pu <<< "$domain" | sed 's/0a//g')
    client_secret="ee${secret}${domain_hex}"
  else
    echo -e "${RED}警告：未成功安装 xxd，生成的 Secret 将不包含伪装域名！${RESET}"
    client_secret="ee${secret}"
  fi

  echo -e "${GREEN}============== 安装完成 ==============${RESET}"
  echo -e "服务器IP：${RED}$public_ip${RESET}"
  echo -e "服务器端口：${RED}$port${RESET}"
  echo -e "MTProxy Secret：${RED}$client_secret${RESET}"
  echo -e "TG认证地址：${YELLOW}http://${public_ip}:80/add.php${RESET}"
  echo -e "TG一键链接：${YELLOW}https://t.me/proxy?server=${public_ip}&port=${port}&secret=${client_secret}${RESET}"
  echo -e "${YELLOW}注意：如果你使用的是默认端口 443，日志中可能显示 8443，为镜像内部映射，请以此处提示为准。${RESET}"
  echo -e "${YELLOW}如需查看日志，请执行：docker logs nginx-mtproxy${RESET}"
  ;;

2)
  echo -e "\n${GREEN}========== 开始卸载 MTProxy ==========${RESET}"

  if docker ps -a | grep -q nginx-mtproxy; then
      echo -e "${YELLOW}正在停止并移除容器 nginx-mtproxy...${RESET}"
      docker stop nginx-mtproxy >/dev/null 2>&1
      docker rm nginx-mtproxy >/dev/null 2>&1
  else
      echo -e "${RED}未检测到容器 nginx-mtproxy，无需卸载。${RESET}"
  fi

  read -rp "是否同时删除镜像 ellermister/nginx-mtproxy？(Y/N): " rm_image
  [[ -z "$rm_image" ]] && rm_image="N"
  if [[ "$rm_image" =~ ^[Yy]$ ]]; then
      echo -e "${YELLOW}正在删除镜像...${RESET}"
      docker rmi ellermister/nginx-mtproxy:latest >/dev/null 2>&1
  fi

  read -rp "是否卸载 Docker 本体（请谨慎）？(Y/N): " rm_docker
  [[ -z "$rm_docker" ]] && rm_docker="N"
  if [[ "$rm_docker" =~ ^[Yy]$ ]]; then
      echo -e "${YELLOW}正在卸载 Docker...${RESET}"
      bash <(curl -sSL https://get.docker.com/) --uninstall
  fi

  echo -e "${GREEN}✅ nginx-mtproxy 卸载完成！${RESET}"
  ;;

3)
  echo -e "${YELLOW}已退出。感谢使用！${RESET}"
  exit 0
  ;;

*)
  echo -e "${RED}无效选项，请输入 1 ~ 3。${RESET}"
  ;;
esac

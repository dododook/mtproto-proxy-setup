#!/bin/bash
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
RESET='\033[0m'

while true; do
  clear
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
      [[ -z "${secret}" ]] && secret=$(cat /proc/sys/kernel/random/uuid | sed 's/-//g') && echo -e "密码：$secret"

      read -e -p "请输入伪装域名(默认azure.microsoft.com): " domain
      [[ -z "${domain}" ]] && domain="azure.microsoft.com"

      read -rp "你需要TAG标签吗 (Y/N): " chrony_install
      [[ -z ${chrony_install} ]] && chrony_install="N"

      if [[ $chrony_install == [yY] || $chrony_install == [yY][eE][sS] ]]; then
        read -e -p "请输入TAG:" tag
        [[ -z "${tag}" ]] && echo "请输入TAG"
        echo -e "正在安装依赖: Docker..."
        echo y | bash <(curl -L -s https://raw.githubusercontent.com/xb0or/nginx-mtproxy/main/docker.sh)
        echo -e "正在安装nginx-mtproxy..."
        docker run --name nginx-mtproxy -d -e tag="$tag" -e secret="$secret" -e domain="$domain" -p 80:80 -p $port:$port ellermister/nginx-mtproxy:latest
      else
        echo -e "正在安装依赖: Docker..."
        echo y | bash <(curl -L -s https://raw.githubusercontent.com/xb0or/nginx-mtproxy/main/docker.sh)
        echo -e "正在安装nginx-mtproxy..."
        docker run --name nginx-mtproxy -d -e secret="$secret" -e domain="$domain" -p 80:80 -p $port:$port ellermister/nginx-mtproxy:latest
      fi

      echo -e "正在设置容器开机自启..."
      docker update --restart=always nginx-mtproxy

      public_ip=$(curl -s http://ipv4.icanhazip.com)
      [ -z "$public_ip" ] && public_ip=$(curl -s ipinfo.io/ip --ipv4)
      domain_hex=$(xxd -pu <<< $domain | sed 's/0a//g')
      client_secret="ee${secret}${domain_hex}"

      echo -e "${GREEN}============== 安装完成 ==============${RESET}"
      echo -e "服务器IP：${RED}$public_ip${RESET}"
      echo -e "服务器端口：${RED}$port${RESET}"
      echo -e "MTProxy Secret：${RED}$client_secret${RESET}"
      echo -e "TG认证地址：http://${public_ip}:80/add.php"
      echo -e "TG一键链接：tg://proxy?server=${public_ip}&port=${port}&secret=${client_secret}"
      echo -e "${YELLOW}注意：如果你使用的是默认端口 443，日志中可能显示 8443，为镜像内部映射，请以此处提示为准。${RESET}"
      echo -e "如需查看日志，请执行：docker logs nginx-mtproxy"
      read -rp "按回车返回菜单..."
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
      docker restart nginx-mtproxy && echo -e "${GREEN}MTProxy 已重启${RESET}"
      read -rp "按回车返回菜单..."
      ;;
    4)
      docker stop nginx-mtproxy && echo -e "${YELLOW}MTProxy 已停止${RESET}"
      read -rp "按回车返回菜单..."
      ;;
    5)
      docker start nginx-mtproxy && echo -e "${GREEN}MTProxy 已启动${RESET}"
      read -rp "按回车返回菜单..."
      ;;
    6)
      echo -e "${YELLOW}🔄 正在更新脚本...${RESET}"
      curl -o mtproxy_menu.sh https://raw.githubusercontent.com/dododook/mtproto-proxy-setup/main/mtproxy_menu.sh
      echo -e "${GREEN}✅ 脚本已更新，请重新运行。${RESET}"
      exit 0
      ;;
    7)
      echo -e "${GREEN}已退出脚本，再见～${RESET}"
      exit 0
      ;;
    *)
      echo -e "${RED}无效选项，请重新输入${RESET}"
      read -rp "按回车返回菜单..."
      ;;
  esac
done

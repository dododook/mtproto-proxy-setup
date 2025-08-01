#!/bin/bash

GREEN='\033[32m'
YELLOW='\033[33m'
RESET='\033[0m'

echo -e "${GREEN}=========================================="
echo -e "===        MTProxy NGINX 管理工具 v5.3.51      ==="
echo -e "==========================================${RESET}"
echo -e "${YELLOW}作者：@yaoguangting  |  基于 ellermister/nginx-mtproxy 🍥${RESET}\n"

while true; do
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

  case $menu in
  1)
    echo -e "\n>>> 正在准备安装 MTProxy..."

    read -e -p "请输入连接端口 (默认: 443): " port
    [[ -z "$port" ]] && port="443"

    read -e -p "请输入密码 (默认: 自动生成): " secret
    if [[ -z "$secret" ]]; then
      secret=$(cat /proc/sys/kernel/random/uuid | sed 's/-//g')
      echo -e "  已自动生成密码：$secret"
    fi

    read -e -p "请输入伪装域名 (默认: azure.microsoft.com): " domain
    [[ -z "$domain" ]] && domain="azure.microsoft.com"

    read -rp "是否需要设置 TAG 标签? (y/N，默认: N): " tag_enable
    [[ -z "$tag_enable" ]] && tag_enable="N"

    echo -e "\n正在检查 Docker 是否已安装..."
    if ! command -v docker >/dev/null 2>&1; then
      echo -e "${YELLOW}Docker 未安装，正在安装...${RESET}"
      bash <(curl -fsSL https://get.docker.com)
    else
      echo -e "${GREEN}您的系统已安装 Docker${RESET}"
    fi

    echo -e "\n正在安装 nginx-mtproxy 容器..."
    if [[ $tag_enable =~ ^[yY]$ ]]; then
      read -e -p "请输入 TAG 标签: " tag
      docker run --name nginx-mtproxy -d \
        -e tag="$tag" -e secret="$secret" -e domain="$domain" \
        -p 80:80 -p $port:$port ellermister/nginx-mtproxy:latest
    else
      docker run --name nginx-mtproxy -d \
        -e secret="$secret" -e domain="$domain" \
        -p 80:80 -p $port:$port ellermister/nginx-mtproxy:latest
    fi

    echo -e "\n正在设置容器开机自启..."
    docker update --restart=always nginx-mtproxy

    public_ip=$(curl -s ipv4.ip.sb || curl -s ipinfo.io/ip)
    domain_hex=$(echo -n "$domain" | xxd -ps | tr -d '\n')
    client_secret="ee${secret}${domain_hex}"

    echo -e "\n${GREEN}============== 安装完成 ==============${RESET}"
    echo -e "服务器IP：$public_ip"
    echo -e "服务器端口：$port"
    echo -e "MTProxy Secret：$client_secret"
    echo -e "TG认证地址：http://$public_ip:80/add.php"
    echo -e "TG一键链接：tg://proxy?server=$public_ip&port=$port&secret=$client_secret"
    echo -e "${YELLOW}注意：如果你使用的是默认端口 443，日志中可能显示 8443，为镜像内部映射，请以此处提示为准。${RESET}"
    echo -e "${YELLOW}如需查看日志，请执行：docker logs nginx-mtproxy${RESET}"
    read -n 1 -s -r -p "按任意键返回主菜单..."
    echo
    ;;
  2)
    echo -e "\n>>> 正在卸载 MTProxy..."
    read -rp "是否删除 nginx-mtproxy 容器？(y/N): " del_container
    [[ -z "$del_container" ]] && del_container="N"
    if [[ $del_container =~ ^[yY]$ ]]; then
      docker stop nginx-mtproxy && docker rm nginx-mtproxy
    fi

    read -rp "是否需要卸载 Docker？(y/N): " del_docker
    [[ -z "$del_docker" ]] && del_docker="N"
    if [[ $del_docker =~ ^[yY]$ ]]; then
      apt-get remove -y docker docker-engine docker.io containerd runc
    fi

    echo -e "${GREEN}✅ 卸载完成！${RESET}"
    read -n 1 -s -r -p "按任意键返回主菜单..."
    echo
    ;;
  3)
    echo -e "🔄 正在重启 MTProxy 容器..."
    docker restart nginx-mtproxy
    echo -e "${GREEN}✅ 重启完成！${RESET}"
    sleep 1
    ;;
  4)
    echo -e "⏸️ 正在停止 MTProxy 容器..."
    docker stop nginx-mtproxy
    echo -e "${GREEN}✅ 停止完成！${RESET}"
    sleep 1
    ;;
  5)
    echo -e "▶️ 正在启动 MTProxy 容器..."
    docker start nginx-mtproxy
    echo -e "${GREEN}✅ 启动完成！${RESET}"
    sleep 1
    ;;
  6)
    echo -e "🔄 正在更新脚本..."
    curl -fsSL https://raw.githubusercontent.com/dododook/mtproto-proxy-setup/main/mtproxy_menu.sh -o "$0"
    echo -e "${GREEN}✅ 脚本已更新，正在重新加载...${RESET}"
    exec "$0"
    ;;
  7)
    echo -e "${YELLOW}Bye!${RESET}"
    exit 0
    ;;
  *)
    echo -e "${YELLOW}无效选项，请重新选择。${RESET}"
    ;;
  esac
done

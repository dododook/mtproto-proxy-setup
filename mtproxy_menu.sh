#!/bin/bash

# --- 颜色定义 ---
# 定义用于不同类型信息的颜色，让脚本输出更清晰
RED='\033[31m'    # 错误或重要信息
GREEN='\033[32m'  # 成功信息
YELLOW='\033[33m' # 警告或提示
BLUE='\033[34m'   # 强调或额外信息
RESET='\033[0m'   # 重置所有颜色

# --- 菜单函数 ---
# 将菜单显示逻辑封装成函数，方便调用和管理
show_menu() {
  clear
  echo -e "${GREEN}==========================================${RESET}"
  echo -e "${GREEN}===        MTProxy NGINX 管理工具      ===${RESET}"
  echo -e "${GREEN}==========================================${RESET}"
  echo -e "${YELLOW}作者：@yaoguangting  |  基于 ellermister/nginx-mtproxy${RESET}\n"
  echo -e "请选择您想要执行的操作："
  echo -e "  ${BLUE}1.${RESET} 安装 MTProxy"
  echo -e "  ${BLUE}2.${RESET} 卸载 MTProxy"
  echo -e "  ${BLUE}3.${RESET} 重启 MTProxy"
  echo -e "  ${BLUE}4.${RESET} 停止 MTProxy"
  echo -e "  ${BLUE}5.${RESET} 启动 MTProxy"
  echo -e "  ${BLUE}6.${RESET} 更新脚本"
  echo -e "  ${BLUE}7.${RESET} 退出"
  echo -e "${GREEN}------------------------------------------${RESET}"
}

# --- 主程序循环 ---
while true; do
  show_menu
  read -rp "请输入选项 [1-7]: " menu

  case $menu in
    1)
      # 安装 MTProxy
      echo -e "\n${YELLOW}>>> 正在准备安装 MTProxy...${RESET}"
      read -e -p "请输入连接端口 (默认: 443): " port
      [[ -z "${port}" ]] && port="443"

      read -e -p "请输入密码 (默认: 自动生成): " secret
      if [[ -z "${secret}" ]]; then
        secret=$(cat /proc/sys/kernel/random/uuid | sed 's/-//g')
        echo -e "  ${GREEN}已自动生成密码：$secret${RESET}"
      fi

      read -e -p "请输入伪装域名 (默认: azure.microsoft.com): " domain
      [[ -z "${domain}" ]] && domain="azure.microsoft.com"

      read -rp "是否需要设置 TAG 标签? (y/N): " chrony_install
      [[ -z ${chrony_install} ]] && chrony_install="N"

      echo -e "\n${BLUE}>>> 正在检查并安装 Docker...${RESET}"
      echo y | bash <(curl -L -s https://raw.githubusercontent.com/xb0or/nginx-mtproxy/main/docker.sh)

      echo -e "\n${BLUE}>>> 正在拉取并启动 nginx-mtproxy 容器...${RESET}"
      if [[ $chrony_install == [yY] || $chrony_install == [yY][eE][sS] ]]; then
        read -e -p "请输入 TAG 标签: " tag
        [[ -z "${tag}" ]] && { echo -e "${RED}错误：TAG 不能为空！${RESET}"; read -rp "按回车键返回菜单..."; continue; }
        docker run --name nginx-mtproxy -d -e tag="$tag" -e secret="$secret" -e domain="$domain" -p 80:80 -p $port:$port ellermister/nginx-mtproxy:latest
      else
        docker run --name nginx-mtproxy -d -e secret="$secret" -e domain="$domain" -p 80:80 -p $port:$port ellermister/nginx-mtproxy:latest
      fi

      # 检查容器是否成功运行
      if docker ps --format '{{.Names}}' | grep -q '^nginx-mtproxy$'; then
        echo -e "${GREEN}MTProxy 容器已成功启动！${RESET}"
      else
        echo -e "${RED}MTProxy 容器启动失败，请检查日志！${RESET}"
        read -rp "按回车键返回菜单..."
        continue
      fi

      echo -e "${BLUE}>>> 正在设置容器开机自启...${RESET}"
      docker update --restart=always nginx-mtproxy

      public_ip=$(curl -s http://ipv4.icanhazip.com)
      [ -z "$public_ip" ] && public_ip=$(curl -s ipinfo.io/ip --ipv4)
      domain_hex=$(xxd -pu <<< $domain | sed 's/0a//g')
      client_secret="ee${secret}${domain_hex}"

      echo -e "\n${GREEN}================== 安装成功！ ==================${RESET}"
      echo -e "${BLUE}配置信息：${RESET}"
      echo -e "  服务器 IP：${YELLOW}$public_ip${RESET}"
      echo -e "  服务器端口：${YELLOW}$port${RESET}"
      echo -e "  MTProxy Secret：${YELLOW}$client_secret${RESET}"
      echo -e "  TG 认证地址：${YELLOW}http://${public_ip}:80/add.php${RESET}"
      echo -e "  TG 一键链接：${YELLOW}tg://proxy?server=${public_ip}&port=${port}&secret=${client_secret}${RESET}"
      echo -e "\n${YELLOW}提示：如果日志显示 8443，那是镜像内部端口，请以此处显示的端口为准。${RESET}"
      echo -e "查看日志命令：${BLUE}docker logs nginx-mtproxy${RESET}"
      read -rp "按回车键返回主菜单..."
      ;;

    2)
      # 卸载 MTProxy
      echo -e "\n${YELLOW}>>> 正在尝试卸载 MTProxy...${RESET}"
      if docker ps -a --format '{{.Names}}' | grep -q '^nginx-mtproxy$'; then
        docker rm -f nginx-mtproxy
        echo -e "${GREEN}MTProxy 容器已成功卸载。${RESET}"
      else
        echo -e "${YELLOW}未找到 nginx-mtproxy 容器，无需卸载。${RESET}"
      fi
      read -rp "按回车键返回主菜单..."
      ;;

    3)
      # 重启 MTProxy
      echo -e "\n${BLUE}>>> 正在重启 MTProxy...${RESET}"
      docker restart nginx-mtproxy
      echo -e "${GREEN}MTProxy 已重启成功。${RESET}"
      read -rp "按回车键返回主菜单..."
      ;;

    4)
      # 停止 MTProxy
      echo -e "\n${BLUE}>>> 正在停止 MTProxy...${RESET}"
      docker stop nginx-mtproxy
      echo -e "${YELLOW}MTProxy 已停止。${RESET}"
      read -rp "按回车键返回主菜单..."
      ;;

    5)
      # 启动 MTProxy
      echo -e "\n${BLUE}>>> 正在启动 MTProxy...${RESET}"
      docker start nginx-mtproxy
      echo -e "${GREEN}MTProxy 已启动成功。${RESET}"
      read -rp "按回车键返回主菜单..."
      ;;

    6)
      # 更新脚本
      echo -e "\n${BLUE}>>> 正在更新脚本...${RESET}"
      curl -o mtproxy_menu.sh https://raw.githubusercontent.com/dododook/mtproto-proxy-setup/main/mtproxy_menu.sh
      echo -e "${GREEN}✅ 脚本更新完成，请重新运行此脚本。${RESET}"
      exit 0
      ;;

    7)
      # 退出脚本
      echo -e "\n${GREEN}已退出脚本，再见！${RESET}"
      exit 0
      ;;

    *)
      # 无效选项
      echo -e "\n${RED}无效的选项！请重新输入 [1-7]。${RESET}"
      read -rp "按回车键返回主菜单..."
      ;;
  esac
done

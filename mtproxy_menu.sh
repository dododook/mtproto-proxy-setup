#!/bin/bash

# --- 颜色定义 ---
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
RESET='\033[0m'

# --- 菜单显示函数 ---
show_menu() {
  clear
  echo -e "${GREEN}==========================================${RESET}"
  echo -e "${GREEN}===    MTProxy 管理工具 v5.4.0dp   ===${RESET}"
  echo -e "${GREEN}==========================================${RESET}"
  echo -e "${YELLOW}作者：@yaoguangting  |  支持多种MTProxy实现 🍥${RESET}\n"
  echo -e "请选择您想要执行的操作："
  echo -e "  ${BLUE}1.${RESET} 安装 MTProxy (nginx-mtproxy)"
  echo -e "  ${BLUE}2.${RESET} 安装 MTG 高性能版本"
  echo -e "  ${BLUE}3.${RESET} 卸载 MTProxy"
  echo -e "  ${BLUE}4.${RESET} 重启 MTProxy"
  echo -e "  ${BLUE}5.${RESET} 停止 MTProxy"
  echo -e "  ${BLUE}6.${RESET} 启动 MTProxy"
  echo -e "  ${BLUE}7.${RESET} 更新脚本"
  echo -e "  ${BLUE}8.${RESET} 退出"
  echo -e "${GREEN}------------------------------------------${RESET}"
}

# --- 生成随机secret ---
generate_secret() {
  local ee_prefix=$1
  if [[ "$ee_prefix" =~ ^[yY]$ ]]; then
    echo "ee$(head -c 16 /dev/urandom | xxd -ps)"
  else
    head -c 16 /dev/urandom | xxd -ps
  fi
}

# --- 安装MTG高性能版本 ---
install_mtg() {
  echo -e "\n${YELLOW}>>> 正在准备安装 MTG 高性能版本...${RESET}"
  
  # 获取用户输入
  read -e -p "请输入连接端口 (默认: 443): " port
  [[ -z "$port" ]] && port="443"
  
  read -e -p "是否生成ee前缀的secret? (Y/N, 默认:N): " ee_secret
  [[ -z "$ee_secret" ]] && ee_secret="N"
  secret=$(generate_secret "$ee_secret")
  
  echo -e "\n请选择伪装域名："
  echo "  1. cloudfront.com (默认)"
  echo "  2. www.microsoft.com"
  echo "  3. www.cloudflare.com"
  echo "  4. www.google.com"
  echo "  5. 自定义域名"
  read -p "请输入选项 [1-5]: " domain_choice
  
  case $domain_choice in
    2) domain="www.microsoft.com" ;;
    3) domain="www.cloudflare.com" ;;
    4) domain="www.google.com" ;;
    5)
      read -rp "请输入自定义伪装域名: " domain
      ;;
    *) domain="cloudfront.com" ;;
  esac
  
  echo -e "\n${BLUE}>>> 正在检查并安装 Docker...${RESET}"
  if ! command -v docker >/dev/null 2>&1; then
    echo -e "${YELLOW}Docker 未安装，正在自动安装...${RESET}"
    bash <(curl -fsSL https://get.docker.com)
  else
    echo -e "${GREEN}您的系统已安装 Docker，跳过安装。${RESET}"
  fi
  
  echo -e "\n${BLUE}>>> 正在拉取并启动 MTG 容器...${RESET}"
  docker pull nineseconds/mtg
  docker run -d --name mtg --restart always \
    -p "$port:443" \
    -e MTG_SECRET="$secret" \
    -e MTG_FAKE_TLS_DOMAIN="$domain" \
    nineseconds/mtg
  
  public_ip=$(curl -s ipv4.ip.sb || curl -s ipinfo.io/ip)
  
  echo -e "\n${GREEN}================== 安装成功！ ==================${RESET}"
  echo -e "${BLUE}配置信息：${RESET}"
  echo -e "  服务器 IP：${YELLOW}$public_ip${RESET}"
  echo -e "  服务器端口：${YELLOW}$port${RESET}"
  echo -e "  MTG Secret：${YELLOW}$secret${RESET}"
  echo -e "  TG 一键链接：${YELLOW}tg://proxy?server=$public_ip&port=$port&secret=$secret${RESET}"
  echo -e "  或：${YELLOW}https://t.me/proxy?server=$public_ip&port=$port&secret=$secret${RESET}"
  echo -e "\n${YELLOW}提示：MTG 版本性能更高但功能较简单，不支持Web界面。${RESET}"
  echo -e "查看日志命令：${BLUE}docker logs mtg${RESET}"
  echo -e "查看状态命令：${BLUE}docker ps | grep mtg${RESET}"
  read -n 1 -s -r -p "按任意键返回主菜单..."
}

# --- 卸载函数 ---
uninstall_mtproxy() {
  echo -e "\n${YELLOW}>>> 请选择要卸载的版本:${RESET}"
  echo "  1. nginx-mtproxy (经典版)"
  echo "  2. mtg (高性能版)"
  echo "  3. 全部卸载"
  read -p "请输入选项 [1-3]: " uninstall_choice
  
  case $uninstall_choice in
    1)
      echo -e "\n${YELLOW}>>> 正在停止并删除 nginx-mtproxy 容器...${RESET}"
      if docker ps -a --format '{{.Names}}' | grep -q '^nginx-mtproxy$'; then
        docker stop nginx-mtproxy >/dev/null 2>&1
        docker rm nginx-mtproxy >/dev/null 2>&1
        echo -e "${GREEN}✅ nginx-mtproxy 容器已成功删除。${RESET}"
      else
        echo -e "${YELLOW}ℹ️ 未检测到 nginx-mtproxy 容器。${RESET}"
      fi
      ;;
    2)
      echo -e "\n${YELLOW}>>> 正在停止并删除 mtg 容器...${RESET}"
      if docker ps -a --format '{{.Names}}' | grep -q '^mtg$'; then
        docker stop mtg >/dev/null 2>&1
        docker rm mtg >/dev/null 2>&1
        echo -e "${GREEN}✅ mtg 容器已成功删除。${RESET}"
      else
        echo -e "${YELLOW}ℹ️ 未检测到 mtg 容器。${RESET}"
      fi
      ;;
    3)
      echo -e "\n${YELLOW}>>> 正在停止并删除所有MTProxy容器...${RESET}"
      if docker ps -a --format '{{.Names}}' | grep -q '^nginx-mtproxy$'; then
        docker stop nginx-mtproxy >/dev/null 2>&1
        docker rm nginx-mtproxy >/dev/null 2>&1
        echo -e "${GREEN}✅ nginx-mtproxy 容器已成功删除。${RESET}"
      fi
      if docker ps -a --format '{{.Names}}' | grep -q '^mtg$'; then
        docker stop mtg >/dev/null 2>&1
        docker rm mtg >/dev/null 2>&1
        echo -e "${GREEN}✅ mtg 容器已成功删除。${RESET}"
      fi
      if ! docker ps -a --format '{{.Names}}' | grep -q -E '^(nginx-mtproxy|mtg)$'; then
        echo -e "${YELLOW}ℹ️ 未检测到任何MTProxy容器。${RESET}"
      fi
      ;;
    *)
      echo -e "${RED}无效选项，取消卸载。${RESET}"
      return
      ;;
  esac

  read -rp "是否需要一并卸载 Docker 及其相关依赖？此操作会影响服务器上所有其他 Docker 容器！(Y/N): " remove_docker
  if [[ "$remove_docker" =~ ^[yY]$ ]]; then
    echo -e "\n${BLUE}>>> 正在尝试卸载 Docker...${RESET}"
    if command -v apt-get >/dev/null; then
      apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >/dev/null 2>&1
      apt-get autoremove -y >/dev/null 2>&1
    elif command -v yum >/dev/null; then
      yum remove -y docker-ce docker-ce-cli containerd.io >/dev/null 2>&1
    elif command -v dnf >/dev/null; then
      dnf remove -y docker-ce docker-ce-cli containerd.io >/dev/null 2>&1
    else
      echo -e "${RED}⚠️ 未知的操作系统类型，无法自动卸载 Docker。请手动执行卸载。${RESET}"
    fi

    read -rp "是否同时删除 Docker 数据目录（/var/lib/docker）？这将永久删除所有镜像和容器数据！(Y/N): " remove_data
    if [[ "$remove_data" =~ ^[yY]$ ]]; then
      echo -e "${RED}>>> 正在删除 Docker 数据目录...${RESET}"
      rm -rf /var/lib/docker
      echo -e "${GREEN}✅ Docker 数据目录已删除。${RESET}"
    fi

    echo -e "${GREEN}✅ Docker 及其依赖已成功卸载。${RESET}"
  fi
}

# --- 容器管理函数 ---
manage_container() {
  local action=$1
  local container_name=$2
  
  if ! docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
    echo -e "${RED}错误：未找到 ${container_name} 容器${RESET}"
    return 1
  fi
  
  case $action in
    restart)
      echo -e "🔄 正在重启 ${container_name} 容器..."
      docker restart "$container_name" >/dev/null
      echo -e "${GREEN}✅ 重启完成！${RESET}"
      ;;
    stop)
      echo -e "⏸️ 正在停止 ${container_name} 容器..."
      docker stop "$container_name" >/dev/null
      echo -e "${GREEN}✅ 停止完成！${RESET}"
      ;;
    start)
      echo -e "▶️ 正在启动 ${container_name} 容器..."
      docker start "$container_name" >/dev/null
      echo -e "${GREEN}✅ 启动完成！${RESET}"
      ;;
    *)
      echo -e "${RED}未知操作${RESET}"
      return 1
      ;;
  esac
  sleep 1
}

# --- 主程序循环 ---
while true; do
  show_menu
  read -rp "请输入选项 [1-8]: " menu
  echo ""

  case $menu in
    1)
      # 原有nginx-mtproxy安装代码保持不变
      # ...
      ;;
    2)
      install_mtg
      ;;
    3)
      uninstall_mtproxy
      read -n 1 -s -r -p "按任意键返回主菜单..."
      echo ""
      ;;
    4)
      echo -e "请选择要重启的容器:"
      echo "  1. nginx-mtproxy (经典版)"
      echo "  2. mtg (高性能版)"
      read -p "请输入选项 [1-2]: " restart_choice
      case $restart_choice in
        1) manage_container "restart" "nginx-mtproxy" ;;
        2) manage_container "restart" "mtg" ;;
        *) echo -e "${RED}无效选项${RESET}" ;;
      esac
      ;;
    5)
      echo -e "请选择要停止的容器:"
      echo "  1. nginx-mtproxy (经典版)"
      echo "  2. mtg (高性能版)"
      read -p "请输入选项 [1-2]: " stop_choice
      case $stop_choice in
        1) manage_container "stop" "nginx-mtproxy" ;;
        2) manage_container "stop" "mtg" ;;
        *) echo -e "${RED}无效选项${RESET}" ;;
      esac
      ;;
    6)
      echo -e "请选择要启动的容器:"
      echo "  1. nginx-mtproxy (经典版)"
      echo "  2. mtg (高性能版)"
      read -p "请输入选项 [1-2]: " start_choice
      case $start_choice in
        1) manage_container "start" "nginx-mtproxy" ;;
        2) manage_container "start" "mtg" ;;
        *) echo -e "${RED}无效选项${RESET}" ;;
      esac
      ;;
    7)
      echo -e "🔄 正在更新脚本..."
      SCRIPT_PATH=$(readlink -f "$0")
      curl -fsSL https://raw.githubusercontent.com/dododook/mtproto-proxy-setup/main/mtproxy_menu.sh -o "$SCRIPT_PATH"
      echo -e "${GREEN}✅ 脚本已更新，正在重新加载...${RESET}"
      exec "$SCRIPT_PATH"
      ;;
    8)
      echo -e "${YELLOW}再见，有缘再会。${RESET}"
      exit 0
      ;;
    *)
      echo -e "${YELLOW}无效选项，请重新选择。${RESET}"
      sleep 1
      ;;
  esac
done

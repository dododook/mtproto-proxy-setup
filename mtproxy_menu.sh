#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

# 主菜单
function show_menu() {
    clear
    echo -e "${GREEN}=========================================="
    echo -e "===        MTProxy NGINX 管理工具 v5.3.3     ==="
    echo -e "==========================================${RESET}"
    echo -e "${YELLOW}作者：@yaoguangting ｜ 基于 ellermister/nginx-mtproxy 🍥${RESET}\n"

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
    case $menu in
        1) install_mtproxy ;;
        2) uninstall_mtproxy ;;
        3) restart_mtproxy ;;
        4) stop_mtproxy ;;
        5) start_mtproxy ;;
        6) update_script ;;
        7) exit 0 ;;
        *) echo "无效选项，请重试。" && sleep 1 && show_menu ;;
    esac
}

# 安装
function install_mtproxy() {
    echo -e "\n>>> 正在准备安装 MTProxy..."

    read -e -p "请输入连接端口 (默认: 443): " port
    [[ -z "${port}" ]] && port="443"

    read -e -p "请输入密码 (默认: 自动生成): " secret
    if [[ -z "${secret}" ]]; then
        secret=$(cat /proc/sys/kernel/random/uuid | sed 's/-//g')
        echo -e "  已自动生成密码：${secret}"
    fi

    echo -e "\n请选择伪装域名（默认: azure.microsoft.com）:"
    echo "  1. azure.microsoft.com"
    echo "  2. www.bing.com"
    echo "  3. www.microsoft.com"
    echo "  4. www.cloudflare.com"
    read -rp "请输入选项 [1-4]，或直接输入自定义域名: " domain_choice
    case "$domain_choice" in
      1|"") domain="azure.microsoft.com" ;;
      2) domain="www.bing.com" ;;
      3) domain="www.microsoft.com" ;;
      4) domain="www.cloudflare.com" ;;
      *) domain="$domain_choice" ;;
    esac

    read -rp "是否需要设置 TAG 标签? (y/N): " chrony_install
    [[ -z ${chrony_install} ]] && chrony_install="N"
    case $chrony_install in
        [yY][eE][sS] | [yY])
            read -e -p "请输入TAG: " tag
            if [[ -z "${tag}" ]]; then
                echo "请输入TAG"
                return
            fi
            echo -e ">>> 正在安装 Docker..."
            echo y | bash <(curl -L -s https://raw.githubusercontent.com/xb0or/nginx-mtproxy/main/docker.sh)
            echo -e ">>> 正在安装 nginx-mtproxy..."
            docker run --name nginx-mtproxy -d -e tag="$tag" -e secret="$secret" -e domain="$domain" -p 80:80 -p $port:$port ellermister/nginx-mtproxy:latest
            ;;
        *)
            echo -e ">>> 正在安装 Docker..."
            echo y | bash <(curl -L -s https://cdn.jsdelivr.net/gh/xb0or/nginx-mtproxy@main/docker.sh)
            echo -e ">>> 正在安装 nginx-mtproxy..."
            docker run --name nginx-mtproxy -d -e secret="$secret" -e domain="$domain" -p 80:80 -p $port:$port ellermister/nginx-mtproxy:latest
            ;;
    esac

    echo -e "\n>>> 正在设置容器开机自启..."
    docker update --restart=always nginx-mtproxy

    public_ip=$(curl -s http://ipv4.icanhazip.com)
    [ -z "$public_ip" ] && public_ip=$(curl -s ipinfo.io/ip --ipv4)
    domain_hex=$(xxd -pu <<< "$domain" | sed 's/0a//g')
    client_secret="ee${secret}${domain_hex}"

    echo -e "${GREEN}============== 安装完成 ==============${RESET}"
    echo -e "服务器IP：${RED}$public_ip${RESET}"
    echo -e "服务器端口：${RED}$port${RESET}"
    echo -e "MTProxy Secret：${RED}$client_secret${RESET}"
    echo -e "TG认证地址：http://${public_ip}:80/add.php"
    echo -e "TG一键链接：tg://proxy?server=${public_ip}&port=${port}&secret=${client_secret}"
    echo -e "${YELLOW}注意：如果你使用的是默认端口 443，日志中可能显示 8443，为镜像内部映射，请以此处提示为准。${RESET}"
    echo -e "如需查看日志，请执行：docker logs nginx-mtproxy"
    read -rp "按 Enter 返回主菜单..." temp
    show_menu
}

function uninstall_mtproxy() {
    echo -e ">>> 正在停止并删除 MTProxy 容器..."
    docker stop nginx-mtproxy && docker rm nginx-mtproxy
    echo -e "${GREEN}>>> MTProxy 已卸载完成。${RESET}"
    read -rp "按 Enter 返回主菜单..." temp
    show_menu
}

function restart_mtproxy() {
    docker restart nginx-mtproxy
    echo -e "${GREEN}>>> 容器已重启${RESET}"
    sleep 1
    show_menu
}

function stop_mtproxy() {
    docker stop nginx-mtproxy
    echo -e "${GREEN}>>> 容器已停止${RESET}"
    sleep 1
    show_menu
}

function start_mtproxy() {
    docker start nginx-mtproxy
    echo -e "${GREEN}>>> 容器已启动${RESET}"
    sleep 1
    show_menu
}

function update_script() {
    echo -e "${YELLOW}🔄 正在更新脚本...${RESET}"
    curl -sSL -o "$0" https://raw.githubusercontent.com/dododook/mtproto-proxy-setup/main/mtproxy_menu.sh
    echo -e "${GREEN}✅ 脚本已更新，正在重新加载...${RESET}"
    sleep 1
    exec "$0"
}

show_menu

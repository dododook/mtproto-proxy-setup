#!/bin/bash
# Author: @yaoguangting
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin

GITHUB_RAW="https://raw.githubusercontent.com/dododook/mtproto-proxy-setup/main/mtproxy_menu.sh"
SCRIPT_PATH=$(readlink -f "$0")

update_script() {
    echo ""
    echo "📥 正在更新脚本..."
    tmpfile=$(mktemp)
    if curl -fsSL "$GITHUB_RAW" -o "$tmpfile"; then
        mv "$tmpfile" "$SCRIPT_PATH"
        chmod +x "$SCRIPT_PATH"
        echo "✅ 脚本已更新为最新版本，正在重启..."
        exec "$SCRIPT_PATH"
    else
        echo "❌ 脚本更新失败，请检查网络或链接地址。"
        rm -f "$tmpfile"
    fi
}

install_mtproxy() {
    echo ""
    read -e -p "请输入链接端口(默认443): " port
    [[ -z "$port" ]] && port="443"

    echo ""
    read -e -p "请输入密码(默认随机生成): " secret
    [[ -z "$secret" ]] && secret=$(cat /proc/sys/kernel/random/uuid | sed 's/-//g')
    echo "密码：$secret"

    echo ""
    echo "请选择伪装域名："
    echo "  1. azure.microsoft.com (默认)"
    echo "  2. www.microsoft.com"
    echo "  3. www.cloudflare.com"
    echo "  4. cdn.jsdelivr.net"
    echo "  5. www.google.com"
    echo "  6. www.bing.com"
    echo "  7. www.youtube.com"
    read -p "请输入选项 [1-7]: " domain_choice
    case $domain_choice in
        2) domain="www.microsoft.com" ;;
        3) domain="www.cloudflare.com" ;;
        4) domain="cdn.jsdelivr.net" ;;
        5) domain="www.google.com" ;;
        6) domain="www.bing.com" ;;
        7) domain="www.youtube.com" ;;
        *) domain="azure.microsoft.com" ;;
    esac

    echo ""
    read -rp "你需要TAG标签吗 (Y/N, 默认N): " tag_confirm
    [[ -z "$tag_confirm" ]] && tag_confirm="N"

    echo ""
    echo "🧱 正在安装依赖 Docker..."
    echo y | bash <(curl -Ls https://cdn.jsdelivr.net/gh/xb0or/nginx-mtproxy@main/docker.sh)

    if [[ "$tag_confirm" =~ ^[yY]$ ]]; then
        echo ""
        read -e -p "请输入TAG: " tag
        docker run --name nginx-mtproxy -d -e tag="$tag" -e secret="$secret" -e domain="$domain" -p 80:80 -p $port:8443 ellermister/nginx-mtproxy:latest
    else
        docker run --name nginx-mtproxy -d -e secret="$secret" -e domain="$domain" -p 80:80 -p $port:8443 ellermister/nginx-mtproxy:latest
    fi

    echo ""
    echo "正在设置容器开机自启..."
    docker update --restart=always nginx-mtproxy

    public_ip=$(curl -s http://ipv4.icanhazip.com)
    [ -z "$public_ip" ] && public_ip=$(curl -s ipinfo.io/ip --ipv4)
    domain_hex=$(echo -n "$domain" | xxd -pu | tr -d '\n')
    client_secret="ee${secret}${domain_hex}"

    echo ""
    echo "============== 安装完成 =============="
    echo -e "服务器IP：\033[32m$public_ip\033[0m"
    echo -e "服务器端口：\033[32m$port\033[0m"
    echo -e "MTProxy Secret：\033[33m$client_secret\033[0m"
    echo -e "TG认证地址：http://$public_ip:80/add.php"
    echo -e "TG一键链接：\033[36mtg://proxy?server=${public_ip}&port=${port}&secret=${client_secret}\033[0m"
    echo -e "备用链接：https://t.me/proxy?server=${public_ip}&port=${port}&secret=${client_secret}"
    echo -e "如需查看日志，请执行：\033[34mdocker logs nginx-mtproxy\033[0m"
    echo -e "⚠️ 注意：请以此处输出为准，docker logs 内部端口可能显示为 8443（容器内端口）"
}

uninstall_mtproxy() {
    echo ""
    echo "⚠️ 即将删除 nginx-mtproxy 容器..."
    docker stop nginx-mtproxy && docker rm nginx-mtproxy
    read -rp "是否一并卸载 Docker？(y/N): " remove_docker
    [[ "$remove_docker" =~ ^[yY]$ ]] && apt-get remove --purge -y docker docker-engine docker.io containerd runc
    echo "✅ 卸载完成。"
}

show_menu() {
    clear
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RESET='\033[0m'

    echo -e "${GREEN}========== MTProxy NGINX 管理工具 ==========${RESET}"
    echo -e "${YELLOW}作者：@yaoguangting ｜ 基于 ellermister/nginx-mtproxy 🍥${RESET}\n"

    echo -e "请选择操作："
    echo -e "1. 安装 MTProxy"
    echo -e "2. 卸载 MTProxy"
    echo -e "3. 退出"
    echo -e "4. 更新脚本"
}

while true; do
    show_menu
    read -rp "请输入选项 [1-4]: " choice
    case $choice in
        1) install_mtproxy ;;
        2) uninstall_mtproxy ;;
        3) exit 0 ;;
        4) update_script ;;
        *) echo "无效输入，请重新选择。" ;;
    esac
    echo ""
    read -rp "按回车键返回菜单..."
done

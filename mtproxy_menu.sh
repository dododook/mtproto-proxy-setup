#!/bin/bash
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
RESET='\033[0m'

clear
echo -e "${GREEN}=========================================="
echo -e "===        MTProxy NGINX 管理工具 v5.3.5      ==="
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
1)
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
    read -rp "请输入对应编号或自定义域名: " domain_input

    case "$domain_input" in
        1|"") domain="azure.microsoft.com" ;;
        2) domain="www.bing.com" ;;
        3) domain="www.microsoft.com" ;;
        4) domain="www.cloudflare.com" ;;
        *) domain="$domain_input" ;;
    esac

    read -rp "是否需要设置 TAG 标签? (y/N): " tag_confirm
    [[ -z ${tag_confirm} ]] && tag_confirm="N"
    case $tag_confirm in
        [yY][eE][sS]|[yY])
            read -e -p "请输入 TAG: " tag
            if [[ -z "${tag}" ]]; then
                echo "请输入 TAG"
                exit 1
            fi
            ;;
    esac

    # 检查端口是否被占用
    if lsof -i:"$port" >/dev/null 2>&1; then
        echo -e "${RED}⚠️ 警告：端口 $port 已被占用，请更换其他端口！${RESET}"
        exit 1
    fi

    echo -e "\n>>> 正在安装 Docker..."
    curl -fsSL https://get.docker.com | bash

    echo -e "\n>>> 正在安装 nginx-mtproxy..."
    if [[ -n "$tag" ]]; then
        docker run --name nginx-mtproxy -d -e tag="$tag" -e secret="$secret" -e domain="$domain" -p 80:80 -p $port:$port ellermister/nginx-mtproxy:latest
    else
        docker run --name nginx-mtproxy -d -e secret="$secret" -e domain="$domain" -p 80:80 -p $port:$port ellermister/nginx-mtproxy:latest
    fi

    docker update --restart=always nginx-mtproxy

    public_ip=$(curl -s ipv4.icanhazip.com || curl -s ipinfo.io/ip)
    domain_hex=$(echo -n "$domain" | xxd -pu | tr -d '\n')
    client_secret="ee${secret}${domain_hex}"

    echo -e "\n============== 安装完成 =============="
    echo -e "服务器IP：${RED}$public_ip${RESET}"
    echo -e "服务器端口：${RED}$port${RESET}"
    echo -e "MTProxy Secret：${RED}$client_secret${RESET}"
    echo -e "TG认证地址：http://$public_ip:80/add.php"
    echo -e "TG一键链接: tg://proxy?server=${public_ip}&port=${port}&secret=${client_secret}"
    echo -e "${YELLOW}注意：如果你使用的是默认端口 443，日志中可能显示 8443，为镜像内部映射，请以此处提示为准。${RESET}"
    echo -e "如需查看日志，请执行：docker logs nginx-mtproxy"
    ;;

2)
    echo -e "\n>>> 正在卸载 MTProxy 容器..."
    docker stop nginx-mtproxy >/dev/null 2>&1
    docker rm nginx-mtproxy >/dev/null 2>&1
    echo -e ">>> 卸载完成。"
    ;;

3)
    echo -e "\n>>> 正在重启 MTProxy..."
    docker restart nginx-mtproxy
    echo -e ">>> 已重启。"
    ;;

4)
    echo -e "\n>>> 正在停止 MTProxy..."
    docker stop nginx-mtproxy
    echo -e ">>> 已停止。"
    ;;

5)
    echo -e "\n>>> 正在启动 MTProxy..."
    docker start nginx-mtproxy
    echo -e ">>> 已启动。"
    ;;

6)
    echo -e "🔄 正在更新脚本..."
    curl -fsSL https://raw.githubusercontent.com/dododook/mtproto-proxy-setup/main/mtproxy_menu.sh -o "$0"
    echo -e "✅ 脚本已更新为最新版本。\n"
    exec "$0"
    ;;

7)
    echo -e "\n已退出脚本。"
    exit 0
    ;;

*)
    echo -e "${RED}无效的选项，请重新运行脚本。${RESET}"
    ;;
esac

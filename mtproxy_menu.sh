#!/bin/bash
RED='\033[0;31m'
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
echo -e "5. 重启 MTProxy"
echo -e "6. 停止 MTProxy"
echo -e "7. 启动 MTProxy"
read -rp "请输入选项 [1-7]: " menu

case $menu in
    1)
        read -e -p "请输入链接端口(默认443): " port
        if [[ -z "${port}" ]]; then
        port="443"
        fi

        # 检查端口是否被占用
        if ss -tuln | grep -q ":$port "; then
            echo -e "\n⚠️ 警告：端口 $port 已被占用，请更换其他端口或释放该端口。"
            read -rp "是否继续安装？(y/N): " confirm_install
            [[ ! "$confirm_install" =~ ^[yY]$ ]] && echo "⛔ 已取消安装。" && return
        fi

        read -e -p "请输入密码(默认随机生成): " secret
        if [[ -z "${secret}" ]]; then
        secret=$(cat /proc/sys/kernel/random/uuid | sed 's/-//g')
        echo -e "密码：$secret"
        fi

        read -e -p "请输入伪装域名(默认azure.microsoft.com): " domain
        if [[ -z "${domain}" ]]; then
        domain="azure.microsoft.com"
        fi

        read -rp "你需要TAG标签吗 (Y/N): " chrony_install
        [[ -z ${chrony_install} ]] && chrony_install="N"

        case $chrony_install in
        [yY][eE][sS] | [yY])
            read -e -p "请输入TAG: " tag
            if [[ -z "${tag}" ]]; then
            echo "请输入TAG"
            fi
            echo -e "正在安装依赖: Docker..."
            echo y | bash <(curl -Ls https://raw.githubusercontent.com/xb0or/nginx-mtproxy/main/docker.sh)
            echo -e "正在安装 nginx-mtproxy..."
            docker run --name nginx-mtproxy -d -e tag="$tag" -e secret="$secret" -e domain="$domain" -p 80:80 -p $port:$port ellermister/nginx-mtproxy:latest
            ;;
        *)
            echo -e "正在安装依赖: Docker..."
            echo y | bash <(curl -Ls https://cdn.jsdelivr.net/gh/xb0or/nginx-mtproxy@main/docker.sh)
            echo -e "正在安装 nginx-mtproxy..."
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
        echo -e "MTProxy Secret：\033[31m$client_secret\033[0m"
        echo -e "TG认证地址：http://${public_ip}:80/add.php"
        echo -e "TG一键链接：tg://proxy?server=${public_ip}&port=${port}&secret=${client_secret}"
        echo -e "${YELLOW}注意：如果你使用的是默认端口 443，日志中可能显示 8443，为镜像内部映射，请以此处提示为准。${RESET}"
        echo -e "如需查看日志，请执行：docker logs nginx-mtproxy"
        ;;
    2)
        echo -e "${RED}即将卸载 MTProxy...${RESET}"
        docker stop nginx-mtproxy && docker rm nginx-mtproxy
        echo -e "✅ 已卸载 nginx-mtproxy 容器。"
        ;;
    3)
        echo "已退出。"
        exit 0
        ;;
    4)
        echo -e "🔄 正在更新脚本..."
        curl -o mtproxy_menu.sh https://raw.githubusercontent.com/dododook/mtproto-proxy-setup/main/mtproxy_menu.sh && chmod +x mtproxy_menu.sh
        echo "✅ 脚本已更新，请重新运行。"
        ;;
    5)
        restart_mtproxy
        ;;
    6)
        stop_mtproxy
        ;;
    7)
        start_mtproxy
        ;;
    *)
        echo "❌ 无效选项。"
        ;;
esac

restart_mtproxy() {
    echo -e "\n🔄 正在重启 nginx-mtproxy 容器..."
    docker restart nginx-mtproxy && echo "✅ 重启完成。"
}

stop_mtproxy() {
    echo -e "\n⛔ 正在停止 nginx-mtproxy 容器..."
    docker stop nginx-mtproxy && echo "✅ 已停止。"
}

start_mtproxy() {
    echo -e "\n▶️ 正在启动 nginx-mtproxy 容器..."
    docker start nginx-mtproxy && echo "✅ 已启动。"
}

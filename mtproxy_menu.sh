#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin

# 脚本版本
script_version="v4"
script_repo="https://raw.githubusercontent.com/dododook/mtproto-proxy-setup/main/mtproxy_menu.sh"

# 获取公网 IP
get_ip() {
    ip=$(curl -s http://ipv4.icanhazip.com)
    [[ -z "$ip" ]] && ip=$(curl -s ipinfo.io/ip --ipv4)
    echo "$ip"
}

# 安装函数
install_mtproxy() {
    read -e -p "\n请输入链接端口(默认443): " port
    [[ -z "$port" ]] && port="443"

    read -e -p "请输入密码(默认随机生成): " secret
    if [[ -z "$secret" ]]; then
        secret=$(cat /proc/sys/kernel/random/uuid | sed 's/-//g')
        echo -e "生成的密码为：\033[32m$secret\033[0m"
    fi

    echo -e "\n可选伪装域名："
    echo "  1. azure.microsoft.com (默认)"
    echo "  2. www.microsoft.com"
    echo "  3. www.bing.com"
    read -e -p "请输入伪装域名(默认1): " domain_choice
    case $domain_choice in
        2) domain="www.microsoft.com";;
        3) domain="www.bing.com";;
        *) domain="azure.microsoft.com";;
    esac

    read -rp "你需要TAG标签吗(Y/N, 默认N): " tag_choice
    [[ -z "$tag_choice" ]] && tag_choice="N"

    if [[ $tag_choice =~ ^[Yy]$ ]]; then
        read -e -p "请输入TAG: " tag
        [[ -z "$tag" ]] && { echo "TAG不能为空，已取消安装。"; return; }
    fi

    echo -e "\n正在安装依赖 Docker..."
    echo y | bash <(curl -L -s https://cdn.jsdelivr.net/gh/xb0or/nginx-mtproxy@main/docker.sh)

    echo -e "正在安装 nginx-mtproxy 容器..."
    docker rm -f nginx-mtproxy >/dev/null 2>&1
    if [[ $tag_choice =~ ^[Yy]$ ]]; then
        docker run --name nginx-mtproxy -d \
        -e tag="$tag" \
        -e secret="$secret" \
        -e domain="$domain" \
        -p 80:80 -p $port:8443 \
        ellermister/nginx-mtproxy:latest
    else
        docker run --name nginx-mtproxy -d \
        -e secret="$secret" \
        -e domain="$domain" \
        -p 80:80 -p $port:8443 \
        ellermister/nginx-mtproxy:latest
    fi

    echo -e "设置容器开机自启..."
    docker update --restart=always nginx-mtproxy

    # 生成一键链接
    public_ip=$(get_ip)
    domain_hex=$(echo -n "$domain" | xxd -pu | tr -d '\n')
    client_secret="ee${secret}${domain_hex}"

    echo -e "\n============== 安装完成 =============="
    echo -e "服务器IP：\033[31m$public_ip\033[0m"
    echo -e "服务器端口：\033[31m$port\033[0m"
    echo -e "MTProxy Secret：\033[32m$client_secret\033[0m"
    echo -e "TG认证地址：\033[36mhttp://$public_ip:80/add.php\033[0m"
    echo -e "TG一键链接：\033[32mtg://proxy?server=${public_ip}&port=${port}&secret=${client_secret}\033[0m"
    echo -e "备用链接：https://t.me/proxy?server=${public_ip}&port=${port}&secret=${client_secret}"
    echo -e "\n注意：如果你使用的是默认端口 443，日志中可能显示 8443，为镜像内部映射，请以此处提示为准。"
    echo -e "如需查看日志，请执行：\033[33mdocker logs nginx-mtproxy\033[0m"
    echo -e "======================================="
}

# 卸载函数
uninstall_mtproxy() {
    echo -e "\n正在停止并删除 nginx-mtproxy 容器..."
    docker rm -f nginx-mtproxy
    read -rp "是否同时卸载 Docker? (Y/N, 默认N): " remove_docker
    [[ $remove_docker =~ ^[Yy]$ ]] && bash <(curl -sSL https://get.docker.com/) --uninstall
    echo -e "卸载完成。"
}

# 自我更新
self_update() {
    echo -e "\n正在从 GitHub 获取最新脚本..."
    curl -fsSL "$script_repo" -o "$0.tmp"
    if [[ $? -eq 0 ]]; then
        mv "$0.tmp" "$0"
        chmod +x "$0"
        echo -e "脚本已更新为最新版本，正在重新启动..."
        exec "$0"
    else
        echo -e "脚本更新失败，请稍后重试。"
    fi
}

# 主菜单
while true; do
    clear
    echo -e "\n=========== MTProxy 管理脚本 ($script_version) ==========="
    echo -e "1. 安装 MTProxy"
    echo -e "2. 卸载 MTProxy"
    echo -e "3. 退出"
    echo -e "4. 更新本脚本"
    echo -e "===================================================="
    read -rp "请输入选项 [1-4]: " opt
    case "$opt" in
        1) install_mtproxy;;
        2) uninstall_mtproxy;;
        3) exit 0;;
        4) self_update;;
        *) echo "无效选项，请重新输入。"; sleep 1;;
    esac
done

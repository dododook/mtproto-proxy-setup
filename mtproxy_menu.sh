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
    echo -e "${GREEN}===    MTProxy/MTG 管理工具 v5.3.9gm    ===${RESET}"
    echo -e "${GREEN}==========================================${RESET}"
    echo -e "${YELLOW}作者：@yaoguangting  |  基于 Docker 部署 🍥${RESET}\n"
    echo -e "请选择您想要执行的操作："
    echo -e "  ${BLUE}1.${RESET} 安装 MTProxy/MTG"
    echo -e "  ${BLUE}2.${RESET} 卸载 MTProxy/MTG"
    echo -e "  ${BLUE}3.${RESET} 重启 MTProxy/MTG"
    echo -e "  ${BLUE}4.${RESET} 停止 MTProxy/MTG"
    echo -e "  ${BLUE}5.${RESET} 启动 MTProxy/MTG"
    echo -e "  ${BLUE}6.${RESET} 更新脚本"
    echo -e "  ${BLUE}7.${RESET} 退出"
    echo -e "${GREEN}------------------------------------------${RESET}"
}

# --- 经典版本安装函数 (从你的代码中提取) ---
install_classic() {
    echo -e "\n${YELLOW}>>> 正在准备安装经典版本（nginx-mtproxy）...${RESET}"
    read -e -p "请输入连接端口 (默认: 443): " port
    [[ -z "$port" ]] && port="443"

    read -e -p "请输入密码 (默认: 自动生成): " secret
    if [[ -z "$secret" ]]; then
        secret=$(cat /proc/sys/kernel/random/uuid | sed 's/-//g')
        echo -e "  ${GREEN}已自动生成密码：$secret${RESET}"
    fi

    echo ""
    echo "请选择伪装域名："
    echo "  1. azure.microsoft.com (默认)"
    echo "  2. www.microsoft.com"
    echo "  3. www.cloudflare.com"
    echo "  4. cdn.jsdelivr.net"
    echo "  5. www.google.com"
    echo "  6. www.bing.com"
    echo "  7. www.youtube.com"
    echo "  8. 自定义域名"
    read -p "请输入选项 [1-8]: " domain_choice
    case $domain_choice in
        2) domain="www.microsoft.com" ;;
        3) domain="www.cloudflare.com" ;;
        4) domain="cdn.jsdelivr.net" ;;
        5) domain="www.google.com" ;;
        6) domain="www.bing.com" ;;
        7) domain="www.youtube.com" ;;
        8)
            read -rp "请输入自定义伪装域名: " domain
            ;;
        *) domain="azure.microsoft.com" ;;
    esac

    echo -e "\n${BLUE}>>> 正在检查并安装 Docker...${RESET}"
    if ! command -v docker >/dev/null 2>&1; then
        echo -e "${YELLOW}Docker 未安装，正在自动安装...${RESET}"
        bash <(curl -fsSL https://get.docker.com)
    else
        echo -e "${GREEN}您的系统已安装 Docker，跳过安装。${RESET}"
    fi

    echo -e "\n${BLUE}>>> 正在拉取并启动 nginx-mtproxy 容器...${RESET}"
    while true; do
        read -rp "是否需要设置 TAG 标签? (Y/N，默认: N): " tag_enable
        [[ -z "$tag_enable" ]] && tag_enable="N"
        if [[ $tag_enable =~ ^[yY]$ ]]; then
            read -e -p "请输入 TAG 标签: " tag
            if [[ -z "$tag" ]]; then
                echo -e "${RED}错误：TAG 不能为空，请重新输入。${RESET}"
            else
                docker run --name nginx-mtproxy -d \
                    -e "tag=$tag" -e "secret=$secret" -e "domain=$domain" \
                    -p 80:80 -p "$port:$port" ellermister/nginx-mtproxy:latest
                break
            fi
        else
            docker run --name nginx-mtproxy -d \
                -e "secret=$secret" -e "domain=$domain" \
                -p 80:80 -p "$port:$port" ellermister/nginx-mtproxy:latest
            break
        fi
    done

    echo -e "\n${BLUE}>>> 正在设置容器开机自启...${RESET}"
    docker update --restart=always nginx-mtproxy

    public_ip=$(curl -s ipv4.ip.sb || curl -s ipinfo.io/ip)
    domain_hex=$(echo -n "$domain" | xxd -ps | tr -d '\n')
    client_secret="ee${secret}${domain_hex}"

    echo -e "\n${GREEN}================== 安装成功！ ==================${RESET}"
    echo -e "${BLUE}配置信息：${RESET}"
    echo -e "  服务器 IP：${YELLOW}$public_ip${RESET}"
    echo -e "  服务器端口：${YELLOW}$port${RESET}"
    echo -e "  MTProxy Secret：${YELLOW}$client_secret${RESET}"
    echo -e "  TG 认证地址：${YELLOW}http://$public_ip:80/add.php${RESET}"
    echo -e "  TG 一键链接：${YELLOW}tg://proxy?server=$public_ip&port=$port&secret=$client_secret${RESET}"
    echo -e "\n${YELLOW}提示：如果日志显示 8443，那是镜像内部端口，请以此处显示的端口为准。${RESET}"
    echo -e "查看日志命令：${BLUE}docker logs nginx-mtproxy${RESET}"
    echo -e "查看状态命令：${BLUE}docker ps | grep nginx-mtproxy${RESET}"
}

# --- 新增：MTG 高性能版本安装函数 ---
install_mtg() {
    echo -e "\n${YELLOW}>>> 正在准备安装 MTG 高性能版本（nineseconds/mtg）...${RESET}"
    
    # 获取端口和伪装域名
    read -e -p "请输入 MTG 代理端口 (默认: 443): " mtg_port
    [[ -z "$mtg_port" ]] && mtg_port="443"
    
    read -e -p "请输入伪装域名 (例如: www.google.com): " mtg_hostname
    [[ -z "$mtg_hostname" ]] && mtg_hostname="www.google.com"
    
    # 自动生成 Secret
    generate_mtg_secret
    
    echo -e "\n${BLUE}>>> 正在检查并安装 Docker...${RESET}"
    if ! command -v docker >/dev/null 2>&1; then
        echo -e "${YELLOW}Docker 未安装，正在自动安装...${RESET}"
        bash <(curl -fsSL https://get.docker.com)
    else
        echo -e "${GREEN}您的系统已安装 Docker，跳过安装。${RESET}"
    fi

    echo -e "\n${BLUE}>>> 正在拉取 nineseconds/mtg 镜像...${RESET}"
    docker pull nineseconds/mtg:latest

    echo -e "\n${BLUE}>>> 正在运行 MTG 容器...${RESET}"
    docker run -d \
        --name mtg \
        --restart=always \
        -p ${mtg_port}:443 \
        -e SECRET=${secret_with_ee} \
        -e HOSTNAME=${mtg_hostname} \
        nineseconds/mtg:latest

    echo -e "\n${BLUE}>>> 正在检查容器状态...${RESET}"
    sleep 5
    if docker ps | grep -q "mtg"; then
        echo -e "${GREEN}✅ MTG 容器已成功启动！${RESET}"
        output_mtg_info
    else
        echo -e "${RED}⚠️ MTG 容器启动失败，请检查日志。${RESET}"
        echo -e "查看日志命令：${BLUE}docker logs mtg${RESET}"
    fi
}

# --- 新增：MTG Secret 生成函数 ---
generate_mtg_secret() {
    random_secret=$(openssl rand -hex 16)
    secret_with_ee="ee${random_secret}"
    echo -e "  ${GREEN}已自动生成 Secret：${secret_with_ee}${RESET}"
}

# --- 新增：MTG 部署信息输出函数 ---
output_mtg_info() {
    public_ip=$(curl -s ipv4.ip.sb || curl -s ipinfo.io/ip)
    encoded_secret=$(echo -n ${secret_with_ee} | base64)
    proxy_link="tg://proxy?server=${public_ip}&port=${mtg_port}&secret=${encoded_secret}"

    echo -e "\n${GREEN}================== MTG 安装成功！ ==================${RESET}"
    echo -e "${BLUE}配置信息：${RESET}"
    echo -e "  服务器 IP：${YELLOW}$public_ip${RESET}"
    echo -e "  服务器端口：${YELLOW}$mtg_port${RESET}"
    echo -e "  Secret：${YELLOW}$secret_with_ee${RESET}"
    echo -e "  伪装域名：${YELLOW}$mtg_hostname${RESET}"
    echo -e "\n  ${BLUE}TG 一键链接：${YELLOW}${proxy_link}${RESET}"
    echo -e "\n${YELLOW}提示：MTG 代理已部署。${RESET}"
    echo -e "查看日志命令：${BLUE}docker logs mtg${RESET}"
    echo -e "查看状态命令：${BLUE}docker ps | grep mtg${RESET}"
}

# --- 卸载函数 (增加 MTG 兼容性) ---
uninstall_mtproxy() {
    echo -e "\n${YELLOW}>>> 正在停止并删除 MTProxy/MTG 容器...${RESET}"
    CONTAINER_NAME=""
    if docker ps -a --format '{{.Names}}' | grep -q '^nginx-mtproxy$'; then
        CONTAINER_NAME="nginx-mtproxy"
    elif docker ps -a --format '{{.Names}}' | grep -q '^mtg$'; then
        CONTAINER_NAME="mtg"
    fi

    if [[ -n "$CONTAINER_NAME" ]]; then
        read -rp "确定要删除 $CONTAINER_NAME 容器吗？(Y/N): " confirm_remove
        if [[ "$confirm_remove" =~ ^[yY]$ ]]; then
            docker stop "$CONTAINER_NAME" > /dev/null 2>&1
            docker rm "$CONTAINER_NAME" > /dev/null 2>&1
            echo -e "${GREEN}✅ $CONTAINER_NAME 容器已成功删除。${RESET}"
        else
            echo -e "${YELLOW}ℹ️ 已取消删除容器操作。${RESET}"
        fi
    else
        echo -e "${YELLOW}ℹ️ 未检测到任何 MTProxy/MTG 容器，无需删除。${RESET}"
    fi

    echo -e "\n${YELLOW}>>> MTProxy/MTG 相关操作已完成。${RESET}"
    read -rp "是否需要一并卸载 Docker 及其相关依赖？此操作会影响服务器上所有其他 Docker 容器！(Y/N): " remove_docker
    if [[ "$remove_docker" =~ ^[yY]$ ]]; then
        echo -e "\n${BLUE}>>> 正在尝试卸载 Docker...${RESET}"
        if command -v apt-get > /dev/null; then
            apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null 2>&1
            apt-get autoremove -y > /dev/null 2>&1
        elif command -v yum > /dev/null; then
            yum remove -y docker-ce docker-ce-cli containerd.io > /dev/null 2>&1
        elif command -v dnf > /dev/null; then
            dnf remove -y docker-ce docker-ce-cli containerd.io > /dev/null 2>&1
        else
            echo -e "${RED}⚠️ 未知的操作系统类型，无法自动卸载 Docker。请手动执行卸载。${RESET}"
            read -n 1 -s -r -p "按任意键返回主菜单..."
            return
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

# --- 主程序循环 ---
while true; do
    show_menu
    read -rp "请输入选项 [1-7]: " menu
    echo ""

    case $menu in
        1)
            clear
            echo -e "${GREEN}==========================================${RESET}"
            echo -e "${GREEN}===    安装 MTProxy/MTG 代理        ===${RESET}"
            echo -e "${GREEN}==========================================${RESET}"
            echo -e "请选择安装方式："
            echo -e "  ${BLUE}1.${RESET} 安装经典版本（nginx-mtproxy）"
            echo -e "  ${BLUE}2.${RESET} 安装 MTG 高性能版本（nineseconds/mtg）"
            read -p "请输入选项 [1-2]: " install_choice
            
            case $install_choice in
                1) install_classic ;;
                2) install_mtg ;;
                *) echo -e "${YELLOW}无效选项，请重新选择。${RESET}"; sleep 1; continue ;;
            esac
            read -n 1 -s -r -p "按任意键返回主菜单..."
            echo ""
            ;;

        2)
            uninstall_mtproxy
            read -n 1 -s -r -p "按任意键返回主菜单..."
            echo ""
            ;;

        3)
            echo -e "🔄 正在重启 MTProxy/MTG 容器..."
            docker restart nginx-mtproxy mtg &>/dev/null
            echo -e "${GREEN}✅ 重启完成！${RESET}"
            sleep 1
            ;;

        4)
            echo -e "⏸️ 正在停止 MTProxy/MTG 容器..."
            docker stop nginx-mtproxy mtg &>/dev/null
            echo -e "${GREEN}✅ 停止完成！${RESET}"
            sleep 1
            ;;

        5)
            echo -e "▶️ 正在启动 MTProxy/MTG 容器..."
            docker start nginx-mtproxy mtg &>/dev/null
            echo -e "${GREEN}✅ 启动完成！${RESET}"
            sleep 1
            ;;

        6)
            echo -e "🔄 正在更新脚本..."
            SCRIPT_PATH=$(readlink -f "$0")
            curl -fsSL https://raw.githubusercontent.com/dododook/mtproto-proxy-setup/main/mtproxy_menu.sh -o "$SCRIPT_PATH"
            echo -e "${GREEN}✅ 脚本已更新，正在重新加载...${RESET}"
            exec "$SCRIPT_PATH"
            ;;

        7)
            echo -e "${YELLOW}再见，有缘再会。${RESET}"
            exit 0
            ;;

        *)
            echo -e "${YELLOW}无效选项，请重新选择。${RESET}"
            sleep 1
            ;;
    esac
done

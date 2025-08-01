# 🚀 MTProxy NGINX 一键部署工具（美化增强版）

[![GitHub stars](https://img.shields.io/github/stars/dododook/mtproto-proxy-setup?style=flat-square)](https://github.com/dododook/mtproto-proxy-setup/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/dododook/mtproto-proxy-setup?style=flat-square)](https://github.com/dododook/mtproto-proxy-setup/network)
[![GitHub license](https://img.shields.io/github/license/dododook/mtproto-proxy-setup?style=flat-square)](https://github.com/dododook/mtproto-proxy-setup/blob/main/LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/dododook/mtproto-proxy-setup?style=flat-square)](https://github.com/dododook/mtproto-proxy-setup/commits/main)

> 基于镜像 [`ellermister/nginx-mtproxy`](https://hub.docker.com/r/ellermister/nginx-mtproxy)，支持伪装域名、自定义端口、TAG 标识统计，一键部署 Telegram MTProto Proxy。默认推荐使用 443 端口，免配置自动映射容器 8443。

---

## 📸 项目界面预览（终端美化）

![preview](https://raw.githubusercontent.com/dododook/mtproto-proxy-setup/main/assets/preview.png)

---

## 🚀 快速开始

```bash
curl -o mtproxy_menu.sh https://raw.githubusercontent.com/dododook/mtproto-proxy-setup/main/mtproxy_menu.sh
chmod +x mtproxy_menu.sh
./mtproxy_menu.sh
```

---

## 🔧 功能特性

- ✅ 一键安装 MTProto Proxy 服务（Docker）
- ✅ 自动生成密码 / Secret / 一键 TG 链接
- ✅ 支持伪装域名选择 / 自定义
- ✅ 自动安装依赖（如缺少 xxd）
- ✅ 一键卸载脚本
- ✅ 结构清晰、终端交互美观

---

## ⚙️ 参数说明

| 参数        | 默认值              | 说明 |
|-------------|----------------------|------|
| 链接端口     | `443`                | 建议保留默认，避免端口映射错误 |
| 密码         | 自动生成 UUID       | 可自定义 |
| 伪装域名     | `www.microsoft.com` | 可选择或自定义 CDN 支持的域名 |
| TAG 标签     | 可选开启             | 用于统计管理面板，如需要可手动填入 |

---

## 📬 Telegram 链接说明

生成链接格式如下：

```
https://t.me/proxy?server=<你的IP>&port=<端口>&secret=ee<密码><伪装域名HEX>
```

举例：

```
ee1234567890abcdef7777772e676f6f676c652e636f6d
→ 密码: 1234567890abcdef
→ 域名: www.google.com → HEX: 7777772e676f6f676c652e636f6d
```

---

## 🛠️ 常见问题

### ❌ Telegram 一直“连接中”怎么办？

请确保以下全部正确：

- ✅ 云服务器安全组已放行端口（如 `443`）
- ✅ Docker 启动时使用了 `-p 443:8443`（已在脚本中自动处理）
- ✅ 所选伪装域名支持 TLS（如 `cdn.jsdelivr.net`）
- ✅ 本地客户端网络未被运营商屏蔽 Telegram 协议（建议测试热点）

---

## 📦 推荐伪装域名列表

- `cdn.jsdelivr.net`
- `www.cloudflare.com`
- `www.microsoft.com`
- `www.google.com`
- `www.bing.com`

---

## 🧼 卸载方法

菜单中选择 `[2] 卸载 MTProxy` 即可清理容器与镜像，支持可选卸载 Docker 本体。

---

## 📌 镜像信息

Docker Hub:  
➡️ https://hub.docker.com/r/ellermister/nginx-mtproxy

容器内部监听端口为 `8443`，脚本已自动完成外部端口（如 `443/5555`）的正确映射。

---

## ✅ 安装验证命令

你可以验证脚本已部署容器端口是否正常：

```bash
docker ps | grep nginx-mtproxy
nc -zv <你的IP> <你映射的端口>
```

成功应显示：`succeeded`，表示端口已开放。

---

## 📜 License

MIT License © [@dododook](https://github.com/dododook)

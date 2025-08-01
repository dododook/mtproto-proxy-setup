# MTProxy NGINX 一键部署工具（美化增强版）

基于镜像 [`ellermister/nginx-mtproxy`](https://hub.docker.com/r/ellermister/nginx-mtproxy)，支持伪装域名、自定义端口、TAG 标识统计、一键部署 MTProto Proxy，并自动生成 Telegram 使用链接。

> 作者：[@yaoguangting](https://github.com/dododook)｜自动脚本适配容器内部监听特性（8443端口），默认推荐使用 `443` 外部端口。

---

## 🚀 快速开始

```bash
# 下载并运行脚本
curl -o mtproxy_menu.sh https://raw.githubusercontent.com/dododook/mtproto-proxy-setup/main/mtproxy_menu_v2.sh
chmod +x mtproxy_menu.sh
./mtproxy_menu.sh
```

---

## 🧩 功能特性

- 一键安装 MTProto Proxy 服务（基于 Docker）
- 自动生成 Secret + 一键链接
- 支持自定义端口 / 密码 / 伪装域名 / TAG
- 自动判断 `xxd` 缺失并尝试安装
- 容器状态一目了然
- 一键卸载功能
- 菜单式交互体验（美化版）

---

## ⚙️ 参数说明

| 参数        | 默认值              | 说明 |
|-------------|----------------------|------|
| 链接端口     | `443`                | 建议保留默认，避免端口映射错误 |
| 密码         | 自动生成 UUID       | 可自定义 |
| 伪装域名     | `www.microsoft.com` | 可选择或自定义 CDN 支持的域名 |
| TAG 标签     | 可选开启             | 用于统计管理面板，如需要可手动填入 |

---

## 🔐 Telegram 一键链接说明

脚本自动生成格式如下：

```
https://t.me/proxy?server=你的IP&port=端口&secret=ee+密码+伪装域名HEX
```

举例：

```
ee1234567890abcdef7777772e676f6f676c652e636f6d
→ 密码: 1234567890abcdef
→ 伪装域名: www.google.com → HEX: 7777772e676f6f676c652e636f6d
```

---

## 🛠️ 常见问题

### ❌ Telegram 一直“连接中”？

请逐一排查：

1. 云服务器安全组是否放通了你填写的端口（如 `443`）
2. 脚本是否正确执行了 `-p 443:8443` 映射（默认使用 `443` 时自动处理）
3. 所选伪装域名是否支持 TLS（如 `cdn.jsdelivr.net`、`www.cloudflare.com`）
4. 客户端网络是否允许 Telegram TCP 连接（建议用手机热点测试）

---

## 🧼 卸载方法

在菜单中选择 **[2] 卸载 MTProxy**，脚本将自动停止容器并清理。

---

## 🧪 推荐伪装域名列表

- `www.microsoft.com`
- `cdn.jsdelivr.net`
- `www.cloudflare.com`
- `www.google.com`
- `www.bing.com`

---

## 📦 镜像信息

镜像地址：
[https://hub.docker.com/r/ellermister/nginx-mtproxy](https://hub.docker.com/r/ellermister/nginx-mtproxy)

容器内部监听端口为 `8443`，脚本已自动将外部端口正确映射至此端口。

---

## 📬 联系作者

如需定制部署、TG通知、Web面板、状态监控、扫码工具等功能扩展，可联系作者：

- GitHub: [@dododook](https://github.com/dododook)
- Telegram: [点击联系](https://t.me/yaoguangting) （如开放）

---

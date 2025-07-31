
# MTProxy 一键部署与管理脚本

这是一个用于快速部署、管理并监控 [MTProto Proxy](https://core.telegram.org/mtproto/mtproto-proxy) 的 Shell 脚本，支持 Docker 容器化部署、Telegram 机器人推送通知、白名单激活、客户端连接查看等功能。

## 📦 脚本地址

- GitHub Raw 地址（用于一键安装）：

  ```bash
  bash <(curl -fsSL https://raw.githubusercontent.com/dododook/mtproto-proxy-setup/refs/heads/main/mtproxy_manager.sh)
  ```

## 🚀 功能特点

- ✅ 一键部署 `ellermister/mtproxy` 镜像
- 🌍 支持自定义端口、伪装域名、Secret
- 📬 Telegram Bot 实时推送部署信息
- 📊 查看连接数（总连接数 / Telegram 客户端 IP）
- 🧼 一键卸载 MTProxy 容器
- 🧊 支持白名单激活访问（`add.php`）

## 📋 使用说明

1. 确保系统已安装 `curl` 和 `docker`（Ubuntu 示例）：

   ```bash
   sudo apt update && sudo apt install -y curl docker.io
   ```

2. 执行脚本：

   ```bash
   bash <(curl -fsSL https://raw.githubusercontent.com/dododook/mtproto-proxy-setup/refs/heads/main/mtproxy_manager.sh)
   ```

3. 选择功能菜单：

   ```
   ==== MTProxy 管理脚本（含连接识别） ====
   1. 部署 MTProxy
   2. 卸载 MTProxy
   3. 退出
   4. 查看连接总数
   5. 查看 Telegram 客户端连接
   ```

## 🔐 Telegram 推送配置

脚本中已预设 Telegram 机器人：

```bash
BOT_TOKEN="8027310373:AAEuKPwgkvr3P-8b54GbKPaM5uU7hGWv71Q"
CHAT_ID="6252019930"
```

如需替换为自己的 Bot，可修改脚本顶部两个变量。

## ✅ 示例输出

```
✅ MTProxy 已部署
🔐 Secret: ee<secret><hex_domain>
📡 链接: tg://proxy?server=IP&port=PORT&secret=ee<secret><hex_domain>
🧊 白名单激活: http://IP:HTTP_PORT/add.php
📷 二维码链接: https://api.qrserver.com/...
```

## 🛠️ 常见问题

### 📌 Telegram 链接无效怎么办？

- 请确认白名单已经激活（访问 `http://IP/add.php` 即可）；
- 检查本地网络是否可访问 Telegram；
- 确保使用的是 Telegram 客户端（Web 无法打开 `tg://` 链接）。

### 📌 推送失败？

- 请确保 Bot Token 和 Chat ID 正确；
- Chat ID 必须是你与 Bot 的对话 ID，首次需向 Bot 发消息激活。

---

## 📎 联系作者

如需定制化部署或问题反馈，请联系 GitHub 用户 [dododook](https://github.com/dododook)。

# 🚀 MTProto Proxy 一键部署工具

这是一个支持用户选择安装 **MTG** 或 **alexbers (Python)** 两种 Telegram MTProto Proxy 的自动化安装工具箱，适用于 Ubuntu 系统，支持 Docker + Docker Compose。

---

## 📦 快速开始（推荐）

只需在服务器终端执行以下命令：

```bash
curl -sSL https://raw.githubusercontent.com/dododook/mtproto-proxy-setup/main/install.sh | bash
```

你将看到提示，选择代理实现版本，并输入自定义端口（如 443 或 8443），即可一键完成安装！

---

## 🔧 脚本说明

| 脚本名 | 说明 |
|--------|------|
| `install.sh` | 统一入口脚本，用户选择安装哪种代理（MTG 或 alexbers） |
| `mtg_deploy_smart.sh` | 安装 MTG 高性能实现（Rust 编写，支持 FakeTLS） |
| `alexbers_deploy.sh` | 安装 alexbers Python 实现（功能可扩展，默认监听 8443） |

---

## 🔐 连接 Telegram 示例

安装完成后会自动输出代理链接，例如：

```
tg://proxy?server=YOUR_IP&port=PORT&secret=SECRET
```

直接点击即可用 Telegram 客户端连接。

---

## 📋 依赖说明

脚本会自动安装以下依赖（如未安装）：

- `docker`
- `docker-compose`
- `curl`

---

## 🤝 致谢

- [alexbers/mtprotoproxy](https://github.com/alexbers/mtprotoproxy)
- [nineseconds/mtg](https://github.com/9seconds/mtg)

---

欢迎 Star & Fork！如有建议可提 Issue 🙌

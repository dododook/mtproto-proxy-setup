# Telegram MTProto Proxy 一键部署脚本（MTG版本）

这是一个使用 [nineseconds/mtg](https://github.com/nineseconds/mtg) 镜像的 Telegram 代理一键部署脚本，适用于 Linux 系统（如 Ubuntu、Debian），支持 **FakeTLS 模式** 和自动生成合法 secret。

## ✅ 功能特性

- 自动安装 Docker 和 Docker Compose v2
- 自动生成符合规范的 FakeTLS Secret
- 自动启动 MTG 容器并监听 443 端口
- 自动输出 Telegram 代理连接链接
- 支持与其他代理方案共存（如 alexbers，使用其他端口）

## 📦 使用方法

在服务器中运行以下命令：

```bash
chmod +x mtg_deploy_smart.sh
./mtg_deploy_smart.sh
```

执行成功后会自动输出一个类似于以下格式的 Telegram 代理链接：

```
tg://proxy?server=你的IP地址&port=443&secret=ee...
```

## 📲 添加代理方式

1. 打开 Telegram → 设置 → 数据与存储 → 代理设置
2. 添加代理 → 选择 **MTProto**
3. 填写服务器、端口和 secret

或者直接点击脚本输出的链接即可。

## 📁 文件说明

- `mtg_deploy_smart.sh`：主部署脚本
- `docker-compose.yml`：由脚本自动生成
- 无需手动写入 config 文件，全部自动化完成

## 🧱 注意事项

- 请确保 443 端口未被占用（如 nginx、apache）
- 建议使用国外服务器（如 Oracle、Contabo、Hetzner 等）
- 建议配合 Cloudflare 或 CDN 中转进一步防封（后续版本支持）

## 🧩 后续计划

- [ ] 支持 alexbers/mtprotoproxy（Python 自定义版本）
- [ ] systemd 开机自启配置
- [ ] TLS + CDN 模式自动化部署

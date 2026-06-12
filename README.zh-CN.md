# vless-reality-starter

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

在一台全新 VPS 上，10 分钟内自建 VLESS + REALITY 代理节点 —— 一个脚本，合理默认值，完整教程。

> [English](README.md)

---

## 是什么

一个 Bash 脚本，把一台纯净的 Ubuntu 24.04 VPS 变成加固的 VLESS + REALITY 代理节点：

- 通过官方安装器安装 [Xray-core](https://github.com/XTLS/Xray-core)
- 自动生成 UUID、x25519 密钥对和 Short ID
- 写入最小化、经过测试的 `config.json`
- 防火墙仅放行 22 和 443 端口
- 输出可直接粘贴的 VLESS URL 和 Clash Meta 片段

流量路径：

```
客户端 -> VPS:443 -> Xray (REALITY) -> 直连出口
```

无需 Cloudflare 代理。无需域名。无需管理 TLS 证书。

---

## 为什么用 REALITY

REALITY 是 Xray 内置的 TLS 1.3 伪装层。你的节点借用真实高流量站点（如 `www.microsoft.com`）的 TLS 握手签名，深度包检测看到的是合法连接，而不是代理。

与早期 WebSocket + Cloudflare 方案对比：

| | 本方案 | WS + CF |
|---|---|---|
| 组件 | 仅 Xray | Xray + k3s + Ingress + CF |
| 是否需要域名 | 否 | 是 |
| TLS 证书 | 否 | 是（通过 CF） |
| 故障面 | 极小 | 较大 |

---

## 快速开始

**前提条件：** Ubuntu 24.04 VPS，root 或 sudo 权限，22 和 443 端口已开放。

```bash
# 1. 在本地克隆仓库（或直接在 VPS 上操作）
git clone https://github.com/UncleJ-h/vless-reality-starter.git
cd vless-reality-starter

# 2. 上传脚本到 VPS
scp single-host/setup-reality.sh ubuntu@<YOUR_SERVER_IP>:~

# 3. SSH 登录并执行
ssh ubuntu@<YOUR_SERVER_IP>
sudo SERVER_HOST=<YOUR_SERVER_IP> bash setup-reality.sh
```

脚本执行完成后会打印连接参数。把 VLESS URL 粘贴到客户端，即可使用。

完整教程 —— VPS 选型、防火墙检查清单、可选 3x-ui 面板、每台设备独立客户端配置和运维命令 —— 请参阅 **[TUTORIAL.md](TUTORIAL.md)**。

---

## 环境变量

所有覆盖项均为可选；未设置时脚本通过 `api.ipify.org` 自动检测 `SERVER_HOST`。

| 变量 | 默认值 | 说明 |
|---|---|---|
| `SERVER_HOST` | 自动检测 | VPS 公网 IP 或域名 |
| `TARGET` | `www.microsoft.com:443` | REALITY 伪装目标 |
| `SERVER_NAME` | `www.microsoft.com` | 向客户端展示的 SNI |
| `PORT` | `443` | 监听端口 |
| `UUID` | 自动生成 | VLESS 客户端 UUID |
| `SHORT_ID` | 自动生成 | 8 字节十六进制 Short ID |
| `DISABLE_ZEABUR_K3S` | `1` | 首次启动时禁用 Zeabur 管理的 k3s |

带显式覆盖的示例：

```bash
sudo SERVER_HOST=<YOUR_SERVER_IP> \
  SERVER_NAME=www.apple.com \
  TARGET=www.apple.com:443 \
  bash setup-reality.sh
```

完整参数说明见 [`.env.example`](.env.example)。

---

## 客户端配置

脚本执行完成后输出如下内容：

```
=== Server Ready ===
Address: <YOUR_SERVER_IP>
Port: 443
UUID: <generated-uuid>
Public Key: <generated-public-key>
Short ID: <generated-short-id>
Server Name: www.microsoft.com
```

### 手动配置客户端

| 字段 | 值 |
|---|---|
| 协议 | `VLESS` |
| 地址 | `<YOUR_SERVER_IP>` 或 `<your-domain.com>` |
| 端口 | `443` |
| UUID | 脚本输出值 |
| 传输 | `tcp` |
| Flow | `xtls-rprx-vision` |
| TLS | `Reality` |
| SNI / Server Name | 脚本输出值 |
| Public Key | 脚本输出值 |
| Short ID | 脚本输出值 |
| Fingerprint | `chrome` |

脚本同时输出可直接粘贴的 **VLESS URL** 和 **Clash Meta** 节点片段。

### Cloudflare DNS（可选）

如果要给节点绑定域名，添加一条 `A` 记录指向 `<YOUR_SERVER_IP>`，并将 **Proxy status 设为 DNS only**（灰云）。不要开启橙云代理 —— REALITY 需要客户端直接与你的服务器建立 TLS 连接。

---

## 运维

```bash
# 服务状态
sudo systemctl status xray --no-pager

# 查看日志
sudo journalctl -u xray -n 100 --no-pager

# 验证配置
sudo /usr/local/bin/xray run -test -config /usr/local/etc/xray/config.json

# 重启服务
sudo systemctl restart xray

# 防火墙状态
sudo ufw status numbered
```

---

## 目录结构

```
single-host/
  setup-reality.sh          # 主安装脚本 —— 你只需要这一个
  open-panel-tunnel.sh      # 访问 3x-ui 面板的 SSH 隧道辅助脚本
  xray/config.json.template # 服务端配置模板（参考用）
  max-zeabur-client.json.template  # 容器用最小化 Xray 客户端配置模板
  max-zeabur.md             # 容器端代理接入说明
  cloudflare-dns-setup.md        # Cloudflare DNS 配置说明
k8s/                        # 旧版 —— K3s + Ingress 清单（不再推荐）
.env.example                # 所有支持的环境变量及注释
TUTORIAL.md                 # 完整分步教程
```

> `k8s/` 保留作历史参考。Kubernetes 方案引入了 k3s、Ingress 和 Cloudflare WebSocket 等额外组件。对于个人单用户场景，单机方案明显更简单、更可靠。

---

## 配合 Claude Code 使用

本项目包含 `CLAUDE.md`，向 Claude Code 提供脚本和架构的完整上下文。

```bash
claude    # 启动 Claude Code —— 自动读取 CLAUDE.md
```

---

## 贡献

欢迎提 Issue 和 PR。详见 [CONTRIBUTING.md](CONTRIBUTING.md)。

---

## 许可证

MIT —— 见 [LICENSE](LICENSE)

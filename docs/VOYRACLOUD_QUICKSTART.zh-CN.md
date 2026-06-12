# VoyraCloud Residential IP VPS 购买后开箱教程

这份文档给刚买完 VPS 的读者看。目标是把一台 VoyraCloud Residential IP VPS 配成自用 VLESS + REALITY 节点。

购买入口：

https://www.voyracloud.com/?ref_code=4BFZXE9M

## 你需要准备什么

- 一台 VoyraCloud Residential IP VPS
- 系统选择 Ubuntu 24.04
- VPS 公网 IP
- SSH 登录用户，通常是 `root` 或 `ubuntu`
- root 密码或 SSH key
- 本地电脑可以打开终端

不需要准备：

- 域名
- 二级子域名
- TLS 证书
- Docker
- Kubernetes
- Cloudflare 代理
- 管理面板

如果你要用域名，只能用 DNS 解析到 VPS IP，不能开 Cloudflare 橙云代理。

## 购买后先保存这些信息

```text
Provider: VoyraCloud
Product: Residential IP VPS
OS: Ubuntu 24.04
Public IP:
SSH user:
SSH port: 22
Purpose: VLESS + REALITY
Created at:
```

不要把 root 密码、SSH 私钥、API key 或 `.env` 内容写进公开文档。

## 第一步：SSH 登录 VPS

如果后台给的是 root 用户：

```bash
ssh root@YOUR_SERVER_IP
```

如果后台给的是 ubuntu 用户：

```bash
ssh ubuntu@YOUR_SERVER_IP
sudo -i
```

进入服务器后检查基础状态：

```bash
whoami
lsb_release -a || cat /etc/os-release
curl -4 https://api.ipify.org && echo
ss -lntp | grep ':443' || true
```

预期：

- 系统是 Ubuntu 24.04
- 公网 IP 和后台显示一致
- 443 端口没有被其他服务占用

## 第二步：安装 VLESS + REALITY

在 VPS 上执行：

```bash
sudo apt-get update
sudo apt-get install -y git
git clone https://github.com/UncleJ-h/vless-reality-starter.git
cd vless-reality-starter
sudo SERVER_HOST=YOUR_SERVER_IP DISABLE_ZEABUR_K3S=0 bash single-host/setup-reality.sh
```

把 `YOUR_SERVER_IP` 替换成你的 VPS 公网 IP。

说明：

- `SERVER_HOST` 是客户端连接地址，可以是 VPS IP，也可以是 DNS only 的域名。
- `DISABLE_ZEABUR_K3S=0` 表示这台机器不是 Zeabur Dedicated Server，不需要清理 Zeabur k3s。
- 默认伪装目标是 `www.microsoft.com:443`，新手不用改。

## 第三步：保存脚本输出

脚本完成后会输出：

```text
=== Server Ready ===
Address: YOUR_SERVER_IP
Port: 443
UUID: ...
Public Key: ...
Short ID: ...
Server Name: www.microsoft.com
Target: www.microsoft.com:443

=== VLESS URL ===
vless://...

=== Clash Meta Node ===
- name: MyReality
  type: vless
  ...
```

请完整保存这段输出，尤其是 `VLESS URL` 和 `Clash Meta Node`。

## 第四步：验证服务

在 VPS 上执行：

```bash
sudo systemctl status xray --no-pager
sudo /usr/local/bin/xray run -test -config /usr/local/etc/xray/config.json
sudo ufw status numbered
```

预期：

- `xray.service` 是 `active`
- config test 通过
- 防火墙只开放 SSH 和 443/tcp

## 第五步：导入客户端

最简单方式：复制脚本输出里的 `vless://` 链接，导入支持 VLESS + REALITY 的客户端。

推荐客户端和下载入口：

| 平台 | 推荐客户端 | 下载入口 | 用法 |
|---|---|---|---|
| Windows | v2rayN | https://github.com/2dust/v2rayN/releases | 复制 `vless://` 链接后，从剪贴板导入 |
| macOS | v2rayN 或 Clash Verge Rev | https://github.com/2dust/v2rayN/releases / https://github.com/clash-verge-rev/clash-verge-rev/releases | v2rayN 可导入 `vless://`，Clash Verge Rev 使用 Clash Meta YAML |
| Android | v2rayNG | https://github.com/2dust/v2rayNG/releases | 下载 APK，复制 `vless://` 链接后从剪贴板导入 |
| iPhone / iPad | Shadowrocket | https://apps.apple.com/us/app/shadowrocket/id932747118 | App Store 安装后，粘贴或扫码导入 `vless://` |

下载建议：

- Windows / macOS / Android 优先从 GitHub Release 下载，不要随便下载第三方重打包版本。
- iOS 优先从 App Store 安装 Shadowrocket。不同 Apple ID 地区的可用性可能不一样。
- 如果客户端不支持直接导入 `vless://`，就使用脚本输出里的 `Clash Meta Node` YAML。

常见字段：

| 字段 | 值 |
|---|---|
| 协议 | `VLESS` |
| 地址 | VPS 公网 IP 或 DNS only 域名 |
| 端口 | `443` |
| UUID | 脚本输出 |
| 传输 | `tcp` |
| Flow | `xtls-rprx-vision` |
| TLS | `Reality` |
| SNI | `www.microsoft.com`，除非你运行脚本时改过 |
| Public Key | 脚本输出 |
| Short ID | 脚本输出 |
| Fingerprint | `chrome` |

## 新增一个账号

这个项目默认不安装管理面板。脚本会在 `/usr/local/etc/xray/config.json` 里创建一个 VLESS client。新增账号的本质是：在 `clients` 数组里再加一个新的 UUID，然后重启 Xray。

在 VPS 上执行：

```bash
NEW_UUID="$(/usr/local/bin/xray uuid)"
CLIENT_NAME="friend-1"

sudo cp /usr/local/etc/xray/config.json \
  "/usr/local/etc/xray/config.json.bak.$(date +%Y%m%d%H%M%S)"

sudo jq --arg id "$NEW_UUID" --arg email "$CLIENT_NAME" \
  '.inbounds[0].settings.clients += [{"id": $id, "flow": "xtls-rprx-vision", "email": $email}]' \
  /usr/local/etc/xray/config.json \
  | sudo tee /usr/local/etc/xray/config.json.tmp >/dev/null

sudo mv /usr/local/etc/xray/config.json.tmp /usr/local/etc/xray/config.json
sudo /usr/local/bin/xray run -test -config /usr/local/etc/xray/config.json
sudo systemctl restart xray
```

给新账号生成 VLESS URL：

```bash
sudo test -f /usr/local/etc/xray/reality-client.env
set -a
. <(sudo cat /usr/local/etc/xray/reality-client.env)
set +a

echo "vless://${NEW_UUID}@${SERVER_HOST}:${PORT}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${SERVER_NAME}&fp=chrome&pbk=${PUBLIC_KEY}&sid=${SHORT_ID}&type=tcp&headerType=none#${CLIENT_NAME}"
```

注意：

- 每个账号只需要 UUID 不同。
- Public Key、Short ID、SNI、端口和服务器地址保持一致。
- 如果你运行安装脚本时用的是域名，`reality-client.env` 里会保存这个域名；如果你想切换为 IP 或另一个 DNS only 域名，先修改 `SERVER_HOST` 再生成分享链接。
- 如果你把某个账号发给别人，对方就能使用这个节点。不要把连接信息公开发布。

## 管理页面怎么用

这个开源 starter 的一键脚本是纯 Xray 单机部署，不负责安装 3x-ui。

如果你的服务器已经有 `3x-ui` 管理页面，可以用它按设备新增 client、查看流量和禁用单个账号。

所以对读者要分两种情况：

1. 如果你只跑本项目的一键脚本：默认没有管理页面，按上面的命令新增 UUID 即可。
2. 如果你的服务器已经安装了 3x-ui：用 SSH 隧道打开管理页面，在面板里新增 client。

仓库里的 `single-host/open-panel-tunnel.sh` 是 SSH 隧道辅助脚本，给已经安装了 3x-ui 的人安全访问面板用。它不会安装面板，但可以打开已有面板。

面板安全原则：

- 面板只监听 `127.0.0.1`，不要监听 `0.0.0.0`。
- 不要把面板端口直接暴露到公网。
- 通过 SSH tunnel 打开本地访问：

```bash
SERVER_HOST=YOUR_SERVER_IP SSH_USER=root LOCAL_PORT=29834 REMOTE_PORT=29834 \
  bash single-host/open-panel-tunnel.sh
```

然后在浏览器打开：

```text
http://127.0.0.1:29834
```

在 3x-ui 里新增账号时，通常是在已有 VLESS + REALITY inbound 下新增 client：

- Protocol: VLESS
- Flow: `xtls-rprx-vision`
- Security: REALITY
- Network: TCP
- 给每个设备或使用者单独生成一个 UUID
- 保存后复制该 client 的分享链接

如果只是给一两个朋友或设备加账号，直接按上面的手动 UUID 方法更简单；如果要多人管理、看流量、禁用单个 client，再考虑面板。

完整面板说明见：

```text
docs/PANEL_3XUI.zh-CN.md
```

## 如果要交给 agent 做

把 `docs/AGENT_PROMPT.zh-CN.md` 里的提示词发给 Claude Code / Codex / 远程运维 agent。

你只需要补三项：

- VPS 公网 IP
- SSH 用户
- 登录方式

如果 agent 报告系统不是 Ubuntu 24.04、443 被占用或 SSH 登录失败，先处理这个基础问题，不要继续硬装。

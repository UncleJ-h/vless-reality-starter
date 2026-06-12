# vless-reality-starter 中文交付包

这套文档的目标是：让人可以照着部署，也让 agent 可以直接执行。

适用场景：

- 买一台 VoyraCloud Residential IP VPS。
- 不需要域名或二级子域名，直接用 VPS 公网 IP。
- 一键部署 VLESS + REALITY。
- 手机、电脑客户端直接导入 `vless://` 链接。
- 已有 3x-ui 面板时，可以按设备新增账号。

购买入口：

https://www.voyracloud.com/?ref_code=4BFZXE9M

## 30 秒判断

| 问题 | 答案 |
|---|---|
| 必须要 VPS 吗 | 是 |
| 必须要二级域名吗 | 否，公网 IP 就能用 |
| 必须要 Cloudflare 吗 | 否。如果用 Cloudflare DNS，只能 DNS only，不能橙云代理 |
| 必须要 TLS 证书吗 | 否，REALITY 不需要你管理证书 |
| 默认有管理页面吗 | 一键脚本不安装面板；已有 3x-ui 时可用 SSH 隧道打开 |
| 管理页面要暴露公网吗 | 不要。只监听 `127.0.0.1`，通过 SSH 隧道访问 |
| 手机电脑怎么用 | 导入脚本输出的 `vless://` 链接 |

## 给人看的路径

先看：

[VoyraCloud 购买后开箱教程](VOYRACLOUD_QUICKSTART.zh-CN.md)

你会完成：

1. 购买 Residential IP VPS。
2. SSH 登录服务器。
3. 运行 `single-host/setup-reality.sh`。
4. 保存 `VLESS URL`。
5. 下载手机 / 电脑客户端。
6. 导入 `vless://` 链接。
7. 验证出口 IP。

## 给 agent 的路径

如果你要把部署交给 Claude Code / Codex / 运维 agent，看：

[Agent 执行提示词](AGENT_PROMPT.zh-CN.md)

你只需要填：

```text
Public IP:
SSH user:
Login method:
```

agent 应该返回：

- 基础检查结果
- 已执行命令摘要
- `xray.service` 是否 active
- config test 是否通过
- 防火墙开放端口
- `vless://` 链接
- Clash Meta YAML

## 给 AI 编程工具的路径

如果你要用 Claude Code、Cursor、Codex 维护这个仓库，而不是直接部署远程 VPS，看：

[AI Agent 工作流](AI_AGENT_WORKFLOW.zh-CN.md)

它解决的是：

- 让 AI 工具先读对上下文。
- 区分“修改仓库”和“部署远程 VPS”。
- 避免把 3x-ui 面板暴露到公网。
- 避免误改 `k8s/`、历史报告和私有信息。
- 让每次修改都有可执行验收命令。

## 3x-ui 管理面板路径

如果你的服务器已经安装了 3x-ui，看：

[3x-ui 管理面板使用说明](PANEL_3XUI.zh-CN.md)

推荐做法：

- 面板只监听 `127.0.0.1`。
- 不开放面板端口到公网。
- 本地通过 SSH tunnel 打开。
- 每台设备一个 client，不共用 UUID。

## 安全验收路径

部署完成后看：

[安全验收清单](SECURITY_CHECKLIST.zh-CN.md)

重点确认：

- 公网只开放 SSH 和 443/tcp。
- 3x-ui 面板没有监听 `0.0.0.0`。
- 面板端口没有出现在 `ufw allow` 里。
- `vless://`、UUID、Public Key、Short ID 不公开发布。

## 客户端下载

| 平台 | 客户端 | 下载入口 |
|---|---|---|
| Windows | v2rayN | https://github.com/2dust/v2rayN/releases |
| macOS | v2rayN 或 Clash Verge Rev | https://github.com/2dust/v2rayN/releases / https://github.com/clash-verge-rev/clash-verge-rev/releases |
| Android | v2rayNG | https://github.com/2dust/v2rayNG/releases |
| iPhone / iPad | Shadowrocket | https://apps.apple.com/us/app/shadowrocket/id932747118 |

优先从 GitHub Release 或 App Store 下载。不要随便下载第三方重打包版本。

## 最小部署命令

在 VPS 上：

```bash
sudo apt-get update
sudo apt-get install -y git
git clone https://github.com/UncleJ-h/vless-reality-starter.git
cd vless-reality-starter
sudo SERVER_HOST=YOUR_SERVER_IP DISABLE_ZEABUR_K3S=0 bash single-host/setup-reality.sh
```

把 `YOUR_SERVER_IP` 替换成 VPS 公网 IP。

如果你是 Zeabur Dedicated Server，并且需要脚本清理 k3s 占用的 443，去掉 `DISABLE_ZEABUR_K3S=0`。

## 最小验收命令

```bash
sudo systemctl status xray --no-pager
sudo /usr/local/bin/xray run -test -config /usr/local/etc/xray/config.json
sudo ufw status numbered
```

预期：

- Xray 是 active。
- config test 通过。
- 防火墙只开放 SSH 和 443/tcp。

## 对外发送建议

给普通读者：

```text
先看 docs/README.zh-CN.md，再按 VOYRACLOUD_QUICKSTART.zh-CN.md 做。
```

给会用 agent 的读者：

```text
把 docs/AGENT_PROMPT.zh-CN.md 复制给 Claude Code / Codex，填 VPS IP 和 SSH 用户，让 agent 部署并返回 VLESS URL。
```

给用 Cursor / Claude Code / Codex 改仓库的人：

```text
先看 docs/AI_AGENT_WORKFLOW.zh-CN.md，把“仓库投影提示词”复制给工具，再开始修改。
```

给已经有面板的读者：

```text
看 docs/PANEL_3XUI.zh-CN.md，用 SSH 隧道打开 3x-ui，然后每台设备新增一个 client。
```

给需要验收安全边界的读者：

```text
看 docs/SECURITY_CHECKLIST.zh-CN.md，确认只暴露 22/443，管理面板不暴露公网。
```

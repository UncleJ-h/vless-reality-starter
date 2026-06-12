# AI Agent 工作流

这份文档给 Claude Code、Cursor、Codex 或其他 AI 编程工具使用。

它和 `AGENT_PROMPT.zh-CN.md` 的区别：

- `AI_AGENT_WORKFLOW.zh-CN.md`：给本地代码仓库里的 AI 编程工具看，用来改脚本、改文档、做审核。
- `AGENT_PROMPT.zh-CN.md`：给远程 VPS 部署 agent 看，用来登录服务器、安装 Xray、返回 `vless://`。

## 仓库投影提示词

把下面这段作为第一条消息发给 Claude Code / Cursor / Codex：

```text
请先阅读这些文件，再回答或修改：

- CLAUDE.md
- README.zh-CN.md
- docs/README.zh-CN.md
- docs/VOYRACLOUD_QUICKSTART.zh-CN.md
- docs/AGENT_PROMPT.zh-CN.md
- docs/PANEL_3XUI.zh-CN.md
- docs/SECURITY_CHECKLIST.zh-CN.md
- single-host/setup-reality.sh
- single-host/open-panel-tunnel.sh

项目目标：
- 这是一个 VLESS + REALITY 单机部署 starter。
- 面向普通人要简单：买 VPS、SSH、跑脚本、导入客户端。
- 面向 agent 要可执行：给出明确命令、验收标准和失败停止条件。
- 普通 VPS 不需要域名或二级子域名，直接用公网 IP。
- 如果使用 Cloudflare DNS，只能 DNS only，不能橙云代理。
- 3x-ui 管理页面不能暴露公网，只能监听 127.0.0.1 并通过 SSH 隧道访问。

修改边界：
- 不要修改 k8s/，它是 legacy 参考。
- 不要把私有 IP、面板路径、面板用户名、密码、vless:// 链接或密钥写进公开文档。
- 不要引入 Docker、k8s、复杂面板安装流程，除非我明确要求。
- 不要把“可选 3x-ui 面板”写成“一键脚本默认安装面板”。
- 保持改动外科化，每个新增步骤都要能验收。

完成后请告诉我：
- 改了哪些文件。
- 人类用户该看哪个入口。
- agent 该复制哪个提示词。
- 还缺哪些必须在真实 VPS 上验证的点。
```

## Cursor 使用方式

建议把上面的“仓库投影提示词”发给 Cursor Chat，然后再提出具体任务。

适合 Cursor 的任务：

- 改 README 结构。
- 审核中文教程是否顺手。
- 给新增功能补文档。
- 检查脚本命令是否和文档一致。

不建议直接让 Cursor 做：

- 登录真实 VPS。
- 保存服务器密码。
- 把私有面板地址写进仓库。

## Claude Code 使用方式

在仓库根目录启动：

```bash
claude
```

Claude Code 会自动读取 `CLAUDE.md`。如果任务涉及中文交付包，仍建议补一句：

```text
请同时阅读 docs/README.zh-CN.md 和 docs/AI_AGENT_WORKFLOW.zh-CN.md，再处理这个任务。
```

## Codex 使用方式

在仓库根目录启动 Codex 后，先发仓库投影提示词，再发具体任务。

适合 Codex 的任务：

- 检查 Bash 语法。
- 对比 README 和脚本命令是否一致。
- 给 agent 提示词补验收步骤。
- 做安全边界审查。

建议每次让 Codex 至少跑：

```bash
bash -n single-host/setup-reality.sh single-host/open-panel-tunnel.sh
```

如果修改了 Markdown 链接，可以让它检查本地链接是否存在。

## 常见任务模板

### 审核是否简单好用

```text
请审核这个项目是否对普通用户足够简单：从购买 VPS、SSH 登录、运行脚本、保存 VLESS URL、下载客户端、导入手机/电脑、到安全验收。请只指出会阻塞用户的地方，并给出最小修改方案。
```

### 审核是否适合 agent 执行

```text
请审核 docs/AGENT_PROMPT.zh-CN.md 是否足够让远程部署 agent 执行。重点检查：前置检查、失败停止条件、安装命令、验收命令、新增账号流程、敏感信息边界。
```

### 审核管理面板是否安全

```text
请审核 docs/PANEL_3XUI.zh-CN.md 和 docs/SECURITY_CHECKLIST.zh-CN.md，确认 3x-ui 面板没有被建议暴露到公网，且用户能通过 SSH 隧道访问。
```

### 审核脚本和文档是否一致

```text
请对比 single-host/setup-reality.sh、README.zh-CN.md 和 docs/*.zh-CN.md，找出命令、默认值、端口、环境变量、验收方式不一致的地方。不要改无关内容。
```

## 真实 VPS 验收任务

AI 编程工具可以准备命令，但真正的最终验收要在干净 Ubuntu 24.04 VPS 上执行：

```bash
sudo SERVER_HOST=YOUR_SERVER_IP DISABLE_ZEABUR_K3S=0 bash single-host/setup-reality.sh
sudo systemctl status xray --no-pager
sudo /usr/local/bin/xray run -test -config /usr/local/etc/xray/config.json
sudo ufw status numbered
sudo ss -lntp
```

通过标准：

- `xray.service` active。
- config test 通过。
- `443/tcp` 对公网可用。
- 客户端导入 `vless://` 后可连通。
- `ufw` 只放行 SSH 和 443。
- 如果有 3x-ui，面板只监听 `127.0.0.1`。

## 一句话原则

让人类少判断，让 agent 少猜，让管理面板不裸奔。

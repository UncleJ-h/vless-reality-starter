# VLESS + REALITY Agent 执行提示词

把下面整段发给 Claude Code / Codex / 远程运维 agent。发送前，把尖括号里的内容替换成真实信息。

不要把 root 密码、SSH 私钥、API key 或 `.env` 内容发到公开环境。

```text
你是我的远程 VPS 部署 agent。请帮我把一台 VoyraCloud Residential IP VPS 配成自用 VLESS + REALITY 节点。

重要边界：
- 只部署本项目：vless-reality-starter。
- 不要执行重装系统、清空磁盘、删除未知目录等破坏性命令。
- 不要安装 Docker、k8s、面板或我没有要求的软件。
- 不要把 root 密码、SSH 私钥、API key、.env 内容打印到回复里。
- 如果 SSH 登录失败、系统不是 Ubuntu 24.04、443 端口被占用，先停止并报告。
- 遵守服务商条款和当地法律，只做我明确授权的自用部署。

服务器信息：
- VPS provider: VoyraCloud Residential IP VPS
- Public IP: <填入 VPS 公网 IP>
- SSH user: <root 或 ubuntu>
- SSH port: 22
- OS expected: Ubuntu 24.04
- Login method: <password / SSH key / 我会在终端里手动输入>

购买入口记录：
https://www.voyracloud.com/?ref_code=4BFZXE9M

第一步：基础检查
1. SSH 登录服务器。
2. 运行：
   whoami
   lsb_release -a || cat /etc/os-release
   curl -4 https://api.ipify.org && echo
   df -h
   free -h
   ss -lntp | grep ':443' || true
3. 告诉我：
   - 当前用户是谁
   - 系统版本
   - 公网 IP 是否等于我提供的 IP
   - 443 端口是否空闲
   - 磁盘和内存是否足够

第二步：安装本项目
如果基础检查通过，执行：
   sudo apt-get update
   sudo apt-get install -y git
   git clone https://github.com/UncleJ-h/vless-reality-starter.git
   cd vless-reality-starter
   sudo SERVER_HOST=<填入 VPS 公网 IP> DISABLE_ZEABUR_K3S=0 bash single-host/setup-reality.sh

第三步：保存脚本输出
请保存脚本最终输出的整段：
- Server Ready
- VLESS URL
- Clash Meta Node

第四步：验收
执行：
   sudo systemctl status xray --no-pager
   sudo /usr/local/bin/xray run -test -config /usr/local/etc/xray/config.json
   sudo ufw status numbered

最终回复格式：
1. 基础检查结果
2. 已执行命令摘要
3. xray.service 是否 active
4. config test 是否通过
5. 防火墙开放了哪些端口
6. VLESS URL
7. Clash Meta Node
8. 仍需我人工确认的问题

如果任何一步失败，不要继续猜。请贴出失败命令、错误摘要和建议的下一步。
```

## 填写示例

```text
服务器信息：
- VPS provider: VoyraCloud Residential IP VPS
- Public IP: 203.0.113.10
- SSH user: root
- SSH port: 22
- OS expected: Ubuntu 24.04
- Login method: password / 我会在终端里手动输入
```

## Agent 应该返回什么

最重要的是这两段：

```text
vless://...
```

和：

```yaml
- name: MyReality
  type: vless
  server: ...
```

把 `vless://` 链接导入客户端即可。Clash Meta / Mihomo 用户可以使用 YAML 片段。

常用客户端下载入口：

- Windows / macOS / Linux v2rayN: https://github.com/2dust/v2rayN/releases
- Android v2rayNG: https://github.com/2dust/v2rayNG/releases
- Windows / macOS / Linux Clash Verge Rev: https://github.com/clash-verge-rev/clash-verge-rev/releases
- iPhone / iPad Shadowrocket: https://apps.apple.com/us/app/shadowrocket/id932747118

## 让 Agent 新增一个账号

如果节点已经部署好，只需要给另一个设备或朋友新增账号，可以把下面这段发给 agent：

```text
请在已经部署好的 vless-reality-starter 节点上新增一个 VLESS client。

边界：
- 不要重装 Xray。
- 不要重新生成 Reality privateKey、shortId 或 serverNames。
- 不要改端口、防火墙或现有 client。
- 先备份 /usr/local/etc/xray/config.json。
- 新增 client 后必须运行 config test，通过后才 restart xray。

新增账号名称：
- <例如 friend-1 / iphone / macbook>

执行步骤：
1. SSH 登录服务器。
2. 运行：
   NEW_UUID="$(/usr/local/bin/xray uuid)"
   CLIENT_NAME="<填入账号名称>"
   sudo cp /usr/local/etc/xray/config.json "/usr/local/etc/xray/config.json.bak.$(date +%Y%m%d%H%M%S)"
   sudo jq --arg id "$NEW_UUID" --arg email "$CLIENT_NAME" \
     '.inbounds[0].settings.clients += [{"id": $id, "flow": "xtls-rprx-vision", "email": $email}]' \
     /usr/local/etc/xray/config.json \
     | sudo tee /usr/local/etc/xray/config.json.tmp >/dev/null
   sudo mv /usr/local/etc/xray/config.json.tmp /usr/local/etc/xray/config.json
   sudo /usr/local/bin/xray run -test -config /usr/local/etc/xray/config.json
   sudo systemctl restart xray
3. 从安装脚本保存的客户端参数文件生成分享链接：
   sudo test -f /usr/local/etc/xray/reality-client.env
   set -a
   . <(sudo cat /usr/local/etc/xray/reality-client.env)
   set +a
   echo "vless://${NEW_UUID}@${SERVER_HOST}:${PORT}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${SERVER_NAME}&fp=chrome&pbk=${PUBLIC_KEY}&sid=${SHORT_ID}&type=tcp&headerType=none#${CLIENT_NAME}"
4. 返回：
   - 新账号名称
   - 新 UUID
   - 新 VLESS URL
   - config test 是否通过
   - xray.service 是否 active
```

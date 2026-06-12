# 安全验收清单

这份清单用于部署后确认：节点能用，但管理面板和多余端口没有暴露到公网。

核心原则：

- VLESS + REALITY 节点对公网开放 `443/tcp`。
- SSH 对公网开放 `22/tcp`，建议后续改成 SSH key 登录。
- 3x-ui 管理页面不对公网开放，只通过 SSH 隧道访问。
- 不公开发布 `vless://` 链接、UUID、Public Key、Short ID。

## 1. 检查 Xray 是否运行

```bash
sudo systemctl status xray --no-pager
sudo /usr/local/bin/xray run -test -config /usr/local/etc/xray/config.json
```

预期：

- `xray.service` 是 active。
- config test 通过。

## 2. 检查公网端口

```bash
sudo ufw status numbered
```

预期只看到：

```text
22/tcp
443/tcp
```

不要放行：

```text
29834/tcp
54321/tcp
任何 3x-ui 面板端口
任何 SOCKS5 / HTTP 代理端口
```

## 3. 检查监听地址

```bash
sudo ss -lntp
```

正常情况：

- Xray 可以监听 `0.0.0.0:443`。
- SSH 可以监听 `0.0.0.0:22`。
- 3x-ui 面板如果存在，应监听 `127.0.0.1:<panel-port>`。

不推荐：

```text
0.0.0.0:<panel-port>
```

如果面板监听在 `0.0.0.0`，回到 3x-ui 设置里改成 `127.0.0.1`，并确认防火墙没有开放面板端口。

## 4. 用 SSH 隧道访问面板

本地电脑执行：

```bash
SERVER_HOST=YOUR_SERVER_IP SSH_USER=root LOCAL_PORT=29834 REMOTE_PORT=29834 \
  bash single-host/open-panel-tunnel.sh
```

浏览器打开：

```text
http://127.0.0.1:29834/<your-panel-base-path>/
```

确认：

- 不需要打开公网面板端口。
- 不需要给面板单独暴露二级域名。
- 面板用户名和密码不写进公开文档。

## 5. 检查客户端连接信息

安装脚本会保存一份客户端参数：

```bash
sudo cat /usr/local/etc/xray/reality-client.env
```

这份文件用于后续新增账号时生成 `vless://` 链接。

不要公开：

- `vless://` 完整链接
- UUID
- Public Key
- Short ID
- 面板 URL
- 面板用户名和密码

## 6. 新增账号后再验收

每新增一个 client 后执行：

```bash
sudo /usr/local/bin/xray run -test -config /usr/local/etc/xray/config.json
sudo systemctl restart xray
sudo systemctl status xray --no-pager
```

然后只把对应设备的 `vless://` 链接发给对应使用者。

## 7. 域名边界

不需要二级域名也能使用，直接用 VPS 公网 IP。

如果要用域名：

- 节点域名只做 DNS only。
- 不要开 Cloudflare 橙云代理。
- 不要把管理面板放在节点同一个公网入口上。

## 8. 最终通过标准

可以认为通过的状态：

- Xray active。
- config test 通过。
- 客户端导入 `vless://` 后能连通。
- `ufw` 只放行 SSH 和 443。
- 3x-ui 面板没有公网暴露。
- 每台设备使用独立 client。

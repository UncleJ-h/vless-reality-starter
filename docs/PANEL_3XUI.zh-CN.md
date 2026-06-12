# 3x-ui 管理面板使用说明

这份文档适用于已经安装了 `3x-ui` 的服务器。

本项目的一键脚本 `single-host/setup-reality.sh` 只安装 Xray 和 VLESS + REALITY 配置，不负责安装 3x-ui。如果你的服务器已经安装了 3x-ui，可以用它管理多设备 client，因此这里保留面板访问和新增账号说明。

## 面板访问方式

不要把 3x-ui 面板端口直接开放到公网。推荐只让面板监听 `127.0.0.1`，然后通过 SSH 隧道访问。

在本地电脑执行：

```bash
SERVER_HOST=YOUR_SERVER_IP SSH_USER=root LOCAL_PORT=29834 REMOTE_PORT=29834 \
  bash single-host/open-panel-tunnel.sh
```

如果你的服务器登录用户是 `ubuntu`：

```bash
SERVER_HOST=YOUR_SERVER_IP SSH_USER=ubuntu LOCAL_PORT=29834 REMOTE_PORT=29834 \
  bash single-host/open-panel-tunnel.sh
```

然后在浏览器打开：

```text
http://127.0.0.1:29834/<your-panel-base-path>/
```

说明：

- `29834` 是示例端口，以你的 3x-ui 实际面板端口为准。
- `<your-panel-base-path>` 是 3x-ui 的 Web Base Path，以你的面板实际设置为准。
- 面板用户名和密码不要写进公开文档。

## 新增一个设备账号

进入 3x-ui 后，一般按这个流程：

1. 打开 `Inbounds` / `入站列表`。
2. 找到已有的 VLESS + REALITY inbound。
3. 点击编辑 inbound。
4. 在 `Clients` / `客户端` 区域点击新增。
5. 给 client 填一个可识别名称，例如：

```text
macbook
iphone
android
windows
ipad
friend-1
```

6. 生成新的 UUID。
7. Flow 选择或填写：

```text
xtls-rprx-vision
```

8. 保存 inbound。
9. 回到入站列表，复制该 client 的分享链接或二维码。
10. 把链接导入对应设备客户端。

## 建议的设备命名

每台设备一个 client，不要多人或多设备共用一个 UUID。

推荐命名：

| 设备 | client 名称 |
|---|---|
| MacBook | `macbook` |
| iMac | `imac` |
| Windows PC | `windows` |
| iPhone | `iphone` |
| Android Phone | `android` |
| iPad | `ipad` |
| 给朋友的临时账号 | `friend-1` |

这样做的好处：

- 可以按设备看流量。
- 某台设备不用了，可以只禁用对应 client。
- 分享给别人时，不影响自己的主设备。

## 客户端导入

3x-ui 复制出来的分享链接通常是 `vless://...`。

常用客户端：

| 平台 | 客户端 | 下载入口 |
|---|---|---|
| Windows | v2rayN | https://github.com/2dust/v2rayN/releases |
| macOS | v2rayN 或 Clash Verge Rev | https://github.com/2dust/v2rayN/releases / https://github.com/clash-verge-rev/clash-verge-rev/releases |
| Android | v2rayNG | https://github.com/2dust/v2rayNG/releases |
| iPhone / iPad | Shadowrocket | https://apps.apple.com/us/app/shadowrocket/id932747118 |

导入后测试：

1. 开启代理。
2. 打开 `https://ipinfo.io`。
3. 确认显示的是 VPS 出口 IP。

## 安全检查

在服务器上确认面板没有暴露到公网：

```bash
ss -lntp | grep 29834
```

推荐结果类似：

```text
127.0.0.1:29834
```

不推荐：

```text
0.0.0.0:29834
```

如果看到 `0.0.0.0:29834`，说明面板监听了所有网卡。应回到 3x-ui 设置里把面板监听地址改成 `127.0.0.1`，或用系统防火墙和云防火墙确保外网不能访问。

防火墙建议：

```bash
sudo ufw status numbered
```

正常情况下只需要开放：

- `22/tcp`，SSH
- `443/tcp`，VLESS + REALITY

不要开放面板端口。

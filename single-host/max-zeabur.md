# Max Zeabur Container Outbound

给 Zeabur 容器借用东京节点做代理出口时，推荐在容器内部运行一个本地 `Xray client`，而不是在东京机额外开放一个公网 `SOCKS5` 端口。

## 目标结构

```text
App / Chromium / CLI
  -> 127.0.0.1:1080 (SOCKS5)
  -> 127.0.0.1:10809 (HTTP)
  -> Xray client
  -> <your-node-subdomain.your-domain.com>:443
  -> Tokyo Xray server
```

## 容器内建议

- 将真实配置持久化到 `/data/home/xray/max-client.json`
- 使用 [max-zeabur-client.json.template](max-zeabur-client.json.template) 作为起点
- 只在容器内监听 `127.0.0.1`
- 不要把 `1080` 或 `10809` 开放到公网

## 启动方式

示例:

```bash
mkdir -p /data/home/xray
cp max-client.json /data/home/xray/max-client.json
nohup ./xray run -c /data/home/xray/max-client.json >/data/home/xray/max-client.log 2>&1 &
```

如果容器有自己的 `setup.sh` / entrypoint，把上述启动逻辑合进去即可。

## 环境变量

```bash
ALL_PROXY=socks5://127.0.0.1:1080
HTTP_PROXY=http://127.0.0.1:10809
HTTPS_PROXY=http://127.0.0.1:10809
```

## Chromium

```bash
chromium --proxy-server=socks5://127.0.0.1:1080
```

## 维护建议

- 给容器单独分配一个 server-side client，例如 `max-zeabur`
- 如果容器用途变化或流量异常，可直接在面板里禁用该 client
- 这类用途共享的是东京节点出口 IP，不保证永远绕过所有平台风控，只是比当前 Ashburn 出口更合适

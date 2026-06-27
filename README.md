# vless-reality-starter

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Self-host your own VLESS + REALITY proxy node on a fresh VPS in ~10 minutes — one script, sane defaults, full tutorial.

> [中文版](README.zh-CN.md)

---

## What

A single Bash script that turns a plain Ubuntu 24.04 VPS into a hardened VLESS + REALITY proxy node:

- Installs official [Xray-core](https://github.com/XTLS/Xray-core) via the upstream installer
- Generates UUID, x25519 keypair, and short-ID automatically
- Writes a minimal, tested `config.json`
- Locks the firewall to ports 22 and 443 only
- Prints a ready-to-paste VLESS URL and Clash Meta snippet

Traffic path:

```
Client -> VPS:443 -> Xray (REALITY) -> direct outbound
```

No Cloudflare proxy. No domain required. No TLS certificate to manage.

---

## Why REALITY

REALITY is a TLS 1.3 camouflage layer built into Xray. Your node borrows the TLS handshake signature of a real, high-traffic site (default: `www.bing.com`) so that deep-packet inspection sees a legitimate connection, not a proxy.

The default camouflage target is `www.bing.com:443`. Earlier versions used `www.microsoft.com:443`, but Bing has been a more reliable default in recent Xray + REALITY smoke tests. You can still override both `TARGET` and `SERVER_NAME` if your VPS reaches another TLS 1.3 site more reliably.

Compared to the earlier Websocket + Cloudflare approach:

| | This setup | WS + CF |
|---|---|---|
| Components | Xray only | Xray + k3s + Ingress + CF |
| Domain required | No | Yes |
| TLS cert | No | Yes (via CF) |
| Failure surface | Minimal | Large |

---

## Quick Start

**Prerequisites:** Ubuntu 24.04 VPS, root or sudo access, ports 22 and 443 open.

```bash
# 1. Clone the repo on your local machine (or directly on the VPS)
git clone https://github.com/UncleJ-h/vless-reality-starter.git
cd vless-reality-starter

# 2. Upload the script to your VPS
scp single-host/setup-reality.sh ubuntu@<YOUR_SERVER_IP>:~

# 3. SSH in and run
ssh ubuntu@<YOUR_SERVER_IP>
sudo SERVER_HOST=<YOUR_SERVER_IP> DISABLE_ZEABUR_K3S=0 bash setup-reality.sh
```

The script prints your connection parameters when it finishes. Copy the VLESS URL into your client and you are done.

For the complete walkthrough — VPS selection, firewall checklist, optional 3x-ui panel, per-device client setup, and ops commands — see **[TUTORIAL.md](TUTORIAL.md)**.

---

## Environment Variables

All overrides are optional; the script auto-detects `SERVER_HOST` via `api.ipify.org` if not set.

| Variable | Default | Description |
|---|---|---|
| `SERVER_HOST` | auto-detect | VPS public IP or domain |
| `TARGET` | `www.bing.com:443` | REALITY camouflage target |
| `SERVER_NAME` | `www.bing.com` | SNI presented to clients |
| `PORT` | `443` | Listening port |
| `UUID` | auto-generate | VLESS client UUID |
| `SHORT_ID` | auto-generate | 8-byte hex short ID |
| `DISABLE_ZEABUR_K3S` | `1` | Disable Zeabur-managed k3s on first boot |

Example with explicit overrides:

```bash
sudo SERVER_HOST=<YOUR_SERVER_IP> \
  DISABLE_ZEABUR_K3S=0 \
  SERVER_NAME=www.apple.com \
  TARGET=www.apple.com:443 \
  bash setup-reality.sh
```

See [`.env.example`](.env.example) for the full reference.

---

## Client Setup

After the script runs, you will see output like this:

```
=== Server Ready ===
Address: <YOUR_SERVER_IP>
Port: 443
UUID: <generated-uuid>
Public Key: <generated-public-key>
Short ID: <generated-short-id>
Server Name: www.bing.com
```

### Manual client settings

| Field | Value |
|---|---|
| Protocol | `VLESS` |
| Address | `<YOUR_SERVER_IP>` or `<your-domain.com>` |
| Port | `443` |
| UUID | from script output |
| Transport | `tcp` |
| Flow | `xtls-rprx-vision` |
| TLS | `Reality` |
| SNI / Server Name | from script output |
| Public Key | from script output |
| Short ID | from script output |
| Fingerprint | `chrome` |

The script also outputs a ready-to-paste **VLESS URL** and a **Clash Meta** node snippet.

### Cloudflare DNS (optional)

If you want a domain in front of your node, add an `A` record pointing to `<YOUR_SERVER_IP>` with **Proxy status: DNS only** (grey cloud). Never enable the orange-cloud proxy — REALITY requires a direct TLS connection to your server.

---

## Operations

```bash
# Service status
sudo systemctl status xray --no-pager

# Tail logs
sudo journalctl -u xray -n 100 --no-pager

# Verify config
sudo /usr/local/bin/xray run -test -config /usr/local/etc/xray/config.json

# Restart
sudo systemctl restart xray

# Firewall
sudo ufw status numbered
```

---

## Repository Layout

```
single-host/
  setup-reality.sh          # Main installer — the only script you need
  open-panel-tunnel.sh      # SSH tunnel helper for 3x-ui panel access
  xray/config.json.template # Server config template (reference)
  max-zeabur-client.json.template  # Minimal Xray client config for containers
  max-zeabur.md             # Container-side proxy integration guide
  cloudflare-dns-setup.md        # Cloudflare DNS setup notes
k8s/                        # Legacy — K3s + Ingress manifests (not recommended)
.env.example                # All supported environment variables with comments
TUTORIAL.md                 # Full step-by-step walkthrough
```

> `k8s/` is kept as a legacy reference. The Kubernetes approach adds k3s, Ingress, and Cloudflare WebSocket into the stack. For personal single-user use, the single-host approach is strictly simpler and more reliable.

---

## Using with Claude Code

This project includes a `CLAUDE.md` that gives Claude Code full context about the scripts and architecture.

```bash
claude    # Start Claude Code — reads CLAUDE.md automatically
```

---

## Contributing

Issues and PRs are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## License

MIT — see [LICENSE](LICENSE)

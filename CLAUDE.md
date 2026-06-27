# vless-reality-starter

**Stack:** Bash + Xray-core | **Port:** 443 | **OS target:** Ubuntu 24.04

## What

One-script installer that provisions a VLESS + REALITY proxy node on a bare VPS. No Docker, no k8s, no domain required.

## Quick Start

```bash
# Upload script, then on the VPS:
sudo SERVER_HOST=<YOUR_SERVER_IP> DISABLE_ZEABUR_K3S=0 bash single-host/setup-reality.sh

# With overrides:
sudo SERVER_HOST=<YOUR_SERVER_IP> DISABLE_ZEABUR_K3S=0 SERVER_NAME=www.apple.com TARGET=www.apple.com:443 \
  bash single-host/setup-reality.sh
```

## Key Files

```
single-host/setup-reality.sh          # Main installer — only file that runs on VPS
single-host/xray/config.json.template # Xray server config template (reference only)
single-host/open-panel-tunnel.sh      # SSH tunnel for 3x-ui panel
single-host/max-zeabur-client.json.template  # Minimal client config for containers
.env.example                          # All env vars with descriptions
docs/README.zh-CN.md                  # Chinese delivery-package navigation
docs/AI_AGENT_WORKFLOW.zh-CN.md       # Claude Code / Cursor / Codex workflow
docs/AGENT_PROMPT.zh-CN.md            # Prompt for remote VPS deployment agents
docs/PANEL_3XUI.zh-CN.md              # Optional 3x-ui panel guide
docs/SECURITY_CHECKLIST.zh-CN.md      # Security acceptance checklist
k8s/                                  # Legacy Kubernetes manifests (not used)
```

## Architecture

```
Client
  |
  v  TLS 1.3 (REALITY camouflage)
VPS:443  <-- Xray inbound (VLESS + REALITY)
  |
  v  direct
Internet outbound (freedom)
```

The script writes `/usr/local/etc/xray/config.json`, enables `xray.service`, and sets `ufw` to allow only 22/tcp and 443/tcp.

It also writes `/usr/local/etc/xray/reality-client.env` with non-private client connection parameters used for generating additional client URLs. Keep it off public docs.

## Configuration

All config via environment variables (no .env file loaded by the script — pass inline or export first):

| Variable | Default | Description |
|---|---|---|
| `SERVER_HOST` | auto (ipify) | VPS public IP or domain |
| `TARGET` | `www.bing.com:443` | REALITY camouflage target |
| `SERVER_NAME` | `www.bing.com` | SNI for clients |
| `PORT` | `443` | Xray inbound port |
| `UUID` | auto-generate | VLESS UUID |
| `SHORT_ID` | auto-generate | 8-byte hex short ID |
| `DISABLE_ZEABUR_K3S` | `1` | Disable Zeabur k3s units |

For ordinary VPS providers, examples should usually pass `DISABLE_ZEABUR_K3S=0`. Leave the default only for Zeabur Dedicated Server hosts where k3s may occupy 443.

## Ops Commands

```bash
sudo systemctl status xray --no-pager
sudo journalctl -u xray -n 100 --no-pager
sudo /usr/local/bin/xray run -test -config /usr/local/etc/xray/config.json
sudo systemctl restart xray
sudo ufw status numbered
```

## Do Not Touch

- `k8s/` — legacy, kept for reference only
- `TUTORIAL.md` — managed separately
- `SANITIZATION_REPORT.md` / `FORK_REPORT.md` — project history records

## Agent Workflow

When using Claude Code, Cursor, Codex, or another coding agent, first project the repository context with:

```text
Read CLAUDE.md, README.zh-CN.md, docs/README.zh-CN.md, docs/AI_AGENT_WORKFLOW.zh-CN.md, and single-host/setup-reality.sh before editing. Keep changes surgical. Do not expose 3x-ui panel ports publicly. Do not modify k8s/ unless explicitly asked.
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

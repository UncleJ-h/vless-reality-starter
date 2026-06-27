#!/usr/bin/env bash

set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Please run as root: sudo SERVER_HOST=<ip-or-domain> $0"
  exit 1
fi

TARGET="${TARGET:-www.bing.com:443}"
SERVER_NAME="${SERVER_NAME:-www.bing.com}"
PORT="${PORT:-443}"
SERVER_HOST="${SERVER_HOST:-}"
UUID="${UUID:-}"
SHORT_ID="${SHORT_ID:-}"
DISABLE_ZEABUR_K3S="${DISABLE_ZEABUR_K3S:-1}"

if ! command -v curl >/dev/null 2>&1; then
  apt-get update
  apt-get install -y curl
fi

if [[ -z "${SERVER_HOST}" ]]; then
  SERVER_HOST="$(curl -4fsS https://api.ipify.org)"
fi

apt-get update
apt-get install -y curl unzip jq openssl ufw

bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u root

if [[ "${DISABLE_ZEABUR_K3S}" == "1" ]]; then
  for unit in init-k3s k3s containerd; do
    if systemctl list-unit-files | grep -q "^${unit}\.service"; then
      systemctl disable --now "${unit}" || true
    fi
  done

  pkill -f '/var/lib/rancher/k3s/.*/containerd-shim-runc-v2' || true
  pkill -f '/go/bin/main' || true
fi

if [[ -z "${UUID}" ]]; then
  UUID="$(/usr/local/bin/xray uuid)"
fi

if [[ -z "${SHORT_ID}" ]]; then
  SHORT_ID="$(openssl rand -hex 8)"
fi

X25519_OUTPUT="$("/usr/local/bin/xray" x25519)"
PRIVATE_KEY="$(awk '/PrivateKey:|Private key:/ {print $NF}' <<<"${X25519_OUTPUT}")"
PUBLIC_KEY="$(awk '/PublicKey:|Public key:/ {print $NF}' <<<"${X25519_OUTPUT}")"
if [[ -z "${PUBLIC_KEY}" ]]; then
  # Xray v26 also prints a REALITY "Password" value that clients can use.
  PUBLIC_KEY="$(awk '/Password/ {print $NF}' <<<"${X25519_OUTPUT}")"
fi

if [[ -z "${PRIVATE_KEY}" || -z "${PUBLIC_KEY}" ]]; then
  echo "ERROR: failed to parse xray x25519 output" >&2
  echo "${X25519_OUTPUT}" >&2
  exit 1
fi

cat > /usr/local/etc/xray/config.json <<EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": ${PORT},
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${UUID}",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "target": "${TARGET}",
          "xver": 0,
          "serverNames": ["${SERVER_NAME}"],
          "privateKey": "${PRIVATE_KEY}",
          "shortIds": ["${SHORT_ID}"]
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls", "quic"]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "tag": "block"
    }
  ]
}
EOF

/usr/local/bin/xray run -test -config /usr/local/etc/xray/config.json
systemctl enable --now xray
systemctl restart xray

cat > /usr/local/etc/xray/reality-client.env <<EOF
SERVER_HOST=${SERVER_HOST}
PORT=${PORT}
SERVER_NAME=${SERVER_NAME}
PUBLIC_KEY=${PUBLIC_KEY}
SHORT_ID=${SHORT_ID}
EOF
chmod 600 /usr/local/etc/xray/reality-client.env

ufw allow OpenSSH
ufw allow "${PORT}/tcp"
ufw --force enable

cat <<EOF

=== Server Ready ===
Address: ${SERVER_HOST}
Port: ${PORT}
UUID: ${UUID}
Public Key: ${PUBLIC_KEY}
Short ID: ${SHORT_ID}
Server Name: ${SERVER_NAME}
Target: ${TARGET}

=== VLESS URL ===
vless://${UUID}@${SERVER_HOST}:${PORT}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${SERVER_NAME}&fp=chrome&pbk=${PUBLIC_KEY}&sid=${SHORT_ID}&type=tcp&headerType=none#MyReality

=== Clash Meta Node ===
- name: MyReality
  type: vless
  server: ${SERVER_HOST}
  port: ${PORT}
  uuid: ${UUID}
  network: tcp
  tls: true
  udp: true
  xudp: true
  servername: ${SERVER_NAME}
  reality-opts:
    public-key: ${PUBLIC_KEY}
    short-id: ${SHORT_ID}
  client-fingerprint: chrome
  flow: xtls-rprx-vision

EOF

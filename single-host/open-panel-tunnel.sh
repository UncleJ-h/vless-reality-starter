#!/usr/bin/env bash

set -euo pipefail

SERVER_HOST="${SERVER_HOST:-<YOUR_SERVER_IP>}"
LOCAL_PORT="${LOCAL_PORT:-29834}"
REMOTE_PORT="${REMOTE_PORT:-29834}"
SSH_USER="${SSH_USER:-ubuntu}"

echo "Opening SSH tunnel on http://127.0.0.1:${LOCAL_PORT}"
echo "Press Ctrl+C to close."

exec ssh -N -L "${LOCAL_PORT}:127.0.0.1:${REMOTE_PORT}" "${SSH_USER}@${SERVER_HOST}"

# VLESS + REALITY on a Single VPS: From Zero to Working Proxy

A practical guide for developers who are comfortable with a terminal but have never self-hosted a proxy node before.

---

## What You Will Build

By the end of this tutorial you will have:

- A running **Xray** process on an Ubuntu 24.04 VPS listening on `443/tcp`
- A VLESS + REALITY inbound secured with X25519 key-pair cryptography
- A `vless://` link and a Clash Meta node config you can paste directly into your client
- An optional human-friendly hostname via Cloudflare DNS (no proxying)
- A firewall that exposes only port 22 and port 443 to the internet

Estimated time: 15–20 minutes for the happy path.

---

## Why VLESS + REALITY

Most encrypted proxy protocols negotiate a custom TLS handshake that a deep-packet-inspection firewall can fingerprint, even without decrypting the payload. REALITY sidesteps this by borrowing a real TLS 1.3 handshake from a high-quality destination such as `www.microsoft.com`. To an observer on the wire, your proxy traffic looks like a normal HTTPS connection to that domain.

VLESS is the transport layer that sits inside that handshake. It is stateless, has no per-connection overhead, and supports the `xtls-rprx-vision` flow control mode, which passes the inner TLS record layer through unmodified to further reduce fingerprinting.

The practical result: compared to older designs that route traffic through Cloudflare's proxy infrastructure (which introduces latency, changes the IP, and breaks WebSocket behavior at scale), a single-host REALITY node is simpler to operate and harder to detect.

---

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| Ubuntu 24.04 VPS | 1 vCPU / 512 MB RAM is enough. Any provider works. |
| Root or passwordless `sudo` | The setup script checks `EUID -ne 0` and exits immediately if not root. |
| SSH key access | Prefer key-only login before you start. |
| `curl`, `unzip`, `jq`, `openssl`, `ufw` | The script installs these automatically if missing. |
| Optional: a domain on Cloudflare | Only needed for Step 4. You can skip it and use a raw IP. |

**Not required:** Docker, Kubernetes, a control panel, or any other software. This is a shell script on a plain VPS.

---

## Step 1: Prepare the VPS

### 1.1 Log in and verify you are root

```bash
ssh ubuntu@<YOUR_SERVER_IP>
sudo -i
whoami
# Expected: root
```

### 1.2 Disable Zeabur-managed K3s (Zeabur Dedicated Server only)

If you are provisioning through **Zeabur Dedicated Server**, the host boots with a Zeabur-managed K3s cluster that holds port 443. The setup script handles this automatically when `DISABLE_ZEABUR_K3S=1` (the default). You do not need to do anything extra.

If your VPS is **not** from Zeabur, pass `DISABLE_ZEABUR_K3S=0` to skip the K3s teardown block. Running that block on a non-Zeabur host is harmless but noisy.

To confirm whether K3s is running before you start:

```bash
systemctl is-active k3s 2>/dev/null || echo "k3s not present"
```

If the output is `active`, you are on a Zeabur host and the default `DISABLE_ZEABUR_K3S=1` is correct.

### 1.3 Verify port 443 is free (non-Zeabur hosts)

```bash
ss -lntp | grep ':443'
# Expected on a fresh VPS: no output
```

If something is already using 443, stop it before proceeding.

---

## Step 2: Run the Setup Script

### 2.1 Copy the repository to the server

From your local machine:

```bash
scp -r /path/to/vless-reality-starter ubuntu@<YOUR_SERVER_IP>:~/
```

Or clone directly on the server:

```bash
git clone https://github.com/<your-fork>/vless-reality-starter.git
cd vless-reality-starter
```

### 2.2 Understand the environment variables

All configuration is passed as environment variables. The script has safe defaults for every variable except `SERVER_HOST`, which defaults to auto-detection via `api.ipify.org`.

| Variable | Default | What it does |
|----------|---------|--------------|
| `SERVER_HOST` | auto-detected | The IP or domain clients will connect to. Set this explicitly if your VPS has multiple interfaces or if auto-detection returns the wrong address. |
| `PORT` | `443` | Listening port. Stick with 443 unless your provider blocks it. |
| `TARGET` | `www.microsoft.com:443` | The real TLS 1.3 site whose handshake REALITY borrows. Must be a site that supports TLS 1.3 and is reachable from your server. |
| `SERVER_NAME` | `www.microsoft.com` | The SNI value presented to clients. Must match `TARGET`. |
| `UUID` | auto-generated | Your client identity token. Auto-generation is fine; save the output. |
| `SHORT_ID` | auto-generated | An 8-byte hex value that identifies this server to clients. Auto-generation is fine; save the output. |
| `DISABLE_ZEABUR_K3S` | `1` | Set to `0` on non-Zeabur hosts if you want to suppress K3s teardown entirely. |

### 2.3 Run the script

The minimal invocation — let the script auto-detect your public IP:

```bash
cd ~/vless-reality-starter
sudo bash single-host/setup-reality.sh
```

If you want to pin a specific IP or domain as the server address:

```bash
sudo SERVER_HOST=<YOUR_SERVER_IP> bash single-host/setup-reality.sh
```

To override the camouflage target (for example, if `www.microsoft.com` is slow from your region):

```bash
sudo SERVER_HOST=<YOUR_SERVER_IP> TARGET=www.apple.com:443 SERVER_NAME=www.apple.com \
  bash single-host/setup-reality.sh
```

### 2.4 What to expect during the run

The script will print package installation output, then the Xray installer progress. At the end you will see a block like this:

```
=== Server Ready ===
Address: <YOUR_SERVER_IP>
Port: 443
UUID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
Public Key: <base64-public-key>
Short ID: <16-hex-chars>
Server Name: www.microsoft.com
Target: www.microsoft.com:443

=== VLESS URL ===
vless://xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx@<YOUR_SERVER_IP>:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.microsoft.com&fp=chrome&pbk=<base64-public-key>&sid=<16-hex-chars>&type=tcp&headerType=none#MyReality

=== Clash Meta Node ===
- name: MyReality
  type: vless
  server: <YOUR_SERVER_IP>
  ...
```

**Copy this entire block somewhere safe before closing the terminal.** The private key is not printed and is not recoverable from the config file. If you need to rotate keys, re-run the script.

### 2.5 Confirm Xray is running

```bash
systemctl is-active xray
# Expected: active

ss -lntp | grep ':443'
# Expected: a line showing xray listening on 0.0.0.0:443
```

---

## Step 3: Connect a Client

### 3.1 Import the vless:// link

Copy the `vless://` URL from the script output. In most clients you can import it as a link or QR code.

**v2rayN (Windows)**

1. Open v2rayN.
2. Click `Servers` → `Add server from clipboard` (or press Ctrl+V with the link already copied).
3. Select the new entry and click `Set as active server`.
4. Enable system proxy or TUN mode.

**v2rayNG (Android)**

1. Tap the `+` button.
2. Choose `Import config from clipboard`.
3. Tap the entry to activate it.

**Shadowrocket (iOS)**

1. Tap the `+` in the top-right corner.
2. Choose `Type: VLESS`.
3. Paste the `vless://` link into the import field, or scan the QR code if your client of choice can generate one.

**Clash Meta / Mihomo**

Paste the YAML block from the script output into the `proxies:` section of your Clash config:

```yaml
proxies:
  - name: MyReality
    type: vless
    server: <YOUR_SERVER_IP>
    port: 443
    uuid: <your-uuid>
    network: tcp
    tls: true
    udp: true
    xudp: true
    servername: www.microsoft.com
    reality-opts:
      public-key: <base64-public-key>
      short-id: <16-hex-chars>
    client-fingerprint: chrome
    flow: xtls-rprx-vision
```

Then reference the proxy in a rule group or set it as default.

---

## Step 4: Optional — Domain Name with Cloudflare DNS Only

If you want a human-readable hostname instead of a raw IP, Cloudflare's DNS-only mode is the correct approach. Do **not** use Cloudflare's orange-cloud (proxy) mode for a REALITY node.

When Cloudflare proxies a record, clients connect to a Cloudflare Anycast IP rather than your server IP directly. REALITY's handshake depends on reaching your actual server on `443/tcp`. Routing through Cloudflare breaks this.

### 4.1 Create an A record

In your Cloudflare DNS dashboard, add:

| Type | Name | Content | Proxy status | TTL |
|------|------|---------|--------------|-----|
| A | `node` | `<YOUR_SERVER_IP>` | DNS only (grey cloud) | Auto |

This makes `node.<your-domain.com>` resolve directly to your server IP.

### 4.2 Wait for propagation

DNS propagation is typically under 5 minutes for a new record on Cloudflare. Verify:

```bash
dig +short node.<your-domain.com>
# Expected: <YOUR_SERVER_IP>
```

### 4.3 Update clients

In your client configuration, replace the `server` / `address` field:

- Before: `<YOUR_SERVER_IP>`
- After: `node.<your-domain.com>`

Leave every other field (`port`, `uuid`, `public-key`, `short-id`, `sni`, `fingerprint`) unchanged. Test one device before migrating others.

### 4.4 Keep the panel off the node hostname

If you install a management panel (see Security Notes below), do not expose it on the same subdomain as the node. Reserve a separate subdomain like `panel.<your-domain.com>` and keep it behind an SSH tunnel or Cloudflare Access, never open to the public internet.

---

## Step 5: Verify It Works

### Basic connectivity check

From your local machine (without the proxy active):

```bash
nc -zv <YOUR_SERVER_IP> 443
# Expected: Connection to <YOUR_SERVER_IP> 443 port [tcp/https] succeeded!
```

### End-to-end check

Enable the proxy in your client and visit `https://check.torproject.org` or `https://ipinfo.io`. The reported IP should be your VPS IP, not your home IP.

### Server-side log check

```bash
# On the server
journalctl -u xray -n 50 --no-pager
```

A healthy log shows `warning`-level lines only (the default log level). If you see `error` lines with connection reset or TLS failure messages, check that the `TARGET` domain is reachable from the server:

```bash
curl -I https://www.microsoft.com --connect-timeout 5
# Expected: HTTP/2 200 or 301
```

---

## Troubleshooting

These observations come from real deployments. Details have been anonymized.

### Port 443 is already in use

**Symptom:** The script exits early with a bind error or `ufw` shows 443 already allowed but Xray does not start.

**Cause:** On a fresh Zeabur Dedicated Server, K3s reserves 443 before the script runs.

**Fix:** The default `DISABLE_ZEABUR_K3S=1` handles this. If you passed `DISABLE_ZEABUR_K3S=0` by mistake, re-run with the default. If K3s teardown completed but 443 is still occupied:

```bash
ss -lntp | grep ':443'
# Identify the process, then:
systemctl stop <service-name>
```

Then restart Xray:

```bash
systemctl restart xray
```

### Xray starts but clients cannot connect

**Symptom:** `systemctl is-active xray` returns `active`, `443/tcp` is listening, but the client times out.

**Most common cause:** The firewall is blocking port 443.

```bash
ufw status
# Should show: 443/tcp ALLOW Anywhere
```

The setup script runs `ufw allow 443/tcp` and `ufw --force enable`. If you ran `ufw reset` manually afterward, re-add the rule:

```bash
ufw allow OpenSSH
ufw allow 443/tcp
ufw --force enable
```

**Second cause:** `SERVER_HOST` in the client config does not match what the script printed. Double-check the `vless://` link parameters.

### The REALITY target is slow or unreachable

**Symptom:** Connections succeed but latency is high, or the Xray log shows repeated errors connecting to the target.

**Cause:** `www.microsoft.com` is the default camouflage target. If it is slow from your VPS region, you can switch to another high-quality TLS 1.3 site.

**Fix:** Re-run the script with a different target. Common alternatives: `www.apple.com:443`, `www.amazon.com:443`. The site must support TLS 1.3 and be consistently reachable from the server:

```bash
curl -I https://www.apple.com --connect-timeout 5
```

Re-run the script with the new values and re-import the updated `vless://` link (the keys will regenerate).

### Dashboard or panel port visible from the internet

**Symptom:** After installing an optional management panel (such as 3x-ui), external connections to the panel port succeed even though `ufw` only lists 22 and 443.

**Cause:** Some hosting providers (including certain Zeabur/cloud paths) allow raw TCP handshakes to pass at the network layer before `ufw` kernel-level rules take effect. The application layer may not be serving anything, but `nc` or `nmap` will still show the port as "open."

**Fix:** Bind the panel web listener to `127.0.0.1` rather than `0.0.0.0`. This is a setting in the panel's configuration, not in `ufw`. After rebinding, verify:

```bash
ss -lntp | grep '<panel-port>'
# Expected: 127.0.0.1:<panel-port> — local only
```

Access the panel over an SSH tunnel:

```bash
bash single-host/open-panel-tunnel.sh
# Then open http://127.0.0.1:29834 in your browser
```

Or set `SERVER_HOST` and `LOCAL_PORT` to match your panel's actual port:

```bash
SERVER_HOST=<YOUR_SERVER_IP> LOCAL_PORT=<panel-port> REMOTE_PORT=<panel-port> \
  bash single-host/open-panel-tunnel.sh
```

### Zeabur Dashboard shows deployment warnings after K3s is disabled

**Symptom:** After running the script with `DISABLE_ZEABUR_K3S=1`, the Zeabur web dashboard displays connectivity or deployment warnings for the host.

**Cause:** Disabling K3s makes the host invisible to Zeabur's orchestration layer. This is expected and intentional — you are repurposing the host as a standalone VPS rather than a Zeabur-managed node.

**Fix:** None needed. The Xray service runs independently of Zeabur. Ignore the dashboard warnings.

### SSH brute-force attempts in the logs

**Symptom:** `journalctl -u ssh -n 100` shows repeated `Failed password` or `Invalid user` lines from many IPs.

**Cause:** Any internet-facing SSH port receives automated brute-force traffic within minutes of provisioning. This is normal and not specific to this setup.

**Fix:**

```bash
# Disable password and root login
sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^KbdInteractiveAuthentication.*/KbdInteractiveAuthentication no/' /etc/ssh/sshd_config
systemctl reload ssh

# Install fail2ban
apt-get install -y fail2ban
systemctl enable --now fail2ban
```

Verify you can still log in with your SSH key before reloading SSH.

---

## Security Notes

### Treat UUID, Public Key, and Short ID as credentials

The combination of `UUID + Public Key + Short ID + SERVER_HOST` is everything a client needs to connect. If any of these values leak publicly, rotate them by re-running the setup script. The old config will be overwritten and existing clients will need the new `vless://` link.

### Never commit secrets to git

If you fork this repository and add a `private/` directory for your own node credentials, add it to `.gitignore` before creating any files there:

```bash
echo "private/" >> .gitignore
git add .gitignore
git commit -m "ignore private credentials directory"
```

A credentials file accidentally pushed to a public repository is a hard-to-reverse mistake. The safer pattern is: keep the setup script and templates in version control, keep the generated credentials in a local-only ignored directory or a password manager.

### Keep panel ports local-only

If you install a management panel, bind its web listener to `127.0.0.1` and access it only over an SSH tunnel. Opening a panel port directly to the internet exposes an HTTP admin interface to the entire internet.

### Apply system updates after setup

A fresh VPS may have months of pending package updates. After verifying your node works:

```bash
apt-get upgrade -y
reboot
```

Revalidate that `443/tcp` is still listening and `xray` is active after the reboot.

### Disable unused services

The script enables UFW and restricts inbound to `22/tcp` and `443/tcp`. Confirm nothing else is exposed:

```bash
ufw status verbose
ss -lntp
```

Any port showing `0.0.0.0:<port>` in the `ss` output and not covered by your `ufw` allow rules should be investigated.

---

## Next Steps

- **Per-client traffic accounting:** If you want to see per-device usage, install 3x-ui and migrate the Xray inbound into it. You can create separate client UUIDs for each device (e.g., `macbook`, `iphone`, `ipad`) and track traffic in the panel.
- **Routing egress traffic from a container:** If you run other services on Zeabur or Docker and want them to use this node as their egress, run a local Xray client inside the container exposing `127.0.0.1:1080` (SOCKS5) and `127.0.0.1:10809` (HTTP). The repository includes a template at `single-host/max-zeabur-client.json.template`.
- **Backup the config:** The generated `config.json` lives at `/usr/local/etc/xray/config.json`. Copy it somewhere safe. If the script is re-run without passing the same `UUID`, `SHORT_ID`, and keys, new values are generated and existing clients will stop working.

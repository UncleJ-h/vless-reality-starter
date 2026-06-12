# Cloudflare Plan: `<your-node-subdomain.your-domain.com>`

## Goal

Use `<your-node-subdomain.your-domain.com>` as the human-friendly hostname for the Tokyo REALITY node without putting the node behind Cloudflare proxying.

## DNS Record

Create:

| Type | Name | Content | Proxy status | TTL |
|------|------|---------|--------------|-----|
| `A` | `<your-node-subdomain>` | `<YOUR_SERVER_IP>` | `DNS only` | `Auto` |

Result:

- `<your-node-subdomain.your-domain.com> -> <YOUR_SERVER_IP>`

## Why `DNS only`

Cloudflare's official DNS docs note that proxied records return Cloudflare Anycast IPs instead of the origin IP. That behavior is correct for web traffic, but not for this REALITY node entrypoint.

Source:

- [Cloudflare Proxy Status](https://developers.cloudflare.com/dns/proxy-status/)

## Client Cutover

Once DNS is live:

1. Keep `port`, `UUID`, `Public Key`, `Short ID`, `SNI`, and `Fingerprint` unchanged
2. Replace only the `server/address` field:
   - before: `<YOUR_SERVER_IP>`
   - after: `<your-node-subdomain.your-domain.com>`
3. Test one device first
4. Then migrate the other devices

## Panel Plan

Do not put the panel on `<your-node-subdomain.your-domain.com>`.

Reserve a separate name later, for example:

- `panel-<your-node-subdomain.your-domain.com>`

That panel hostname should be fronted by SSH tunnel or Cloudflare Tunnel / Access, not opened directly to the internet.

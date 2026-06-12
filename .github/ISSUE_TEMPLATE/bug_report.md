---
name: Bug report
about: Something broke — script error, connection failure, service not starting
title: "[Bug] "
labels: bug
assignees: ''
---

## Description

<!-- What went wrong? Be specific. -->

## Steps to Reproduce

1. 
2. 
3. 

## Expected Behavior

<!-- What should have happened? -->

## Actual Behavior

<!-- What actually happened? Include full error output. -->

## Environment

| Field | Value |
|---|---|
| Ubuntu version | <!-- `lsb_release -a` output --> |
| Xray version | <!-- `/usr/local/bin/xray version` --> |
| VPS provider | <!-- e.g. Vultr, Hetzner, DigitalOcean --> |
| Script invocation | <!-- e.g. `sudo SERVER_HOST=<YOUR_SERVER_IP> bash setup-reality.sh` --> |

## Script Output

```
<!-- Paste full terminal output here. Replace real IPs with <YOUR_SERVER_IP>, UUIDs with <UUID>, keys with <KEY>. -->
```

## Xray Log (if service started)

```bash
sudo journalctl -u xray -n 50 --no-pager
```

```
<!-- Paste output here -->
```

## Checklist

- [ ] I replaced all real IPs, UUIDs, and private keys with placeholders
- [ ] I tested on a fresh Ubuntu 24.04 instance
- [ ] I checked existing issues for duplicates

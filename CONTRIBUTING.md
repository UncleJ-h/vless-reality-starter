# Contributing

This is a personal project maintained by [UncleJ-h](https://github.com/UncleJ-h). Issues and pull requests are welcome, but there is no commitment to response times or acceptance.

## What is in scope

- Bug fixes in `single-host/setup-reality.sh` (tested on Ubuntu 24.04)
- Corrections to documentation or examples
- Support for additional Ubuntu LTS versions
- Improvements to the Xray config template

## What is out of scope

- Reintroducing the Kubernetes / k3s path — `k8s/` is kept as a reference, not as an active target
- Support for non-Debian distros (not planned)
- Multi-user or SaaS features

## Development Setup

No build toolchain required. The project is plain Bash and YAML.

```bash
git clone https://github.com/UncleJ-h/vless-reality-starter.git
cd vless-reality-starter
```

To test the installer you need a clean Ubuntu 24.04 VM or VPS. Running the script locally on macOS or an existing server is not supported.

```bash
# Minimal smoke test on a fresh VM:
sudo SERVER_HOST=<YOUR_SERVER_IP> bash single-host/setup-reality.sh
sudo /usr/local/bin/xray run -test -config /usr/local/etc/xray/config.json
sudo systemctl is-active xray
```

## Submitting Changes

1. Fork the repository and create a branch from `main`.
2. Keep commits focused — one logical change per commit.
3. If you change `setup-reality.sh`, test on a fresh Ubuntu 24.04 instance before opening a PR.
4. Open a pull request with a clear description of what changed and why.

## Reporting Bugs

Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md). Include:

- Ubuntu version (`lsb_release -a`)
- Xray version (`/usr/local/bin/xray version`)
- The exact command you ran (with real IPs replaced by `<YOUR_SERVER_IP>`)
- Full error output

**Do not include real IP addresses, UUIDs, or private keys in issues.**

## Using Claude Code

This project includes a `CLAUDE.md` with full context for Claude Code.

```bash
claude    # reads CLAUDE.md automatically
```

## License

By contributing you agree that your changes will be licensed under the [MIT License](LICENSE).

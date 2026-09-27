# Networking and Optimizer Notes

Read this file before changing DNS, address-family preference, firewall rules,
kernel tuning, package mirrors, or host overrides. These changes can disconnect
SSH, panels, tunnels, and every client on a node.

## IPv4 preference without disabling IPv6

The user-provided `gai.conf` change is a valid glibc address-selection override,
but it affects applications using `getaddrinfo`; it does not change DNS itself and
does not guarantee that every application chooses IPv4.

Inspect first:

```bash
grep -n 'precedence ::ffff:0:0/96' /etc/gai.conf
```

Apply only after approval:

```bash
grep -q '^precedence ::ffff:0:0/96  100$' /etc/gai.conf || \
  printf '%s\n' 'precedence ::ffff:0:0/96  100' | sudo tee -a /etc/gai.conf
```

Rollback:

```bash
sudo sed -i '/^precedence ::ffff:0:0\/96  100$/d' /etc/gai.conf
```

## DNS configuration

Do not edit `/etc/resolv.conf` until checking who manages it:

```bash
readlink -f /etc/resolv.conf
resolvectl status 2>/dev/null || true
```

On systems using `systemd-resolved`, Netplan, NetworkManager, or cloud-init,
direct edits may be overwritten. Configure DNS through that manager. Public
resolvers mentioned by the user are Google (`8.8.8.8`, `8.8.4.4`) and
Cloudflare (`1.1.1.1`, `1.0.0.1`); availability and policy suitability must be
tested from the target network.

## GitHub hosts-file override

Do not add this historical workaround:

```text
185.199.108.133 raw.githubusercontent.com
```

It appears inside some reviewed community installers, but GitHub uses a CDN and
addresses can change. A fixed entry may break downloads or route them incorrectly.
If present, compare with current DNS and remove it after fixing the underlying DNS
or routing issue.

## UFW

`ufw allow PORT` is incomplete unless the protocol, source range, IPv6 behavior,
and current SSH path are known. Safer inspection:

```bash
sudo ufw status verbose
sudo ss -lntup
```

Before enabling UFW remotely, explicitly allow the active SSH management path.
Enabling UFW does not mean "close every port for abuse"; it activates the current
policy and ruleset. Record `ufw status numbered` before edits and test a second SSH
session before closing the first.

## BBR and VPS optimizers

Verify kernel support and current state before changing sysctl values:

```bash
uname -r
sysctl net.ipv4.tcp_congestion_control net.core.default_qdisc
sysctl net.ipv4.tcp_available_congestion_control
```

The OPIran optimizer is reachable but high-impact: reviewed code can alter sysctl,
DNS, APT sources, kernel packages, `/etc/hosts`, and reboot the server. Download and
inspect it; do not pipe it directly into a shell on a production node.

## Ubuntu mirror selector

The `dev-ir` gist benchmarks mirrors and rewrites APT source URLs. Back up both
legacy and deb822 source locations, ensure the selected mirror matches the Ubuntu
suite, and run `apt-get update` after the change. A fast mirror is not necessarily
complete, current, or trustworthy.

## Server password and root shell

`passwd` changes a local account password. `sudo -i` opens a root login shell; it
does not "change the server to Ubuntu." Never send passwords to an agent, and
prefer SSH keys with a tested recovery path.

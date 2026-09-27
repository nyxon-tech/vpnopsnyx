# Node and relay lifecycle: build, register, migrate, retire

## Contents
1. First contact with a new server
2. Building an exit node (PasarGuard)
3. Registering it in the panel
4. Adding a relay
5. Migrating a location to a new server (keep the node ids)
6. Retiring a server
7. Upgrades and reboots
8. Package mirrors on restricted networks
9. Controlled package upgrade
10. Reboot verification

## 1. First contact with a new server

- The operator installs your key (`ssh-copy-id -i key.pub root@IP`). Some clouds force a password change
  at first login, which makes `ssh-copy-id` fail silently. Confirm with `ssh -o BatchMode=yes`.
- Refer to the server by IP (or a neutral alias) in your SSH config. Keep role and location labels in the
  private inventory, not in hostnames that other people see.
- Suggest disabling SSH password authentication once key login works.
- Take a baseline read-only snapshot: OS, kernel, cores, RAM, disk, NIC speed, free download
  (`scripts/node/snapshot.sh`, `scripts/node/fleet_quick.sh`), plus what else already runs there
  (`panels_scan.sh`). Resold servers often come with another admin's node installed.

## 2. Building an exit node (PasarGuard)

1. Docker from the distro repos (`docker.io` + the compose plugin) avoids running third-party install
   scripts as root.
2. Pull the node image **by digest**, the same one as the rest of the fleet, and tag it `latest`, so the
   compose file stays generic.
3. Copy the node layout from a healthy node: the compose file, the node management script, the node API
   service binary and its unit. Verify sha256 on both ends. Never copy another node's `.env` or tunnel
   registry, because they contain keys and tokens.
4. Create the instance with a fresh self-signed cert (EC P-256; CN and SAN = the server IP) and a fresh
   `API_KEY` (`scripts/node/install_extra_node.sh NAME SERVICE_PORT API_PORT TEMPLATE`).
5. Tuning (`/etc/sysctl.d/99-vpn-node.conf`): BBR + fq; larger socket buffers;
   `ip_local_reserved_ports` covering every fixed listener; **`tcp_mtu_probing = 0`**;
   `nofile` limits raised. Add 2–4 GB of swap with `vm.swappiness=10` as a cushion against OOM kills
   (`add_swap.sh`).
6. Reverse-tunnel clients to each relay (`client_tunnel.sh`). Use a fresh token per tunnel, generated on
   the relay and piped across, never printed.

## 3. Registering it in the panel

- Write the node through the panel's own CRUD inside the panel container. Pass the key and cert through
  environment variables or a temp file that gets deleted, never through stdout.
- Choose the core deliberately. A node on a cloned core also listens on every port that core defines.
- Restart the panel (announced, off-peak). The new node stays "connecting" until then.
- Afterwards, check that the node shows "connected", that its users appear in `node_user_usages` within
  minutes, and that a data test from in-country passes through every relay that is supposed to reach it.

## 4. Adding a relay

1. Baseline it (CPU steal, RAM, disk, NIC, and what the DC filters: inbound from abroad, egress to each
   exit). Test it with `path_test.sh` from the relay toward every exit, and from abroad toward the relay.
2. Pick the mode per location: reverse tunnel where inbound from abroad works, DNAT where only egress works.
3. Mirror an existing relay's tunnel set with new tokens: same forwards, different bind ports if you like.
4. On each node, add a client with the relay's token (piped).
5. Reserve every bind and forward port on the relay (`reserve_ports.sh relay`).
6. Data-test every location through the new relay from **another** in-country server.
7. Only then add it to DNS, one name at a time, and watch its load.

## 5. Migrating a location to a new server (keep the node ids)

The goal is to keep users, history, groups and hosts attached, with the shortest possible gap.

1. **Prepare** the new server fully: the node instances (same ports), tuning, and tunnel clients created
   **with the same tokens** as on the old server but not started (`PREPARE_ONLY=1`). The relays need no
   change at all.
2. **Repoint** the node rows in the panel DB to the new address, key and cert (`pg_repoint_nodes.sh`
   builds the script without printing keys). Keep the old row values for rollback.
3. **Restart the panel.** The new server receives its config within ~40 s. The old server stops Xray
   about `keep_alive` seconds later.
4. **As soon as the new ports listen**, stop and disable all old tunnel clients and start all new ones in
   one step, so the relay never sees two clients with one token. Poll for readiness with a simple loop
   whose arguments you write out explicitly (see the zsh warning in SKILL.md).
5. On the old server, add an nft **bridge** that DNATs the DIRECT ports to the new IP. The DIRECT DNS
   record can then move at any time.
6. Move the DIRECT DNS record. **Don't move it before step 3:** users would reach a server that has no
   config yet.
7. Data-test everything from in-country. Watch per-node users.
8. Retire the old server (section 6) once its traffic is gone.

## 6. Retiring a server

- Stop **and disable** every tunnel client. If a client is only stopped, a reboot revives it and it
  steals the relay's control channel from the new server.
- Stop your node containers and clear their restart policy. Leave alone any container whose logs show
  calls from a panel other than yours.
- Remove temporary `*_bridge` nft tables.
- Search the rest of the fleet and the panel DB (nodes, hosts) for the old IP. Clean up DNS, SSH config
  and `known_hosts`.
- Before cancelling a server, check whether the operator has reused it for something else. Look at the
  hostname, running services and recent logins.

## 7. Upgrades and reboots

- Run `apt-get upgrade` as a detached unit (`systemd-run --unit=ops-apt-upgrade …`) so an SSH drop can't
  kill it halfway. Use `NEEDRESTART_MODE=l` so nothing restarts silently. On busy relays, run it under
  `nice`/`ionice`.
- An upgrade of the docker package restarts every container. On a node that means every Xray instance;
  on the panel host it means a panel restart. Time it accordingly.
- Schedule kernel reboots one server at a time. A one-shot cron job that deletes itself before rebooting
  (and checks the year, so it can never fire again) works well. Afterwards, verify that the host came
  back, containers are up, tunnels are established, and the data test passes.
- Clocks: servers run in UTC; Iran is UTC+3:30. Always state both when you schedule something.

## 8. Package Mirrors On Restricted Networks

Mirror reachability and speed vary by network and date. Test candidate Ubuntu mirrors
by downloading the release-matched `Packages.gz`, record latency/throughput, back up
the current deb822 or `sources.list` configuration, and validate `apt-get update`.
Automatically restore the original configuration if Ubuntu indexes fail. Community
mirror scripts are discovery sources, not permission to execute them as root.

## 9. Controlled Package Upgrade

Upgrade one host at a time, off-peak, with a provider console available. Hold Docker
Engine, containerd, and related plugins during the general OS upgrade when restarting
all containers would be unsafe; upgrade that stack separately in its own window.
Use noninteractive package settings only after reviewing config-file behavior, keep
the old configuration (`--force-confold`) where appropriate, and run detached with a
durable log. `NEEDRESTART_MODE=l` lists restart requirements rather than silently
restarting services; confirm behavior against https://github.com/liske/needrestart.

## 10. Reboot Verification

Detect a completed reboot by a changed `/proc/sys/kernel/random/boot_id`, not ping
alone. Then verify failed units, every enabled tunnel/DNAT unit, nftables tables,
`net.ipv4.ip_forward`, containers, core listeners, and a real data test from another
in-country server. Start with the least risky host; reboot the panel host last when
its startup is relied upon to resynchronize nodes.

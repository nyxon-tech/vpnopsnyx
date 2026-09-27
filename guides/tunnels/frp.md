# FRP Runbook

**Source:** https://github.com/fatedier/frp  
**Trust:** `verified`, `official`

Pin matching `frps` and `frpc` releases. Capture server/client configuration, bind
and proxy ports, authentication method, TLS settings, dashboards, firewall, and
service units. Keep tokens and OIDC secrets outside Git and logs.

Validate config syntax, start the server first, then one client proxy. Verify logs,
server registration, listening sockets, and a real request through each proxy. Limit
dashboard exposure and permissions.

**Rollback:** stop new services, restore prior binaries/config/service units and
firewall rules, reload systemd, start the old pair, and confirm original proxies.

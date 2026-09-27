# rathole Runbook

**Upstream:** https://github.com/rapiz1/rathole  
**Community installer:** https://github.com/Musixal/rathole-tunnel

Pin an upstream release and verify its checksum. Capture server/client TOML, service
units, DNS/hosts changes, ports, and firewall state. Keep tokens outside Git and
restrict config permissions. Start server before client, verify authenticated
connection and forwarded listeners, then run a real request through each service.

The community installer is `third-party` and `high-impact`: it may alter systemd,
firewall state, and `/etc/hosts`. Review it before use.

**Rollback:** disable the new services, restore the previous TOML/binary and any
modified hosts/firewall entries, reload systemd, start the old version, and retest.

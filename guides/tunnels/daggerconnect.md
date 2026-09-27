# DaggerConnect Runbook

**Source:** https://github.com/itsFLoKi/DaggerConnect  
**Trust:** `verified-source`, `third-party`, `community`

Review the repository, installer, release artifacts, and dependencies before use;
do not rely on an unverified version notice. Record ports, addresses, services,
firewall/routing state, generated files, and hashes of downloaded artifacts.

Deploy first on non-production hosts. Verify both control and data planes, sockets,
packet counters, reconnect behavior, resource use, and a real request through every
published path.

**Rollback:** stop and disable created services, restore recorded network state,
remove only files created by the reviewed installer, restore previous routes/firewall,
and verify the original path. Use a provider console if management routing changes.

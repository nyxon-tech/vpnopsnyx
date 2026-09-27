# Private Operator Templates

Templates in this directory define structure without containing production data.

- [Fleet inventory example](fleet-inventory.example.md) records roles, providers,
  locations, services, and verification state without prescribing credentials.
- [Panel lab results](panel-lab-results.example.json) records API, restore, and
  end-to-end status for the six primary panels.
- [Datacenter benchmark](datacenter-benchmark.example.json) records anonymized,
  repeatable path measurements without public infrastructure identifiers.

Copy templates into a private workspace before filling them in. Do not commit real
IP inventories, domains, account identifiers, subscription URLs, tokens, passwords,
or private keys to VPNOpsNyx.

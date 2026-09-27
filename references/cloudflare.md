# Cloudflare DNS for relay fleets

## Contents
1. Record layout
2. Token handling
3. The helper script
4. Change patterns
5. Verifying

## 1. Record layout

- **DNS-only (grey cloud) A records.** Reality/Xray TCP on custom ports is not HTTP, and Cloudflare's
  proxy would terminate or refuse it. CDN-fronted designs (WS/gRPC over 443 through the proxy) are a
  separate architecture with their own trade-offs.
- One name per location (`de.example.com`, `nl.example.com`, …), with **one A record per relay** that
  can currently serve that location. Round-robin spreads users across relays.
- The subscription domain (`sub.example.com`) resolves to the relays that forward the panel port. If a
  host uses `{HOST_DOMAIN}`, it is also a tunnel address (see `architecture.md` §4).
- DIRECT names (`de.direct.example.com`) point at the exit IP itself.
- TTL "auto" (300 s) is fine. Clients and ISP resolvers cache anyway, so expect 5–15 minutes before most
  users follow a change.
- Resellers may CNAME their branded names to yours. One change then reaches all of their customers.

## 2. Token handling

- Create an API token scoped to **Zone → DNS → Edit** on only the zones you manage. Never use the global
  API key.
- Store it in a file with mode 600 (`~/.config/cloudflare/api_token`, directory 700). Never put it on a
  command line or in an environment variable that ends up in logs.
- Give it to curl through a header read from a process substitution, so the token never appears in argv
  (`ps`) or in the shell history:
  ```bash
  curl -s -H @<(printf 'Authorization: Bearer %s\n' "$(tr -d '\n' < "$TOKEN_FILE")") "$API$path"
  ```
- If a token was ever pasted into a chat or a terminal transcript, ask the operator to roll it.

## 3. The helper script

`scripts/local/cf.sh` wraps the API with the token handling above:
```
cf.sh zones                                 list zones: name id
cf.sh records ZONE [name-substring]         name type content ttl proxied id
cf.sh add-a ZONE NAME IP [ttl]              add a DNS-only A record
cf.sh del-a ZONE NAME IP                    delete the A record NAME -> IP
cf.sh GET|POST|PUT|PATCH|DELETE PATH [json] raw call
```
`NAME` is the full name (`de.example.com`). If you give the helper its own permission rule in your agent
(for example `Bash(/full/path/cf.sh *)`), always call it by that exact path.

## 4. Change patterns

| Goal | Change |
|---|---|
| A relay cannot serve location X | `del-a` the relay's IP from X's name, and from the subscription domain if it doubles as X's tunnel address |
| A relay is back | Data-test it for every location first, then `add-a` it back to exactly those names |
| A relay is fully down (quota exhausted, provider outage) | Remove it from every name. Check that each name still has at least one IP |
| New relay | Add it to a single location first, watch its users and data test, then extend |
| Shift load between relays | Change which names list which relays. You can't weight round-robin, but you can remove a relay from the heaviest names |

Record every change as `time | name | ip | added/removed | reason`. If the operator doesn't want backups,
this log is how you undo a change.

## 5. Verifying

```bash
dig +short @1.1.1.1 de.example.com A
dig +short @8.8.8.8 de.example.com A
```
Then run the data test against **each** IP returned, using that name's port. A name is only healthy
when every IP in it passes.

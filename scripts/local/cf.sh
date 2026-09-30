#!/usr/bin/env bash
# Token-safe Cloudflare DNS helper (bash + curl + perl; works on macOS without python).
# The API token lives in a mode-600 file and reaches curl through a process-substitution header
# file, so it never appears in argv, `ps` or shell history.
#   TOKEN_FILE=~/.config/cloudflare/api_token  (default; use one file per Cloudflare account)
#
#   cf.sh zones                               list zones: name id
#   cf.sh records ZONE [name-substring]       name type content ttl proxied id
#   cf.sh add-a ZONE NAME IP [ttl]            add a DNS-only A record
#   cf.sh del-a ZONE NAME IP                  delete the A record NAME -> IP
#   cf.sh GET|POST|PUT|PATCH|DELETE PATH [json]   raw call
#
# Store a token without echoing it (in a real terminal; a chat app's "Run" button gives empty stdin):
#   read -rs T && printf '%s' "$T" > ~/.config/cloudflare/api_token && chmod 600 ~/.config/cloudflare/api_token && unset T && wc -c < ~/.config/cloudflare/api_token
set -u
TOKEN_FILE=${TOKEN_FILE:-$HOME/.config/cloudflare/api_token}
[ -s "$TOKEN_FILE" ] || { echo "missing or empty $TOKEN_FILE" >&2; exit 1; }
API=https://api.cloudflare.com/client/v4
call() {
  local method=$1 path=$2 body=${3:-}
  if [ -n "$body" ]; then
    curl -s -m 30 -X "$method" -H @<(printf 'Authorization: Bearer %s\n' "$(tr -d '\n' < "$TOKEN_FILE")") \
      -H "Content-Type: application/json" --data "$body" "$API$path"
  else
    curl -s -m 30 -X "$method" -H @<(printf 'Authorization: Bearer %s\n' "$(tr -d '\n' < "$TOKEN_FILE")") "$API$path"
  fi
}
J='use JSON::PP; local $/; my $j = decode_json(<STDIN>);'
zone_id() { call GET "/zones?name=$1" | perl -e "$J"' print $j->{result}[0]{id} // ""'; }
case "${1:-}" in
  zones)
    call GET "/zones?per_page=50" | perl -e "$J"' printf "%-24s %s\n", $_->{name}, $_->{id} for @{$j->{result}}' ;;
  records)
    zid=$(zone_id "$2"); [ -n "$zid" ] || { echo "zone $2 not found" >&2; exit 1; }
    call GET "/zones/$zid/dns_records?per_page=500" | F="${3:-}" perl -e "$J"' for (@{$j->{result}}) { next unless index($_->{name}, $ENV{F}) >= 0; printf "%-34s %-6s %-40s ttl=%-5s proxied=%-5s %s\n", $_->{name}, $_->{type}, $_->{content}, $_->{ttl}, ($_->{proxied} ? "true" : "false"), $_->{id} }' ;;
  add-a)
    zid=$(zone_id "$2")
    call POST "/zones/$zid/dns_records" "{\"type\":\"A\",\"name\":\"$3\",\"content\":\"$4\",\"ttl\":${5:-1},\"proxied\":false}" \
      | perl -e "$J"' print $j->{success} ? "added\n" : encode_json($j->{errors})."\n"' ;;
  del-a)
    zid=$(zone_id "$2")
    rid=$(call GET "/zones/$zid/dns_records?type=A&name=$3&content=$4" | perl -e "$J"' print $j->{result}[0]{id} // ""')
    [ -n "$rid" ] || { echo "no A record $3 -> $4"; exit 0; }
    call DELETE "/zones/$zid/dns_records/$rid" | perl -e "$J"' print $j->{success} ? "deleted\n" : encode_json($j->{errors})."\n"' ;;
  GET|POST|PUT|PATCH|DELETE) call "$@" ;;
  *) sed -n '2,16p' "$0" ;;
esac

#!/usr/bin/env bash
# Prove the walls hold. Run after `docker compose up -d` (and with --profile red
# for the red checks). Every line should print PASS.
set -uo pipefail

pass(){ echo "PASS  $1"; }
fail(){ echo "FAIL  $1"; FAILED=1; }
FAILED=0

# 1. Internal networks really are internal
for n in llm-red llm-blue arena-net siem-net; do
  v=$(docker network inspect "purple-swarm_$n" -f '{{.Internal}}' 2>/dev/null)
  [ "$v" = "true" ] && pass "$n is internal" || fail "$n is NOT internal"
done

# 2. Published ports bind to localhost only
if docker compose port splunk 8000 2>/dev/null | grep -q '^127.0.0.1:'; then
  pass "Splunk UI bound to 127.0.0.1"
else
  fail "Splunk UI not bound to 127.0.0.1"
fi

# 3. Red can't reach the internet, Splunk, or blue's knowledge store
if docker compose ps --status running red-cai | grep -q red-cai; then
  docker compose exec -T red-cai curl -s -m 5 https://example.com >/dev/null \
    && fail "red reached the internet" || pass "red has no internet"
  docker compose exec -T red-cai curl -s -m 5 http://splunk:8000 >/dev/null \
    && fail "red reached Splunk" || pass "red cannot reach Splunk"
  docker compose exec -T red-cai curl -s -m 5 http://qdrant-blue:6333 >/dev/null \
    && fail "red reached blue's knowledge store" || pass "red cannot reach qdrant-blue"
  docker compose exec -T red-cai curl -s -m 5 http://juice-shop:3000 >/dev/null \
    && pass "red can reach the arena" || fail "red cannot reach the arena"
  [ "$(docker compose exec -T red-cai id -u)" != "0" ] \
    && pass "red runs as non-root" || fail "red runs as root"
else
  echo "SKIP  red checks (start with: docker compose --profile red up -d)"
fi

# 4. No container has the Docker socket
if docker compose ps -q | xargs -r docker inspect -f '{{range .Mounts}}{{.Source}} {{end}}' | grep -q docker.sock; then
  fail "a container mounts docker.sock"
else
  pass "no docker.sock mounts"
fi

exit $FAILED

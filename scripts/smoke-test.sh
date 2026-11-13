#!/usr/bin/env bash
# Smoke test: scripts/smoke-test.sh <image>
# Checks that the IDE answers on :3000, that the EduIDE plugins and the
# Mannheim additions are present, and that java and mvn run.
set -u

image="${1:?usage: $0 <image>}"
failures=0
pass() { echo "ok    $*"; }
fail() { echo "FAIL  $*"; failures=$((failures + 1)); }

container=""
trap '[ -n "$container" ] && docker rm -f "$container" > /dev/null 2>&1' EXIT

# The IDE binds 127.0.0.1 inside the container by default; --hostname=0.0.0.0
# makes the published port reachable from the host.
container="$(docker run -d --rm -p 127.0.0.1::3000 "$image" /home/project --hostname=0.0.0.0)" || { fail "container does not start"; exit 1; }
port="$(docker port "$container" 3000/tcp | head -1 | sed 's/.*://')"
status=000
for _ in $(seq 1 60); do
    status="$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:${port}/" || true)"
    [ "$status" = 200 ] && break
    sleep 2
done
[ "$status" = 200 ] && pass "IDE answers HTTP 200 on :3000" || fail "IDE answers HTTP $status on :3000"

check() { # check <description> <command run in the container>
    if docker exec "$container" sh -c "$2" > /dev/null 2>&1; then pass "$1"; else fail "$1 ($2)"; fi
}

for plugin in theia-cloud-monitor scorpio data-bridge ms-vscode.live-server; do
    check "plugin $plugin present" "test -d /home/theia/plugins/$plugin"
done
check "java 25" "java -version 2>&1 | grep -q '\"25\\.'"
check "mvn runs" "mvn -v"
check "MAVEN_OPTS keeps base options and adds ours" "echo \"\$MAVEN_OPTS\" | grep -q -- '-Xmx.*--sun-misc-unsafe-memory-access=allow'"
check "course settings merged, edition settings kept" "grep -q editor.formatOnSave /home/theia/.theia-ide/settings.json && grep -q java.jdt.ls.vmargs /home/theia/.theia-ide/settings.json"
check "keymaps shipped" "test -s /home/theia/.theia-ide/keymaps.json"

echo
if [ "$failures" -eq 0 ]; then echo "smoke test passed: $image"; else echo "smoke test FAILED ($failures): $image"; exit 1; fi

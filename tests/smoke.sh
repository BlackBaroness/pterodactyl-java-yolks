#!/bin/bash
set -euo pipefail

image=${1:?image required}
version=${2:?Java version required}
platform=${3:-linux/amd64}
engine=${CONTAINER_ENGINE:-docker}
test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# Verify the account lookup used by Paper/Leaf, including with a read-only root.
for runtime_user in container 1000:1000; do
    # shellcheck disable=SC2016 # The script expands inside the container.
    "$engine" run --rm -i --platform "$platform" --read-only --user "$runtime_user" \
    --tmpfs /tmp:rw,exec,mode=1777 \
    --tmpfs /home/container:rw,mode=1777 \
    --entrypoint /bin/bash \
    "$image" -euc '
        cat > /tmp/UnixSystemCheck.java
        export STARTUP="java /tmp/UnixSystemCheck.java $(id -u) $(id -g)"
        exec /entrypoint.sh
    ' < "$test_dir/UnixSystemCheck.java"
done

# Verify the actual Pterodactyl entrypoint and variable substitution.
output=$("$engine" run --rm --platform "$platform" \
    -e 'STARTUP=java -XshowSettings:properties -version' "$image" 2>&1)
printf '%s\n' "$output"
grep -Eq "java.specification.version = $version$" <<< "$output"
grep -Fq 'java.vendor = Eclipse Adoptium' <<< "$output"

output=$("$engine" run --rm --platform "$platform" \
    -e 'STARTUP=echo {{SERVER_NAME}}' \
    -e 'SERVER_NAME=Leaf-test-server' "$image" 2>&1)
[[ "$output" == *'Leaf-test-server' ]]

# shellcheck disable=SC2016 # The script expands inside the container.
"$engine" run --rm --platform "$platform" --entrypoint /bin/bash "$image" -euc '
    test "$(id -un)" = container
    test "$HOME" = /home/container
    test "$PWD" = /home/container
    test -w "$HOME"
    test -w /tmp
    test -s /etc/ssl/certs/ca-certificates.crt
    test -s "$JAVA_HOME/lib/security/cacerts"
    test -n "$(fc-list)"
    javac -version
    jcmd -h >/dev/null
    jfr --version
    ldconfig -p | grep -q libstdc++.so.6
    while IFS= read -r library; do
        dependencies=$(LD_LIBRARY_PATH="$JAVA_HOME/lib:$JAVA_HOME/lib/server" ldd "$library" 2>&1)
        if [[ "$dependencies" == *"not found"* ]]; then
            printf "%s\n" "$dependencies" >&2
            exit 1
        fi
    done < <(find "$JAVA_HOME/lib" -name "*.so" -type f)
'

# The server must receive stop signals directly as PID 1.
signal_startup='bash /tmp/signal.sh'
# shellcheck disable=SC2016 # Create the signal handler inside the container.
container=$("$engine" run -d --platform "$platform" \
    --entrypoint /bin/bash -e "STARTUP=$signal_startup" "$image" -euc '
        printf "trap \"exit 143\" TERM\ntouch /tmp/ready\nwhile :; do sleep 1; done\n" > /tmp/signal.sh
        exec /entrypoint.sh
    ')
trap '"$engine" rm -f "$container" >/dev/null 2>&1 || true' EXIT
for ((attempt=0; attempt<50; attempt++)); do
    # shellcheck disable=SC2016 # Read the container PID namespace.
    if "$engine" exec "$container" /bin/sh -c 'test -f /tmp/ready && test "$(cat /proc/1/comm)" = bash'; then
        break
    fi
    sleep 0.1
done
test "$attempt" -lt 50
"$engine" stop --time 5 "$container" >/dev/null
exit_code=$("$engine" inspect --format '{{.State.ExitCode}}' "$container")
test "$exit_code" = 143

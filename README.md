# Pterodactyl Temurin images

Only Eclipse Temurin **25** and **27**, based on **Debian 13 (trixie-slim)**,
for modern Minecraft servers, primarily Leaf 26.2+.

| Java | Image | Platforms |
| --- | --- | --- |
| 25 | `ghcr.io/blackbaroness/pterodactyl-java-yolks:java_25` | amd64, arm64 |
| 27 | `ghcr.io/blackbaroness/pterodactyl-java-yolks:java_27` | amd64, arm64 |

Choose the Java version supported by your Leaf build and plugins. The images
contain the complete official Temurin HotSpot JDK, including its native symbols,
`javac`, `jcmd` and `jfr`, but no bundled server. No JVM tuning flags are
forced; set the startup command and memory/GC options in the panel.

## Build and updates

GitHub Actions builds and publishes both versions on demand (`workflow_dispatch`)
or every Monday at **03:17 UTC**. Pushes do not trigger builds. The workflow pulls
fresh base images, tests both architectures before publishing each version, and
uses `GITHUB_TOKEN` to publish to `ghcr.io/<owner>/<repository>:java_<version>`.
Enable Actions and package publishing in your fork; make packages public for
unauthenticated Wings pulls. Existing containers need to be recreated with the
new image to receive updates. Previously published obsolete registry tags are
not deleted by removing their source files.

```sh
docker build --pull --build-arg JAVA_VERSION=25 -t java-yolk:25 .
docker run --rm -e 'STARTUP=java -version' java-yolk:25
bash tests/smoke.sh java-yolk:25 25
```

Use `JAVA_VERSION=27` for the other image. The default is 25. The container runs
as UID/GID 1000 in `/home/container`, supports Pterodactyl `{{VARIABLE}}` startup
placeholders, shell quoting, `TZ` and `INTERNAL_IP`, and forwards stop signals to
the server process. Shell syntax in `STARTUP` is trusted administrator input.

## spark async-profiler

The image includes glibc, `libstdc++6` and the complete upstream HotSpot runtime.
Fonts, fontconfig and native AWT dependencies are included for plugins that render
text, following [PaperMC's Java installation guidance](https://docs.papermc.io/misc/java-install/)
to avoid headless Java packages. No desktop or X server is installed. The profiler
itself comes from spark; it does not need a separate installation in the image.

[spark's requirements](https://spark.lucko.me/docs/misc/Using-async-profiler)
cover Linux amd64/arm64. When kernel perf-events are unavailable, spark
automatically falls back to `itimer`, which is sufficient for most users.
Native CPU profiling through perf-events also depends on the host kernel,
Docker seccomp/capabilities and Wings configuration; a Dockerfile cannot grant
that access. Do not enable privileged containers or `SYS_ADMIN` by default.
If you need perf-events, configure the minimum required host/runtime access
using the [async-profiler container guide](https://github.com/async-profiler/async-profiler/blob/master/docs/ProfilingInContainer.md).

Keep `/tmp` writable and executable so spark can extract and load its native
library. Actual profiling should be verified on the target Wings host with
your Leaf and spark versions; a container smoke test cannot verify kernel
permissions or compatibility of every plugin with Java 27.

# TH Mannheim Java 25 image (course "PR2").
# Derived from the EduIDE standalone Java 25 edition image. Everything else
# (Scorpio, data bridge, Java toolchain and extensions, git credential cache)
# comes from the base and is not repeated here.

# Test build from an EduIDE PR. Moves to 2.0.0 at the EduIDE release, after
# that Renovate bumps it (see renovate.json).
ARG EDUIDE_VERSION=pr-221
FROM ghcr.io/eduide/eduide/java-25-standalone:${EDUIDE_VERSION}

# Live Preview is not part of the edition image. An extension is a vsix
# unpacked into /home/theia/plugins/<id>.
ARG LIVE_SERVER_VERSION=0.4.20
RUN d=/home/theia/plugins/ms-vscode.live-server && mkdir -p "$d" && \
    curl -fsSL "https://open-vsx.org/api/ms-vscode/live-server/${LIVE_SERVER_VERSION}/file/ms-vscode.live-server-${LIVE_SERVER_VERSION}.vsix" -o /tmp/ext.vsix && \
    unzip -q /tmp/ext.vsix -d "$d" && rm /tmp/ext.vsix

# Silence the sun.misc.Unsafe warning of Maven on Java 25 (per course config).
# Appended, the base already sets JVM options for Maven.
ENV MAVEN_OPTS="${MAVEN_OPTS} --sun-misc-unsafe-memory-access=allow"

# User-level defaults, not files in /home/project, so the workspace stays empty
# and a clone works. The edition ships ~/.theia-ide/settings.json with its own
# tuning, so the course settings are merged into it (course wins on conflicts).
COPY --chown=theia:theia user/settings.json /tmp/course-settings.json
COPY --chown=theia:theia user/keymaps.json /home/theia/.theia-ide/keymaps.json
RUN node -e ' \
  const fs = require("fs"); \
  const f = "/home/theia/.theia-ide/settings.json"; \
  const read = (p) => JSON.parse(fs.readFileSync(p, "utf8").replace(/^\s*\/\/.*$/gm, "")); \
  fs.writeFileSync(f, JSON.stringify({ ...read(f), ...read("/tmp/course-settings.json") }, null, 4)); \
' && rm /tmp/course-settings.json

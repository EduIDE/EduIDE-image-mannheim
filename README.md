# EduIDE image for TH Mannheim

TH Mannheim's own [EduIDE](https://github.com/EduIDE/EduIDE) image for the course "PR2" (Java 25).
It is also the reference example for how a university derives an installation-specific image from an EduIDE edition image.
The image is a thin layer: `FROM` an EduIDE edition image plus the few things this installation needs.

Published as `ghcr.io/eduide/eduide-image-mannheim/java-25`.

## Use it as a template for your university

1. Click "Use this template" on GitHub and create your repository.
2. Pick the edition image in the `Dockerfile` (`FROM ghcr.io/eduide/eduide/<language>-standalone:${EDUIDE_VERSION}`).
   Standalone images work without Artemis, `<language>-artemis` images are for Artemis installations.
   Scorpio, the data bridge and the Theia Cloud monitor stay in the image, do not remove them.
3. Add what you need, keep it small:
   - packages: `USER root`, `apt-get install`, then `USER theia` again
   - extensions: unpack the vsix into `/home/theia/plugins/<extension id>` (see the Live Preview step in the `Dockerfile`)
   - settings: edit `user/settings.json`, merged into the edition's user settings (yours win)
   - keybindings: edit `user/keymaps.json`
4. Change the image name in `.github/workflows/build.yml` (`image-name`, and again in the smoke job) and in the `verify` job of `.github/workflows/release.yml`, e.g. `eduide/<your-repo>/<name>`.
   The workflow is the shared EduIDE one and publishes multi-arch (amd64 and arm64) to `ghcr.io`.
5. Push to `main`, or open a pull request, to build.
   Every build runs the smoke test: the IDE answers HTTP 200 on :3000, the EduIDE plugins are present, `java` and `mvn` run.
   Adapt `scripts/smoke-test.sh` to your additions.
6. Run a release (see Versioning), then make the package public in the GitHub package settings if your cluster pulls without credentials.
7. Reference the image in your installation's Helm values with the FULL image path and a tag.
   The EduIDE chart prefixes `ghcr.io/eduide` to every image without a tag, so a path alone would be rewritten:

   ```yaml
   image: ghcr.io/eduide/eduide-image-mannheim/java-25:2.0.0
   ```

Adjust `renovate.json` (the `depNameTemplate`) if you derive from another edition image.

## Versioning

The image tag is a semantic version of this repository: `2.0.0`, or `2.0.0-rc.1` for a prerelease.
It usually follows the EduIDE version the image is built on; a change that only concerns this repository (new extension, setting, package) is a patch bump (`2.0.1`).
Releases are manual and the only way to publish a numbered tag: merge a release pull request (the `CHANGELOG.md` section), then run

```sh
gh workflow run release.yml -f version=2.0.0
```

`release.yml` drafts the GitHub Release, builds the image as `2.0.0`, verifies it and publishes the release, which creates the `v2.0.0` tag.
It refuses a release while `EDUIDE_VERSION` in the `Dockerfile` is not a released EduIDE version.
The `release` skill (`.claude/skills/release/SKILL.md`) walks through it.
Pushes to `main` publish `latest` and `latest-<short sha>`, pull requests publish `pr-<N>`.
Do not use `latest` in a cluster.

`EDUIDE_VERSION` in the `Dockerfile` currently points at an EduIDE pull request build (`pr-221`).
It moves to `2.0.0` at the EduIDE release.
After that Renovate opens a pull request for every new numbered EduIDE release (only semver tags are considered).
Merge it, then release a new version.

## What TH Mannheim adds

| What | Where |
|---|---|
| Live Preview extension (`ms-vscode.live-server`) | `Dockerfile` |
| `MAVEN_OPTS` with `--sun-misc-unsafe-memory-access=allow` (no Unsafe warnings on Java 25), appended to the base options | `Dockerfile` |
| Editor and Java defaults (format on save, organize imports, inlay hints, telemetry off, dark theme) | `user/settings.json` |
| Keybindings: `alt+x` closes the editor, `ctrl+alt+b` runs the build task | `user/keymaps.json` |

Java, Maven, the Java extensions, the git credential cache and the Scorpio workspace bootstrap come from `java-25-standalone`.

## Build and test locally

```sh
docker build -t eduide-image-mannheim .
scripts/smoke-test.sh eduide-image-mannheim
```

## License

MIT, like EduIDE (see `LICENSE`).

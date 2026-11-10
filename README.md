# Personal Dev Container Templates

Personal [Dev Container Template](https://containers.dev/implementors/templates) collection, published to GHCR and reusable across projects.

| Template | ID |
| --- | --- |
| Personal Dev | `ghcr.io/huybui38/dev-container-template/personal-dev:latest` |

## `personal-dev`

A general-purpose dev container for day-to-day work:

- **git CLI** and **GitHub CLI** (`gh`)
- **Node.js LTS + npm** via the official [node feature](https://github.com/devcontainers/features/tree/main/src/node) (`nodeVersion` template option)
- **opencode** (OpenCode 2) installed on first container create
- **zsh + Oh My Zsh** (from the base image) as the default terminal
- Multi-arch base image (`linux/amd64` + `linux/arm64`) — runs natively on Apple Silicon
- Runtime-agnostic: works with **Docker Desktop or Podman** (rootless, daemonless)

### Host isolation by default

- Only the project folder is bind-mounted (`workspaceMount`), at a fixed path — nothing else from the host filesystem is visible
- No host mounts: no `~/.ssh`, no `~/.gitconfig`, no host Docker socket (`mounts: []`)
- Runs as the built-in non-root `vscode` user
- No forwarded ports unless listed (`forwardPorts: []`); forwarded ports bind to `localhost` only
- Credentials are created inside the container (`gh auth login`, `git config --global user.…`)

macOS setup recommendations: [`src/personal-dev/NOTES.md`](src/personal-dev/NOTES.md)

## Structure

```
├── src
│   └── personal-dev
│       ├── devcontainer-template.json   # template metadata + options
│       ├── NOTES.md                     # template docs (merged into generated README.md)
│       └── .devcontainer
│           ├── devcontainer.json
│           └── Dockerfile
└── test
    ├── personal-dev
    │   └── test.sh                       # smoke test, runs inside the built container
    └── test-utils
        └── test-utils.sh
```

Each Template has its own sub-folder under `src/`, containing a `devcontainer-template.json` and a `.devcontainer/` folder. To add another template later, add a new folder following the same layout — the release workflow publishes everything under `src/` automatically.

## Using in another project

```bash
npm install -g @devcontainers/cli        # or: brew install devcontainer

devcontainer templates apply --workspace-folder . \
    --template-id ghcr.io/huybui38/dev-container-template/personal-dev:latest \
    --template-args '{ "imageVariant": "ubuntu-24.04", "nodeVersion": "lts" }'
```

Then run **Dev Containers: Reopen in Container** (VS Code) or `devcontainer up --workspace-folder .`. You can also type the template ID into the VS Code / GitHub Codespaces "Add Dev Container Configuration Files" flow.

> Packages on GHCR are private by default. Make the template public once at
> <https://github.com/users/huybui38/packages/container/dev-container-template%2Fpersonal-dev/settings>

## Publishing

The [release workflow](.github/workflows/release.yaml) publishes every template under `src/` to GHCR and regenerates each template's `README.md` (merged from `devcontainer-template.json` + `NOTES.md`):

1. Bump `version` (semver) in the template's `devcontainer-template.json`
2. Push to `main`
3. Run **Release Dev Container Templates & Generate Documentation** (workflow_dispatch)

Requires *Settings → Actions → General → "Allow GitHub Actions to create and approve pull requests"* for the automated documentation PR.

## Testing

PRs touching a template run its smoke test automatically ([CI](.github/workflows/test-pr.yaml)). Locally (needs Docker; the template itself also runs under Podman, but these scripts assume the Docker CLI):

```bash
./.github/actions/smoke-test/build.sh personal-dev
./.github/actions/smoke-test/test.sh personal-dev
```

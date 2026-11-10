## What's inside

| Tool | Source | Notes |
| --- | --- | --- |
| git CLI | base image + `apt-get install` | preinstalled in the base image, kept explicit so it is always present |
| GitHub CLI (`gh`) | [github-cli feature](https://github.com/devcontainers/features/tree/main/src/github-cli) | authenticate inside the container, not on the host |
| Node.js LTS + npm | [node feature](https://github.com/devcontainers/features/tree/main/src/node) | version configurable via the `nodeVersion` template option |
| opencode (OpenCode 2) | `npm install -g @opencode/cli` in `postCreateCommand` | installed on first create, so it stays current |
| zsh + Oh My Zsh | base image | wired as the default VS Code terminal profile |

The base image (`mcr.microsoft.com/devcontainers/base`) is multi-arch (`linux/amd64` + `linux/arm64`), so this template runs natively on Apple Silicon.

## Host isolation by default

This template is intentionally isolated from the host machine:

- **Only the project folder is mounted** — `workspaceMount` bind-mounts just the workspace, at a fixed path (`/workspaces/<project>`). Nothing else from the host filesystem is visible.
- **No host credentials** — `mounts` is empty: no `~/.ssh`, no `~/.gitconfig`, no `~/.aws`, no host keychains.
- **No host Docker socket** — the host Docker daemon is not reachable from inside. If you need containers, add the Docker-in-Docker feature; do NOT add Docker-from-Docker (it mounts the host socket and breaks isolation).
- **Non-root user** — everything runs as the built-in `vscode` user.
- **No forwarded ports by default** — `forwardPorts` is empty; ports you add are bound to `localhost` on the host only.
- **Credentials live in the container** — run `gh auth login` and set `git config --global user.name` / `user.email` inside the container on first create.

If you occasionally want the host SSH agent instead of in-container keys, opt in explicitly (off by default):

```jsonc
"remoteEnv": { "SSH_AUTH_SOCK": "/ssh-agent" },
"mounts": [ "source=${localEnv:SSH_AUTH_SOCK},target=/ssh-agent,type=bind" ]
```

## Container runtime: Docker Desktop or Podman

This template is runtime-agnostic — everything in it (features, named volumes, port forwarding) works with both:

- **Docker Desktop** — the default path.
- **Podman (5+)** — a daemonless, rootless alternative: no root-owned daemon or socket on the host, and no Docker Desktop license. On macOS it runs a small Apple Hypervisor Linux VM behind the scenes, with virtiofs mounts on Podman 5+:

  ```bash
  brew install podman
  podman machine init
  podman machine start
  ```

  Point your tools at it:

  ```jsonc
  // VS Code user settings (per the Dev Containers docs)
  "dev.containers.dockerPath": "podman",
  "dev.containers.dockerComposePath": "podman-compose"
  ```

  ```bash
  # Dev Container CLI (supported flag, tested by the CLI's own Podman suite)
  devcontainer up --docker-path podman --workspace-folder .
  ```

## macOS development experience - recommendations

1. **Run native arm64 on Apple Silicon.** All images and features here are multi-arch; verify with `uname -m` inside the container (should print `arm64`). Avoid `--platform linux/amd64` overrides - Rosetta/QEMU emulation is slow.
2. **Pick your runtime: Docker Desktop or Podman.** Podman is rootless and daemonless, which fits the isolation goals of this template. See the runtime section above.
3. **Tune Docker Desktop (if you use it).** Settings -> General: use **VirtioFS** for file sharing (much faster bind mounts), give the VM **>= 8 GB RAM / 4 CPUs** in Resources, and on Apple Silicon enable **"Use Rosetta for x86_64/amd64 emulation"** as a fallback for the rare amd64-only image.
4. **Keep `node_modules` out of the bind mount.** Bind mounts are the slowest I/O path on macOS. After applying the template, uncomment this in `.devcontainer/devcontainer.json`:
   ```jsonc
   "mounts": [
       "source=${localWorkspaceFolderBasename}-node_modules,target=${containerWorkspaceFolder}/node_modules,type=volume"
   ]
   ```
   The volume is engine-managed (Docker or Podman), so isolation from the host is preserved.
5. **Maximum isolation + speed: "Clone Repository in Named Container Volume".** VS Code and the `devcontainer` CLI can clone your repo straight into a volume so the source never touches the host filesystem. Combine with this template for a fully hermetic workspace.
6. **Familiar shell.** zsh + Oh My Zsh ship with the base image and are wired as the default terminal. Install a Nerd Font (e.g. MesloLGS NF) in your host terminal for proper glyph rendering.
7. **Match your timezone.** Add `"containerEnv": { "TZ": "America/Los_Angeles" }` (or your zone) so timestamps match the host.
8. **Authenticate inside the container.** `gh auth login` for GitHub over HTTPS, and set `git config --global user.name "..."` / `user.email "..."` on first create. Nothing is inherited from the host.
9. **Opt into SSH agent forwarding only when needed.** See the snippet above; leave it off to keep the container isolated.

## Using this template in another project

```bash
# once per machine
npm install -g @devcontainers/cli    # or: brew install devcontainer

# inside the project
devcontainer templates apply --workspace-folder . \
    --template-id ghcr.io/huybui38/dev-container-template/personal-dev:latest \
    --template-args '{ "imageVariant": "ubuntu-24.04", "nodeVersion": "lts" }'
```

Then open the project in VS Code and run **Dev Containers: Reopen in Container**, or start it with `devcontainer up --workspace-folder .`.

## Customizing

- `imageVariant` - base image: `ubuntu-24.04` (default), `ubuntu-22.04`, `debian-12`
- `nodeVersion` - `lts` (default), `latest`, or a major version (`24`, `22`, `20`)
- `forwardPorts` - list the ports your project serves
- opencode v1 is still available if you prefer it: use `npm install -g opencode-ai@latest` instead of `@opencode/cli`

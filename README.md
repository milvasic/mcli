# mcli

A single-file Bash CLI for managing Docker Compose services.

Each service is an immediate subdirectory containing a Compose file (`docker-compose.yml`, `docker-compose.yaml`, `compose.yml`, or `compose.yaml`). `mcli` discovers these automatically and lets you start, stop, restart, pull images and more for all of them — or just the ones you name.

## Install

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/milvasic/mcli/refs/heads/main/install.sh)"
```

This installs `mcli` to `/usr/local/bin`. If a previous version is already installed, the installer will prompt you to upgrade.

For non-interactive environments (CI, scripts), pass `--yes` to auto-approve upgrades:

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/milvasic/mcli/refs/heads/main/install.sh)" -- --yes
```

`wget` is also supported if `curl` is not available.

## Uninstall

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/milvasic/mcli/refs/heads/main/install.sh)" -- --uninstall
```

This removes `mcli` from `/usr/local/bin`.

## Usage

```
mcli <command> [service1 [service2 ...]] [--dry-run] [--all]
```

### Commands

| Command                      | Description                                                          |
| ---------------------------- | -------------------------------------------------------------------- |
| `list`                       | List discovered services (disabled services are marked)              |
| `create-network`             | Ensure the shared `services` Docker bridge network exists            |
| `start [services..]`         | Start all or specified services (skips disabled)                     |
| `stop [services..]`          | Stop all or specified services, removing orphans (skips disabled)    |
| `restart [services..]`       | Restart all or specified services (skips disabled)                   |
| `pull [services..]`          | Pull latest images, skipping buildable services (skips disabled)     |
| `backup <service>`           | Stop service, back up to `.bkp/<service>/<date>[.<counter>].tar.gz`, restart service. Archive includes `image.txt` with container image digests. |
| `backup <service> --live`    | Back up without stopping (live backup)                               |
| `backup size`                | Show disk space used by all backups under `.bkp/`                   |
| `restore <service>`          | Restore service from a backup archive in `.bkp/<service>/`; interactive picker when multiple backups exist. Wipes the service dir before extraction so its contents match the archive exactly. |
| `disable <services..>`       | Disable one or more services (excluded from start/stop/restart/pull) |
| `enable <services..>`        | Re-enable one or more previously disabled services                   |
| `update`                     | Update mcli to the latest version                                    |
| `completions bash\|zsh`      | Output shell completion script for bash or zsh                       |
| `version`, `--version`, `-v` | Print version                                                        |
| `help`, `--help`, `-h`       | Show help message                                                    |

### Options

| Option      | Description                                                                                                                                 |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `--dry-run` | Print the commands that would be executed without running them (applies to: `create-network`, `start`, `stop`, `restart`, `pull`, `backup`, `restore`, `update`) |
| `--all`     | Include disabled services in start/stop/restart/pull (applies to: `start`, `stop`, `restart`, `pull`)                                       |
| `--live`    | Skip stop/start around backup; back up while the service is running (applies to: `backup`)                                                   |

`--dry-run`, `--all`, and `--live` can appear anywhere after the command.

### Examples

```sh
# Start all discovered services
mcli start

# Stop specific services
mcli stop traefik portainer

# Preview what would happen without executing anything
mcli restart --dry-run

# Pull latest images for a single service
mcli pull nginx

# List all discovered services
mcli list

# Disable a service so it's skipped by start/stop/pull
mcli disable my-service

# Re-enable a previously disabled service
mcli enable my-service

# Start all services including disabled ones
mcli start --all

# Back up a service (stops it first, archives to .bkp/my-service/2026-05-26.tar.gz, restarts it)
mcli backup my-service

# Back up without stopping the service
mcli backup my-service --live

# Show disk space used by all backups
mcli backup size

# Restore a service from a backup (interactive picker when multiple backups exist)
mcli restore my-service

# Preview what restore would do without making changes
mcli restore my-service --dry-run
```

## Service Discovery

`mcli` scans immediate subdirectories of the current working directory for Docker Compose files. A folder is recognized as a service if it contains `docker-compose.yml`, `docker-compose.yaml`, `compose.yml`, or `compose.yaml` (the Compose v2 default filenames).

The following are skipped during discovery:

- Symlinks
- Directories ignored by git (matched with `git check-ignore`, so full `.gitignore` semantics apply — negation, leading/trailing `/`, `**` globs). Requires being inside a git work tree; outside a git repo, `.gitignore` is not honored.
- Directories containing a `.git` folder

## Shared Network

All services share a Docker bridge network named `services`. Use `mcli create-network` to ensure it exists before starting services that need to communicate with each other.

## Configuration

Disabled services are stored in `${XDG_CONFIG_HOME:-~/.config}/mcli/disabled`. Each entry is a full path to the service directory, scoped by the working directory from which `mcli disable` was run. This means different service directories maintain independent disabled lists.

## Shell Completions

`mcli completions` outputs a completion script for bash or zsh. Source it once or add the line to your shell's config file.

**Bash** — add to `~/.bashrc`:

```sh
source <(mcli completions bash)
```

**Zsh** — add to `~/.zshrc`:

```sh
source <(mcli completions zsh)
```

Completions cover all commands and, for commands that operate on services, dynamically suggest discovered service names.

## Changelog

### 0.10.6

- Service discovery now uses `git check-ignore` to respect `.gitignore` with full gitignore semantics (negation, leading/trailing `/`, `**` globs) instead of substring-prefix matching against raw `.gitignore` lines, which previously skipped `node-app/` for a `node` entry and ignored `!`-negations. Requires git and a git work tree; outside a git repo `.gitignore` is not honored.

### 0.10.5

- `start`, `stop`, `pull`, `backup`, and `restore` now invoke `docker compose`, `tar`, and `find` as argv arrays instead of building shell strings and `eval`-ing them, so service directory names containing shell metacharacters (`"`, `$`, backtick, `;`) are handled safely; `--dry-run` output is rendered via `printf %q` so it remains copy-pasteable

### 0.10.3

- `mcli restore <service>` picker now distinguishes pre-restore snapshots from regular backups: regular archives are listed first, then pre-restore archives tagged `[pre-restore] <name>`, so identically-named files in `.bkp/<service>/` and `.bkp/<service>/pre-restore/` are no longer indistinguishable

### 0.10.2

- `mcli backup size` now prints a `note:` line when `du` hits permission errors on backup subdirectories, so under-counted sizes are visible instead of silently swallowed; run with `sudo` for full coverage

### 0.10.1

- `mcli restore <service>` now wipes the service directory before extracting the archive, so the restored state matches the archive exactly (previously, files added after the backup were left in place because `tar` only overwrites overlapping paths)
- Caveat: any bind-mount path nested under the service directory is also wiped — keep host-side volumes outside the service folder

### 0.10.0

- Added `mcli completions bash|zsh` command to output shell completion scripts for bash and zsh
- Completions cover all commands and dynamically suggest service names for service-aware commands

### 0.9.0

- Added `mcli restore <service>` command to recover a service from a `.tar.gz` backup archive
- Restore flow: stop service → optional pre-restore snapshot → extract chosen archive → start service
- Interactive numbered picker shown when more than one backup exists (including archives in `pre-restore/`)
- Pre-restore backup written to `.bkp/<service>/pre-restore/<date>.tar.gz` (counter suffix on same-day collision)
- Full `--dry-run` support: logs all steps without modifying anything

### 0.8.0

- `mcli backup <service>` now embeds `image.txt` inside the archive with `<image>:<tag>@sha256:<digest>` for each container (falls back to compose file image references when the service is not running)

### 0.7.0

- `mcli backup <service>` now creates a compressed `.tar.gz` archive instead of a plain directory copy, reducing backup disk footprint
- Same-day backups for the same service are named `<date>.1.tar.gz`, `<date>.2.tar.gz`, etc.

### 0.6.0

- `mcli backup <service>` now stops the service before copying and restarts it afterwards to prevent data inconsistencies during backup
- Added `--live` flag to `backup` to preserve the old behaviour (back up without stopping the service)

### 0.5.1

- Fixed `backup size` silently producing no output when backup directories contain root-owned subdirectories (set -e interaction with `du`)

## Contributing

Issues and pull requests are welcome. Please keep changes minimal and focused.

## License

[MIT](LICENSE)

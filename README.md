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

| Command                                         | Description                                                                                                                                                                                    |
| ----------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `list`                                          | List discovered services (disabled services are marked)                                                                                                                                        |
| `create-network`                                | Ensure the shared `services` Docker bridge network exists                                                                                                                                      |
| `start [services..]`                            | Start all or specified services (skips disabled); polls containers after `up -d` to catch crash-loops                                                                                          |
| `stop [services..]`                             | Stop all or specified services, removing orphans (skips disabled)                                                                                                                              |
| `restart [services..]`                          | Restart all or specified services (skips disabled)                                                                                                                                             |
| `pull [services..]`                             | Pull latest images, skipping buildable services (skips disabled)                                                                                                                               |
| `backup <service>`                              | Stop service, back up to `.bkp/<service>/<date>[.<counter>].tar.gz`, restart service. Archive includes `image.txt` with container image digests.                                               |
| `backup <service> --live`                       | Back up without stopping (live backup)                                                                                                                                                         |
| `backup --all`                                  | Back up every enabled service in turn                                                                                                                                                          |
| `backup size`                                   | Show disk space used by all backups under `.bkp/`                                                                                                                                              |
| `backup prune`                                  | Prune old backups by count (`--keep N`) and/or age (`--older-than DUR`); optionally scoped with `--service NAME`. Pre-restore archives under `pre-restore/` are not pruned.                    |
| `restore <service>`                             | Restore service from a backup archive in `.bkp/<service>/`; interactive picker when multiple backups exist. Wipes the service dir before extraction so its contents match the archive exactly. |
| `restore <service> --backup <name>`             | Restore from a specific archive (exact filename, with or without `.tar.gz`) found under `.bkp/<service>/` or `.bkp/<service>/pre-restore/`.                                                    |
| `restore <service> --backup latest`             | Restore from the newest regular backup (by mtime), skipping the interactive picker.                                                                                                            |
| `restore <service> --backup pre-restore-latest` | Restore from the newest pre-restore archive (by mtime).                                                                                                                                        |
| `restore --all`                                 | Restore every enabled service in turn; interactive picker per service when multiple backups exist. Continues past per-service failures and reports all at the end.                             |
| `disable <services..>`                          | Disable one or more services (excluded from start/stop/restart/pull)                                                                                                                           |
| `enable <services..>`                           | Re-enable one or more previously disabled services                                                                                                                                             |
| `update`                                        | Update mcli to the latest version                                                                                                                                                              |
| `update --check`                                | Check if an update is available without installing; exits `0`=up to date, `1`=update available, `2`=local newer, `3`=fetch failed                                                              |
| `completions bash\|zsh`                         | Output shell completion script for bash or zsh                                                                                                                                                 |
| `version`, `--version`, `-v`                    | Print version                                                                                                                                                                                  |
| `help`, `--help`, `-h`                          | Show help message                                                                                                                                                                              |

> **Note:** `stop` and `restart` run `docker compose down --remove-orphans`, which removes any containers attached to the same Compose project that aren't declared in the current compose file. If you've manually added sidecar containers (debugging shells, ad-hoc tools), they will be removed too.

### Options

| Option                                        | Description                                                                                                                                                                                                                        |
| --------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--dry-run`                                   | Print the commands that would be executed without running them (applies to: `create-network`, `start`, `stop`, `restart`, `pull`, `backup`, `restore`, `update`)                                                                   |
| `--check`                                     | Check if an update is available without installing; only valid for `update`                                                                                                                                                        |
| `--no-health`                                 | Skip post-start container health polling (applies to: `start`, `restart`)                                                                                                                                                          |
| `--health-timeout N`                          | Seconds to poll for running state after `docker compose up -d`; default `15` (applies to: `start`, `restart`)                                                                                                                      |
| `--all`                                       | Include disabled services in `start`/`stop`/`restart`/`pull`; loop over all services (including disabled) for `backup`/`restore` (applies to: `start`, `stop`, `restart`, `pull`, `backup`, `restore`)                             |
| `--live`                                      | Skip stop/start around backup; back up while the service is running (applies to: `backup`)                                                                                                                                         |
| `--keep N`                                    | After a successful backup, prune oldest archives until at most `N` remain per service. Also accepted by `backup prune`. Pre-restore archives are not counted or pruned.                                                            |
| `--older-than DUR`                            | For `backup prune`: delete archives older than `DUR`. `DUR` is `<N><unit>` with unit one of `s`, `m` (minutes), `h`, `d`, `w` — e.g. `30d`, `12h`, `2w`.                                                                           |
| `--service NAME`                              | For `backup prune`: restrict pruning to a single service.                                                                                                                                                                          |
| `--backup <name\|latest\|pre-restore-latest>` | For `restore`: select a backup non-interactively. `latest` picks the newest regular archive by mtime; `pre-restore-latest` picks the newest pre-restore archive; any other value is an exact filename (`.tar.gz` suffix optional). |
| `--yes`                                       | For `restore`: auto-accept the pre-restore snapshot prompt. Mutually exclusive with `--no-pre-restore`.                                                                                                                            |
| `--no-pre-restore`                            | For `restore`: skip the pre-restore snapshot entirely (no prompt, no archive created). Mutually exclusive with `--yes`.                                                                                                            |

All options can appear anywhere after the command.

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

# Back up every enabled service, keeping only the 5 newest archives per service
mcli backup --all --keep 5

# Back up a single service and prune anything older than 30 days afterwards
mcli backup my-service --keep 5

# Standalone prune: drop archives older than 30 days across every service
mcli backup prune --older-than 30d

# Standalone prune: keep only the 3 newest archives for one service
mcli backup prune --service my-service --keep 3

# Preview what prune would delete without touching disk
mcli backup prune --keep 5 --dry-run

# Restore a service from a backup (interactive picker when multiple backups exist)
mcli restore my-service

# Preview what restore would do without making changes
mcli restore my-service --dry-run

# Restore every enabled service in turn (interactive picker per service)
mcli restore --all

# Restore from the newest backup without interaction (skip picker and pre-restore prompt)
mcli restore my-service --backup latest --no-pre-restore

# Restore from a specific archive and create a pre-restore snapshot automatically
mcli restore my-service --backup 2026-06-01.tar.gz --yes

# Restore the most recent pre-restore snapshot
mcli restore my-service --backup pre-restore-latest --no-pre-restore
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

## Service Ordering

Create `.mcli/order` in the same directory you run `mcli` from to control the start order:

```
# .mcli/order — one service name per line; # comments allowed
traefik
postgres
app
worker
```

- Services named in the file start in listed order.
- Services not listed follow in discovery order.
- `mcli stop` always walks the reverse of the start order.
- `mcli list` reflects the same order.

If `.mcli/order` does not exist, all commands use alphabetical discovery order (the previous default).

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

### 0.16.0

- `mcli restore <service> --backup <name|latest|pre-restore-latest>` selects a backup without the interactive picker: `latest` picks the newest regular archive by mtime, `pre-restore-latest` picks the newest pre-restore archive, and any other value is an exact filename looked up under `.bkp/<service>/` and `.bkp/<service>/pre-restore/` (`.tar.gz` suffix optional)
- `--yes` auto-accepts the pre-restore snapshot prompt, creating the safety archive without interaction
- `--no-pre-restore` skips the pre-restore snapshot entirely (no prompt, no archive)
- `--yes` and `--no-pre-restore` are mutually exclusive; using either with a non-`restore` command is an error

### 0.15.0

- `mcli start` (and `mcli restart`) now poll container states for up to 15 seconds after `docker compose up -d` to detect crash-loops that Compose itself misses (exit 0 is returned even when containers immediately restart or exit)
- Containers in `restarting`, `exited`, or `dead` state are treated as a start failure; the service is added to the failed list and `mcli` exits non-zero
- `--no-health`: skip the post-start poll entirely (preserves the previous behavior)
- `--health-timeout N`: override the default 15-second polling window

### 0.14.0

- Added `mcli update --check`: fetches the remote script, compares versions, and prints `up to date`, `update available: X.Y.Z → A.B.C`, or `local version is newer` without running the installer; exits `0`/`1`/`2`/`3` respectively, making it safe to wire into cron, motd, or a status line

### 0.13.0

- Added `mcli restore --all` to restore every enabled service in turn; interactive picker per service when multiple backups exist; continues past per-service failures and reports all at the end

### 0.12.0

- Added service ordering via `.mcli/order`: one service name per line controls the sequence for `start`, `stop`, and `list`; services not in the file follow in discovery order; `stop` always walks the reverse of the start order

### 0.11.0

- Added backup retention: `mcli backup <service> --keep N` (and `mcli backup --all --keep N`) prunes the oldest archives for each service after a successful backup, so `.bkp/` no longer grows unboundedly
- Added `mcli backup --all` to back up every enabled service in turn
- Added `mcli backup prune` standalone subcommand with `--keep N`, `--older-than DUR` (`Nd`/`Nh`/`Nw`/`Nm`/`Ns`), and optional `--service NAME` scoping; respects `--dry-run` and prints exactly which archives would be deleted
- Pre-restore archives under `.bkp/<service>/pre-restore/` are intentionally excluded from both `--keep` counting and `--older-than` deletion, so safety snapshots taken before a restore are never silently removed

### 0.10.7

- Disabled-services config now keys off the canonical path of the current directory (`readlink -f` / `realpath`) instead of `$(pwd)`, so a service stays disabled regardless of whether you enter the project through a symlink or its real path
- Legacy non-canonical entries are migrated transparently the next time any `mcli` command (`list`, `start`, `stop`, `restart`, `pull`, `enable`, `disable`) runs from the affected directory, so services previously disabled via a symlink path stay disabled across the upgrade without manual intervention

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

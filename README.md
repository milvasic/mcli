# mcli

A single-file Bash CLI for managing Docker Compose services.

Each service is an immediate subdirectory containing a `docker-compose.yml` (or `docker-compose.yaml`). `mcli` discovers these automatically and lets you start, stop, restart, and pull images for all of them — or just the ones you name.

## Install

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/milvasic/mcli/refs/heads/main/install.sh)"
```

This installs `mcli` to `/usr/local/bin`. If a previous version is already installed, the installer will prompt you to upgrade.

For non-interactive environments (CI, scripts), pass `--yes` to auto-approve upgrades:

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/milvasic/mcli/refs/heads/main/install.sh)" -- --yes
```

`wget` is also supported if `curl` is not available.

## Uninstall

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/milvasic/mcli/refs/heads/main/install.sh)" -- --uninstall
```

This removes `mcli` from `/usr/local/bin`.

## Usage

```
mcli <command> [service1 [service2 ...]] [--dry-run] [--all]
```

### Commands

| Command                | Description                                                       |
| ---------------------- | ----------------------------------------------------------------- |
| `list`                 | List discovered services (disabled services are marked)           |
| `create-network`       | Ensure the shared `services` Docker bridge network exists         |
| `start [services..]`   | Start all or specified services (skips disabled)                  |
| `stop [services..]`    | Stop all or specified services (skips disabled)                   |
| `restart [services..]` | Restart all or specified services (skips disabled)                |
| `pull [services..]`    | Pull latest images for all or specified services (skips disabled) |
| `disable <services..>` | Disable one or more services (excluded from start/stop/pull)      |
| `enable <services..>`  | Re-enable one or more previously disabled services                |
| `update`               | Update mcli to the latest version                                 |
| `version`              | Print version                                                     |
| `help`                 | Show help message                                                 |

### Options

| Option      | Description                                                    |
| ----------- | -------------------------------------------------------------- |
| `--dry-run` | Print the commands that would be executed without running them |
| `--all`     | Include disabled services in start/stop/restart/pull           |

`--dry-run` and `--all` can appear anywhere after the command.

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
```

## Service Discovery

`mcli` scans immediate subdirectories of the current working directory for Docker Compose files. A folder is recognized as a service if it contains `docker-compose.yml` or `docker-compose.yaml`.

The following are skipped during discovery:

- Symlinks
- Directories listed in `.gitignore` (simple literal prefix matching)
- Directories containing a `.git` folder

## Shared Network

All services share a Docker bridge network named `services`. Use `mcli create-network` to ensure it exists before starting services that need to communicate with each other.

## Configuration

Disabled services are stored in `${XDG_CONFIG_HOME:-~/.config}/mcli/disabled`. Each entry is a full path to the service directory, scoped by the working directory from which `mcli disable` was run. This means different service directories maintain independent disabled lists.

## License

[MIT](LICENSE)

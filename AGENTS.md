# Project Guidelines

## Overview

`mcli` is a single-file Bash CLI (`./mcli`) for managing Docker Compose services. Each service is a subdirectory containing a `docker-compose.yml` or `docker-compose.yaml`.

A companion `install.sh` handles installation, upgrades, and uninstallation of `mcli` to `/usr/local/bin`. The `update` command in `mcli` invokes it directly via `curl`.

## Code Style

- Bash with `set -euo pipefail`
- Functions use snake_case
- Color-coded output via ANSI escape sequences (`log`, `error`, `info`, `dry_run_log` helpers)
- All Docker commands support `--dry-run` mode — never execute side effects without checking `$dry_run`

## Architecture

- **Single file**: All logic lives in `./mcli` — no external scripts or libraries
- **Service discovery**: `get_services()` scans immediate subdirectories for compose files, skipping symlinks, `.gitignore` entries, and folders with `.git`
- **Filtering**: `filter_services()` narrows discovered services by CLI arguments, excludes disabled services unless `--all` is set
- **Shared network**: Services share a Docker bridge network named `services`
- **Error accumulation**: Commands collect failures and report them at the end rather than exiting on first error

## Conventions

- New commands follow the existing pattern: define a function, add a case in the dispatch block
- Commands that operate on services accept optional service name arguments via `filter_services` and support `--dry-run` and `--all`
- `disable` and `enable` are exceptions: they do their own service validation, do not use `filter_services`, and do not support `--dry-run` or `--all`
- Use `eval` for command execution to support `--dry-run` logging of the exact command string
- Keep the script POSIX-path compatible; no bashisms beyond what's already used
- Update the `usage()` function whenever the script changes (bug fixes, new features, new options)
- Update `README.md` whenever the script changes (bug fixes, new features, new options)
- Format all Markdown files with `prettier` after editing (`prettier --write *.md`)

## Versioning

The version is hardcoded as `VERSION` near the top of `./mcli`. Follow semver:

- **Patch** (`0.1.x`): bug fixes, behavioral tweaks, internal refactors
- **Minor** (`0.x.0`): new commands or new options
- **No bump**: doc-only changes (`README.md`, `AGENTS.md`, comments)

## Validation

There is no test suite. After making changes, verify syntax with:

```sh
bash -n mcli
```

Then do a quick smoke-test by running `./mcli help` and exercising the affected command with `--dry-run`.

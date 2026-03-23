# Project Guidelines

## Overview

`mcli` is a single-file Bash CLI (`./mcli`) for managing Docker Compose services. Each service is a subdirectory containing a `docker-compose.yml` or `docker-compose.yaml`.

## Code Style

- Bash with `set -euo pipefail`
- Functions use snake_case
- Color-coded output via ANSI escape sequences (`log`, `error`, `dry_run_log` helpers)
- All Docker commands support `--dry-run` mode — never execute side effects without checking `$dry_run`

## Architecture

- **Single file**: All logic lives in `./mcli` — no external scripts or libraries
- **Service discovery**: `get_services()` scans immediate subdirectories for compose files, skipping symlinks, `.gitignore` entries, and folders with `.git`
- **Filtering**: `filter_services()` narrows discovered services by CLI arguments
- **Shared network**: Services share a Docker bridge network named `services`
- **Error accumulation**: Commands collect failures and report them at the end rather than exiting on first error

## Conventions

- New commands follow the existing pattern: define a function, add a case in the dispatch block
- Commands that operate on services accept optional service name arguments via `filter_services`
- Use `eval` for command execution to support `--dry-run` logging of the exact command string
- Keep the script POSIX-path compatible; no bashisms beyond what's already used
- Update the `usage()` function whenever the script changes (bug fixes, new features, new options)
- Update `README.md` whenever the script changes (bug fixes, new features, new options)

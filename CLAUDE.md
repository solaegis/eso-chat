# CLAUDE.md

Guidance for Claude Code when working in this repository.

<!-- AUTO-MANAGED: project-description -->
## Overview

EsoChat is a solaegis ESO (Elder Scrolls Online) PC addon scaffold: Taskfile tooling, ESOUI packaging, GitHub Actions release + ESOUI upload, LAM settings with Support footer, and `scripts/rename-addon.sh` to brand a new addon. ESO Lua 5.1; no `goto`.

<!-- END AUTO-MANAGED -->

<!-- AUTO-MANAGED: build-commands -->
## Build & Development Commands

- **Lint**: `task lint`
- **Format**: `task format`
- **Test**: `task test`
- **Validate**: `task validate`
- **Build**: `task build` / `task build:fast`
- **Install to ESO Live**: `task install:live` (required after code changes for in-game testing)
- **Rename**: `task rename -- --name … --title … --alias … --slash … --repo …`

<!-- END AUTO-MANAGED -->

<!-- AUTO-MANAGED: architecture -->
## Architecture

Load order: Core → Defaults → Initializer → Commands → SupportFooter → Panel → Init.

Namespace: `EsoChat` (`EC`). Server-scoped SV via `GetWorldName()`. Docs under `docs/`.

<!-- END AUTO-MANAGED -->

<!-- AUTO-MANAGED: conventions -->
## Code Conventions

- Lua 5.1 only (no `goto`)
- `EC.SafeCall` / `SafeCallMulti`; `EC.Info`/`Warn`/`Error`/`DebugPrint` — avoid raw `d()` for product logs
- LAM: plain text only; Support footer via `AppendSupportFooter`
- After code changes: `task install:live`

<!-- END AUTO-MANAGED -->

<!-- MANUAL -->
## Custom Notes

Product identity tokens must stay consistent so `rename-addon.sh` can rebrand them. See `docs/DEVELOPMENT.md`.

<!-- END MANUAL -->

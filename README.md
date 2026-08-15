# ESO Chat

[![Version](https://img.shields.io/github/v/release/solaegis/eso-chat?include_prereleases&sort=semver&label=Version)](https://github.com/solaegis/eso-chat/releases)
[![ESO API](https://img.shields.io/badge/ESO_API-101051-blue)](https://github.com/solaegis/eso-chat)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

Runnable solaegis scaffold for Elder Scrolls Online **PC** addons: Taskfile tooling, ESOUI-compliant packaging, GitHub Actions release + ESOUI upload, LibAddonMenu settings with Buy Me a Coffee / in-game gold support, and a one-shot **rename** script to brand a new addon.

## Create a new addon

```bash
# After cloning this template into your new repo:
./scripts/rename-addon.sh \
  --name EsoChat \
  --title "ESO Chat" \
  --alias EC \
  --slash ech \
  --repo solaegis/eso-chat \
  --esoui-id 0
```

Use `--dry-run` to preview. Details: [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).

## Quick start (template stub)

```bash
task init          # deps hints + optional pre-commit
task install:live  # copy into ESO Live AddOns with version injection
# In-game: /reloadui then /ech help
```

## Commands (stub)

| Command | Action |
|---------|--------|
| `/ech` | Status |
| `/ech help` | Help |
| `/ech settings` | Open LibAddonMenu panel |
| `/ech debug` | Toggle debug |
| `/ech reset` | Reset settings |

Alias: `/esochat`. LAM also registers `/echsettings`.

## Tooling

| Task | Description |
|------|-------------|
| `task test` | Lint + validate |
| `task build` | Release ZIP |
| `task build:fast` | ZIP without full test gate |
| `task install:live` | Install to Live (preferred on Mac) |
| `task rename -- …` | Rebrand template tokens |

## Docs

- [Architecture](docs/ARCHITECTURE.md)
- [Development](docs/DEVELOPMENT.md)
- [Publishing](docs/PUBLISHING.md)
- [ESOUI best practices](docs/esoui-addon-best-practices.md)
- [Lua patterns](docs/LUA_PATTERNS.md)
- [SavedVariables](docs/SAVEDVARS.md)

## Support

- [Buy Me a Coffee](https://www.buymeacoffee.com/lewisvavasw)
- In-game gold mail to `@solaegis` (from the settings Support footer)

## License

MIT — see [LICENSE](LICENSE).

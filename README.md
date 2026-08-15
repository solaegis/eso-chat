# ESO Chat

[![Version](https://img.shields.io/github/v/release/solaegis/eso-chat?include_prereleases&sort=semver&label=Version)](https://github.com/solaegis/eso-chat/releases)
[![ESO API](https://img.shields.io/badge/ESO_API-101051-blue)](https://github.com/solaegis/eso-chat)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

Chat enhancement addon for Elder Scrolls Online **PC** (keyboard chat): display formatting, mentions, whisper alerts, history, tab management, filtering, copy/export, input helpers, and optional automation.

## Quick start

```bash
task install:live
# In-game: /reloadui then /ech help
```

## Commands

| Command | Action |
|---------|--------|
| `/ech` | Status |
| `/ech help` | Help |
| `/ech settings` | Open LibAddonMenu |
| `/ech history [n]` | Show history |
| `/ech mentions` | List mention keywords |
| `/ech create …` | Create tabs (typed; see `/ech create help`) |
| `/ech notes [clear]` | Open Notes notepad, or clear active scope |
| `/ech tab …` | Tab list/create/rename/focus |
| `/ech profile …` | Tab category profiles |
| `/ech copy [n]` | Copy history lines |
| `/ech export` | Export settings |
| `/ech filter` | Filter status |

Alias: `/esochat`. LAM: `/echsettings`.

## Features

- Name modes (character / account / both), nicknames, timestamps, strip colors/says/zone tags
- Mentions with highlight + sound (optional Lua patterns)
- Whisper / party notifications and tab flash/switch
- Account-wide chat history with retention limits
- Tab create/rename, per-tab categories, layout restore, profiles
- Spam presets + keyword/flood filter
- Clipboard copy and settings export/import
- Input character counter and send history
- Optional automation (default off)

See [docs/CREDITS.md](docs/CREDITS.md) for prior-art acknowledgements.

## Tooling

| Task | Description |
|------|-------------|
| `task test` | Unit tests + lint + validate |
| `task test:unit` | Unit tests only |
| `task build` | Release ZIP |
| `task install:live` | Install to Live (preferred on Mac) |

## Docs

- [Architecture](docs/ARCHITECTURE.md)
- [Tabs](docs/TABS.md)
- [Filtering](docs/FILTERING.md)
- [Compatibility](docs/COMPAT.md)
- [Credits](docs/CREDITS.md)
- [Development](docs/DEVELOPMENT.md)
- [Publishing](docs/PUBLISHING.md)

## Support

- [Buy Me a Coffee](https://www.buymeacoffee.com/lewisvavasw)
- In-game gold: mail `@solaegis`

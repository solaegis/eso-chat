# Development

## Prerequisites

```bash
brew install go-task stylua luajit
luarocks install luacheck
brew install pre-commit   # or: pip install pre-commit
```

## Create a new addon from this template

1. Clone or use GitHub **Use this template** into a new repo (e.g. `eso-chat`).
2. Rebrand all template tokens:

```bash
./scripts/rename-addon.sh \
  --name EsoChat \
  --title "ESO Chat" \
  --alias EC \
  --slash ech \
  --repo solaegis/eso-chat \
  --esoui-id 0
```

Preview with `--dry-run` first. See [Rename](#rename--rebrand) below.

3. Set `ESOUI_ADDON_ID` in `.github/workflows/release.yaml` after your first ESOUI listing (or pass `--esoui-id` during rename).
4. Add `ESOUI_API_KEY` as a GitHub Actions secret for uploads.

## Day-to-day

| Task | Command |
|------|---------|
| Lint | `task lint` |
| Format | `task format` |
| Validate | `task validate` |
| Test (lint + validate) | `task test` |
| Install to Live (preferred on Mac) | `task install:live` then `/reloadui` |
| Symlink install | `task install:dev` |
| Fast ZIP | `task build:fast` |

After any Lua/manifest change, run `task install:live` before in-game testing. Symlinks are less reliable on some Mac setups.

## Rename / rebrand

`scripts/rename-addon.sh` (also `task rename -- …`) rewrites:

- Manifest filename (`EsoChat.txt` → `{Name}.txt`)
- Global namespace, short alias, SavedVariables name
- Slash commands and LAM slash
- Taskfile / workflow `ADDON_NAME`, README URLs, Core website/feedback links
- Optional `ESOUI_ADDON_ID`

It does **not** rename the parent git checkout directory. If your folder is still `eso-addon-template`, rename it yourself to match the repo slug.

## Slash commands (template stub)

- `/ech` / `/esochat` — status
- `/ech help` — help
- `/ech settings` — open LAM
- `/ech debug` — toggle debug
- `/ech reset` — reset settings (preserves `perCharacterData`)

## Agent / AI notes

See root `AGENTS.md`, `CLAUDE.md`, and `.cursorrules`. Prefer the docs in this folder as the source of truth for practices.

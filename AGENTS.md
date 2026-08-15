# Agent notes — EsoChat

## Learned User Preferences

- After addon code changes (`.lua`, manifest, `src/`), run `task install:live` then `/reloadui` for in-game testing on Mac (prefer copy+inject over symlink).
- LAM: no emoji/Unicode icons in names or tooltips; keep `choices`/`choicesValues`/`tooltips` the same length; non-nil sentinels only.
- Support footer: Buy Me a Coffee + Send Gold In-Game to `@solaegis`.
- `## Version:` is free-form / `@project-version@` (semver from tag). `## AddOnVersion:` is integer only (`@addon-build-version@` → YYYYMMDD) — never semver.
- Account SavedVariables are server-scoped via `GetWorldName()`.
- New product addons: run `scripts/rename-addon.sh` so folder/manifest/namespace/SV/slash/CI names match before shipping.
- Prefer `.yaml` for new YAML files.
- Do not edit attached plan files when implementing from a plan.

## Learned Workspace Facts

- This repo is the solaegis ESO addon **template** (scaffold + docs). Product addons are separate repos created from it.
- PC manifest is `EsoChat.txt` (not `.addon`). ZIP root must be `EsoChat/`.
- Optional deps: LibAddonMenu-2.0, LibDebugLogger.
- Slash: `/ech` (alias `/esochat`). Docs SoT under `docs/`.
- Release workflow uploads to ESOUI when `ESOUI_ADDON_ID != 0` using `secrets.ESOUI_API_KEY`.
- Practices hybrid: packaging/release from eso-combat-lock; Lua/settings depth from CharacterMarkdown (slimmed).

## Docs map

- `docs/ARCHITECTURE.md`, `DEVELOPMENT.md`, `PUBLISHING.md`
- `docs/esoui-addon-best-practices.md`, `VERSION_PLACEHOLDER_SYSTEM.md`
- `docs/LUA_PATTERNS.md`, `SAVEDVARS.md`, `OPTIONAL_ADVANCED.md`

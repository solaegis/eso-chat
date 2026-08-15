# Agent notes — EsoChat

## Learned User Preferences

- After addon code changes (`.lua`, manifest, `src/`), run `task install:live` then `/reloadui` for in-game testing on Mac (prefer copy+inject over symlink).
- LAM: no emoji/Unicode icons in names or tooltips; keep `choices`/`choicesValues`/`tooltips` the same length; non-nil sentinels only.
- Support footer: Buy Me a Coffee + Send Gold In-Game to `@solaegis`.
- `## Version:` is free-form / `@project-version@` (semver from tag). `## AddOnVersion:` is integer only (`@addon-build-version@` → YYYYMMDD) — never semver.
- Account SavedVariables are server-scoped via `GetWorldName()`.
- Prefer `.yaml` for new YAML files.
- Do not edit attached plan files when implementing from a plan.
- Slash primary is `/ech` (never `/cm` — that belongs to CharacterMarkdown).

## Learned Workspace Facts

- Product: ESO Chat (`EsoChat` / `EC`) — keyboard chat enhancement (display, mentions, history, tabs, filtering, copy/export).
- PC manifest is `EsoChat.txt`. ZIP root must be `EsoChat/`.
- Optional deps: LibAddonMenu-2.0, LibDebugLogger, LibChatMessage, LibMediaProvider-1.0; OptionalDependsOn also lists pChat/rChat for load order.
- Register chat formatters on `EVENT_PLAYER_ACTIVATED` and chain prior formatters.
- `settingsSchemaVersion` is **1**; missing keys filled by `EC.EnsureDefaultsFilled` (no migration ladder).
- Unit tests: `tests/run.lua` via `task test` / `task test:unit`.
- Docs: ARCHITECTURE, TABS, FILTERING, COMPAT, CREDITS under `docs/`.

# Version Placeholder System

Canonical solaegis version placeholder rules for ESO PC addons.

## Placeholders

| Placeholder | Where | Becomes |
|-------------|-------|---------|
| `@project-version@` | `## Version:` in `EsoChat.txt`, `EC.VERSION` in `src/Core.lua`, `README_ESOUI.txt` | Semver from git tag (e.g. `1.0.1`) |
| `@addon-build-version@` | `## AddOnVersion:` in `EsoChat.txt` only | Integer date via `set-addon-version.sh` (e.g. `20260805`) |

ESO parses `AddOnVersion` with C `atoi`, so it **must** be a positive integer — never semver (`1.0.1` would load as `1`).

## Replacement

`scripts/replace-version.sh` substitutes `@project-version@` at build/install time. It **never** rewrites `## AddOnVersion:` lines (guards against accidental semver injection).

```bash
./scripts/replace-version.sh build/EsoChat 1.1.0
./scripts/set-addon-version.sh build/EsoChat/EsoChat.txt
```

Release CI and `task build` / `task install:live` both run these steps.

## AddOnVersion at release

CI / `set-addon-version.sh` sets `## AddOnVersion:` to `YYYYMMDD` for LibAddonMenu sorting and ESO precedence. Dev trees keep `@addon-build-version@` until built.

## Showing version in-game

After a release build or `task install:live`, `/ech` status shows the injected version from `EC.VERSION`.

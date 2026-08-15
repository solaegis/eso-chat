# Publishing

## Versioning

See [VERSION_PLACEHOLDER_SYSTEM.md](VERSION_PLACEHOLDER_SYSTEM.md).

- Tag releases as `vX.Y.Z` (e.g. `v1.0.0`).
- `## Version:` becomes the semver from the tag.
- `## AddOnVersion:` becomes `YYYYMMDD` at build (integer only).

## Checklist

1. Update `CHANGELOG.md` with `## [X.Y.Z] - YYYY-MM-DD`
2. `task release:check` (or `task test` + `task build`)
3. In-game smoke: `task install:live`, `/reloadui`, slash + settings panel
4. Commit, push, tag:

```bash
git tag v1.0.0
git push origin main --tags
```

5. GitHub Actions `release` workflow builds the ZIP, creates a GitHub Release, and uploads to ESOUI when `ESOUI_ADDON_ID` is not `0`.

## ESOUI upload

- Secret: `ESOUI_API_KEY`
- Env in `.github/workflows/release.yaml`: `ESOUI_ADDON_ID`, `ESO_API_VERSION` (listing `compatible` badge, e.g. `12.0.0`)
- Listing body: ASCII-only BBCode in `README_ESOUI.txt` (AI disclosure + credits)
- ZIP root must be `{AddonName}/` containing `{AddonName}.txt` — validators enforce this

## First listing

1. Create the addon page on esoui.com manually once.
2. Copy the numeric addon id into `ESOUI_ADDON_ID` (or re-run rename with `--esoui-id`).
3. Subsequent tagged releases can upload automatically.

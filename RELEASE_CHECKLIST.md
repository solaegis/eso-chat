# Release checklist

## Automated

- [ ] `task test` (lint + validate)
- [ ] `task build` or `task build:fast`
- [ ] `scripts/validate-esoui-compliance.sh` passes
- [ ] ZIP root is `EsoChat/` (or renamed addon) with matching `.txt` manifest
- [ ] `## AddOnVersion:` is a positive integer in the built artifact
- [ ] `README_ESOUI.txt` is ASCII-only, includes AI disclosure and LibAddonMenu credit

## Content

- [ ] `CHANGELOG.md` has `## [X.Y.Z]` for this release
- [ ] Manifest `## APIVersion:` matches Live (and PTS if dual)
- [ ] After first ESOUI listing: `ESOUI_ADDON_ID` set in release workflow
- [ ] GitHub secret `ESOUI_API_KEY` configured (for upload when id ≠ 0)

## In-game

- [ ] `task install:live` + `/reloadui`
- [ ] `/ech help` and `/ech settings` work
- [ ] Support footer opens BMC / gold mail compose

## Publish

- [ ] Commit clean
- [ ] Tag `vX.Y.Z` and push tags
- [ ] Confirm GitHub Release artifact
- [ ] Confirm ESOUI upload (or skipped when id is 0)

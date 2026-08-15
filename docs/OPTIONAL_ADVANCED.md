# Optional advanced topics

Not required for a new solaegis addon. Add when the product needs them.

## mdBook + GitHub Pages

- `book.toml` + `docs/SUMMARY.md` + `.github/workflows/docs.yaml`
- Mirror eso-combat-lock / CharacterMarkdown docs pipelines

## Host unit tests

- Plain Lua runner under `tests/` with a mock ESO harness (see eso-combat-lock)
- Wire `task dev:test:unit` into `task test` when you have specs

## Compliance ZIP fixtures

- `scripts/build-compliance-fixtures.sh` + negative ZIP traps in CI
- Useful once packaging regressions appear

## Schema migration ladder

- `MigrateSavedVars` with sequential version steps (eso-combat-lock `CharacterDb.lua`)

## Extra libraries

Declare only what you use in `OptionalDependsOn`:

- LibSlashCommander, LibChatMessage, LibAsync, LibSets, LibCustomIcons, …

Graceful fallbacks when missing.

## Textures / UI

- Bundle `textures/*.dds` (whitelist copy already includes them)
- Named dynamic controls: adopt-or-create; never expect `DestroyControl`
- Top-level windows for anything drawn; `GuiRoot` alone is not enough for visible children

## ESO API reference

Use the sibling CharacterMarkdown dump `ESOUIDocumentationP50.txt` or in-game globals — do not ship the dump inside every addon.

# SavedVariables

## Server-scoped account settings

Always pass `GetWorldName()` as the ZO_SavedVars namespace so NA / EU / PTS do not overwrite each other:

```lua
EC.db = ZO_SavedVars:NewAccountWide(
    EC.SV_NAME,
    EC.SV_VERSION,
    GetWorldName(),
    defaults
)
```

Create SavedVariables only inside `EVENT_ADD_ON_LOADED` (see `src/Init.lua`).

## Naming

- `## SavedVariables:` must be globally unique — prefix with the addon name (`EsoChatSettings`).
- Keep `EC.SV_NAME` in Core in sync with the manifest.

## Per-character data

Store character-specific fields **inside** the account-wide table:

```lua
EC.db.perCharacterData[tostring(GetCurrentCharacterId())] = { ... }
EC.charData = EC.db.perCharacterData[characterId]
```

Do **not** put `perCharacterData` in Defaults as something that reset should wipe. `EC.ResetSettings` preserves that table.

## Schema migration (optional advanced)

When you bump settings shape:

1. Increase `EC.SV_VERSION` / a `settingsSchemaVersion` field.
2. Migrate from the **previous** version only via sequential steps (`N-1 → N`).
3. Greenfield installs already have current defaults — skip migration.

Document product-specific steps in your addon; this template ships greenfield `SV_VERSION = 1` only.

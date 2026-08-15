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

## Schema

`EC.SCHEMA_VERSION` / `settingsSchemaVersion` is **1**. New default keys are filled on load by `EC.EnsureDefaultsFilled` (non-destructive). There is no sequential migration ladder.

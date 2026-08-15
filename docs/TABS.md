# Tabs

EsoChat manages keyboard chat **containers** and **tabs** via ZOS APIs and `CHAT_SYSTEM`.

## Features

- Enumerate containers/tabs (`GetNumChatContainers`, `GetChatContainerTabInfo`)
- Create/rename tabs (`AddWindow` / `AddChatContainerTab` / `SetChatContainerTabInfo`)
- Per-tab category maps (`SetChatContainerTabCategoryEnabled`)
- Snapshot/restore layout into SavedVariables (`tabs.layout`)
- **Window size and position** (`tabs.containers`): width/height/anchors survive logout and `/reloadui`
- Optional raised max size (toward full `GuiRoot`) so chat can grow past vanilla caps
- Named profiles (`Social`, `Guild`, `Combat`, `Whispers`) in `tabs.profiles`
- Alert routing: flash inactive tab; optional switch on whisper/mention/party
- **Unread pulse and counter**: flash once on first unread, slow pulse + display-only `(N)` until the tab is focused and scrolled to the bottom (also counts when the active tab is scrolled up)
- Per-tab display overrides (`layout[i].overrides`)
- **Special filter tabs** (`filterMode`): Whispers / Mentions / Friends / Notes
- **`/ech create`**: typed tab creation (specials, group, profiles) with optional verified whisper targets
- **Group tab** (`groupChannel` layout flag) + optional combat pin setting

## `/ech create`

Preferred entry point for creating tabs. `/ech tab create <name>` remains for bare labels.

```
/ech create <tabLabel>
/ech create whispers [tabLabel] [@account | --to <Name>]
/ech create mentions [tabLabel]
/ech create friends [tabLabel]
/ech create notes [tabLabel]
/ech create group [tabLabel]
/ech create social|guild|combat|system [tabLabel]
/ech create help
```

| Type | Behavior |
|------|----------|
| Bare label | Always creates a new empty tab |
| `whispers` / `w` | Special filter tab; optional `@account` or `--to Name` verified (friend → group → guild) before create; default label = verified target |
| `mentions` / `m`, `friends` / `f`, `notes` / `n` | Special filter tabs (ensure-if-missing) |
| `group` | Party-channel only while grouped (`CHAT_CATEGORY_PARTY`); empty when solo; requires being in a group to create; default label `Group`; marks `layout.groupChannel` |
| `social` / `guild` / `combat` / `system` | Create/ensure tab and apply profile seed (`combat` and `system` both use the Combat / system-messages profile) |

Whisper targets fail closed if not found. `whispers` is always the special filter mode (not the Whispers profile seed).

Implementation: [`src/chat/TabCreate.lua`](../src/chat/TabCreate.lua).

## Special filter tabs

ZOS tabs only filter by channel category. EsoChat adds these modes:

| Mode | How it works |
|------|----------------|
| **Whispers** | Both whisper in/out categories. Focusing restores last whisper target. |
| **Mentions** | All categories off; addon injects mention hits and sticky follow-ups (both sides). |
| **Friends** | All categories off; injects friend lines, whispers to friends, and sticky self-replies. |
| **Notes** | All categories off; multiline EditBox notepad (not chat buffer). Content persists in SavedVariables. LAM **Keep Notes per character** chooses account-wide vs `perCharacterData`. Edit/delete in place; `/ech notes clear` clears the active scope. |

Matching lines are **copied** into Mentions/Friends (they still appear on normal tabs). Sticky duration is **Conversation sticky (minutes)** (default 5, max 60).

```
/ech tab ensure whispers|mentions|friends|notes
/ech tab mode <tabName> none|whispers|mentions|friends|notes
/ech notes
/ech notes clear
```

LAM: Enable special filter tabs, sticky slider, Create/Update buttons for each mode, Notes per-character checkbox, Clear Notes.

Implementation: [`src/chat/TabFilters.lua`](../src/chat/TabFilters.lua), [`src/chat/Notes.lua`](../src/chat/Notes.lua).

## Group tab + combat visibility

`/ech create group` builds a party-chat tab and sets `groupChannel` on the layout entry.

| Setting / state | Behavior |
|-----------------|----------|
| While **grouped** | Group tab has only `CHAT_CATEGORY_PARTY` enabled |
| While **not grouped** | All categories off on that tab (no new messages) |
| Keep group tab visible in combat | **off** by default — while grouped and in combat, move that group tab to first position and keep focus; restore when combat ends |

`groupChannel` is the source of truth; join/leave/update and layout restore call `Tabs.SyncGroupTabCategories()`.

## Unread pulse and counter

Any non-blocked message whose category is enabled on a tab counts as unread when that tab is **not viewable** (inactive, or active but scrolled up).

| Setting | Default | Behavior |
|---------|---------|----------|
| Unread pulse until read | on | One-shot `Flash()`, then slow pulse until focused **and** at bottom |
| Unread message counter | on | Display-only `Name (N)` / `Name (99+)` via `ZO_TabButton_Text_SetText` (never saved into the ZOS tab name) |
| Flash inactive tab on alert | on | Used for whisper/mention/party flash only when unread pulse is **off**; when pulse is on, unread owns flash |

Session-only (clears on `/reloadui`). Filtered/blocked messages are not counted. Unread runs independently of **Enable tab features**. Diagnose with `/ech unread`.

Implementation: [`src/chat/TabUnread.lua`](../src/chat/TabUnread.lua).

## Size and position

| Setting | Default | Behavior |
|---------|---------|----------|
| Remember window size | on | Debounced save of width/height; restore on login |
| Allow larger than default | on | Sets `CHAT_SYSTEM.maxContainerWidth/Height` from `GuiRoot` and refreshes control constraints |
| Remember window position | on | Saves/restores anchor offsets on `GuiRoot` |
| Restore layout on login | on | Must be on for size/position restore |

Resize works independently of the **Enable tab features** toggle. Drag the bottom-right corner of the chat window after `/reloadui`. Diagnose with `/ech resize` (shows system max vs control constraints).

Primary container is stored under key `primary`; additional containers use `tab:<firstTabName>`.

Implementation: [`src/chat/ContainerLayout.lua`](../src/chat/ContainerLayout.lua).

## Slash

```
/ech create …
/ech tab list
/ech tab create <name>
/ech tab rename <old> <new>
/ech tab focus <name>
/ech tab categories <name>
/ech tab ensure whispers|mentions|friends
/ech tab mode <tabName> none|whispers|mentions|friends
/ech profile list|save|apply|delete
```

## Platform

Tab automation and resize sync are **keyboard chat only**. Gamepad chat soft-disables formatter/tabs with a warning.

## Credits

Tab alert and last-channel ideas inspired by FCOChatTabBrain and Chat Window Manager. Raised max chat size / size sync inspired by pChat (see [CREDITS.md](CREDITS.md)).

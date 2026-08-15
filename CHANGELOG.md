# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Group tab (`groupChannel`): party category only while grouped; all categories off when solo (`Tabs.SyncGroupTabCategories`)
- Tab unread flash/pulse and display-only `(N)` counter until focused and scrolled to bottom (`tabs.unreadPulseEnabled`, `tabs.unreadCounterEnabled`); label fix: primaryContainer fallback, re-apply during pulse, independent of tabs master toggle, `/ech unread`
- Chat window resize beyond vanilla caps (optional) with width/height/position remembered across logins and `/reloadui` (`tabs.containers`, schema 7)
- `/ech resize` diagnostic; resize raise retries and layout hooks so constraints stay elevated after ZOS recalculates tabs
- Special filter tabs: Whispers / Mentions / Friends with bidirectional conversation sticky (`conversationStickyMinutes`, schema 8); `/ech tab ensure` and LAM create buttons

### Fixed

- False gamepad-chat detection when PC gamepad-preferred mode still uses keyboard chat (`GAMEPAD_SETTING_USE_KEYBOARD_CHAT` / `CHAT_SYSTEM.primaryContainer`); was aborting formatter, tabs, and window resize
- Settings freeze: sound dropdowns use a curated shortlist only (full `SOUNDS` table never loaded into LAM)
- Removed Sound filter / Clear filter controls from settings

## [0.2.0] - 2026-08-15

### Added

- Chat display formatting (name modes, nicknames, timestamps, strip says/zone/colors, prevent fade)
- Mentions with highlight and sound; optional Lua-pattern keywords
- Whisper and party notifications; tab flash/switch routing
- Account-wide chat history with max entries and retention
- Tab ecosystem: create/rename, category maps, layout restore, profiles (Social/Guild/Combat/Whispers)
- Filtering presets (LFG/trade/recruit), custom keywords, flood protection
- Copy history to clipboard; settings export/import; SV size warnings
- Input character counter and send history
- Compat detection for pChat/rChat with formatter chaining
- Optional automation (default off), loot-in-chat hook, emoji flag, i18n stub (en/de/fr)
- Unit tests under `tests/` wired into `task test`
- Docs: CREDITS, TABS, FILTERING, COMPAT; product README
- Notification sound pickers: filterable scrollable dropdowns from stock `SOUNDS` (+ LibMediaProvider when present)

### Credits

Inspired by ideas from pChat, rChat, FCOChatTabBrain, Chat Window Manager, Chat2Clipboard, SmartChatMsg, HelloTamriel!, TOM, Chat Input Viewer, ShowLootChat, CopyTextESO. Independent implementation.

## [0.1.0] - 2026-08-15

### Added

- Initial solaegis ESO addon template scaffold
- Server-scoped SavedVariables, LAM panel, Support footer (BMC + gold)
- Taskfile lint/validate/build/install, CI and release workflows with ESOUI upload gate
- `scripts/rename-addon.sh` for rebranding template tokens to a new addon name

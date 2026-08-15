# Filtering

Optional message filtering runs before history capture and formatter display.

## Presets

- LFG/LFM style phrases
- WTB/WTS/WTT trade spam
- Guild recruitment phrases

## Custom

Newline-separated block keywords in LAM **Filtering**.

## Flood

Same sender + identical text within `floodSeconds` is blocked when flood protection is on.

## Scope

Apply to zone (default), optionally say and guild channels.

## Behavior

When blocked and `hideFromHistory` is on, the line is dropped from history and notifications. The formatter returns an empty string so the line is not shown.

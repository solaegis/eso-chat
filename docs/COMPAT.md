# Compatibility

EsoChat registers its `CHAT_ROUTER` message formatter on `EVENT_PLAYER_ACTIVATED` and **chains** any previous formatter when discoverable.

## Known addons

OptionalDependsOn lists `pChat` and `rChat` so they load first when present. On detect, EsoChat warns once per session.

## Force overlaps

LAM **Force feature overlaps** keeps EsoChat display transforms active even when another chat addon is installed. Without it, EsoChat still chains formatters but users should expect overlapping display features.

## Gamepad

Keyboard chat APIs are used for formatter, tabs, and input counter. Gamepad chat mode disables those paths.

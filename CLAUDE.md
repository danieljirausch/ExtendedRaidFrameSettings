# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Release

```bash
./release.sh   # packages addon into ExtendedRaidFrameSettings.zip
```

GitHub Actions auto-releases on any tag push — runs `release.sh` and creates GitHub release.

## Architecture

WoW retail addon (interface 120005) that injects a "Growth Direction" dropdown into Blizzard's EditMode dialog for raid frames.

**Load order** (defined in `.toc`):
1. `LibStub` — library versioning (prevents duplicate loads)
2. `LibUIDropDownMenu.xml` + `.lua` — dropdown UI library
3. `Libs/EditModeExpanded-1.0.lua` — frame registration into Blizzard EditMode
4. `ExtendedRaidFrameSettings.lua` — main addon logic (73 lines)

**Main addon flow** (`ExtendedRaidFrameSettings.lua`):
- Waits for `Blizzard_EditMode` addon via `EventUtil.ContinueOnAddOnLoaded`
- Registers `CompactRaidFrameContainer` with EditModeExpanded library
- Adds Left/Right dropdown via `LibUIDropDownMenu`
- Hooks `CompactRaidFrameContainerMixin.LayoutFrames` via `hooksecurefunc` (non-taint)
- `reverseGroupsIfNeeded()` swaps `flowFrames`/`flowFrameTypes` arrays when growth=Right and group mode is discrete

**Persistence**: `ERFSConfig` SavedVariable — simple table, `ERFSConfig.container.growthDirection` = 0 (Left) or 1 (Right).

**`EditModeExpanded-1.0`** (2243 lines): manages per-layout profiles, frame positioning/scaling, custom settings widgets. Profile key format: `layoutType-[character-realm]-layoutName`.

## WoW-specific constraints

- `hooksecurefunc` only — never overwrite Blizzard functions directly (taint risk)
- No UI changes during combat lockdown
- Addon code runs in WoW Lua sandbox — no file I/O, no standard Lua libraries

## References

`~/Projects/Local/wow-ui-source/` — local Blizzard UI API source. Look up frame mixins, event names, function signatures here before guessing.

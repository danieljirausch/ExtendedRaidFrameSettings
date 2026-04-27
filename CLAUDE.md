# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ExtendedRaidFrameSettings is a World of Warcraft retail addon (Interface 120005 / patch 12.0.5) that extends the default raid frame settings in Edit Mode.

## WoW Addon Structure

- The `.toc` file is the addon manifest. `## Interface:` must match the current retail client version (XYYYZZ format). `## SavedVariables:` declares persistent per-character or per-account data.
- Lua files listed in the `.toc` are loaded in order at startup. XML files define UI frames/templates.
- The WoW Lua environment is sandboxed: no `io`, `os`, `require`, or `loadfile`. Use the WoW API, frame events, and secure hooks (`hooksecurefunc`).
- Protected (secure) frames cannot be modified in combat (`InCombatLockdown()` returns true). Always guard frame mutations with a combat check or defer via `PLAYER_REGEN_ENABLED`.
- Taint: calling protected Blizzard functions from addon code can "taint" execution and block secure actions. Minimize taint by hooking rather than replacing Blizzard functions.

## WoW UI Source Reference

Blizzard's UI source is cloned at `~/Projects/Local/wow-ui-source/`. Use it to look up Blizzard frame implementations, templates, and API signatures before hooking or extending anything.

## Key WoW API Surfaces

The addon operates in the Edit Mode system. Important globals and APIs:
- `EditModeManagerFrame`, `EditModeSystemSettingsDialog` — the Edit Mode UI framework
- `CompactRaidFrameContainer`, `PartyFrame` — the raid/party frame containers
- `FlowContainer_SetOrientation`, `FlowContainer_SetMaxPerLine` — control raid frame layout flow
- `Enum.EditModeUnitFrameSetting`, `Enum.RaidGroupDisplayType` — Edit Mode enums
- `hooksecurefunc` — safe post-hook without taint
- `EventUtil.ContinueOnAddOnLoaded` — run code after a specific Blizzard addon loads

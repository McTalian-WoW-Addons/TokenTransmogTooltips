# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Non-negotiable rules

- **Never create a commit without a confirmed manual human review first.** Show the diff (or state exactly what changed and where) and wait for an explicit "yes, commit". Passing tests, a clean `trunk check`, or earlier approval of a plan are not substitutes for reviewing the actual change.
- **Never commit to `main`.** Always create and work on a new branch. The only exception is an explicit human override given for that specific commit, in the moment; a general "go ahead" earlier in the session does not count.
- Both rules apply to every path that produces a commit — amends, rebases, `git commit -a`, and commits made by scripts, hooks, or subagents.
- **Never comment on GitHub pull requests or issues unless explicitly asked to in that request.** This covers review comments, inline PR comments, issue comments, creating or editing PR/issue bodies, and any `gh` command that posts text to GitHub. Reading, listing, and summarizing back in chat is always fine.

## What this project is

A World of Warcraft **retail** addon (Lua 5.1 + WoW API) that augments item tooltips for raid/open-world gear tokens, showing which transmog appearances the player is still missing.

There is no Blizzard API for token → gear mappings, so **all of that data is hand-maintained** under `TokenTransmogTooltips/Raids/`. The runtime logic (`Core.lua`, ~240 lines) is small; nearly all of the repo's complexity and nearly all of its bugs live in the data tree and its load order.

## Commands

```bash
make build                                  # dev build (alpha markers kept) into ./.release
make watch                                  # rebuild on change
make test                                   # busted, whole suite
make test-file FILE=TokenTransmogTooltips_spec/Core_spec.lua
make test-pattern PATTERN="modID"           # --filter on test description
make test-only                              # only tests tagged `only`
make test-cov                               # coverage -> luacov-html/index.html
make lua_deps                               # luarocks install the rockspec (--local, lua 5.4)
trunk check                                 # lint/format (trunk.io, wbt-configs plugin)
```

`busted` is invoked from `$HOME/.luarocks/bin`. Tests are Lua 5.4 on the host; the addon itself runs Lua 5.1 in-client, and `TokenTransmogTooltips_spec/_mocks/helper.lua` (a busted suite helper wired up in `.busted`) supplies the compat shims and `Enum.ItemCreationContext` stub.

Builds use [`wow-build-tools`](https://github.com/McTalian-WoW-Addons/wow-build-tools), expected on PATH. CI (`.github/workflows/*.yml`) delegates to reusable workflows in that same repo.

## Architecture

### Load order is load-bearing

`.toc` loads `Raids/_raids.xml` → `tokenClassAppearanceModInfo.lua` → `Core.lua`. Within `Raids/`, XML files define the sequence, and violating it produces nil-reference errors at load:

- **`_raids.xml`**: `_index.lua` first (it creates `ns.Raids`, `ns._Gear`, `ns.mergeTable`), then one `<Include>` per raid. Ordering is roughly chronological by tier.
- **Raid `_index.xml`**: `_index.lua` first (creates `ns._Gear.{RaidName}`), token-group `_index.xml` includes next, `tokens.lua` **last** (it dereferences the aggregated tables).
- **Token group `_index.xml`**: class `.lua` files first, the directory-named aggregator `.lua` **last**.

`xml_load_order_spec.lua` enforces all three rules; `_mocks/data_loader.lua` reimplements the XML walk so tests load the real data tree the way the client does.

### Data shape

Two parallel namespaces, built bottom-up:

- `ns._Gear.{Raid}.{CLASS}[difficulty][slot][appearanceID] = { modID, }` — per-class raw data (one file per class).
- `ns._Gear.{Raid}.{TOKENGROUP}[difficulty][slot][CLASS] = <the above>` — the aggregator re-pivots class data so a token can grab one `[difficulty][slot]` table covering every class in its group.
- `ns.Raids.{Raid}[tokenID] = { Difficulties = { [Enum.ItemCreationContext.X] = <tokengroup[diff][slot]> } }` — `tokens.lua`.
- `tokenClassAppearanceModInfo.lua` flattens all of `ns.Raids` into `ns.tokenClassAppearanceModInfo[tokenID]`, erroring on duplicate token IDs in alpha builds.

Token-group names (`MYSTIC`/`DREADFUL`/`CONQUEROR`/`VOIDWOVEN`/…) differ per expansion and are **directory organization only** — nothing in the runtime reads them, except `ns.shadowlandsMultiClassLookup` in `tokenClassAppearanceModInfo.lua`, which maps Shadowlands-era group names used as class keys back to real class icons.

### Tooltip resolution (`Core.lua`)

`TTT:GetTooltipInfo(link)` → parse `itemID` + `itemContext` (slot 12 of the link options) → `ns.tokenClassAppearanceModInfo[tokenID]` → unwrap `Difficulties[itemContext]` **only if `itemContext > 0`** → unwrap `ALLIANCE`/`HORDE` if present → group classes by identical appearance fingerprints so they share a tooltip row → query `C_TransmogCollection` for collection status.

`GetAppearanceSourceInfo` resolves asynchronously, so the function returns a `linksReceived` flag; when false, `OnTooltipSetItem` calls `tooltip:RefreshDataNextUpdate()` and the whole thing runs again. Any change here must stay idempotent across repeated calls.

### Non-raid sources

Open-world/vendor sources (`Benthic`, `BlackEmpire`, `ForbiddenReach`) have no difficulty context. They organize by armor type (`cloth/`, `leather/`, `mail/`, `plate/`) instead of class-named token groups, use a source-specific difficulty key (`NAZJATAR`, `NZOTH_ASSAULTS`, `THE_FORBIDDEN_REACH`), and map `tokenID` straight to class data with **no `Difficulties` wrapper** — which is what makes the `itemContext > 0` guard in `Core.lua` matter. See `.github/instructions/data-model.instructions.md` for the full pattern catalog.

## Conventions

- 2-space indent (tabs in `Core.lua` and other logic files are the existing style there — match the file), double quotes, no semicolons.
- **Trailing comma on every table entry.** For single-element arrays this is mandatory, not cosmetic: `{ modID, }` — without it Lua unpacks the value.
- Use `Enum.ItemCreationContext.*` constants, never numeric literals.
- Forward slashes in all paths, including XML `file=` attributes, regardless of host OS.
- No external Lua libraries; native Lua + WoW API only.
- Wrap debug-only code in `--@alpha@` / `--@end-alpha@` (`#@alpha@` in `.toc`); `wow-build-tools` strips it from release builds. `@project-version@` in `.toc` is substituted at build time.

## WoW API ground truth

Validate any WoW API/enum/constant against the local [`wow-ui-source`](https://github.com/Gethe/wow-ui-source) checkout at `../wow-ui-source`. Retail-only project — the checkout must be on `live`, `ptr`, `ptr2`, or `beta`, and up to date; say which branch you referenced. On pre-release branches, flag new APIs/enum values and prefer existence guards (`if C_NewAPI and C_NewAPI.Fn then`) so the `live` client keeps working. Avoid anything in `Deprecated_*` files. The `wow-api-researcher` agent handles this lookup.

## Adding a new token source

Data collection is a three-step workflow backed by in-game alpha tooling, documented as prompt files in `.github/prompts/`:

1. `/new-token <SourceName>` — creates `.github/raid_token_records/{NNN}_{SourceName}.md` from `.github/docs/NEW_RAID_TEMPLATE.md`.
2. In-game: the Dungeon Journal "Extract Tokens" button gets token IDs; `/tttgen` (Set Label mode for raid sets, Item List mode for non-raid items) gets appearance/mod IDs. Paste raw output into the record and mark each AUDIT choice with `[X]`.
3. `/plan-token NNN` → `/generate-token NNN` — turn the record into the PLAN OUTPUT and then the actual Lua/XML files.

`/dump TTT_Debug` inspects the merged token table in alpha builds. Details in `.github/docs/debugging-tools.md` and `.github/docs/testing-guide.md`.

Automated tests catch structure and load-order problems, but appearance _accuracy_ can only be confirmed in-game — build, `/reload`, and hover the token at each difficulty (and each faction, where relevant).

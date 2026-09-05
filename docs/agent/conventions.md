# TokenTransmogTooltips conventions

## Structure

- `.toc` loads `Raids/_raids.xml` → `tokenClassAppearanceModInfo.lua` → `Core.lua`; XML files inside `Raids/` fix the sub-order — violating it produces nil-reference errors at load: raid `_index.lua` before its `<Include>`s, a raid's token-group includes before its `tokens.lua` (last), and a token group's class `.lua` files before its aggregator `.lua` (last). `xml_load_order_spec.lua` enforces all three; `_mocks/data_loader.lua` reimplements the walk so tests load the real tree like the client does.
- Data shape, bottom-up: `ns._Gear.{Raid}.{CLASS}[difficulty][slot][appearanceID] = { modID, }` per class; `{TOKENGROUP}[difficulty][slot][CLASS]` re-pivots it; `ns.Raids.{Raid}[tokenID].Difficulties[itemContext]` points at a `tokengroup[diff][slot]` table; `tokenClassAppearanceModInfo.lua` flattens everything to `[tokenID]`, erroring on a duplicate ID in alpha builds.
- Token-group names (`MYSTIC`/`DREADFUL`/…) are directory organization only; nothing reads them except `ns.shadowlandsMultiClassLookup`, which maps old group names back to class icons.
- Non-raid sources (`Benthic`, `BlackEmpire`, `ForbiddenReach`) skip the `Difficulties` wrapper and map `tokenID` straight to class data — this is what the `itemContext > 0` guard in `Core.lua` is for. Full pattern catalog: `.github/instructions/data-model.instructions.md`.
- `Core.lua`'s tooltip build returns a `linksReceived` flag; when false, `OnTooltipSetItem` calls `tooltip:RefreshDataNextUpdate()` and reruns the whole resolution — keep any change here idempotent across repeated calls.

## WoW API

- Validate any API/enum/constant against the local `wow-ui-source` checkout at `../wow-ui-source`; retail-only project, so the checkout must be on `live`, `ptr`, `ptr2`, or `beta` and up to date — say which branch was referenced.
- `/wow-dev:wow-api` handles this lookup.
- On a pre-release branch, flag new or newly-deprecated APIs and prefer existence guards (`if C_NewAPI and C_NewAPI.Fn then`) so the `live` client keeps working. Avoid anything in `Deprecated_*` files.
- Use `Enum.ItemCreationContext.*` constants, never numeric literals.

## Strings

- No locale system (`localeDir` is absent) — user-facing text is hardcoded English in `Core.lua`.
- Debug-only text (labels, dumps) stays inside `--@alpha@`/`--@end-alpha@` blocks so it never ships.

## Testing

- Tests run Lua 5.4 on the host; the addon runs Lua 5.1 in-client. `TokenTransmogTooltips_spec/_mocks/helper.lua` (wired via `.busted`) supplies the compat shims and the `Enum.ItemCreationContext` stub.
- `make boot_sim` simulates a client login against the real files (via `wow-build-tools boot-sim`) to catch Lua load errors before a player does; no build step needed first since there are no `Libs/` externals.
- Automated tests catch structure/load-order problems; appearance _accuracy_ only gets confirmed in-game — build, `/reload`, hover the token at each difficulty and faction.
- New token sources: `/new-token` → `/plan-token` → `/generate-token` prompt workflow drives `.github/raid_token_records/`; `/dump TTT_Debug` inspects the merged token table in alpha builds.

## Packaging

- Only `TokenTransmogTooltips/` ships; `.scripts/`, `_spec/`, `.github/`, `docs/` are dev-only.
- Wrap debug-only code in `--@alpha@`/`--@end-alpha@` (`#@alpha@` in the `.toc`); `wow-build-tools` strips it from release builds. `@project-version@` in the `.toc` is substituted at build time.
- Never commit without a confirmed human review of the diff, and never commit to `main` — the only exception is an explicit human override for that specific commit, given in the moment.
- Never comment on GitHub PRs or issues (review comments, inline comments, PR/issue bodies, any posting `gh` command) unless explicitly asked to in that request; reading/listing/summarizing back in chat is always fine.

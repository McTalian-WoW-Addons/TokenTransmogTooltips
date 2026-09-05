# Agent decisions

Rationale only. Not read by skills or agents.

## Why the data tree carries almost all the risk

`Core.lua` is small (roughly 240 lines) and has stayed stable; nearly every historical
bug has come from the `Raids/` data tree instead — a wrong `modID`, a missing
appearance, or a load-order violation. That is why the test suite (`xml_load_order_spec.lua`,
`data_integrity_spec.lua`) is weighted toward validating data shape and load order rather
than exercising `Core.lua`'s logic, and why appearance accuracy still has to be confirmed
in-game per difficulty/faction — no automated check can know what Blizzard actually ships.

## Why non-raid sources have no Difficulties wrapper

Raid tokens are difficulty-gated (LFR/Normal/Heroic/Mythic via `Enum.ItemCreationContext`),
so their data nests under `Difficulties[itemContext]`. Sources like `Benthic`,
`BlackEmpire`, and `ForbiddenReach` are world/vendor drops with no such context, so their
tables map `tokenID` straight to class data. `Core.lua`'s `itemContext > 0` guard exists
specifically to tell these two shapes apart at resolution time.

## Why shadowlandsMultiClassLookup exists

Shadowlands-era token groups were named things like `MYSTIC` and reused as if they were
class keys in some older data. `ns.shadowlandsMultiClassLookup` in
`tokenClassAppearanceModInfo.lua` maps those old group names back to real class icons so
the tooltip can still render a class icon for that era's data without rewriting it.

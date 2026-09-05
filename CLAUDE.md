# TokenTransmogTooltips

WoW retail addon (Lua 5.1 + WoW API): tooltips on raid/open-world gear tokens showing missing transmog appearances. Token-to-gear data has no Blizzard API and is hand-maintained under `TokenTransmogTooltips/Raids/`. Shared workflow: `wow-dev` plugin skills.

## Commands

`make help` lists targets. Checks: `/wow-dev:run-checks`. Only via make: `make build`, `make watch`, `make boot_sim` (simulate client login, catch load errors before checks), `make test-cov` (-> luacov-html/), `make lua_deps`.

## Conventions

- Never commit without a confirmed human review of the diff; never commit to `main`; never comment on GitHub PRs/issues unless explicitly asked.
- 2-space indent (tabs in `Core.lua`/other logic files are the existing style there — match the file), double quotes, no semicolons.
- Trailing comma on every table entry; mandatory for single-element arrays: `{ modID, }`.
- Use `Enum.ItemCreationContext.*` constants, never numeric literals.
- Forward slashes in all paths, including XML `file=` attributes.
- No external Lua libraries; native Lua + WoW API only.
- Wrap debug-only code in `--@alpha@`/`--@end-alpha@`; `wow-build-tools` strips it from release builds.
  Full list: `docs/agent/conventions.md`.

## Docs

- `.github/docs/testing-guide.md` — writing/validating data tests; in-game verification.
- `.github/docs/debugging-tools.md` — alpha-only tools; `/dump TTT_Debug`.
- `.github/docs/environment-setup.md` — wow-ui-source/wow-build-tools setup, branch check.
- `.github/docs/NEW_RAID_TEMPLATE.md` — template used by the `/new-token` workflow.

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

- `mix setup` — install deps, create/migrate DB, install + build assets
- `mix phx.server` (or `iex -S mix phx.server`) — run app at http://localhost:4000
- `mix test` — runs `ecto.create --quiet` + `ecto.migrate --quiet` then ExUnit
- `mix test path/to/file_test.exs:LINE` — run a single test
- `mix ecto.reset` — drop, recreate, migrate, seed
- `mix credo --strict` — lint (config in `.credo.exs`)
- `mix dialyzer` — type checks (dialyxir)

Dev DB: Postgres on localhost, user/pass `postgres/postgres`, database `treking_dev` (see `config/dev.exs`).

## Architecture

This is a Phoenix 1.8 / LiveView 1.0 app on Elixir ~> 1.19.1 for scoring a trail-running season. The whole user-facing app is **one LiveView** — there is no traditional CRUD controller stack.

### Domain model (binary_id PKs, see `lib/treking/schemas/`)

- `Race` — `name`, `date`
- `Runner` — `first_name`, `last_name`, `birth_year`, `country`, `gender` (`:m`/`:f` enum)
- `Result` — `belongs_to :runner`, `belongs_to :race`, `position`, `points`, `category` (`:active | :challenger | :marathon | :ultra` enum), `dnf`. Unique on `(runner_id, race_id)`.

`Treking.Schemas.Base` is a `__using__` macro applied by all schemas — it sets binary_id primary/foreign keys, imports `Ecto.Changeset` + `EctoEnum`, and aliases `Repo`. New schemas should `use Treking.Schemas.Base` rather than `use Ecto.Schema` directly.

### Main flow — `Treking` + `TrekingWeb.LiveController`

`TrekingWeb.LiveController` (mounted at `/` in `router.ex`) is the entire UI:

1. **Upload** an `.xls`/`.xlsx` via LiveView upload, parsed with `XlsxReader`. The user sees raw columns indexed `0..N-1`.
2. **Map columns** via dropdowns: for each of first_name / last_name / gender / country / birth_year / FIN (dnf marker) / position, the user picks which spreadsheet column holds that field. Special sentinel values bypass per-column parsing: `"M"`/`"F"` (force gender), `"NO_YEAR"`, `"ALL_FIN"`, `"NO_COUNTRY"`.
3. **Parse each row** using a `with` pipeline of `parse_*` functions. `{:error, :ignore}` skips a row (empty rows, DNS/DSQ/STA/RFP markers); any other error halts the whole batch.
4. **Insert** via `Treking.insert/1`: wraps the whole batch in `Repo.transaction`, and for each row calls `fetch_or_insert_runner` (matches on name + gender + optionally birth_year + country) then inserts a `Result`.
5. **Export** (`Treking.create_all_sheets/0`) builds 4 XLSX sheets (challenger M/F, active M/F) using `Elixlsx`. "Challenger" aggregates `[:challenger, :ultra, :marathon]` categories.

### Scoring rules (in `Treking.get_points/2`)

- DNF → 1 point
- Position 1..50 → a hard-coded points table (1st=100, 2nd=85, …)
- Position > 50 → `@break_off_points` (5)
- Season total per runner = sum of their **top `@valid_races` (8)** results, sorted desc

These constants live at the top of `lib/treking.ex`. Changing the scoring table or `@valid_races` changes the season ranking.

### Country normalization

`Treking.fetch_country/1` is a huge hand-maintained map mapping spreadsheet country strings (IOC codes, full names, native names) to canonical Croatian-language labels (e.g. `"GER"`, `"Germany"`, `"Deutschland"` → `"NJEMAČKA"`). Unknown inputs return `{:error, "<input> is an unknown country"}` and halt the batch — add new mappings to this map when an import fails on a new country string.

### Gender/DNF marker constants

`@male_markers`, `@female_markers`, `@fin_markers`, `@dnf_markers`, `@dns_markers` at the top of `lib/treking_web/live/live_controller.ex` control how spreadsheet cells map to enums. Spreadsheets come from different timing systems, so these lists grow over time.

## Conventions

- Credo is `strict: true` and enforces `Readability.AliasAs` and `Readability.SinglePipe` (no single-element pipes). `lib/treking_web/components/` and `test/support/` are excluded.
- `@moduledoc` is disabled in credo (`Readability.ModuleDoc, false`).
- Database files at the repo root (`after_season.sql`, etc.) are `pg_dump` snapshots — see `docs.md`.

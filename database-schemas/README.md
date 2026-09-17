# Database schemas

Machine-readable schema definitions for the ODM v3 relational model, derived from `dictionary-tables/*.csv` (the source of truth).

## What's here

- **`schema-postgres-v<version>.sql`, `schema-sqlite-v<version>.sql`, `schema-mysql-v<version>.sql`** — the SQL DDL for all 26 ODM v3 tables (7 dictionary/reference tables plus 19 data tables), one file per dialect. These are **hand-maintained**, not mechanically generated: column types, lengths, and nullability were reconciled against the live dictionary data empirically (real max string lengths, real blank/populated rates, real FK integrity) rather than trusted from any single declared source — see `sync-odm-sql-templates` (a PHES-ODM-ops skill) for the full process and the empirical findings behind specific choices. A CSV change that only adds/edits rows needs no update here; one that renames, adds, or removes a column does.

  The version in the filename means "confirmed compatible up to this dictionary version," not "content regenerated for this version" — `.github/workflows/regenerate-odm-template.yml` bumps it automatically (renaming only, content untouched) once its own smoke test proves the schema still loads that version's seed data cleanly. Exactly one file per dialect should exist at any time; if you ever find two, an earlier rename was skipped or interrupted.

## What's not here (yet)

- **`odm_v3.yaml`**, the LinkML schema generated from `parts`/`sets` by `PHES-ODM/PHES-ODM-LinkMLGenerator`, is planned to land here too, kept in sync automatically whenever that generator's own schema regenerates. Not yet wired up — that repo's rollout pipeline currently publishes to several other consumer repos (MapGenerator, Mapper, Search-MCP, General-Skill, QPCR-Pipeline) but not back to PHES-ODM itself, and its own dictionary-source configuration needs to be brought current before any new live target is added.

## Related, but stored elsewhere

- **`templates/sql-v3/seed-{postgres,sqlite,mysql}-v<version>.sql`** — reference-table seed data (the 7 dictionary/reference tables' actual rows: `languages`, `countries`, `zones`, `parts`, `sets`, `translations`, `wideNames`), regenerated mechanically from the CSVs by `templates/sql-v3/generate_seed_data.py` every time they change. Kept alongside that script rather than here since it's a generated *data* artifact, not part of the schema definition, and is versioned per dictionary release the same way `templates/ODM_templates_V<version>.xlsx` is.
- **`templates/ODM_templates_V<version>.xlsx`** — the Excel dictionary workbook, generated from the same CSVs by `templates/workbook-v3/generate_workbook.py`.

## How these stay current

`.github/workflows/regenerate-odm-template.yml` regenerates the Excel workbook and the SQL seed data automatically on every push to `main` that touches `dictionary-tables/ODM_*.csv`, and opens a PR. It never touches the schema files here — those require the judgment process in the `sync-odm-sql-templates` skill (empirical length/nullability/orphan checks against real data, load-tested against real PostgreSQL/SQLite/MySQL engines) run by a maintainer, since a structural change carries real design weight that a CSV-content change doesn't.

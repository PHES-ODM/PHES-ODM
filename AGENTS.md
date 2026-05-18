# AGENTS.md

Guidance for AI coding agents (Claude Code, Gemini CLI, Cursor, Copilot, etc.) and human contributors working in this repository.

This file is the canonical AI/contributor guidance for **this repo only**. Tool-specific pointers (`CLAUDE.md`, `GEMINI.md`, `.cursorrules`) all redirect here.

For **org-level navigation** across the PHES-ODM constellation, see `PHES-ODM/.github` (the org-profile repo).

## What this repo is — and what it isn't

This is **the dictionary repo**. Despite the name `PHES-ODM/PHES-ODM`, it is *not* the org-wide hub for development across the constellation of PHES-ODM tools. It ships:

- Versioned CSV dictionary tables in `dictionary-tables/` — the canonical artefact.
- An ERD (`doc-source/ODM_ERD_V3.0.0.pdf`) and SQL schema templates in `templates/`.
- Excel templates for data submission (`templates/`, `data/`).
- Two utility scripts in `src/` for round-tripping the schema and refreshing dictionary CSVs from OSF.

There is **no test suite, no build, no package to install**. Most "work" here is editing CSVs and keeping cross-references coherent.

The OSF project `49z2b` is the upstream source of the Excel dictionary the CSVs are derived from.

## Where downstream consumers live (PHES-ODM org constellation)

A change to the dictionary here ripples through many sibling repos in the `PHES-ODM` org. Be deliberate about edits — a partID renamed here breaks the validator, documentation cross-references, and downstream schema-generation, ontology-mapping, and search-indexing pipelines.

| Repo | What it does | Why an editor here might care |
|------|--------------|------------------------------|
| [`PHES-ODM-Doc`](https://github.com/PHES-ODM/PHES-ODM-Doc) | Documentation site (`docs.phes-odm.org`) | Renders the dictionary; new parts need doc pages. |
| [`PHES-ODM-Validation`](https://github.com/PHES-ODM/PHES-ODM-Validation) | Validator (`validate-docs.phes-odm.org`) | Consumes these CSVs; schema-breaking edits break validation. |
| [`PHES-ODM-Map`](https://github.com/PHES-ODM/PHES-ODM-Map) | Format-mapping tools (non-ODM → ODM) | Map sources reference partIDs. |
| [`PHES-ODM-manuscripts`](https://github.com/PHES-ODM/PHES-ODM-manuscripts) | Academic manuscripts and preprints | Cites specific dictionary versions. |
| [`PHES-ODM-sharing`](https://github.com/PHES-ODM/PHES-ODM-sharing) | Data-sharing tooling | Operates on ODM-formatted data. |

Additional org tooling under active development — LinkML schema generation, ontology mapping, natural-language search — also consumes the dictionary downstream. Treat any partID rename as a breaking change for these pipelines.

**Implication for AI agents:** if a task here looks like it really belongs in a sister repo (e.g., "build a validator", "generate LinkML", "search the dictionary"), say so before writing code. The right move is usually a PR over there, not new code here.

## Dictionary architecture

The dictionary in `dictionary-tables/` is a small relational system in its own right. Each CSV is versioned with a `_v3.0.0` suffix (the current release); unsuffixed copies (e.g. `ODM_parts.csv`) mirror the latest. All cross-references are by `partID` — a short camelCase token that is the universal foreign key.

| File | Role | Key |
|------|------|-----|
| `ODM_parts.csv` | Controlled vocabulary. Every term used anywhere in the ODM (tables, columns, measurements, categories, units, methods) is a row here, typed by `partType`. | `partID` |
| `ODM_sets.csv` | Groups parts into sets (unit sets, mma sets, quality sets, etc.). | `setCompID` = `setID` + `partID` |
| `ODM_translations.csv` | Per-language label/description/instruction for each part. | `translationID` (e.g. `eng<partID>`) |
| `ODM_wideNames.csv` | Wide-format column-name composition (measure/protocol/attribute slots) for flat reporting templates. | `wideName` |
| `ODM_countries.csv`, `ODM_languages.csv`, `ODM_zones.csv` | Lookup tables keyed by `partID`. | varies |

**The cross-file invariant:** every `partID` referenced in `sets`, `translations`, `wideNames`, etc. must exist in `parts.csv`. Adding a new part means touching at least `parts.csv` + `translations.csv` (English at minimum) and often `sets.csv`. Editing one file in isolation is usually wrong.

`ODM_parts.csv` is wide (~100 columns) because it also encodes which **report tables** each part belongs to (`measures`, `samples`, `sites`, `protocols`, ...) plus matching `*Required` and `*Order` columns. Those columns are how the 15 report tables are derived from a single vocabulary — there is no separate "schema per table" file.

## Schema round-trip (SQL)

The SQL schema is authored in Lucidchart, not in this repo. The flow:

1. Edit the ERD in Lucid.
2. Export SQL → `src/lucid-mysql.sql` (Lucid's order doesn't respect FK dependencies, so it isn't executable as-is).
3. Run `python src/lucid-to-sql.py` to split `CREATE TABLE` from `ALTER TABLE` (FK) statements and reorder them. Output: `templates/ODM-mysql.sql`.
4. Toggle `clip = 1` in the script to operate on the clipboard instead of files.

`src/data-tables.r` is the other utility: it pulls the latest dictionary Excel from OSF (`49z2b`) and writes CSVs into `dictionary-tables/`. Requires R packages `osfr`, `here`, `dplyr`, `knitr`, `readxl`. Run from the project root so `here()` resolves correctly.

## Versioning and release workflow

- Active development happens on the `dev` branch; feature branches PR into `dev`; periodic PRs from `dev` → `main` cut a release. Current `main` is at v3.0.0 (merged from PR #275).
- New-version checklist (from `CONTRIBUTING.md`): every file in `dictionary-tables/` gets the new version suffix (e.g. `ODM_parts_v3.0.0.csv` → `ODM_parts_v3.1.0.csv`); the unsuffixed mirrors are updated to match. Tag the release commit with the version number.
- Prior major versions live in `Archived V2.0/`, `Archived V2.1/`, `Archived V2.2/`, `archived V1.0/`. Don't edit them.

## Conventions

- **File and folder names:** kebab-case, lowercase (per `CONTRIBUTING.md`).
- **partIDs:** camelCase, short, stable. They are public identifiers — once published they should not be renamed. A rename is a breaking change for every sister repo in the constellation.
- **CSV editing:** Use a data-frame tool (R `read.csv()`/`write.csv()`, Python pandas). Never `sed`/`awk`/`perl`. Several columns contain commas inside quoted strings and free-text descriptions; line-based tools silently corrupt them.
- **`NA` is a literal** in these CSVs, meaning "not applicable for this part type" — not a missing cell. Preserve it on read/write. In R: `read.csv(..., na.strings = "")` and `write.csv(..., na = "NA")`. In pandas: `read_csv(..., keep_default_na=False)` and `to_csv(..., na_rep="NA")`.
- **Issue templates** in `.github/ISSUE_TEMPLATE/` are the expected route for proposing new parts or new variant/mutation alleles; check there before hand-designing a part.

## Org-level conventions (also see `PHES-ODM/.github`)

- **Canonical org:** `PHES-ODM`. The historical `Big-Life-Lab/PHES-ODM` URL still works via GitHub redirect, but new links should use `PHES-ODM/...`. Existing references in this repo's `README.md` and `CONTRIBUTING.md` are stale and survive only via redirect.
- **Open-science commitment** (per the project Constitution): anything load-bearing should be public. Private sister repos are appropriate for in-progress work; they should not become the only place a published artefact exists.

## What this repo does **not** contain

To save discovery time: no R package, no Python package, no Quarto site, no CI beyond issue templates, no automated dictionary validator. The validator lives in `PHES-ODM-Validation`. Documentation rendering lives in `PHES-ODM-Doc`. Cross-repo coordination, roadmap, and working-group context do not live here.

## Project sites

User-facing sites under `phes-odm.org`:

- [`phes-odm.org`](https://phes-odm.org) — project landing (Webflow-hosted; no backing repo).
- [`docs.phes-odm.org`](https://docs.phes-odm.org) — documentation (`PHES-ODM-Doc`).
- [`validate-docs.phes-odm.org`](https://validate-docs.phes-odm.org) — validator UI (`PHES-ODM-Validation`).

## Tool-specific notes

- **Claude Code**: this file is loaded via `CLAUDE.md` (one-line pointer). Project skills (e.g., `discourse-respond`) live in `~/github/ai-infrastructure/skills/` for Doug, not in this repo.
- **MCP servers**: a Discourse MCP (configured for `odm.discourse.group`) is available in Doug's environment, useful for steering-committee / community discussion.

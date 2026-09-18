# Contributing

Contributions are welcomed. 

## Working groups

The develop of the Ottawa Data Model mostly occurs with informal working groups are created as needed to improve metadata sections. These working groups are time-limited and follow an agile development approach. Please feel free to suggest of offer hosting a working group in GitHub issues or discussions. 

Working groups propose changes directly through a pull request to `main` (the `dev` branch is no longer part of the active workflow). Initial review for the PR is from previous contributors, and we welcome community review from anyone in the wastewater surveillance community. Please explain the rationale for the change in the issue or pull request. Please `watch` this GH repo to ensure you are aware of proposed changes. 

## Repo Organization

### Naming Conventions

* Use [kebab-case](https://www.theserverside.com/definition/Kebab-case#:~:text=Kebab%20case%20%2D%2D%20or%20kebab,properly%20convey%20a%20resource's%20meaning.) when naming files and folder making sure to use lower case

### Git Workflow

This repo follows the [git feature branch workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/feature-branch-workflow)

* The `main` branch should always have the latest public/working/correct/buildable version of the model.
* As much as possible avoid committing directly to `main`. Instead, new features, bug fixes, part additions, etc. should be worked on a separate branch and then a PR should be made to `main`.
* When a new version is released, the commit that has the new version should be tagged with the version number.

### New Version Checklist

Steps 1–4 apply to every pull request touching the dictionary tables. Steps 5–9 are the maintainer's process for actually cutting a new version once enough such PRs have landed on `main`.

1. **Edit the files in the [dictionary-tables](https://github.com/PHES-ODM/PHES-ODM/tree/main/dictionary-tables) folder directly** — adding parts, adjusting sets, or correcting errors — and open a pull request to `main`. Explain the rationale for the change in the issue or pull request.

2. **The pull request is checked automatically against [`internal_structure_rules/DICTIONARY_VALIDATION.md`](internal_structure_rules/DICTIONARY_VALIDATION.md)**, the dictionary's own structural rule spec (`validate-dictionary-rules.yml`). A HARD rule violation fails the check and blocks merging — fix it before proceeding. A SOFT/advisory finding doesn't block anything, but is worth a manual look in the job summary; it usually means either a legitimate edge case or a miscategorization worth fixing while you're there.

3. **You do not need to manually create or update a versioned copy of a dictionary table** (e.g. `ODM_parts_v3.1.0.csv`) — a GitHub Action keeps each `ODM_<table>.csv` and its versioned sibling in sync automatically once your change lands on `main`.

4. **You do not need to manually regenerate the SQL schema or the Excel dictionary template** — separate GitHub Actions do this automatically from the updated CSVs and open their own pull request with the result. The hand-maintained SQL schema files live in [`database-schemas`](database-schemas); their content only changes when a column is renamed/added/removed (see [`sync-odm-sql-templates`](https://github.com/PHES-ODM/PHES-ODM-ops), a maintainer-run process), but their filenames are bumped to the new version automatically.

5. **Update the Entity Relationship Diagram** if the change adds, removes, or restructures a table or relationship (not needed for a routine part/set addition or content correction) — run the `sync-odm-erd` process to pull a fresh export from the team's Lucid diagram into `doc-source/`.

6. **Sync the documentation site** (`PHES-ODM/PHES-ODM-Doc`) — swaps in the new dictionary snapshot, bumps the doc's own version, and renders the reference chapters. This is designed to happen automatically once cross-repo publishing is configured between the two repos; until then, run the `sync-odm-doc-release` process by hand.

7. **Update the LinkML schema copy** in [`database-schemas`](database-schemas) from `PHES-ODM/PHES-ODM-LinkMLGenerator`'s generated `odm_v3.yaml`. That repository regenerates the schema from the dictionary already; pulling a copy back into this repo automatically isn't wired up yet, so for now this is a manual copy.

8. **Update the changelog and merge it to `main`**: run the `sync-odm-changelog` process to draft the `changelog.md` entry for the new version — comparing the real dictionary content on `main` against the previous release's tag, rather than trusting the CSVs' own `firstReleased`/`changes` columns, which have been caught lagging a real change by a full release — and merge it. This has to land on `main` *before* the release is cut, so the tagged commit already contains its own changelog entry.

9. **Draft and publish a GitHub Release from `main`**, creating the new version tag (`vX.Y.Z`, matching existing tags) as part of that same step via GitHub's own release UI (or `gh release create`) — there's no separate manual `git tag` command. Paste the changelog entry from step 8 into the release description.

10. **Update all other directories**, following the documentation [outlined here](https://phes-odm.github.io/PHES-ODM-LinkMLGenerator/how-to/dictionary-workflow/#3-regenerate-the-linkml-map-schemas)
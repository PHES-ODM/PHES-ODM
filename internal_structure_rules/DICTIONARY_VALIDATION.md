# PHES-ODM dictionary validation rules

Formal rule specification derived from an empirical audit of `dictionary-tables/*.csv` (originally: `v3.0.1-ODM dictionary-workingDoc.xlsx`, `parts` sheet, 2,265 rows across 31 partTypes). Each rule has a stable ID, an exact condition, an explicit exception list (empty if none), a one-line rationale, and a severity. This document is the spec a validator implements against — see `.github/scripts/validate_dictionary_rules.py` (the validator; each check function is named after the rule ID(s) it enforces) and `.github/workflows/validate-dictionary-rules.yml` (the GitHub Action that runs it on every pull request touching `dictionary-tables/ODM_*.csv`).

## How to read a rule

- **ID**: stable identifier. Referenced verbatim in validator output, so a violation message can point back here.
- **Severity**:
  - **HARD** — zero exceptions beyond the ones listed. A validator MUST fail a PR that violates this.
  - **SOFT** — a strong pattern with legitimate, judgment-dependent exceptions (new-content lag, genuinely mixed-by-design columns, etc.). A validator SHOULD report a violation as an advisory warning, never a blocking failure.
- **Scope**: every rule applies to `status=active` parts only, checked against the live `dictionary-tables/*.csv` (not the authoring workbook — see "Out of scope" at the end for workbook-only concerns that don't apply here at all). A `status=depreciated` part is never evidence for or against a rule, and reactivating one requires bringing it into line with the current rules first, not grandfathering its old shape.
- **Sentinel convention**: nine columns (`domain`, `specimenSet`, `compartmentSet`, `group`, `class`, `nomenclature`, `unitSet`, `aggregationScale`, `aggregationSet`) use a dedicated "not applicable" sentinel partID (`naDomain`, `naSpecimenSet`, `naCompartmentSet`, `naGroup`, `naClass`, `naNomenclature`, `naUnitSet`, `naAggrScale`, `naAggrSet`) rather than being left blank. `domain=allDo` is a distinct, non-sentinel value meaning "applies to all domains" — never conflate the two.

---

## `measurements`

| ID | Condition | Exceptions | Rationale | Severity |
|---|---|---|---|---|
| PT.MEA.01 | `aggregationScale` ∈ {`seeUnitAggScale`, `quantAggScale`, `qualAggScale`, `othAgg`} | `hMe` (`naAggrScale` — see PT.MEA.03) | Closed value set; `seeUnitAggScale` defers to the measurement's own unit. | HARD |
| PT.MEA.02 | `dataType` ∈ {`seeUnitData`, `integer`, `float`, `categorical`, `varchar`, `boolean`} | none | Closed value set; `seeUnitData` defers to the unit, same mechanism as PT.MEA.01. | HARD |
| PT.MEA.03 | `hMe` (wideNames header placeholder) has `unitSet=naUnitSet`, `aggregationScale=naAggrScale`, `dataType=varchar` | — | `hMe`'s value comes from the table header at parse time, so the normal unit-deferral chain (PT.MEA.01/02) doesn't apply to it. | HARD |
| PT.MEA.04 | `missingnessSet`, when populated, `= genMissingnessSet` | none | No measurement uses a specialized missingness set. | HARD |
| PT.MEA.05 | `qualityIndSet` is populated | `hMe` | Every real measurement has a quality profile; `hMe` is a placeholder, not a measurement. | HARD |
| PT.MEA.06 | `mmaSet` populated ⟺ `dataType` ∈ {`categorical`, `boolean`} | none | See XC.04 for the general rule this instantiates. | HARD |
| PT.MEA.07 | `nomenclature` ∈ {`naNomenclature`, `who`, `pangolin`, `ncbiNom`, `icd`} | none | Closed value set; real values only for measurements tied to an external naming standard. | HARD |
| PT.MEA.08 | `protocolSteps=input`, `measures=input`, `wideNames=input` | none (holds even for `hMe`) | Every measurement is usable in all three tables. | HARD |
| PT.MEA.09 | `domain`, `specimenSet`, `compartmentSet`, `group`, `class`, `unitSet`, `aggregationSet` carry a real (non-sentinel) value | `hMe` (fully sentinel across all of these — see PT.MEA.03) | Last observed at 97–100% population; a sentinel here on an otherwise-normal measurement is worth a second look, not an automatic rule violation. **Confirmed 2026-09**: a full manual review of every live finding resolved 26 of 32 as real miscategorizations (now fixed) and the remaining 6 as `hMe`'s already-documented placeholder exception — `hMe` is excluded here so it stops needing re-review on every run. | SOFT |

## `attributes`

| ID | Condition | Exceptions | Rationale | Severity |
|---|---|---|---|---|
| PT.ATT.01 | `domain`, `specimenSet`, `compartmentSet`, `group`, `class`, `nomenclature`, `unitSet`, `aggregationScale`, `aggregationSet` are all the sentinel | none | Attributes describe structural/metadata fields, never measured quantities. | HARD |
| PT.ATT.02 | `dataType` ∈ {`varchar`, `categorical`, `datetime`, `integer`, `float`, `date`, `boolean`} — never `seeUnitData` | none | An attribute never defers to a unit; it states its own type. | HARD |
| PT.ATT.03 | `mmaSet` populated ⟺ `dataType` ∈ {`categorical`, `boolean`} | none | Instance of XC.04; fully bidirectional for this partType. | HARD |
| PT.ATT.04 | Exactly one `pK` per `<table>` triplet column, counting `partSupport` rows alongside `attributes` rows | `partID`'s own row (`parts=pK`, `sets=fK`) | `partSupport` is the dictionary's own structural columns (`partDesc`, `label`, `status`, etc.) — the self-referential counterpart to `attributes` — so its rows must be included or per-table `pK` counts look short by one. | HARD |
| PT.ATT.05 | `maxLength` defaults to `30` unless the field needs more room | judgment | ~72% are exactly 30; real, deliberate variation exists both up and down for free-text/short-code fields. | SOFT |
| PT.ATT.06 | `minLength` is `0` | judgment | ~97% population; a real nonzero minimum is rare but not invalid. | SOFT |

## `categories`

| ID | Condition | Exceptions | Rationale | Severity |
|---|---|---|---|---|
| PT.CAT.01 | `unitSet`, `aggregationSet`, `aggregationScale` are all the sentinel | none | A category is never itself a unit/aggregation classification. | HARD |
| PT.CAT.02 | `nomenclature` is the sentinel | none | Categories never carry an external naming-system reference. | HARD |
| PT.CAT.03 | Every populated `<table>` triplet role `= input` | none | Instance of XC.02: content-bearing types never take `pK`/`fK`/`header`. | HARD |
| PT.CAT.04 | `dataType` ∈ {`varchar`, `boolean`} | `boolean` only for the two literal `TRUE`/`FALSE` category rows | `categorical` never appears on a `categories` row itself — that shape is reserved for the parts *consuming* a category-backed `mmaSet`. | HARD |
| PT.CAT.05 | `TRUE`/`FALSE` partIDs are exactly the uppercase strings `TRUE` and `FALSE` | — | Confirmed live bug (2026-09): `ODM_sets.csv`'s `booleanSet` membership rows had drifted to the lowercased-initial `True`/`False`, breaking the FK to `parts.partID` after `parts.csv` was corrected to uppercase. Check every FK reference to these two partIDs, not just the `parts.csv` row itself. | HARD |
| PT.CAT.06 | `mmaSet` is never populated | none (including `TRUE`/`FALSE`, which are `booleanSet`'s own member rows, not something pointing at a set) | A category is a value, not something with its own enumerated value set. | HARD |
| PT.CAT.07 | `domain`, `compartmentSet` are the sentinel | none | A category is domain/compartment-agnostic by construction. | HARD |
| PT.CAT.08 | `group`, `class` are NOT required to be uniform | — (this is an explicit anti-rule) | Deliberately a mixed bag (~half populated) — genuine organizational tags, not a completeness gap. Never flag a blank `group`/`class` on a category as a violation. | — (documentation only) |

## `units`

| ID | Condition | Exceptions | Rationale | Severity |
|---|---|---|---|---|
| PT.UNI.01 | `compartmentSet`, `unitSet` are the sentinel | none | A unit never classifies itself by compartment or by another unit. | HARD |
| PT.UNI.02 | `domain`, `specimenSet`, `aggregationScale`, `aggregationSet` carry real values | `hUn` ("See Header for Unit"), `naUnit` ("Unit not applicable") — both fully sentinel across all four columns | These two are placeholder/support rows, not real units. | HARD |
| PT.UNI.03 | `qualityIndSet`, `missingnessSet`, `mmaSet` are blank | none | No sentinel is defined for these columns on this partType. | HARD |
| PT.UNI.04 | `wideNames=input`, `measures=input`, `protocolSteps=input` | none | Every unit is a valid wide-format header component and measurement unit. | HARD |
| PT.UNI.05 | `dataType` ∈ {`integer`, `float`, `varchar`, `datetime`, `boolean`} | — | Reflects the type of the value reported in that unit — what a measurement's `dataType=seeUnitData` resolves to. | SOFT (informational closed-set note; not independently enforced beyond the general `dataType` enum) |

## `classes`

| ID | Condition | Exceptions | Rationale | Severity |
|---|---|---|---|---|
| PT.CLS.01 | `dataType=varchar`, `aggregationSet=naAggrSet` | none | Uniform across the partType. | HARD |
| PT.CLS.02 | `class = ` own `partID` | none | Every class row unconditionally self-references its own `class` column. | HARD |
| PT.CLS.03 | `unitSet=naUnitSet` ⟺ (`aggregationScale=naAggrScale` AND `compartmentSet=naCompartmentSet`); otherwise `aggregationScale=seeUnitAggScale` and `compartmentSet` is a real value | none | A class either has no unit at all (and is sentinel across all three), or defers entirely to its unit — never a partial mix. | HARD |
| PT.CLS.04 | `measures=input` AND `parts=input` | none | A class is always a valid `measures.class` and self-referential `parts.class` value. | HARD |
| PT.CLS.05 | `group` is the sentinel | none | Classes never belong to a group. | HARD |
| PT.CLS.06 | `missingnessSet`, `mmaSet` are blank | none | No sentinel defined for these on this partType. | HARD |
| PT.CLS.07 | `domain`, `specimenSet` are NOT required to be uniform | — (anti-rule) | Genuine mixed-by-design classification; do not flag blanks/sentinels here as violations. | — (documentation only) |
| PT.CLS.08 | A class's `domain` equals `allDo` whenever the `measurements` rows referencing it (via `measurements.class`) span more than one domain; otherwise it matches that single domain exactly | `naClass` (not a real class) | The class generalizes over, rather than pins to, its members' domains. Requires a join against `measurements.class`/`measurements.domain`. | HARD (multi-table check) |

## `groups`

| ID | Condition | Exceptions | Rationale | Severity |
|---|---|---|---|---|
| PT.GRP.01 | `compartmentSet=anyCompartmentSet`, `parts=input`, `unitSet=naUnitSet`, `aggregationSet=naAggrSet` | none | Uniform across the partType, including the `naGroup` placeholder row itself. | HARD |
| PT.GRP.02 | `qualityIndSet`, `missingnessSet` are blank | none | No sentinel defined for these on this partType. | HARD |
| PT.GRP.03 | `domain` ∈ {`bio`, `allDo`} | none (`naDomain` never appears) | A group is always either biological or domain-agnostic, never "not applicable." | HARD |
| PT.GRP.04 | `domain=bio` ⟹ `specimenSet=saSpecimenSet`; `domain=allDo` ⟹ `specimenSet` ∈ {`siSaSpecimenSet`, `poSpecimenSet`, `siSpecimenSet`, `naSpecimenSet`} | `naSpecimenSet` only on `naGroup` | Specimen classification splits exactly along the domain line. | HARD |
| PT.GRP.05 | `aggregationScale=seeUnitAggScale` | `naGroup` (`naAggrScale`) | Every group defers to its (possibly absent) unit the normal way except the one genuinely inapplicable row. | HARD |
| PT.GRP.06 | `class` ∈ {`organism`, `naClass`} | none | `organism` flags every single-pathogen/taxon group, enabling an "all organism-level groups" rollup; everything else (structural groups, multi-strain variant-tracking groups) is `naClass`. | HARD |
| PT.GRP.07 | `dataType=varchar` | none | Uniform across the partType. | HARD |

## `methods`

| ID | Condition | Exceptions | Rationale | Severity |
|---|---|---|---|---|
| PT.MET.01 | `domain`, `specimenSet`, `compartmentSet` carry real (non-sentinel) values | none | No method is domain/specimen/compartment-agnostic. | HARD |
| PT.MET.02 | `group` is a real value | none (`naGroup` never appears) | Every method belongs to a real group (`procGrp`, `measGrp`, `bactMisc`, `popGrp` observed). | HARD |
| PT.MET.03 | `dataType` ∈ {`categorical`, `boolean`} | none | A method is always a choice among named options or a yes/no flag. | HARD |
| PT.MET.04 | `mmaSet` is populated | none | Every method needs an enumerating set — stricter than the general XC.04 rule, since methods have zero exceptions. | HARD |
| PT.MET.05 | `missingnessSet=genMissingnessSet`; `qualityIndSet` is populated (never blank) | none | — | HARD |
| PT.MET.06 | `protocolSteps=input` AND `wideNames=input` | none | No other table triplet is used by this partType. | HARD |

## `qualityIndicators`

| ID | Condition | Exceptions | Rationale | Severity |
|---|---|---|---|---|
| PT.QI.01 | `domain`, `specimenSet`, `compartmentSet`, `group`, `class`, `nomenclature`, `unitSet`, `aggregationScale`, `aggregationSet` are all the sentinel | none | A quality indicator describes a property of a measurement's quality, never its subject matter — not even `allDo`. | HARD |
| PT.QI.02 | `qualityIndSet`, `missingnessSet`, `mmaSet` are blank | none | No sentinel defined for these on this partType. | HARD |
| PT.QI.03 | `dataType=varchar`, `maxLength=30`, `minLength=0` | none | Total uniformity across the partType. | HARD |
| PT.QI.04 | `qualityReports=input`; every other `<table>` triplet column is blank | none | The single most narrowly-scoped partType — never used by any other table. | HARD |

---

## Vocabulary and schema-structure closure (`VOCAB.*`)

These 22 partTypes (377 active rows) define the dictionary's own vocabulary rather than content. The dominant shape is **closure**: the set of values actually used in a consuming column exactly equals the set of active partIDs defined under the corresponding vocabulary partType — checked as a full set-difference in both directions, never a spot check.

| ID | Vocabulary partType (defined) | Consuming location (used) | Exceptions | Severity |
|---|---|---|---|---|
| VOCAB.01 | `specimens` | members of every `specimenSets` grouping | none | HARD |
| VOCAB.02 | `compartments` | members of every `compartmentSets` grouping | none | HARD |
| VOCAB.03 | `aggregations` | members of every `aggregationSets` grouping | none | HARD |
| VOCAB.04 | `specimenSets` | `parts.specimenSet` | none | HARD |
| VOCAB.05 | `compartmentSets` | `parts.compartmentSet` | none | HARD |
| VOCAB.06 | `unitSets` | `parts.unitSet` | none | HARD |
| VOCAB.07 | `qualityIndSets` | `parts.qualityIndSet` | none | HARD |
| VOCAB.08 | `aggregationSets` | `parts.aggregationSet` | none | HARD |
| VOCAB.09 | `missingnessSets` | `parts.missingnessSet` | none | HARD |
| VOCAB.10 | `dictSets` | `sets.setID` where `sets.setType=dictSets` | none | HARD |
| VOCAB.11 | `shortSets` | `sets.setID` where `sets.setType=shortSets` | none | HARD |
| VOCAB.12 | `domains` | `parts.domain` | none | HARD |
| VOCAB.13 | `nomenclatures` | `parts.nomenclature` | `nextclade` may be unused (sanctioned but currently idle — documented in the `nomenclature` attribute's own `partInstr`) | HARD |
| VOCAB.14 | `aggregationScales` | `parts.aggregationScale` | none | HARD |
| VOCAB.15 | `dataTypes` | `parts.dataType` | `blob` may be unused among active parts (its only historical use is on a now-`depreciated` row) | HARD |
| VOCAB.16 | `mmaSets` (n=77) | `parts.mmaSet` (curated, non-whole-category uses only — see XC.04 for the other two forms) | none | HARD |
| VOCAB.17 | Every `mmaSets` row is self-referential (`mmaSet` = own `partID`) | — | none | HARD |
| VOCAB.18 | `setTypeSet` (an `mmaSets` row) enumerates exactly the 9 Set-definition partTypes in VOCAB.04–11 + `mmaSets` itself, no more and no less | — | none | HARD |
| VOCAB.19 | `partTypes` (n=32) | `parts.partType` (31 of 32 used) ∪ `wideNames.wideNameType` (uses the 32nd, `exceptions`, plus a strict subset of the other 31) | none | HARD |
| VOCAB.20 | `tableSupport` row count `= 2 × (distinct base table names in ODM_parts.csv's own triplet columns) + 2` | — | The `+2` are general-purpose non-table-specific rows (`changes`, `descrChange`). | HARD |
| VOCAB.21 | `shortName` row count `=` (one row per base table name) `+ 2` | — | The `+2` are partType-level shorthands (`measurements`, `methods`), not table shorthands. | HARD |

## `dataType`-level rules (`DT.*`)

Checked across all active parts regardless of partType.

| ID | Condition | Exceptions | Rationale | Severity |
|---|---|---|---|---|
| DT.01 | `dataType=seeUnitData` only ever appears on `measurements` rows | `andBoo` (`aggregations`), `waterCompartmentSet` (`compartmentSets`) — both confirmed, still-outstanding copy-paste residue from a measurement template row, not accepted exceptions; a validator should keep flagging them until fixed | Vocabulary-definition/support partTypes have no unit to defer to at all, so `seeUnitData` there is never meaningful. **Correction**: this was originally written as a strict `dataType=seeUnitData ⟺ aggregationScale=seeUnitAggScale` biconditional, on the theory the two tokens always move together. Empirically false — confirmed live (2026-09): 396/427 `dataType=seeUnitData` measurements also defer `aggregationScale`, but 31 legitimate ones (`ampSize`, `caff`, `duration`, `popDensity`, `tds`, etc.) state a concrete `aggregationScale=quantAggScale` instead, and 196 rows do the reverse (defer `aggregationScale` while stating a concrete `dataType`). Type and aggregation-scale deferral are independent per-row decisions, same lesson as DT.03. | HARD |
| DT.02 | On the `aggregations` vocabulary partType: `minValue=maxValue=seeUnitVal` | `naAggr` (blank — correctly, no unit to defer to) | Third member of the `seeUnit*` deferral family, extended to the atomic-aggregation-method vocabulary. **`epiMean` was a known, temporary gap against this rule (missing the deferral with no `naAggr`-style excuse) — fixed 2026-09; zero exceptions beyond `naAggr` remain.** | HARD |
| DT.03 | For `measurements` rows with a numeric `dataType` (`integer`, `float`, or `seeUnitData`), each of `minValue`/`maxValue` independently is either `seeUnitVal` (deferred to the referenced `units` row) or a real, domain-meaningful number — never blank, never a value that ignores the unit dependency | A concrete `minValue` (e.g. `0`, a natural floor that holds regardless of unit) may coexist with a deferred `maxValue`, and vice versa — confirmed live (e.g. `c2811t`, `mCF`, `mESV`, `nh3nh4`: `minValue=0`, `maxValue=seeUnitVal`) | The deferral is NOT gated on the measurement's own `dataType` literally being `seeUnitData` — a measurement can state a concrete `integer`/`float` type while its numeric range still depends on which unit gets chosen (confirmed: 472/476 active numeric-dataType measurements defer at least `maxValue`, 2026-09 cleanup). `minValue` and `maxValue` are independent decisions, not a single all-or-nothing pair. | SOFT (a strong, near-universal pattern with legitimate per-field exceptions requiring domain judgment — not a single clean boolean condition) |
| DT.04 | `categorical`-typed rows have `minLength`/`maxLength` populated | none | Universal despite not being a length-bound type in the `varchar` sense — likely documents the enumerated choice's label length. | HARD |
| DT.05 | `integer`/`float`/`seeUnitData`-typed rows do NOT have `minLength`/`maxLength` populated | none | Stray `varchar`-template residue (`minLength=0`, `maxLength=30/50/100`) with no meaning on a numeric type. **Resolved 2026-09**: 58 rows across `dictionary-tables/*.csv` had this residue (far more than the 20 first spotted — a full sweep found the rest), all cleared, several also gaining a real `minValue`/`maxValue` in the process (see DT.03). Confirmed zero remaining violations across all active rows. Promoted from SOFT to HARD now that the debt is actually clean — a validator should treat any future recurrence as a real regression, not tolerate it as ongoing debt. | HARD |

---

## Cross-cutting / global rules (`XC.*`)

| ID | Condition | Exceptions | Rationale | Severity |
|---|---|---|---|---|
| XC.01 | The 9 sentinel columns (see "Sentinel convention" above) use their type-specific `na*` partID, never blank, never the literal string `"NA"` | — | Foundational; every per-partType sentinel rule above instantiates this. | HARD |
| XC.02 | `attributes`/`partSupport` rows take `pK`/`fK`/`header` roles on `<table>` triplet columns; `measurements`/`categories`/`units`/`classes`/`groups`/`methods` take `input` only | none | Table-triplet role is determined by partType, not by which table. | HARD |
| XC.03 | `dataType=seeUnitData`/`aggregationScale=seeUnitAggScale` always resolve to a real value on the referenced `units` row | none | See DT.01; the `units` partType is where the deferred value actually lives. | HARD |
| XC.04 | `mmaSet` enumeration takes exactly one of three forms: (a) explicit pointer to a curated `mmaSets` grouping (VOCAB.16); (b) implicit closure — the value is enumerated by "whichever column elsewhere in the workbook draws its values exclusively from this partType" (the 9 Set-definition partTypes, VOCAB.04–11 + `mmaSets` itself, per `setTypeSet`/VOCAB.18); (c) a partType category name used directly as the `mmaSet` value, meaning "any active row of that partType is valid" (e.g. `qualityFlag.mmaSet=qualityIndicators`) | `TRUE`/`FALSE` category rows (they're `booleanSet`'s own members, not something with an enumerating set) | Every categorical/boolean-typed part has an enumerating set behind it — it's just sometimes explicit and sometimes implicit. | HARD |
| XC.05 | `partID` is globally unique across all active parts, checked across every partType at once | none | — | HARD |
| XC.06 | `partID` matches `^[a-zA-Z][a-zA-Z0-9]*$` (no whitespace, including non-breaking space `\xa0`) | `16rgs` (starts with a digit — the scientific name "16S Ribosomal Gene Sequencing") | Only one legitimate exception found; every other violation to date (`nsp1`–`nsp16`, `orf3a`/`orf3b`/`orf7a`/`orf9b`/`orf9c`/`orf10`/`orf14` family carrying trailing/embedded whitespace) was a real bug, not a naming choice. | HARD |
| XC.07 | `firstReleased`, `lastUpdated` are populated, in strict `X.Y.Z` semver format, and `firstReleased <= lastUpdated` | none | — | HARD |
| XC.08 | `changes` is populated | `firstReleased <= 2.0.0` | The `changes`-field convention became consistently enforced starting ~v2.1.0; earlier foundational rows were never backfilled. A gap on a part first released after 2.0.0 is a real violation. | HARD |
| XC.09 | Every active `partID` has exactly one `eng` row in `translations.csv` | none | `eng` is a mechanical copy of the part's own `label`/`partDesc`, not a drafted translation — there is no legitimate reason for it to be missing. | HARD |
| XC.10 | Every active `partID` has a translation row in every other registered language (read `ODM_languages.csv`, don't hardcode the list) | A newly-added part (this dictionary version's `firstReleased`) may lag non-`eng` translations temporarily | Full non-English coverage is the goal; a brand-new part isn't a violation, an old one still missing coverage is. | SOFT |
| XC.11 | `fKAliasID`, wherever populated, resolves to a real, existing `partID` | none | Standard FK integrity, checked from the `parts.csv` side (companion to the SQL-schema `fKAliasID` FK enforced by `sync-odm-sql-templates`). | HARD |
| XC.12 | `label`, `partDesc` are populated for every active part | none | — | HARD |
| XC.13 | `status` ∈ {`active`, `depreciated`} | none | No leftover `development` status. | HARD |
| XC.14 | No two active parts share the same `label` | none | Resolved historically by depreciating the duplicate `partID` in each pair, keeping one canonical active `partID` per real-world concept. | HARD |
| XC.15 | `minValue < maxValue` wherever both are real numbers | rows where either is the `seeUnitVal` deferral token (not a number at all) | — | HARD |
| XC.16 | In `sets.csv`: every `setID` maps to exactly one `setType`; `setCompID` is unique; there are zero duplicate `(setID, partID)` membership pairs | none | Internal key integrity of the sets table. | HARD |
| XC.17 | Every column header in every published `dictionary-tables/*.csv` table has a matching `partID` describing it (via `partSupport` for dictionary-structure columns, or an `attributes` row for a data-table column) | none | The dictionary describes its own schema using itself. A failure here means either a genuinely missing part needs writing, or the column itself shouldn't exist in that table — check the column's actual content before assuming which (see the `parts.csv`/12-column and `zones.csv`/`Column1` incidents this rule already caught). | HARD |
| XC.18 | Every `wideNames.csv` `*Name` column matches the CURRENT `label` of the partID (or, for `fractionInput`, the `sets.csv` partID) its paired `*Input` column names | none | `*Input` is the stable identity reference; `*Name` is a display cache with no independent authority and nothing re-syncs it automatically when the referenced `label` changes. Re-check on every `label` change, not just when `wideNames.csv` itself is edited. | HARD |

---

## Out of scope for CSV validation

The following apply only to the authoring workbook (`*-ODM dictionary-workingDoc.xlsx`) before its content is trimmed and exported to the published `dictionary-tables/*.csv` files. A CSV-based validator has no way to check these and should not attempt to — they're recorded here only so a reader doesn't wonder why a workbook-side concern from the original audit doesn't appear as a rule above.

- The `parts` sheet's last 19 columns (`label_fr`/`partDescription_fr`/`partInstruction_fr`, the crosswalk columns `nwss`/`nwssProcess`/`nwssNotes`/`ena`/`enaNotes`/`norman`/`normanNotes`/`wSphere`/`wSphereNotes`/`ncbi`/`phage`, and the v1-migration columns `version1Table`/`version1Location`/`version1Variable`/`version1Category`/`version1to2Changes`) are trimmed before publication and never appear in the published CSVs at all. Their sparse/loosely-paired population in the workbook is not a completeness concern.
- The `True`/`False` category partIDs being stored as native Excel booleans (rather than text) in the authoring workbook's `partID` column is a workbook-export risk (a spreadsheet tool could silently rewrite them on save), not something checkable in the CSV itself — XC.06/PT.CAT.05 cover the CSV-side consequence directly.

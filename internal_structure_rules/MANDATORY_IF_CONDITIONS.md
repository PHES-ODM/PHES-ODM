# PHES-ODM `mandatoryIf` conditions

For every `<table>` a `parts.csv` attribute belongs to, its `<table>Required` companion column states whether it's `mandatory`, `recommended`, `optional`, or `mandatoryIf` — populated only under some condition. Unlike the other three values, `mandatoryIf` doesn't say what that condition actually is anywhere in the published data; this document records it, one attribute at a time, alongside the rationale.

Only tables with at least one genuine `mandatoryIf` attribute are listed. As of this writing (dictionary v3.0.1): `protocolSteps`, `protocolRelationships`, `sites`, `contacts`, `parts`, `qualityReports`, `samples`, `wideNames`. Two more tables surfaced `mandatoryIf` values during this walkthrough that turned out to be miscategorized, corrected in `ODM_parts.csv`/`ODM_parts_v3.0.1.csv`, and are no longer listed here: `measures.relDateStart`/`relDateEnd` (should be `recommended`, not `mandatoryIf` — see the `sites` section) and `wideNames.wideNameType` (should be plain `mandatory` — see the `wideNames` section).

## How to read an entry

- **ID**: stable identifier, `MANDIF.<table>.<n>`.
- **Attribute**: the `partID` (and its `label`) the condition applies to, within this specific table.
- **Condition**: the exact circumstance under which the attribute is required. Stated as precisely as the underlying logic allows — a reference to another column's value, another attribute's presence, a business rule, etc.
- **Rationale**: why the condition exists, if it's non-obvious.

---

## `protocolSteps`

Every row reports on exactly one of a `measure` or a `method` — never both, never neither. Which one is populated determines whether `unit`/`aggregation` apply at all, since a method (a categorical/boolean choice) has no unit or aggregation scale the way a measure does.

| ID | Attribute | Condition | Rationale |
|---|---|---|---|
| MANDIF.protocolSteps.01 | `measure` (Measure) | Mandatory when this row reports a measure — i.e. when `method` is blank. Mutually exclusive with `method`: exactly one of the two must be populated per row. | A protocol step is either a measurement step or a method step, never both. |
| MANDIF.protocolSteps.02 | `method` (Method) | Mandatory when this row reports a method — i.e. when `measure` is blank. Mutually exclusive with `measure`: exactly one of the two must be populated per row. | Same rule as `measure`, from the other side. |
| MANDIF.protocolSteps.03 | `unit` (Unit) | Mandatory when `measure` is populated (this row reports a measure); blank when `method` is populated. | Methods don't have units — a method is a categorical/boolean choice, not a quantity reported in some unit. |
| MANDIF.protocolSteps.04 | `aggregation` (Aggregation) | Mandatory when `measure` is populated (this row reports a measure); blank when `method` is populated. | Same reasoning as `unit` — aggregation scale is a measure-only concept. |

---

## `protocolRelationships`

Every row expresses `[subject] [relationshipID] [object]`. Each of the subject and object roles is filled by *either* a whole protocol *or* a specific step within one — independently of each other, with no constraint that both sides be the same kind (a protocol-to-step relationship is just as valid as protocol-to-protocol or step-to-step).

| ID | Attribute | Condition | Rationale |
|---|---|---|---|
| MANDIF.protocolRelationships.01 | `protocolIDSub` (Protocol ID subject) | Mandatory when the subject of this relationship is a whole protocol — i.e. when `stepIDSub` is blank. Mutually exclusive with `stepIDSub`: exactly one of the two must be populated per row. | The subject is either a protocol or a step, never both. |
| MANDIF.protocolRelationships.02 | `stepIDSub` (Step ID Subject) | Mandatory when the subject of this relationship is a specific step — i.e. when `protocolIDSub` is blank. Mutually exclusive with `protocolIDSub`. | Same rule as `protocolIDSub`, from the other side. |
| MANDIF.protocolRelationships.03 | `protocolIDObj` (Protocol ID object) | Mandatory when the object of this relationship is a whole protocol — i.e. when `stepIDObj` is blank. Mutually exclusive with `stepIDObj`: exactly one of the two must be populated per row. | The object is either a protocol or a step, never both. |
| MANDIF.protocolRelationships.04 | `stepIDObj` (Step ID Object) | Mandatory when the object of this relationship is a specific step — i.e. when `protocolIDObj` is blank. Mutually exclusive with `protocolIDObj`. | Same rule as `protocolIDObj`, from the other side. |

Every row therefore has exactly one populated subject field and exactly one populated object field, chosen independently — all four subject/object kind combinations (protocol↔protocol, protocol↔step, step↔protocol, step↔step) are valid.

---

## `sites`

`geoLat`, `geoLong`, and `geoEPSG` form a single coupled group, not three independent conditions: reporting geospatial coordinates for a site only makes sense as a complete package — a coordinate pair without its reference system is ambiguous, and an EPSG code without actual coordinates is meaningless.

| ID | Attribute | Condition | Rationale |
|---|---|---|---|
| MANDIF.sites.01 | `geoLat` (Latitude) | Mandatory if latitude/longitude data is available for this site AND a `geoEPSG` value is being reported. | Coordinates without a stated reference system are ambiguous. |
| MANDIF.sites.02 | `geoLong` (Longitude) | Same condition as `geoLat` — the two are always reported together. | Same rationale as `geoLat`. |
| MANDIF.sites.03 | `geoEPSG` (European Petroleum Survey Group Coordinates) | Mandatory if coordinates (`geoLat`/`geoLong`) are available AND being reported. | The EPSG code is meaningless without actual coordinates to interpret against it. |

(Note: `measures.relDateStart`/`relDateEnd` were found during this walkthrough to be miscategorized as `mandatoryIf` — corrected to `recommended` in `ODM_parts.csv`/`ODM_parts_v3.0.1.csv`, so `measures` is no longer in scope for this document.)

---

## `contacts`

| ID | Attribute | Condition | Rationale |
|---|---|---|---|
| MANDIF.contacts.01 | `organizationID` (Organization ID) | Mandatory when the contact is affiliated with an organization, rather than an independent/individual contact. | A contact who isn't tied to any organization has no `organizationID` to report. |

---

## `parts`

`parts` is the dictionary describing its own structural columns — `<table>Required` here means "required when defining a *new part row*," not a row in some other table.

| ID | Attribute | Condition | Rationale |
|---|---|---|---|
| MANDIF.parts.01 | `fKAliasID` (Foreign Key Alias ID) | Mandatory when the new part's column is a foreign key under a different name than the table/column it actually references (e.g. `sampleIDObj` → `sampleID`). | Without it, nothing records what a renamed FK column actually points at. |
| MANDIF.parts.02 | `unitSet` (Unit set) | Mandatory when the part is a `measurements`/`units`-type row (or otherwise participates in the unit-classification system). | Ties directly to the sentinel convention already documented in `DICTIONARY_VALIDATION.md` (XC.01) — every classification column gets a real value or its sentinel, never left blank. |
| MANDIF.parts.03 | `minValue` (Minimum value part support) | Mandatory when the part's `dataType` is numeric (`integer`/`float`) and a real, meaningful range exists (i.e. not deferred via `seeUnitVal` — see DT.03). | — |
| MANDIF.parts.04 | `maxValue` (Maximum value part support) | Same condition as `minValue`. | — |
| MANDIF.parts.05 | `minLength` (Minimum length) | Mandatory when the part's `dataType` is a string-length-bound type (`varchar`/`categorical`) — see DT.04. | — |
| MANDIF.parts.06 | `maxLength` (Maximum length) | Same condition as `minLength`. | — |
| MANDIF.parts.07 | `latExp` (LaTeX expression) | Mandatory for every active `units`-type part. **Confirmed empirically (2026-09)**: 151/153 active `units` rows have it populated; the only 2 exceptions are `hUn`/`naUnit`, the same placeholder/support rows already excepted from `DICTIONARY_VALIDATION.md`'s PT.UNI.02 — neither is a real physical unit, so no LaTeX symbol applies. | Every genuine unit needs a symbol to render (e.g. `$\%$`, `$ml$`) — only the two non-unit placeholder rows are exempt. |

---

## `qualityReports`

Every row documents the quality of exactly one of: a single measure, a whole measure set, or a sample — a mutually exclusive trio, not independent conditions.

| ID | Attribute | Condition | Rationale |
|---|---|---|---|
| MANDIF.qualityReports.01 | `measureRepID` (Measure Report ID) | Mandatory when this row reports quality for a single measure — i.e. when both `measureSetRepID` and `sampleID` are blank. Mutually exclusive with the other two: exactly one of the three must be populated per row. | A quality report is scoped to exactly one of a measure, a measure set, or a sample. |
| MANDIF.qualityReports.02 | `measureSetRepID` (Measure set report set ID) | Mandatory when this row reports quality for a whole measure set — i.e. when both `measureRepID` and `sampleID` are blank. Mutually exclusive with the other two. | Same rule as `measureRepID`, from a different member of the trio. |
| MANDIF.qualityReports.03 | `sampleID` (Sample ID) | Mandatory when this row reports quality for a sample — i.e. when both `measureRepID` and `measureSetRepID` are blank. Mutually exclusive with the other two. | Same rule as `measureRepID`/`measureSetRepID`, from the third member of the trio. |

---

## `samples`

Two independent conditions live in this table: a date/time reporting fallback, and a composite-sampling duration.

| ID | Attribute | Condition | Rationale |
|---|---|---|---|
| MANDIF.samples.01 | `collDate` (Collection Date, time not included) | Mandatory when the exact collection time isn't known and this sample is using the `collDate` + `collAppxT` fallback instead of a precise `collDT` timestamp. Paired with `collAppxT`: the two are reported together as an alternative to `collDT`, never alongside it. | `collDT` (mandatory) is the normal combined date-time field; this pair exists specifically for when a precise time isn't available. |
| MANDIF.samples.02 | `collAppxT` (Collection Approximate Time Period) | Mandatory when the exact collection time is unknown — reported alongside `collDate` instead of a precise `collDT`. | Same fallback pairing as `collDate`, from the other side. |
| MANDIF.samples.03 | `collPer` (Collection period) | Mandatory when `collType` is one of the composite/time-integrated collection types (e.g. `comp`, `autoComp`, `manComp`, `timePr`, `flowPr`, `volPr`, `areaPr`, `autoSeq` — members of `collectSet`) rather than a discrete point-in-time collection like `grb` (Grab sample). | Only a sample collected continuously or repeatedly over a span of time has a meaningful "period" (e.g. "24 hours") to report — a grab sample doesn't. |

---

## `wideNames`

Each `wideNames` row documents one wide-format column name, built from a formula that depends on its `wideNameType` (`attributes`, `measurements`, `methods`, or `exceptions` for combined/custom names — see [PHES-ODM-Doc's wide-names guide](https://docs.phes-odm.org/wide-names.html) for the formulas themselves). Every `*Name`/`*Input` pair is mandatory exactly when that component is part of the current row's formula — otherwise it's not applicable, not merely optional.

**Note**: `wideNameType` itself was found during this walkthrough to be miscategorized as `mandatoryIf` — it's populated on 100% of active rows with no real condition, so it's been corrected to plain `mandatory` in `ODM_parts.csv`/`ODM_parts_v3.0.1.csv`.

**Data-quality note**: verifying the "populated exactly when part of the formula" claim against live data at first appeared to contradict it — every `*Input` column looked populated on nearly every row, regardless of `wideNameType`. This turned out to be a spreadsheet-formula artifact from the original authoring workbook: cells not part of a given row's formula held the literal string `"0"` (not a valid partID shape) rather than being left blank. Confirmed and cleaned (2026-09): 738 `"0"` cells across `dictionary-tables/ODM_wideNames.csv`/`ODM_wideNames_v3.0.1.csv`, replaced with blank. After cleaning, the "populated iff part of the formula" condition holds cleanly.

| ID | Attribute | Condition | Rationale |
|---|---|---|---|
| MANDIF.wideNames.01 | `wideMeasure` | Mandatory when `wideNameType=measurements`. | Holds the fully-assembled wide-name for a measurement-value column; only meaningful for that type. |
| MANDIF.wideNames.02 | `wideProtocol` | Mandatory when `wideNameType=methods`. | Same mechanism as `wideMeasure`, for a protocol-step/method column. |
| MANDIF.wideNames.03 | `wideAttribute` | Mandatory when `wideNameType=attributes`. | Same mechanism, for an attribute column. |
| MANDIF.wideNames.04 | `reportTableName`/`reportTableInput` | Mandatory when `wideNameType=attributes` (the long-format table the attribute lives in) or `wideNameType=methods` (always `ps`, the `protocolSteps` table). Not part of the `measurements` formula, though occasionally present anyway as harmless redundant context (confirmed: 2 `measurements` rows — actually one wideName documented twice, once per originating template — carry the trivially-true `mr` measures-table shorthand). | The report table only needs stating when the formula doesn't already imply it via `compartment`/`specimen`/etc. |
| MANDIF.wideNames.05 | `partTypeName`/`partTypeInput` | Mandatory when `wideNameType=methods` (always `met`). Not part of the `attributes` or plain `measurements` formulas, though a measurement sourced from a protocol step (rather than the plain `measures` table) also needs it (`mes`) — confirmed in the live data as a rare sub-case, not the norm for `measurements`-type rows. | Distinguishes a measure-based from a method-based protocol step in the wide-name string. |
| MANDIF.wideNames.06 | `compartmentName`/`compartmentInput` | Mandatory when `wideNameType=measurements`. | Part of the measurement formula (`compartment_specimen_fraction_measure_unit_aggregation_index_attribute`). |
| MANDIF.wideNames.07 | `specimenName`/`specimenInput` | Mandatory when `wideNameType=measurements`. | Same formula as `compartmentInput`. |
| MANDIF.wideNames.08 | `fractionName`/`fractionInput` | Mandatory when `wideNameType=measurements`. May legitimately be the `NA` sentinel partID (not blank) when the fraction concept genuinely doesn't apply to that specific measure — that's real content, not the `"0"` artifact. | Same formula; fraction not applying to every measure is expected, not a gap. |
| MANDIF.wideNames.09 | `measureName`/`measureInput` | Mandatory when `wideNameType=measurements`. | Same formula. |
| MANDIF.wideNames.10 | `methodName`/`methodInput` | Mandatory when `wideNameType=methods`. | The method being reported by this protocol-step column. |
| MANDIF.wideNames.11 | `unitName`/`unitInput` | Mandatory when `wideNameType=measurements`. | Same formula as `compartmentInput`. |
| MANDIF.wideNames.12 | `aggregationName`/`aggregationInput` | Mandatory when `wideNameType=measurements`. | Same formula. |
| MANDIF.wideNames.13 | `attributeName`/`attributeInput` | Mandatory for `wideNameType` ∈ {`attributes`, `measurements`, `methods`} — i.e. every standard type. Always blank/not-applicable only for `exceptions`. | The trailing `attribute` component (`value`/`purpose`/`qualityFlag`) closes every standard formula. |

`exceptions`-type rows (combined attributes, or combined measures/methods via the `_n_AND_.../_n_OR_...` naming scheme) don't use any of the above pairs the normal way — they follow their own formula, not captured by this column set.

**Not yet fully resolved**: a single live `methods`-type row (`ps_met_pcrmeth_value`) has real, non-`"0"` values in `compartmentInput`/`specimenInput` even though the method formula doesn't use them — extra context rather than a formula requirement, but with only one example of this type it's not yet clear whether that's a one-off or a documented convention worth its own rule. Revisit if/when more `methods`-type rows exist.

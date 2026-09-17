"""
Generates the full ODM working/template workbook from dictionary-tables/*.csv
(the source of truth), writing templates/ODM_templates_V<version>.xlsx --
<version> read from the CSVs' own "Version,X.Y.Z" stamp row, matching the
existing templates/ naming convention (e.g. ODM_templates_V3.0.0.xlsx).

Covers: parts, sets, wideNames, languages, translations, countries, zones
(verbatim data) + wideName-Dropdowns and wideNames' own dropdown/lookup/
wideName-builder formulas, plus all 19 general table-template sheets
(measures, samples, sites, protocolSteps, ...) with their header-row
formulas, Part-IDs mirror tables, and dropdown-column validation.

Uses xlsxwriter, not openpyxl, to WRITE the file. openpyxl can read an existing
Excel-authored dynamic-array formula (FILTER/SORTBY/TRANSPOSE) but cannot
reliably author a new one from scratch -- it writes a legacy "CSE" array
formula without the `xl/metadata.xml` XLDAPR block Excel needs to recognize a
genuine spilling dynamic array, so a fresh openpyxl-only file opens with those
formulas blank/unresolved. xlsxwriter's write_dynamic_array_formula() writes
that metadata correctly (verified: `<c cm="1">` + XLDAPR in xl/metadata.xml).

Two related formula-authoring gotchas (see CLAUDE.md for the full writeups):
- xlsxwriter treats XLOOKUP as a dynamic-array function unconditionally (checked
  its source: an unconfigurable regex in write_formula()/write_array_formula()),
  marking the cell with the same cm="1"/t="array" metadata as a real spill, which
  then makes Excel insert the "@" implicit-intersection operator into any OTHER
  formula referencing that cell. Fixed by using IFERROR(VLOOKUP(...),"") instead
  for every *Input lookup -- VLOOKUP isn't in that regex, so it writes as a
  completely plain formula. Every *Name/*Input pair is adjacent columns in
  wideName-Dropdowns by construction, which is what makes VLOOKUP viable here.
- CONCAT (a post-2007 function) needs an explicit `_xlfn.` prefix in the XML the
  same way XLOOKUP does, but xlsxwriter does NOT auto-add it the way it does for
  the dynamic-array function list -- write `_xlfn.CONCAT(...)` yourself. Writing
  plain `CONCAT(...)` is what caused Excel to silently insert "@" in front of
  wideMeasure/wideProtocol/wideAttribute (the only three formulas using CONCAT)
  even though the referenced cells themselves were completely clean.

Column positions are never hardcoded -- every formula resolves a column's
current letter from the live CSV header at generation time, so a future
dictionary-tables schema change (added/removed/reordered columns) doesn't
silently re-break a formula the way several of the original hand-built
workbook's fixed-letter references already have (see SKILL.md notes).
"""
import csv
import glob
import os
import shutil
import xlsxwriter
from xlsxwriter.utility import xl_col_to_name

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DICT_TABLES = os.path.join(REPO_ROOT, "dictionary-tables")
OUT_DIR = os.path.join(REPO_ROOT, "templates")

# Blank rows reserved below existing data, for future manual additions -- dropdown
# validation and XLOOKUP/builder formulas extend this far down, not just to the
# last real row.
EXTRA_ROWS = 500


def read_version(name="ODM_parts.csv"):
    """Reads the "Version,X.Y.Z,,,..." stamp row (row 1) of an unsuffixed
    dictionary-tables CSV -- the authoritative current release version, used to
    name the output file (ODM_templates_V<version>.xlsx), matching the existing
    convention already in templates/ (e.g. ODM_templates_V3.0.0.xlsx)."""
    path = os.path.join(DICT_TABLES, name)
    with open(path, newline="", encoding="utf-8") as f:
        r = csv.reader(f)
        version_row = next(r)
    return version_row[1]


def archive_superseded(glob_pattern, current_path):
    """Moves any existing file matching `glob_pattern` whose path isn't
    `current_path` into templates/archived templates/ -- keeps exactly one
    live copy per generated-file family (this workbook, the SQL seed files)
    in templates/, with every version the dictionary has ever stamped
    preserved for reference in one place rather than left to accumulate
    alongside the current one."""
    archive_dir = os.path.join(REPO_ROOT, "templates", "archived templates")
    for old_path in glob.glob(glob_pattern):
        if os.path.abspath(old_path) == os.path.abspath(current_path):
            continue
        os.makedirs(archive_dir, exist_ok=True)
        dest = os.path.join(archive_dir, os.path.basename(old_path))
        shutil.move(old_path, dest)
        print(f"archived superseded {old_path} -> {dest}")


def load_csv(name):
    path = os.path.join(DICT_TABLES, name)
    with open(path, newline="", encoding="utf-8") as f:
        r = csv.reader(f)
        next(r)  # Version stamp row
        header = next(r)
        rows = [row for row in r]
    return header, rows


def col_letter(header, name):
    return xl_col_to_name(header.index(name))


def warn_stale_wideNames_labels(parts_header, parts_rows, sets_header, sets_rows,
                                 wideNames_header, wideNames_rows):
    # wideNames.csv's *Name columns are a cached display label for the *Input partID
    # next to them -- *Input is the only real reference; *Name has no independent
    # authority and nothing re-syncs it when the referenced part's label changes
    # later (see CLAUDE.md, "wideNames.csv's *Name columns are cached labels" --
    # found 80/110 rows stale in practice after a uniform shortName-label rename was
    # never back-filled here). Warn loudly rather than silently generating a workbook
    # whose dropdown-driven Input lookups won't resolve for those rows.
    p_idx = {h: i for i, h in enumerate(parts_header)}
    s_idx = {h: i for i, h in enumerate(sets_header)}
    label_by_partid = {r[p_idx["partID"]]: r[p_idx["label"]] for r in parts_rows}
    label_by_setpartid = {r[s_idx["partID"]]: r[s_idx["label"]] for r in sets_rows}
    w_idx = {h: i for i, h in enumerate(wideNames_header)}
    pairs = ["reportTable", "partType", "compartment", "specimen", "fraction",
             "measure", "method", "unit", "aggregation", "attribute"]
    stale = []
    orphaned_name = []
    for r in wideNames_rows:
        for base in pairs:
            input_val = r[w_idx[f"{base}Input"]]
            name_val = r[w_idx[f"{base}Name"]]
            if not input_val or input_val.strip() in ("", "0"):
                # Complementary case to the one below: a *Name was recorded but never
                # resolved to a partID at all (found in practice -- September 2026 --
                # hum_sit_NA_popServ_peeps_total_NA_value had partTypeName="Measures"
                # with partTypeInput blank; the earlier one-off fix pass that resynced
                # *Name-to-*Input's-label only handled rows that already HAD an Input
                # value, so this shape slipped through). Not the same bug as stale
                # label text, but the same underlying risk -- a *Name that doesn't
                # actually resolve to anything.
                if name_val and name_val.strip() not in ("", "0"):
                    orphaned_name.append((r[w_idx["wideName"]], base, name_val))
                continue
            real_label = (label_by_setpartid if base == "fraction" else label_by_partid).get(input_val)
            if real_label is not None and real_label != name_val:
                stale.append((r[w_idx["wideName"]], base, name_val, real_label))
    if stale:
        print(f"WARNING: {len(stale)} wideNames *Name cell(s) don't match their *Input partID's current label")
        print("         (dropdown-driven Input lookups for these rows won't resolve in Excel)")
        for s in stale[:10]:
            print("        ", s)
        if len(stale) > 10:
            print(f"         ... and {len(stale) - 10} more")
    if orphaned_name:
        print(f"WARNING: {len(orphaned_name)} wideNames *Name cell(s) have text but no resolved *Input partID")
        print("         (the Name was recorded but never matched to a real partID -- check by hand)")
        for s in orphaned_name[:10]:
            print("        ", s)
        if len(orphaned_name) > 10:
            print(f"         ... and {len(orphaned_name) - 10} more")


def write_data_sheet(wb, sheet_name, header, rows):
    ws = wb.add_worksheet(sheet_name)
    for col, h in enumerate(header):
        ws.write_string(0, col, h)
    for row_idx, row in enumerate(rows, start=1):
        for col, val in enumerate(row):
            if val != "":
                ws.write_string(row_idx, col, val)
    return ws


TABLE_ROLES = {"header", "fK", "pK"}  # confirmed identical vocabulary across every
# general table-template's triplet-role column (measures and all 18 remaining
# tables checked directly against current parts.csv) -- lowercase K, not the
# original workbook's own stale cached casing ("cK"/"PK"/"FK").


def build_header_formulas(ws, table_name, parts_header, parts_rows, p_label, p_partID):
    """Writes the live TRANSPOSE(SORTBY(FILTER(...))) header-row formulas (label
    side + a mirrored partID side after a gap and 'Part IDs ->' label) for one
    general table-template sheet. Generic across every table -- the triplet-role
    column is always named exactly <table_name>/<table_name>Order, confirmed
    directly against parts.csv for all 19 general templates, not assumed.
    Returns (header_partids, n_header_cols, partid_label_col) for building the
    mirror table and, later, wiring up dropdown validations.
    """
    role_idx = parts_header.index(table_name)
    order_idx = parts_header.index(f"{table_name}Order")
    partID_idx = parts_header.index("partID")
    label_idx = parts_header.index("label")
    status_idx = parts_header.index("status")

    header_cols = [
        (r[partID_idx], float(r[order_idx]))
        for r in parts_rows
        if r[role_idx] in TABLE_ROLES and r[status_idx] == "active"
    ]
    header_cols.sort(key=lambda x: x[1])  # stable -- ties keep CSV row order, matching FILTER+SORTBY
    header_partids = [c[0] for c in header_cols]
    n_header_cols = len(header_partids)

    p_role = col_letter(parts_header, table_name)
    p_order = col_letter(parts_header, f"{table_name}Order")
    role_condition = "+".join(f'(parts!${p_role}:${p_role}="{role}")' for role in TABLE_ROLES)
    # VALUE(...) matters: every parts.csv cell is written as text, so the *Order
    # column arrives at SORTBY as text too and sorts lexicographically ("1","10",
    # "11",...,"19","2",...) instead of numerically -- exactly what put measures'
    # header columns out of order originally.
    order_formula = f'_xlfn._xlws.FILTER(parts!${p_order}:${p_order},{role_condition})'

    label_formula = (
        f'=TRANSPOSE(_xlfn.SORTBY(_xlfn._xlws.FILTER(parts!${p_label}:${p_label},{role_condition}),'
        f'VALUE({order_formula}),1))'
    )
    ws.write_dynamic_array_formula(0, 0, 0, n_header_cols - 1, label_formula)

    partid_label_col = n_header_cols + 2
    ws.write_string(0, partid_label_col, "Part IDs ->")
    partid_formula = (
        f'=TRANSPOSE(_xlfn.SORTBY(_xlfn._xlws.FILTER(parts!${p_partID}:${p_partID},{role_condition}),'
        f'VALUE({order_formula}),1))'
    )
    ws.write_dynamic_array_formula(0, partid_label_col + 1, 0, partid_label_col + n_header_cols, partid_formula)

    return header_partids, n_header_cols, partid_label_col


def main():
    parts_header, parts_rows = load_csv("ODM_parts.csv")
    sets_header, sets_rows = load_csv("ODM_sets.csv")
    wideNames_header, wideNames_rows = load_csv("ODM_wideNames.csv")
    languages_header, languages_rows = load_csv("ODM_languages.csv")
    translations_header, translations_rows = load_csv("ODM_translations.csv")
    countries_header, countries_rows = load_csv("ODM_countries.csv")
    zones_header, zones_rows = load_csv("ODM_zones.csv")

    warn_stale_wideNames_labels(parts_header, parts_rows, sets_header, sets_rows,
                                 wideNames_header, wideNames_rows)

    version = read_version()
    out_path = os.path.join(OUT_DIR, f"ODM_templates_V{version}.xlsx")
    archive_superseded(os.path.join(OUT_DIR, "ODM_templates_V*.xlsx"), out_path)
    wb = xlsxwriter.Workbook(out_path)

    write_data_sheet(wb, "parts", parts_header, parts_rows)
    write_data_sheet(wb, "sets", sets_header, sets_rows)
    ws_wn = write_data_sheet(wb, "wideNames", wideNames_header, wideNames_rows)
    write_data_sheet(wb, "languages", languages_header, languages_rows)
    write_data_sheet(wb, "translations", translations_header, translations_rows)
    write_data_sheet(wb, "countries", countries_header, countries_rows)
    write_data_sheet(wb, "zones", zones_header, zones_rows)

    # --- resolved column letters (parts/sets), computed fresh from the live headers ---
    p_partID = col_letter(parts_header, "partID")
    p_label = col_letter(parts_header, "label")
    p_partType = col_letter(parts_header, "partType")
    p_status = col_letter(parts_header, "status")
    s_setID = col_letter(sets_header, "setID")
    s_partID = col_letter(sets_header, "partID")
    s_label = col_letter(sets_header, "label")
    s_status = col_letter(sets_header, "status")

    # --- wideName-Dropdowns sheet ---
    # Each Name/Input pair pulls live off `parts` (or `sets`, for fractionName) via a
    # dynamic-array FILTER() anchored in row 2, spilling down -- matches the original
    # workbook's own convention (one formula per column, not per row). Note: an
    # xlsxwriter-authored version of this (with the correct XLDAPR dynamic-array
    # metadata, verified byte-for-byte against a genuinely Excel-authored spill) was
    # tried first and did not resolve when opened -- if FILTER doesn't populate here
    # either, that points to a dynamic-array support gap in the Excel build being used
    # to open this file, not a formula-authoring problem; test with a hand-typed
    # =FILTER(A1:A5,TRUE) in a blank cell of the same workbook to confirm.
    #
    # reportTableName/partTypeName: `partInstr` (column E in the original) is a real,
    # populated classifier for every `shortName` row -- literally "table"/"part type"/
    # "sheet support" -- confirmed directly against both the source xlsx and the
    # current parts.csv. An earlier attempt special-cased the two known partType-
    # shorthand rows (`mes`/`met`) by partID instead, on the mistaken belief this
    # column didn't carry the distinction in the current schema; it does, so this
    # matches the original formula exactly.
    p_partType_idx = parts_header.index("partType")
    p_status_idx = parts_header.index("status")
    p_partInstr_idx = parts_header.index("partInstr")
    p_partInstr = col_letter(parts_header, "partInstr")

    def count_matching(predicate):
        return sum(1 for r in parts_rows if predicate(r))

    def is_active(r, part_type):
        return r[p_partType_idx] == part_type and r[p_status_idx] == "active"

    pairs = [
        ("reportTable",
         f'(parts!${p_partType}:${p_partType}="shortName")*(parts!${p_status}:${p_status}="active")*(parts!${p_partInstr}:${p_partInstr}="table")',
         count_matching(lambda r: is_active(r, "shortName") and r[p_partInstr_idx] == "table")),
        ("partType",
         f'(parts!${p_partType}:${p_partType}="shortName")*(parts!${p_status}:${p_status}="active")*(parts!${p_partInstr}:${p_partInstr}="part type")',
         count_matching(lambda r: is_active(r, "shortName") and r[p_partInstr_idx] == "part type")),
        ("compartment", f'(parts!${p_partType}:${p_partType}="compartments")*(parts!${p_status}:${p_status}="active")',
         count_matching(lambda r: is_active(r, "compartments"))),
        ("specimen", f'(parts!${p_partType}:${p_partType}="specimens")*(parts!${p_status}:${p_status}="active")',
         count_matching(lambda r: is_active(r, "specimens"))),
        ("fraction", None, None),  # sourced from sets, not parts -- filled in separately below
        ("measure", f'(parts!${p_partType}:${p_partType}="measurements")*(parts!${p_status}:${p_status}="active")',
         count_matching(lambda r: is_active(r, "measurements"))),
        ("method", f'(parts!${p_partType}:${p_partType}="methods")*(parts!${p_status}:${p_status}="active")',
         count_matching(lambda r: is_active(r, "methods"))),
        ("unit", f'(parts!${p_partType}:${p_partType}="units")*(parts!${p_status}:${p_status}="active")',
         count_matching(lambda r: is_active(r, "units"))),
        ("aggregation", f'(parts!${p_partType}:${p_partType}="aggregations")*(parts!${p_status}:${p_status}="active")',
         count_matching(lambda r: is_active(r, "aggregations"))),
        ("attribute", f'(parts!${p_partType}:${p_partType}="attributes")*(parts!${p_status}:${p_status}="active")',
         count_matching(lambda r: is_active(r, "attributes"))),
    ]

    dropdown_header = []
    for base, _, _ in pairs:
        dropdown_header += [f"{base}Name", f"{base}Input"]
    dropdown_header.append("wideNameType")

    ws_dd = wb.add_worksheet("wideName-Dropdowns")
    for col, h in enumerate(dropdown_header):
        ws_dd.write_string(0, col, h)

    name_source_col = {}   # base -> column letter of its Name-list in wideName-Dropdowns
    input_source_col = {}  # base -> column letter of its Input-list in wideName-Dropdowns

    fs_setID_idx = sets_header.index("setID")
    fs_status_idx = sets_header.index("status")
    fraction_n = sum(1 for r in sets_rows if r[fs_setID_idx] == "wideFractionSet" and r[fs_status_idx] == "active")

    col_idx = 0
    for base, cond, n in pairs:
        name_col = xl_col_to_name(col_idx)
        input_col = xl_col_to_name(col_idx + 1)
        name_source_col[base] = name_col
        input_source_col[base] = input_col
        name_col_idx = col_idx
        input_col_idx = col_idx + 1

        if base == "fraction":
            n = fraction_n
            name_formula = f'=FILTER(sets!${s_label}:${s_label},(sets!${s_setID}:${s_setID}="wideFractionSet")*(sets!${s_status}:${s_status}="active"))'
            input_formula = f'=FILTER(sets!${s_partID}:${s_partID},(sets!${s_setID}:${s_setID}="wideFractionSet")*(sets!${s_status}:${s_status}="active"))'
        else:
            name_formula = f'=FILTER(parts!${p_label}:${p_label},{cond})'
            input_formula = f'=FILTER(parts!${p_partID}:${p_partID},{cond})'

        if n > 0:
            ws_dd.write_dynamic_array_formula(1, name_col_idx, n, name_col_idx, name_formula)
            ws_dd.write_dynamic_array_formula(1, input_col_idx, n, input_col_idx, input_formula)
        col_idx += 2

    # wideNameType: static list -- no structural column marks "the 4 partTypes valid
    # here" (empirically observed subset, not formally enumerated); same as the
    # original workbook's own static-range approach for this one column.
    wnt_col_idx = len(dropdown_header) - 1
    wnt_col = xl_col_to_name(wnt_col_idx)
    for i, v in enumerate(["measurements", "attributes", "methods", "exceptions"]):
        ws_dd.write_string(1 + i, wnt_col_idx, v)

    # --- wideNames: dropdown validation on *Name columns, XLOOKUP formula on *Input ---
    wn_data_rows = len(wideNames_rows)
    wn_last_row = wn_data_rows + EXTRA_ROWS  # 0-indexed last data row (row 1 = first data row)

    for base in ["reportTable", "partType", "compartment", "specimen", "fraction",
                 "measure", "method", "unit", "aggregation", "attribute"]:
        wn_name_col = wideNames_header.index(f"{base}Name")
        wn_input_col = wideNames_header.index(f"{base}Input")
        dd_name_col = name_source_col[base]
        dd_input_col = input_source_col[base]
        wn_name_letter = xl_col_to_name(wn_name_col)

        ws_wn.data_validation(
            1, wn_name_col, wn_last_row, wn_name_col,
            {"validate": "list", "source": f"='wideName-Dropdowns'!${dd_name_col}$2:${dd_name_col}$1048576"},
        )

        for row_idx in range(1, wn_last_row + 1):
            excel_row = row_idx + 1  # 1-indexed Excel row number for formula text
            # VLOOKUP, not XLOOKUP: xlsxwriter unconditionally treats XLOOKUP as a
            # "future function" needing dynamic-array cell metadata (cm="1"/t="array"),
            # with no way to opt out via the public API (checked its source directly).
            # Excel then auto-inserts the "@" implicit-intersection operator into any
            # OTHER formula referencing that cell (wideMeasure/wideProtocol/
            # wideAttribute all reference these *Input cells), which broke resolution
            # for columns F/G/H. VLOOKUP does the identical lookup here -- every
            # *Name/*Input pair sits in adjacent columns in wideName-Dropdowns by
            # construction -- and isn't treated specially at all, so it writes as a
            # completely plain formula with no metadata. IFERROR(...,"") replaces
            # XLOOKUP's 4th if_not_found arg for the same reason as before: most rows
            # leave most *Name columns blank, and an unhandled lookup failure would
            # cascade #N/A through every CONCAT/IF downstream.
            ws_wn.write_formula(
                row_idx, wn_input_col,
                f"=IFERROR(VLOOKUP({wn_name_letter}{excel_row},"
                f"'wideName-Dropdowns'!${dd_name_col}:${dd_input_col},2,FALSE),\"\")",
            )

    wnt_wn_col = wideNames_header.index("wideNameType")
    ws_wn.data_validation(
        1, wnt_wn_col, wn_last_row, wnt_wn_col,
        {"validate": "list", "source": f"='wideName-Dropdowns'!${wnt_col}$2:${wnt_col}$5"},
    )

    # --- wideNames: wideName/charLength/wideMeasure/wideProtocol/wideAttribute are
    # live formulas, not static text -- this sheet is the interactive wideName builder,
    # not a flat copy of the published CSV. A user picks *Name dropdowns; everything
    # else (the *Input lookups above, and the composed wideName below) recomputes.
    c = {name: col_letter(wideNames_header, name) for name in [
        "wideName", "charLength", "wideMeasure", "wideProtocol", "wideAttribute",
        "wideNameType", "reportTableInput", "partTypeName", "partTypeInput",
        "compartmentInput", "specimenInput", "fractionInput", "measureInput",
        "methodInput", "unitInput", "aggregationInput", "index", "attributeInput", "tag",
    ]}
    c_idx = {name: wideNames_header.index(name) for name in c}

    def concat_args(field_names, row):
        # e.g. ["compartmentInput","specimenInput"] -> 'O2,"_",Q2' -- the exact
        # comma-quoted-underscore-comma join _xlfn.CONCAT(...) needs between cell refs.
        return ',"_",'.join(f"{c[name]}{row}" for name in field_names)

    for row_idx in range(1, wn_last_row + 1):
        r = row_idx + 1  # 1-indexed Excel row number for formula text
        tag_ref = f"{c['tag']}{r}"

        measure_segs = concat_args(
            ["compartmentInput", "specimenInput", "fractionInput", "measureInput",
             "unitInput", "aggregationInput", "index", "attributeInput"], r)
        wide_measure = (
            f'=IF({c["wideNameType"]}{r}="measurements",'
            f'IF({tag_ref}="",_xlfn.CONCAT({measure_segs}),'
            f'_xlfn.CONCAT({measure_segs},".odm",{tag_ref})),"NA")'
        )

        # Matches the original exactly: IF(partTypeName="measurement", ...). A real
        # example (ps_met_pcrmeth_value, restored to wideNames.csv from the source
        # xlsx's own cached value) has partTypeName="Methods part-type Shorthand", so
        # this condition is FALSE there too and it correctly falls to the "other"
        # branch -- the same outcome an earlier attempt got by comparing
        # partTypeInput="mes" instead, which was changed under the mistaken belief
        # this branch was untested dead code. Left as the original's literal
        # "measurement" comparison since there's no real example exercising the TRUE
        # branch either way, and no reason left to diverge from the original text.
        protocol_meas_segs = concat_args(
            ["reportTableInput", "partTypeInput", "compartmentInput", "specimenInput",
             "fractionInput", "measureInput", "unitInput", "aggregationInput", "index",
             "attributeInput"], r)
        protocol_other_segs = concat_args(
            ["reportTableInput", "partTypeInput", "methodInput", "attributeInput"], r)
        wide_protocol = (
            f'=IF({c["wideNameType"]}{r}="methods",'
            f'IF({c["partTypeName"]}{r}="measurement",'
            f'IF({tag_ref}="",_xlfn.CONCAT({protocol_meas_segs}),_xlfn.CONCAT({protocol_meas_segs},".odm",{tag_ref})),'
            f'IF({tag_ref}="",_xlfn.CONCAT({protocol_other_segs}),_xlfn.CONCAT({protocol_other_segs},".odm",{tag_ref}))'
            f'),"NA")'
        )

        attr_segs = concat_args(["reportTableInput", "attributeInput"], r)
        wide_attribute = (
            f'=IF({c["wideNameType"]}{r}="attributes",'
            f'IF({tag_ref}="",_xlfn.CONCAT({attr_segs}),'
            f'_xlfn.CONCAT({attr_segs},".odm",{tag_ref})),"NA")'
        )

        char_length = f'=LEN({c["wideName"]}{r})'

        ws_wn.write_formula(row_idx, c_idx["wideMeasure"], wide_measure)
        ws_wn.write_formula(row_idx, c_idx["wideProtocol"], wide_protocol)
        ws_wn.write_formula(row_idx, c_idx["wideAttribute"], wide_attribute)

        # wideNameType="exceptions" doesn't fit the attributes/measurements/methods
        # composition pattern at all -- none of wideAttribute/wideMeasure/wideProtocol
        # apply, so the IF-chain formula would just fall through to "NA". These 9 rows
        # (as of the current data) are genuinely one-off, hand-authored wideName
        # strings (e.g. wat_sa_hFr_OR_3_otherM_otherA_otherV_hUn_hAg_value) with no
        # mechanical derivation -- write the literal value straight from the CSV
        # instead of a formula, matching the source data rather than overwriting it
        # with a computed "NA".
        is_exception_row = (
            row_idx - 1 < len(wideNames_rows)
            and wideNames_rows[row_idx - 1][c_idx["wideNameType"]] == "exceptions"
        )
        if is_exception_row:
            ws_wn.write_string(row_idx, c_idx["wideName"], wideNames_rows[row_idx - 1][c_idx["wideName"]])
        else:
            wide_name = (
                f'=IF({c["wideNameType"]}{r}="attributes",{c["wideAttribute"]}{r},'
                f'IF({c["wideNameType"]}{r}="measurements",{c["wideMeasure"]}{r},{c["wideProtocol"]}{r}))'
            )
            ws_wn.write_formula(row_idx, c_idx["wideName"], wide_name)
        ws_wn.write_formula(row_idx, c_idx["charLength"], char_length)

    # ================================================================
    # Stage 2/3: dropdown recipes, shared across every general table-template
    # sheet. Built once, here, rather than per-sheet -- many attributes are
    # reused verbatim across multiple tables (Purpose is the same purposeSet for
    # both measures and samples; Unit/Aggregation/Measure are shared by measures,
    # protocolSteps and phActions; Measure license is shared by measures,
    # polygons and datasets), so one shared `lists` sheet avoids building the
    # same FILTER twice under two different names.
    # ================================================================
    # Missingness always comes from `sets` (genMissingnessSet), never a direct
    # partType="missingness" filter over parts -- maintainer's correction:
    # genMissingnessSet's membership IS the canonical "all missingness parts" list
    # (confirmed: both give the same 8 active members today), but sourcing it from
    # the set is the actually-intended mechanism, matching how every other
    # enumerated value list here works (a named set, not a raw partType scan).
    #
    # Every dropdown's real source is its own attribute's `mmaSet` field in
    # parts.csv (e.g. purpose -> purposeSet, measureLic -> licSet) -- checked
    # directly for all ~35 dropdown columns across all 19 sheets before writing
    # any of this, not guessed from a partType. Two attributes (`method`,
    # `qualityFlag`) have `mmaSet` literally equal to a partType NAME rather than
    # a named set (the dictionary's "the whole category is the valid value set"
    # convention -- docs/dictionary-rules/parts-by-partType.md item 4) -- these
    # use the "parts_type" recipe kind instead of "set".
    #
    # One real trap found doing this: "Relationship between entities" is reused
    # by name across sampleRelationships/protocolRelationships/
    # polygonRelationships, and its shared attribute's own mmaSet (`relSet`) is a
    # red herring -- relSet is a 10-member superset that doesn't match any single
    # table's actual dropdown values. Each table has its OWN dedicated set
    # (sampleRelSet/protocolRelSet/polyRelSet) that isn't discoverable from the
    # attribute row at all, only by comparing the original workbook's cached list
    # values against every "*Rel*" setID directly.
    def active_partype_cond(pt):
        return f'(parts!${p_partType}:${p_partType}="{pt}")*(parts!${p_status}:${p_status}="active")'

    def active_set_cond(setid):
        return f'(sets!${s_setID}:${s_setID}="{setid}")*(sets!${s_status}:${s_status}="active")'

    def count_active_partype(pt):
        return count_matching(lambda r: is_active(r, pt))

    fs_setID_idx2 = sets_header.index("setID")
    fs_status_idx2 = sets_header.index("status")

    def count_set(setid):
        return sum(1 for r in sets_rows if r[fs_setID_idx2] == setid and r[fs_status_idx2] == "active")

    missingness_n = count_set("genMissingnessSet")

    # attribute partID -> ("parts_type"|"set", key, needs_missingness)
    recipes = {
        # measures
        "purpose": ("set", "purposeSet", True),
        "compartment": ("parts_type", "compartments", True),
        "specimen": ("parts_type", "specimens", True),
        "fraction": ("set", "fractionSet", True),
        "group": ("parts_type", "groups", False),
        "class": ("parts_type", "classes", False),
        "measure": ("parts_type", "measurements", True),
        "unit": ("parts_type", "units", False),
        "aggregation": ("parts_type", "aggregations", False),
        # Value Treatment: maintainer's call -- unlike the original workbook's own
        # (stale) list, this includes missingness too.
        "valTreat": ("set", "valTreatSet", True),
        "nomenclature": ("parts_type", "nomenclatures", True),
        "reportable": ("set", "booleanSet", False),
        "measureLic": ("set", "licSet", True),
        # samples
        "repType": ("set", "replicateSet", True),
        "origin": ("set", "originSet", True),
        "collType": ("set", "collectSet", True),
        "saMaterial": ("set", "sampleMatSet", True),
        # sites
        "siteType": ("set", "siteTypeSet", True),
        "sampleShed": ("set", "shedSet", True),
        "siteLevel": ("set", "siteLevelSet", False),
        # protocolSteps
        "method": ("parts_type", "methods", True),
        # polygons
        "geoType": ("set", "geoTypeSet", True),
        # organizations
        "orgType": ("set", "orgTypeSet", True),
        "orgLevel": ("set", "orgLevelSet", True),
        "orgSector": ("set", "orgSectorSet", True),
        # instruments
        "insType": ("set", "insTypeSet", True),
        # qualityReports
        "qualityFlag": ("parts_type", "qualityIndicators", True),
        "severity": ("set", "sevSet", True),
        # relationship tables -- three distinct dedicated sets, NOT the shared
        # relSet the common attribute's own mmaSet points to (see note above)
        "relationshipID__sampleRelationships": ("set", "sampleRelSet", False),
        "relationshipID__protocolRelationships": ("set", "protocolRelSet", False),
        "relationshipID__polygonRelationships": ("set", "polyRelSet", False),
        # phActions
        "actionType": ("set", "actionTypeSet", False),
        "action": ("set", "allActionsSet", False),
        # calculations
        "calcType": ("set", "calcTypeSet", False),
        "standard": ("set", "allStandardSet", False),
        # accessions
        "dataHost": ("set", "dataRepoSet", False),
        # datasets
        "originalFormat": ("set", "ogFormSet", False),
    }

    def render(recipe, out_col):
        kind, key, needs_missing = recipe
        if kind == "parts_type":
            base = f'_xlfn._xlws.FILTER(parts!${out_col}:${out_col},{active_partype_cond(key)})'
        else:
            base = f'_xlfn._xlws.FILTER(sets!${out_col}:${out_col},{active_set_cond(key)})'
        if needs_missing:
            missing = f'_xlfn._xlws.FILTER(sets!${out_col}:${out_col},{active_set_cond("genMissingnessSet")})'
            return f'_xlfn.VSTACK({base},{missing})'
        return base

    def count_recipe(recipe):
        kind, key, needs_missing = recipe
        n = count_active_partype(key) if kind == "parts_type" else count_set(key)
        return n + missingness_n if needs_missing else n

    ws_lists = wb.add_worksheet("lists")
    list_label_col = {}
    list_partid_col = {}
    col_idx = 0
    for attr_key, recipe in recipes.items():
        kind, _, _ = recipe
        out_col_for_label = p_label if kind == "parts_type" else s_label
        out_col_for_partid = p_partID if kind == "parts_type" else s_partID

        label_col = xl_col_to_name(col_idx)
        partid_col = xl_col_to_name(col_idx + 1)
        list_label_col[attr_key] = label_col
        list_partid_col[attr_key] = partid_col
        ws_lists.write_string(0, col_idx, f"{attr_key}Label")
        ws_lists.write_string(0, col_idx + 1, f"{attr_key}PartID")

        n = count_recipe(recipe)
        if n > 0:
            ws_lists.write_dynamic_array_formula(
                1, col_idx, n, col_idx, "=" + render(recipe, out_col_for_label))
            ws_lists.write_dynamic_array_formula(
                1, col_idx + 1, n, col_idx + 1, "=" + render(recipe, out_col_for_partid))
        col_idx += 2

    def wire_columns(ws, header_partids, n_header_cols, partid_label_col, extra_rows, column_recipe_keys):
        """Wires up one general table-template sheet's data columns: dropdown
        validation + VLOOKUP-resolved partID mirror for columns present in
        column_recipe_keys (attr_partid -> recipe key in `recipes`), plain
        same-row passthrough mirror for every other column. Generic across every
        sheet -- measures and all 18 remaining tables call this identically."""
        for attr_partid, recipe_key in column_recipe_keys.items():
            if attr_partid not in header_partids:
                continue
            data_col = header_partids.index(attr_partid)
            label_col = list_label_col[recipe_key]
            ws.data_validation(
                1, data_col, extra_rows, data_col,
                {"validate": "list", "source": f"='lists'!${label_col}$2:${label_col}$1048576"},
            )

        for j, attr_partid in enumerate(header_partids):
            label_side_col = xl_col_to_name(j)
            partid_side_col_idx = partid_label_col + 1 + j
            recipe_key = column_recipe_keys.get(attr_partid)
            for row_idx in range(1, extra_rows + 1):
                excel_row = row_idx + 1
                label_ref = f"{label_side_col}{excel_row}"
                if recipe_key is not None:
                    label_col = list_label_col[recipe_key]
                    partid_col = list_partid_col[recipe_key]
                    formula = f"=IFERROR(VLOOKUP({label_ref},'lists'!${label_col}:${partid_col},2,FALSE),\"\")"
                else:
                    formula = f"={label_ref}"
                ws.write_formula(row_idx, partid_side_col_idx, formula)

    # ================================================================
    # Stage 2: measures (representative general table-template sheet)
    # ================================================================
    ws_meas = wb.add_worksheet("measures")
    header_partids, n_header_cols, partid_label_col = build_header_formulas(
        ws_meas, "measures", parts_header, parts_rows, p_label, p_partID)
    MEAS_DATA_ROWS = EXTRA_ROWS
    measures_columns = {k: k for k in (
        "purpose", "compartment", "specimen", "fraction", "group", "class", "measure",
        "unit", "aggregation", "valTreat", "nomenclature", "reportable", "measureLic")}
    wire_columns(ws_meas, header_partids, n_header_cols, partid_label_col, MEAS_DATA_ROWS, measures_columns)

    # ================================================================
    # Stage 3, phase 2: remaining 18 general table-template sheets, dropdown
    # columns mapped and wired the same way as measures. Every mapping below
    # was verified against the original workbook's cached list values (item
    # counts checked against a live Python recount of each attribute's real
    # mmaSet/partType membership, not assumed from the label text) -- see the
    # `recipes` dict above for the specific set/partType each one resolves to
    # and why (especially the three relationship tables, which do NOT share the
    # `relationshipID` attribute's own nominal mmaSet).
    #
    # Not covered here: addresses' State/Country and datasets' Language ID --
    # these reference zones.csv/countries.csv/languages.csv directly rather
    # than a parts.csv/sets.csv-backed recipe, and need INDEX/MATCH rather than
    # VLOOKUP (the lookup column sits to the *right* of the return column in
    # both zones and countries), so they're wired separately, right after this
    # loop.
    TABLE_DROPDOWN_COLUMNS = {
        "measureSets": {},
        "samples": {
            "purpose": "purpose", "saMaterial": "saMaterial", "origin": "origin",
            "repType": "repType", "collType": "collType",
            "pooled": "reportable", "reportable": "reportable",
        },
        "sampleRelationships": {"relationshipID": "relationshipID__sampleRelationships"},
        "qualityReports": {"qualityFlag": "qualityFlag", "severity": "severity"},
        "phActions": {"actionType": "actionType", "action": "action", "threatTarget": "measure"},
        "protocols": {},
        "protocolRelationships": {"relationshipID": "relationshipID__protocolRelationships"},
        "protocolSteps": {"method": "method", "measure": "measure", "unit": "unit", "aggregation": "aggregation"},
        "contacts": {},
        "sites": {"siteType": "siteType", "sampleShed": "sampleShed", "siteLevel": "siteLevel"},
        "addresses": {},
        "polygons": {"geoType": "geoType", "poLic": "measureLic"},
        "polygonRelationships": {"relationshipID": "relationshipID__polygonRelationships"},
        "datasets": {"originalFormat": "originalFormat", "license": "measureLic"},
        "organizations": {"orgType": "orgType", "orgLevel": "orgLevel", "orgSector": "orgSector"},
        "instruments": {"insType": "insType"},
        "accessions": {"dataHost": "dataHost"},
        "calculations": {"calcType": "calcType", "standard": "standard"},
    }
    table_sheets = {}
    for table_name, column_map in TABLE_DROPDOWN_COLUMNS.items():
        ws_t = wb.add_worksheet(table_name)
        header_partids_t, n_cols_t, partid_label_col_t = build_header_formulas(
            ws_t, table_name, parts_header, parts_rows, p_label, p_partID)
        wire_columns(ws_t, header_partids_t, n_cols_t, partid_label_col_t, EXTRA_ROWS, column_map)
        table_sheets[table_name] = (ws_t, header_partids_t, partid_label_col_t)
        print(f"{table_name}: {n_cols_t} columns, {len(column_map)} dropdown(s)")

    # --- addresses' State/Country and datasets' Language ID: direct references
    # to zones.csv/countries.csv/languages.csv, not a parts.csv/sets.csv recipe.
    # INDEX/MATCH, not VLOOKUP: the lookup column (zoneName/nameEngl/langName)
    # sits to the RIGHT of the return key (isoCode/isoCode/lang) in all three
    # source sheets, and VLOOKUP can only look up-and-return moving rightward.
    zones_zoneName = col_letter(zones_header, "zoneName")
    # isoZone (e.g. "CA-SK"), not isoCode (e.g. "CA") -- isoCode is only the
    # country prefix and repeats across every zone within that country, so it
    # can't uniquely resolve which province/region was picked. Caught by
    # maintainer review: "saskatchewan" was mirroring to "CA", not "CA-SK".
    #
    # Known, accepted limitation: the State/Province dropdown isn't scoped by
    # whichever Country was picked in the same row, and 109 zoneName values
    # collide across different countries (e.g. "Saint George" x5 -- common
    # parish/district names repeat across Caribbean nations) -- an ambiguous
    # name silently resolves to zones.csv's first matching row, which may be
    # the wrong country. Maintainer's call: leave as-is; a submitter who hits
    # this can look up the correct isoZone code directly in the zones sheet
    # and type it in rather than using the dropdown. Not worth the added
    # complexity of a Country-dependent cascading dropdown for this.
    zones_isoZone = col_letter(zones_header, "isoZone")
    countries_nameEngl = col_letter(countries_header, "nameEngl")
    countries_isoCode = col_letter(countries_header, "isoCode")
    languages_langName = col_letter(languages_header, "langName")
    languages_lang = col_letter(languages_header, "lang")

    def wire_direct_reference(ws, header_partids, partid_label_col, extra_rows,
                               attr_partid, sheet_name, label_col, key_col):
        if attr_partid not in header_partids:
            return
        data_col = header_partids.index(attr_partid)
        n_rows = {"zones": len(zones_rows), "countries": len(countries_rows), "languages": len(languages_rows)}[sheet_name]
        ws.data_validation(
            1, data_col, extra_rows, data_col,
            {"validate": "list", "source": f"='{sheet_name}'!${label_col}$2:${label_col}${n_rows + 1}"},
        )
        label_side_col = xl_col_to_name(data_col)
        partid_side_col_idx = partid_label_col + 1 + data_col
        for row_idx in range(1, extra_rows + 1):
            excel_row = row_idx + 1
            formula = (
                f"=IFERROR(INDEX('{sheet_name}'!${key_col}:${key_col},"
                f"MATCH({label_side_col}{excel_row},'{sheet_name}'!${label_col}:${label_col},0)),\"\")"
            )
            ws.write_formula(row_idx, partid_side_col_idx, formula)

    addr_ws, addr_partids, addr_partid_col = table_sheets["addresses"]
    # "State, Province, or Region" attribute's own partID -- confirmed against
    # parts.csv the same way as every other dropdown column here.
    wire_direct_reference(addr_ws, addr_partids, addr_partid_col, EXTRA_ROWS,
                           "stateProvReg", "zones", zones_zoneName, zones_isoZone)
    wire_direct_reference(addr_ws, addr_partids, addr_partid_col, EXTRA_ROWS,
                           "country", "countries", countries_nameEngl, countries_isoCode)

    ds_ws, ds_partids, ds_partid_col = table_sheets["datasets"]
    wire_direct_reference(ds_ws, ds_partids, ds_partid_col, EXTRA_ROWS,
                           "lang", "languages", languages_langName, languages_lang)

    wb.close()
    print(f"wrote {out_path}")
    print(f"parts: {len(parts_rows)} rows, sets: {len(sets_rows)} rows, wideNames: {len(wideNames_rows)} rows")
    for base, cond, n in pairs:
        n_display = fraction_n if base == "fraction" else n
        print(f"  wideName-Dropdowns.{base}Name/{base}Input: {n_display} active rows")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
Generate seed-{postgres,sqlite,mysql}.sql from the live dictionary-tables/*.csv,
matching schema-{postgres,sqlite,mysql}.sql's table/column definitions.

Handles, empirically discovered during generation (see conversation for detail):
- Mixed encoding in ODM_translations.csv (21 bytes are Mac OS Roman inside an
  otherwise-UTF-8 file) — recovered byte-by-byte, not blanket-decoded.
- 3 orphaned FK rows in ODM_sets.csv (partIDs 'gcDay100K'/'mVolt' referenced but
  not present in ODM_parts.csv) — excluded, logged below, NOT silently dropped
  without a trace.
- A synthetic 'pipelineHeader' category (calcTypeSet) + its ODM_sets.csv
  membership row, added per the pipelineID/calculationID PK/FK fix
  (https://odm.discourse.group/t/pipelineid-primary-key-x-foreign-key-issues/200)
  — NOT present in the live CSVs, clearly flagged in the output as synthetic.

Blank CSV cell -> SQL NULL. Non-blank cell (including the literal string "NA",
which is itself a real partID/categorical value in this dictionary, not a null
marker) -> quoted string. This distinction matters: don't conflate "field not
populated" with "field populated with the value that means not-applicable."
"""
import csv
import io
import os

DICT_DIR = os.path.join(os.path.dirname(__file__), '..', '..', 'dictionary-tables')
OUT_DIR = os.path.dirname(__file__)

BAD_SET_PARTIDS = {'gcDay100K', 'mVolt'}  # see module docstring


def read_csv(name):
    path = os.path.join(DICT_DIR, name)
    with open(path, 'rb') as f:
        raw = f.read()
    try:
        text = raw.decode('utf-8')
    except UnicodeDecodeError:
        chunks, remaining = [], raw
        while remaining:
            try:
                chunks.append(remaining.decode('utf-8'))
                remaining = b''
            except UnicodeDecodeError as e:
                chunks.append(remaining[:e.start].decode('utf-8'))
                chunks.append(remaining[e.start:e.start + 1].decode('mac_roman'))
                remaining = remaining[e.start + 1:]
        text = ''.join(chunks)
    rows = list(csv.reader(io.StringIO(text)))
    return rows[1], rows[2:]  # header, data (row 0 is the "Version,3.0.0,..." metadata line)


def quote_ident(name, dialect):
    return f'`{name}`' if dialect == 'mysql' else f'"{name}"'


def sql_escape(value, dialect):
    escaped = value.replace("'", "''")
    if dialect == 'mysql':
        escaped = escaped.replace('\\', '\\\\')
    return escaped


def format_value(value, is_numeric, dialect):
    if value is None or value == '':
        return 'NULL'
    if is_numeric:
        try:
            float(value)
            return value
        except ValueError:
            # Confirmed empirically: every *Order/minLength/maxLength column's only
            # non-numeric content is the literal "NA" (the ODM's generic missingness
            # marker). Unlike string/VARCHAR columns — where "NA" is a real categorical
            # value worth preserving as text — a genuinely INTEGER column has no way to
            # store text at all, so NULL is the only valid representation of "not
            # applicable" here. Falling back to a quoted string (as this used to do)
            # doesn't help: Postgres still rejects 'NA' for an integer column with the
            # same "invalid input syntax for type integer" error, quoted or not.
            return 'NULL'
    return "'" + sql_escape(value, dialect) + "'"


def gen_inserts(table, header, rows, dialect, numeric_cols=frozenset(), batch=200):
    if not rows:
        return f"-- {table}: no rows to insert\n"
    q = lambda n: quote_ident(n, dialect)
    col_list = ', '.join(q(c) for c in header)
    stmts = []
    for i in range(0, len(rows), batch):
        chunk = rows[i:i + batch]
        tuples = []
        for r in chunk:
            vals = [format_value(r[j] if j < len(r) else '', header[j] in numeric_cols, dialect)
                    for j in range(len(header))]
            tuples.append('(' + ', '.join(vals) + ')')
        stmts.append(f"INSERT INTO {q(table)} ({col_list}) VALUES\n  " + ",\n  ".join(tuples) + ";")
    return '\n\n'.join(stmts) + '\n'


PARTS_NUMERIC = {
    'protocolStepsOrder', 'protocolRelationshipsOrder', 'measuresOrder', 'measureSetsOrder',
    'datasetsOrder', 'sitesOrder', 'samplesOrder', 'addressesOrder', 'contactsOrder',
    'organizationsOrder', 'phActionsOrder', 'calculationsOrder', 'instrumentsOrder',
    'polygonRelationshipsOrder', 'polygonsOrder', 'accessionsOrder', 'languagesOrder',
    'translationsOrder', 'partsOrder', 'setsOrder', 'qualityReportsOrder',
    'sampleRelationshipsOrder', 'protocolsOrder', 'countriesOrder', 'zonesOrder',
    'wideNamesOrder', 'minLength', 'maxLength',
}
SETS_NUMERIC = {'enumeration'}


def build_synthetic_pipeline_header(parts_h, parts_d):
    """Templated off the 'normalization' calcTypeSet sibling, per add-odm-part convention."""
    template = next(r for r in parts_d if r[0] == 'normalization')
    row = list(template)  # copy
    overrides = {
        'partID': 'pipelineHeader',
        'partLabel': 'Pipeline Header',
        'partDesc': ('SYNTHETIC, not yet in the live dictionary. Marks the header/anchor row of a '
                     'calculations pipeline (calcType=pipelineHeader, treatmentID NULL); its own '
                     'calculationID is the pipelineID shared by every row in that pipeline. See '
                     'https://odm.discourse.group/t/pipelineid-primary-key-x-foreign-key-issues/200'),
        'firstReleased': '3.0.1',
        'lastUpdated': '3.0.1',
        'changes': 'SYNTHETIC — added in V3.0.1 for the pipelineID/calculationID PK/FK fix; not yet upstreamed to ODM_parts.csv',
    }
    for col, val in overrides.items():
        row[parts_h.index(col)] = val
    return row


def build_synthetic_calctype_membership(sets_h, sets_d):
    max_enum = max(int(r[sets_h.index('enumeration')])
                   for r in sets_d if r[sets_h.index('setID')] == 'calcTypeSet')
    row = [''] * len(sets_h)
    values = {
        'setCompID': 'calcTypeSet_pipelineHeader',
        'setID': 'calcTypeSet',
        'setType': 'mmaSets',
        'partID': 'pipelineHeader',
        'label': 'Pipeline Header',
        'enumeration': str(max_enum + 1),
        'status': 'active',
        'firstReleased': '3.0.1',
        'lastUpdated': '3.0.1',
        'changes': 'SYNTHETIC — not yet upstreamed to ODM_sets.csv',
        'notes': '',
    }
    for col, val in values.items():
        row[sets_h.index(col)] = val
    return row


def main():
    lang_h, lang_d = read_csv('ODM_languages.csv')
    country_h, country_d = read_csv('ODM_countries.csv')
    zone_h, zone_d = read_csv('ODM_zones.csv')
    parts_h, parts_d = read_csv('ODM_parts.csv')
    sets_h, sets_d = read_csv('ODM_sets.csv')
    trans_h, trans_d = read_csv('ODM_translations.csv')
    wide_h, wide_d = read_csv('ODM_wideNames.csv')

    # The live CSV header has "FractionInput" (capital F) while every sibling column
    # (specimenInput, unitInput, ...) is lowercase-first — an apparent typo in the
    # source data, not a meaningful difference. The schema uses the consistent
    # camelCase form, so normalize here rather than propagate the inconsistency.
    # "Tag" -> "tag" for the same reason (schema uses lowercase, matching every
    # other single-word column name in this table, e.g. "source", "label").
    wide_rename = {'FractionInput': 'fractionInput', 'Tag': 'tag'}
    wide_h = [wide_rename.get(c, c) for c in wide_h]

    # wideName is the PK, but the live CSV has 131 rows for only 72 distinct wideName
    # values — the same wide-column name documented once per originating template
    # (source = "EU Airport template", "HPAIV H5N1 Template", etc.). Treated as a
    # canonical lookup table (one definition per wideName), not a provenance log:
    # keep the first occurrence of each wideName, drop the rest, and report exactly
    # what was dropped rather than silently truncating.
    wi = wide_h.index('wideName')
    seen_widenames = set()
    wide_d_deduped, dropped_widenames = [], []
    for r in wide_d:
        if r[wi] in seen_widenames:
            dropped_widenames.append(r[wi])
            continue
        seen_widenames.add(r[wi])
        wide_d_deduped.append(r)
    wide_d = wide_d_deduped

    part_ids = {r[0] for r in parts_d}
    pi = sets_h.index('partID')
    excluded_sets = [r for r in sets_d if r[pi] in BAD_SET_PARTIDS]
    sets_d_clean = [r for r in sets_d if r[pi] not in BAD_SET_PARTIDS]

    synthetic_part = build_synthetic_pipeline_header(parts_h, parts_d)
    synthetic_membership = build_synthetic_calctype_membership(sets_h, sets_d_clean)

    parts_d_final = parts_d + [synthetic_part]
    sets_d_final = sets_d_clean + [synthetic_membership]

    for dialect in ('postgres', 'sqlite', 'mysql'):
        out_path = os.path.join(OUT_DIR, f'seed-{dialect}.sql')
        parts_lines = []

        preamble = {
            'postgres': "-- Generated seed data for PHES-ODM v3.0.1 (PostgreSQL). See generate_seed_data.py.\nBEGIN;\n",
            'sqlite':   "-- Generated seed data for PHES-ODM v3.0.1 (SQLite). See generate_seed_data.py.\nPRAGMA foreign_keys = ON;\nBEGIN TRANSACTION;\n",
            'mysql':    "-- Generated seed data for PHES-ODM v3.0.1 (MySQL/MariaDB). See generate_seed_data.py.\nSTART TRANSACTION;\n",
        }[dialect]
        postamble = {
            'postgres': "\nCOMMIT;\n",
            'sqlite':   "\nCOMMIT;\n",
            'mysql':    "\nCOMMIT;\n",
        }[dialect]

        parts_lines.append(preamble)
        parts_lines.append("\n-- languages (must precede translations)\n")
        parts_lines.append(gen_inserts('languages', lang_h, lang_d, dialect))
        parts_lines.append("\n-- countries (must precede zones)\n")
        parts_lines.append(gen_inserts('countries', country_h, country_d, dialect))
        parts_lines.append("\n-- zones\n")
        parts_lines.append(gen_inserts('zones', zone_h, zone_d, dialect))
        parts_lines.append(
            f"\n-- parts ({len(parts_d)} live rows + 1 synthetic 'pipelineHeader' row, "
            "flagged via changes='SYNTHETIC...' — not yet upstreamed to ODM_parts.csv)\n"
        )
        if dialect == 'mysql':
            # parts is the ONLY seeded table with a genuine self-reference (many of its
            # own columns FK to its own partID) where insertion order can't guarantee
            # prerequisite rows come first. MySQL/InnoDB has no deferred-constraint
            # mechanism (unlike Postgres/SQLite's DEFERRABLE, used throughout this
            # schema), so FOREIGN_KEY_CHECKS is disabled for *only* this one INSERT and
            # immediately re-enabled — not for the whole file. Every other seeded table
            # (sets/translations/zones/wideNames) has its dependencies fully loaded by
            # insertion order already, so it gets real, live constraint checking here,
            # matching the rigor Postgres/SQLite get for free via DEFERRABLE: turning
            # FOREIGN_KEY_CHECKS back on does NOT retroactively validate rows inserted
            # while it was off, so disabling it file-wide (as an earlier version of
            # this script did) would have silently skipped integrity checking for
            # every single row, not just parts's.
            parts_lines.append("SET FOREIGN_KEY_CHECKS=0;\n")
        parts_lines.append(gen_inserts('parts', parts_h, parts_d_final, dialect, PARTS_NUMERIC))
        if dialect == 'mysql':
            parts_lines.append("SET FOREIGN_KEY_CHECKS=1;\n")
        parts_lines.append(
            f"\n-- sets ({len(sets_d_clean)} live rows, {len(excluded_sets)} excluded as orphaned FKs: "
            f"{[r[0] for r in excluded_sets]} reference partIDs not present in ODM_parts.csv "
            "('gcDay100K', 'mVolt') — upstream data-quality gap, not fixed here. "
            "Plus 1 synthetic 'calcTypeSet_pipelineHeader' membership row.)\n"
        )
        parts_lines.append(gen_inserts('sets', sets_h, sets_d_final, dialect, SETS_NUMERIC))
        parts_lines.append("\n-- translations\n")
        parts_lines.append(gen_inserts('translations', trans_h, trans_d, dialect))
        parts_lines.append(
            f"\n-- wideNames ({len(wide_d)} rows kept, {len(dropped_widenames)} dropped as duplicate "
            f"wideName values — same wide-column name re-documented per originating template; kept "
            f"first occurrence only, per maintainer decision. Dropped: {dropped_widenames})\n"
        )
        parts_lines.append(gen_inserts('wideNames', wide_h, wide_d, dialect))
        parts_lines.append(postamble)

        with open(out_path, 'w', encoding='utf-8') as f:
            f.write('\n'.join(parts_lines))

        print(f"wrote {out_path} ({os.path.getsize(out_path):,} bytes)")

    print(f"\nExcluded {len(excluded_sets)} orphaned sets.csv rows: {[r[0] for r in excluded_sets]}")
    print(f"Dropped {len(dropped_widenames)} duplicate wideNames.csv rows: {dropped_widenames}")
    print(f"Row totals: languages={len(lang_d)} countries={len(country_d)} zones={len(zone_d)} "
          f"parts={len(parts_d_final)} (incl. 1 synthetic) sets={len(sets_d_final)} (incl. 1 synthetic) "
          f"translations={len(trans_d)} wideNames={len(wide_d)}")


if __name__ == '__main__':
    main()

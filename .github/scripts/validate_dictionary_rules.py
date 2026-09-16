#!/usr/bin/env python3
"""
Validates dictionary-tables/*.csv against the rule spec in
internal_structure_rules/DICTIONARY_VALIDATION.md.

Each check function is named after the rule ID(s) it implements and appends
Violation entries to a shared list. HARD violations fail the run (exit 1);
SOFT violations are printed as advisory warnings only and never fail it.

Run standalone: `python3 .github/scripts/validate_dictionary_rules.py`
(reads dictionary-tables/*.csv relative to the repo root, two levels up).
"""
import csv
import io
import os
import re
import sys
from collections import Counter, defaultdict

DICT_DIR = os.path.join(os.path.dirname(__file__), '..', '..', 'dictionary-tables')

TABLE_NAMES = [
    'protocolSteps', 'protocolRelationships', 'measures', 'measureSets', 'datasets', 'sites',
    'samples', 'addresses', 'contacts', 'organizations', 'phActions', 'calculations',
    'instruments', 'polygonRelationships', 'polygons', 'accessions', 'languages', 'translations',
    'parts', 'sets', 'qualityReports', 'sampleRelationships', 'protocols', 'countries', 'zones',
    'wideNames',
]

SENTINEL = {
    'domain': 'naDomain', 'specimenSet': 'naSpecimenSet', 'compartmentSet': 'naCompartmentSet',
    'group': 'naGroup', 'class': 'naClass', 'nomenclature': 'naNomenclature',
    'unitSet': 'naUnitSet', 'aggregationScale': 'naAggrScale', 'aggregationSet': 'naAggrSet',
}
SENTINEL_COLUMNS = list(SENTINEL.keys())

NA = ('', 'NA')  # a blank cell and the literal "NA" marker are both "not populated" for this purpose


def is_blank(v):
    return v in NA


# ---------------------------------------------------------------------------
# CSV loading (mixed-encoding-safe -- see sync-odm-sql-templates skill / this
# repo's own generate_seed_data.py for why: ODM_translations.csv has
# previously contained stray Mac OS Roman bytes inside an otherwise-UTF-8 file)
# ---------------------------------------------------------------------------

def read_version(name='ODM_parts.csv'):
    path = os.path.join(DICT_DIR, name)
    with open(path, newline='', encoding='utf-8') as f:
        return next(csv.reader(f))[1]


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
    header, data = rows[1], rows[2:]
    return header, [dict(zip(header, r)) for r in data]


# ---------------------------------------------------------------------------
# Violations
# ---------------------------------------------------------------------------

class Violations:
    def __init__(self):
        self.items = []  # (rule_id, severity, partID, message)

    def add(self, rule_id, severity, part_id, message):
        self.items.append((rule_id, severity, part_id, message))

    def hard(self):
        return [v for v in self.items if v[1] == 'HARD']

    def soft(self):
        return [v for v in self.items if v[1] == 'SOFT']


V = Violations()


# ---------------------------------------------------------------------------
# Generic check helpers
# ---------------------------------------------------------------------------

def check_sentinel(rows, columns, rule_id, exceptions=None, severity='HARD'):
    """All `columns` must equal their sentinel value, for every row not in `exceptions`."""
    exceptions = exceptions or set()
    for r in rows:
        if r['partID'] in exceptions:
            continue
        for col in columns:
            if r[col] != SENTINEL[col]:
                V.add(rule_id, severity, r['partID'], f"{col}={r[col]!r}, expected sentinel {SENTINEL[col]!r}")


def check_closed_set(rows, column, valid_values, rule_id, exceptions=None, severity='HARD'):
    exceptions = exceptions or {}
    for r in rows:
        allowed = exceptions.get(r['partID'], valid_values)
        if r[column] not in allowed:
            V.add(rule_id, severity, r['partID'], f"{column}={r[column]!r}, expected one of {sorted(valid_values)}")


def check_populated(rows, column, rule_id, exceptions=None, severity='HARD'):
    exceptions = exceptions or set()
    for r in rows:
        if r['partID'] in exceptions:
            continue
        if is_blank(r[column]):
            V.add(rule_id, severity, r['partID'], f"{column} is blank, expected populated")


def check_blank(rows, column, rule_id, exceptions=None, severity='HARD'):
    exceptions = exceptions or set()
    for r in rows:
        if r['partID'] in exceptions:
            continue
        if not is_blank(r[column]):
            V.add(rule_id, severity, r['partID'], f"{column}={r[column]!r}, expected blank")


def check_equals(rows, column, value, rule_id, exceptions=None, severity='HARD'):
    exceptions = exceptions or {}
    for r in rows:
        expected = exceptions.get(r['partID'], value)
        if r[column] != expected:
            V.add(rule_id, severity, r['partID'], f"{column}={r[column]!r}, expected {expected!r}")


def check_triplet_role(rows, table, role, rule_id, severity='HARD'):
    """<table> triplet column must equal `role` (or be blank if role is None)."""
    for r in rows:
        v = r[table]
        if role is None:
            if not is_blank(v):
                V.add(rule_id, severity, r['partID'], f"{table}={v!r}, expected blank")
        elif v != role:
            V.add(rule_id, severity, r['partID'], f"{table}={v!r}, expected {role!r}")


def check_closure(defined_ids, used_values, rule_id, exceptions=None, severity='HARD'):
    exceptions = exceptions or set()
    only_defined = (defined_ids - used_values) - exceptions
    only_used = used_values - defined_ids
    for pid in sorted(only_defined):
        V.add(rule_id, severity, pid, "defined but never used/referenced")
    for pid in sorted(only_used):
        V.add(rule_id, severity, pid, "used/referenced but not defined")


# ===========================================================================
# Load data
# ===========================================================================

def load():
    parts_h, parts_all = read_csv('ODM_parts.csv')
    sets_h, sets_all = read_csv('ODM_sets.csv')
    trans_h, trans_all = read_csv('ODM_translations.csv')
    wide_h, wide_all = read_csv('ODM_wideNames.csv')
    lang_h, lang_all = read_csv('ODM_languages.csv')
    countries_h, countries_all = read_csv('ODM_countries.csv')
    zones_h, zones_all = read_csv('ODM_zones.csv')
    return {
        'version': read_version(),
        'parts_h': parts_h, 'parts_all': parts_all,
        'sets_h': sets_h, 'sets_all': sets_all,
        'trans_h': trans_h, 'trans_all': trans_all,
        'wide_h': wide_h, 'wide_all': wide_all,
        'lang_h': lang_h, 'lang_all': lang_all,
        'countries_h': countries_h, 'countries_all': countries_all,
        'zones_h': zones_h, 'zones_all': zones_all,
    }


# ===========================================================================
# PT.* -- per-partType rules
# ===========================================================================

def check_measurements(by_type):
    rows = by_type.get('measurements', [])
    non_hme = [r for r in rows if r['partID'] != 'hMe']
    check_closed_set(rows, 'aggregationScale', {'seeUnitAggScale', 'quantAggScale', 'qualAggScale', 'othAgg'}, 'PT.MEA.01', exceptions={'hMe': {'naAggrScale'}})
    check_closed_set(rows, 'dataType', {'seeUnitData', 'integer', 'float', 'categorical', 'varchar', 'boolean'}, 'PT.MEA.02')
    hme = next((r for r in rows if r['partID'] == 'hMe'), None)
    if hme:
        if not (hme['unitSet'] == 'naUnitSet' and hme['aggregationScale'] == 'naAggrScale' and hme['dataType'] == 'varchar'):
            V.add('PT.MEA.03', 'HARD', 'hMe', 'hMe placeholder does not have unitSet=naUnitSet/aggregationScale=naAggrScale/dataType=varchar')
    for r in rows:
        if not is_blank(r['missingnessSet']) and r['missingnessSet'] != 'genMissingnessSet':
            V.add('PT.MEA.04', 'HARD', r['partID'], f"missingnessSet={r['missingnessSet']!r}, expected genMissingnessSet or blank")
    check_populated(non_hme, 'qualityIndSet', 'PT.MEA.05')
    for r in rows:
        cat_bool = r['dataType'] in ('categorical', 'boolean')
        populated = not is_blank(r['mmaSet'])
        if cat_bool != populated:
            V.add('PT.MEA.06', 'HARD', r['partID'], f"dataType={r['dataType']!r} but mmaSet populated={populated}")
    check_closed_set(rows, 'nomenclature', {'naNomenclature', 'who', 'pangolin', 'ncbiNom', 'icd'}, 'PT.MEA.07')
    check_triplet_role(rows, 'protocolSteps', 'input', 'PT.MEA.08')
    check_triplet_role(rows, 'measures', 'input', 'PT.MEA.08')
    check_triplet_role(rows, 'wideNames', 'input', 'PT.MEA.08')
    for r in rows:
        if r['partID'] == 'hMe':
            continue  # documented exception -- see PT.MEA.03
        for col in ('domain', 'specimenSet', 'compartmentSet', 'group', 'class', 'unitSet', 'aggregationSet'):
            if r[col] == SENTINEL[col]:
                V.add('PT.MEA.09', 'SOFT', r['partID'], f"{col} is sentinel ({SENTINEL[col]}) -- worth a second look")


def check_attributes(by_type):
    rows = by_type.get('attributes', [])
    check_sentinel(rows, SENTINEL_COLUMNS, 'PT.ATT.01')
    check_closed_set(rows, 'dataType', {'varchar', 'categorical', 'datetime', 'integer', 'float', 'date', 'boolean'}, 'PT.ATT.02')
    for r in rows:
        cat_bool = r['dataType'] in ('categorical', 'boolean')
        populated = not is_blank(r['mmaSet'])
        if cat_bool != populated:
            V.add('PT.ATT.03', 'HARD', r['partID'], f"dataType={r['dataType']!r} but mmaSet populated={populated}")
    for r in rows:
        if r['maxLength'] not in ('', 'NA', '30'):
            V.add('PT.ATT.05', 'SOFT', r['partID'], f"maxLength={r['maxLength']!r}, default is 30")
        if r['minLength'] not in ('', 'NA', '0'):
            V.add('PT.ATT.06', 'SOFT', r['partID'], f"minLength={r['minLength']!r}, default is 0")


def check_pk_per_table(attributes_rows, partsupport_rows):
    """PT.ATT.04: exactly one pK per <table> triplet column, counting attributes + partSupport."""
    all_rows = attributes_rows + partsupport_rows
    for table in TABLE_NAMES:
        pks = [r['partID'] for r in all_rows if r[table] == 'pK']
        if len(pks) != 1:
            V.add('PT.ATT.04', 'HARD', None, f"{table}: expected exactly 1 pK, found {len(pks)} ({pks})")


def check_categories(by_type):
    rows = by_type.get('categories', [])
    check_sentinel(rows, ['unitSet', 'aggregationSet', 'aggregationScale'], 'PT.CAT.01')
    check_sentinel(rows, ['nomenclature'], 'PT.CAT.02')
    for r in rows:
        for table in TABLE_NAMES:
            v = r[table]
            if not is_blank(v) and v != 'input':
                V.add('PT.CAT.03', 'HARD', r['partID'], f"{table}={v!r}, expected 'input' or blank")
    check_closed_set(rows, 'dataType', {'varchar'}, 'PT.CAT.04', exceptions={'TRUE': {'boolean'}, 'FALSE': {'boolean'}})
    for pid in ('TRUE', 'FALSE'):
        row = next((r for r in rows if r['partID'].upper() == pid and r['partID'] != pid), None)
        if row:
            V.add('PT.CAT.05', 'HARD', row['partID'], f"boolean category partID is {row['partID']!r}, expected exact uppercase {pid!r}")
    check_blank(rows, 'mmaSet', 'PT.CAT.06')
    check_sentinel(rows, ['domain', 'compartmentSet'], 'PT.CAT.07')


def check_units(by_type):
    rows = by_type.get('units', [])
    check_sentinel(rows, ['compartmentSet', 'unitSet'], 'PT.UNI.01')
    placeholder_exceptions = {'hUn', 'naUnit'}
    non_placeholder = [r for r in rows if r['partID'] not in placeholder_exceptions]
    for col in ('domain', 'specimenSet', 'aggregationScale', 'aggregationSet'):
        for r in non_placeholder:
            if r[col] == SENTINEL.get(col, None):
                V.add('PT.UNI.02', 'HARD', r['partID'], f"{col} is sentinel but this is not a placeholder unit (hUn/naUnit)")
    for pid in placeholder_exceptions:
        row = next((r for r in rows if r['partID'] == pid), None)
        if row:
            for col in ('domain', 'specimenSet', 'aggregationScale', 'aggregationSet'):
                if row[col] != SENTINEL[col]:
                    V.add('PT.UNI.02', 'HARD', pid, f"{col}={row[col]!r}, expected sentinel {SENTINEL[col]!r}")
    check_blank(rows, 'qualityIndSet', 'PT.UNI.03')
    check_blank(rows, 'missingnessSet', 'PT.UNI.03')
    check_blank(rows, 'mmaSet', 'PT.UNI.03')
    check_triplet_role(rows, 'wideNames', 'input', 'PT.UNI.04')
    check_triplet_role(rows, 'measures', 'input', 'PT.UNI.04')
    check_triplet_role(rows, 'protocolSteps', 'input', 'PT.UNI.04')


def check_classes(by_type, measurements_rows):
    rows = by_type.get('classes', [])
    check_equals(rows, 'dataType', 'varchar', 'PT.CLS.01')
    check_equals(rows, 'aggregationSet', 'naAggrSet', 'PT.CLS.01')
    for r in rows:
        if r['class'] != r['partID']:
            V.add('PT.CLS.02', 'HARD', r['partID'], f"class={r['class']!r}, expected self-reference {r['partID']!r}")
    for r in rows:
        no_unit = r['unitSet'] == 'naUnitSet'
        if no_unit:
            if not (r['aggregationScale'] == 'naAggrScale' and r['compartmentSet'] == 'naCompartmentSet'):
                V.add('PT.CLS.03', 'HARD', r['partID'], "unitSet=naUnitSet but aggregationScale/compartmentSet not both sentinel")
        else:
            if r['aggregationScale'] != 'seeUnitAggScale' or r['compartmentSet'] == 'naCompartmentSet':
                V.add('PT.CLS.03', 'HARD', r['partID'], "has a real unitSet but aggregationScale != seeUnitAggScale or compartmentSet is sentinel")
    check_triplet_role(rows, 'measures', 'input', 'PT.CLS.04')
    check_triplet_role(rows, 'parts', 'input', 'PT.CLS.04')
    check_sentinel(rows, ['group'], 'PT.CLS.05')
    check_blank(rows, 'missingnessSet', 'PT.CLS.06')
    check_blank(rows, 'mmaSet', 'PT.CLS.06')

    # PT.CLS.08: domain generalization -- multi-table check against measurements.class/domain
    domains_by_class = defaultdict(set)
    for m in measurements_rows:
        if m['class'] and m['class'] != 'naClass':
            domains_by_class[m['class']].add(m['domain'])
    for r in rows:
        if r['partID'] == 'naClass':
            continue
        member_domains = domains_by_class.get(r['partID'], set())
        if not member_domains:
            continue
        if len(member_domains) > 1:
            if r['domain'] != 'allDo':
                V.add('PT.CLS.08', 'HARD', r['partID'], f"members span domains {sorted(member_domains)} but class.domain={r['domain']!r}, expected allDo")
        else:
            (only,) = member_domains
            if r['domain'] != only:
                V.add('PT.CLS.08', 'HARD', r['partID'], f"single member domain is {only!r} but class.domain={r['domain']!r}")


def check_groups(by_type):
    rows = by_type.get('groups', [])
    check_equals(rows, 'compartmentSet', 'anyCompartmentSet', 'PT.GRP.01')
    check_triplet_role(rows, 'parts', 'input', 'PT.GRP.01')
    check_equals(rows, 'unitSet', 'naUnitSet', 'PT.GRP.01')
    check_equals(rows, 'aggregationSet', 'naAggrSet', 'PT.GRP.01')
    check_blank(rows, 'qualityIndSet', 'PT.GRP.02')
    check_blank(rows, 'missingnessSet', 'PT.GRP.02')
    check_closed_set(rows, 'domain', {'bio', 'allDo'}, 'PT.GRP.03')
    for r in rows:
        if r['domain'] == 'bio' and r['specimenSet'] != 'saSpecimenSet':
            V.add('PT.GRP.04', 'HARD', r['partID'], f"domain=bio but specimenSet={r['specimenSet']!r}, expected saSpecimenSet")
        elif r['domain'] == 'allDo':
            allowed = {'siSaSpecimenSet', 'poSpecimenSet', 'siSpecimenSet', 'naSpecimenSet'}
            if r['specimenSet'] not in allowed:
                V.add('PT.GRP.04', 'HARD', r['partID'], f"domain=allDo but specimenSet={r['specimenSet']!r}, expected one of {sorted(allowed)}")
            if r['specimenSet'] == 'naSpecimenSet' and r['partID'] != 'naGroup':
                V.add('PT.GRP.04', 'HARD', r['partID'], "specimenSet=naSpecimenSet reserved for naGroup")
    check_equals(rows, 'aggregationScale', 'seeUnitAggScale', 'PT.GRP.05', exceptions={'naGroup': 'naAggrScale'})
    check_closed_set(rows, 'class', {'organism', 'naClass'}, 'PT.GRP.06')
    check_equals(rows, 'dataType', 'varchar', 'PT.GRP.07')


def check_methods(by_type):
    rows = by_type.get('methods', [])
    for col in ('domain', 'specimenSet', 'compartmentSet'):
        for r in rows:
            if r[col] == SENTINEL[col]:
                V.add('PT.MET.01', 'HARD', r['partID'], f"{col} is sentinel, expected a real value")
    for r in rows:
        if r['group'] == 'naGroup':
            V.add('PT.MET.02', 'HARD', r['partID'], "group=naGroup, expected a real group")
    check_closed_set(rows, 'dataType', {'categorical', 'boolean'}, 'PT.MET.03')
    check_populated(rows, 'mmaSet', 'PT.MET.04')
    check_equals(rows, 'missingnessSet', 'genMissingnessSet', 'PT.MET.05')
    check_populated(rows, 'qualityIndSet', 'PT.MET.05')
    check_triplet_role(rows, 'protocolSteps', 'input', 'PT.MET.06')
    check_triplet_role(rows, 'wideNames', 'input', 'PT.MET.06')


def check_quality_indicators(by_type):
    rows = by_type.get('qualityIndicators', [])
    check_sentinel(rows, SENTINEL_COLUMNS, 'PT.QI.01')
    check_blank(rows, 'qualityIndSet', 'PT.QI.02')
    check_blank(rows, 'missingnessSet', 'PT.QI.02')
    check_blank(rows, 'mmaSet', 'PT.QI.02')
    check_equals(rows, 'dataType', 'varchar', 'PT.QI.03')
    check_equals(rows, 'maxLength', '30', 'PT.QI.03')
    check_equals(rows, 'minLength', '0', 'PT.QI.03')
    check_triplet_role(rows, 'qualityReports', 'input', 'PT.QI.04')
    for table in TABLE_NAMES:
        if table == 'qualityReports':
            continue
        check_triplet_role(rows, table, None, 'PT.QI.04')


# ===========================================================================
# VOCAB.* -- vocabulary closure
# ===========================================================================

def check_vocab(by_type, wide_all, sets_active):
    def ids(pt):
        return {r['partID'] for r in by_type.get(pt, [])}

    sets_by_type = defaultdict(list)
    for s in sets_active:
        sets_by_type[s['setID']].append(s)

    def members_of_sets(set_ids):
        result = set()
        for sid in set_ids:
            for s in sets_by_type.get(sid, []):
                result.add(s['partID'])
        return result

    check_closure(ids('specimens'), members_of_sets(ids('specimenSets')), 'VOCAB.01')
    check_closure(ids('compartments'), members_of_sets(ids('compartmentSets')), 'VOCAB.02')
    check_closure(ids('aggregations'), members_of_sets(ids('aggregationSets')), 'VOCAB.03')

    def used_values(col):
        return {r[col] for r in by_type_all_content(by_type) if col in r and not is_blank(r[col])}

    check_closure(ids('specimenSets'), used_values('specimenSet'), 'VOCAB.04')
    check_closure(ids('compartmentSets'), used_values('compartmentSet'), 'VOCAB.05')
    check_closure(ids('unitSets'), used_values('unitSet'), 'VOCAB.06')
    check_closure(ids('qualityIndSets'), used_values('qualityIndSet'), 'VOCAB.07')
    check_closure(ids('aggregationSets'), used_values('aggregationSet'), 'VOCAB.08')
    check_closure(ids('missingnessSets'), used_values('missingnessSet'), 'VOCAB.09')

    dictsets_used = {s['setID'] for s in sets_active if s['setType'] == 'dictSets'}
    check_closure(ids('dictSets'), dictsets_used, 'VOCAB.10')
    shortsets_used = {s['setID'] for s in sets_active if s['setType'] == 'shortSets'}
    check_closure(ids('shortSets'), shortsets_used, 'VOCAB.11')

    check_closure(ids('domains'), used_values('domain'), 'VOCAB.12')
    check_closure(ids('nomenclatures'), used_values('nomenclature'), 'VOCAB.13', exceptions={'nextclade'})
    check_closure(ids('aggregationScales'), used_values('aggregationScale'), 'VOCAB.14')
    check_closure(ids('dataTypes'), used_values('dataType'), 'VOCAB.15', exceptions={'blob'})

    used_mmaSet_curated = {v for v in used_values('mmaSet') if v in ids('mmaSets')}
    check_closure(ids('mmaSets'), used_mmaSet_curated, 'VOCAB.16')
    for r in by_type.get('mmaSets', []):
        if r['mmaSet'] != r['partID']:
            V.add('VOCAB.17', 'HARD', r['partID'], f"mmaSet={r['mmaSet']!r}, expected self-reference {r['partID']!r}")

    set_definition_types = {'unitSets', 'specimenSets', 'compartmentSets', 'qualityIndSets',
                             'aggregationSets', 'missingnessSets', 'dictSets', 'shortSets', 'mmaSets'}
    setTypeSet_row = next((r for r in by_type.get('mmaSets', []) if r['partID'] == 'setTypeSet'), None)
    if setTypeSet_row is None:
        V.add('VOCAB.18', 'HARD', 'setTypeSet', "setTypeSet row not found in mmaSets partType")
    else:
        members = {s['partID'] for s in sets_active if s['setID'] == 'setTypeSet'}
        if members != set_definition_types:
            V.add('VOCAB.18', 'HARD', 'setTypeSet', f"members={sorted(members)}, expected exactly {sorted(set_definition_types)}")

    used_partType = {r['partType'] for r in by_type_all_content(by_type)}
    used_wideNameType = {r['wideNameType'] for r in wide_all if r.get('wideNameType') and not is_blank(r['wideNameType'])}
    check_closure(ids('partTypes'), used_partType | used_wideNameType, 'VOCAB.19')


def by_type_all_content(by_type):
    for rows in by_type.values():
        for r in rows:
            yield r


# ===========================================================================
# DT.* -- dataType-level rules
# ===========================================================================

def check_datatype_rules(active_parts, by_type):
    for r in active_parts:
        if r['dataType'] == 'seeUnitData' and r['partType'] != 'measurements':
            V.add('DT.01', 'HARD', r['partID'], f"dataType=seeUnitData on partType={r['partType']!r}, only 'measurements' rows may defer this way")

    for r in by_type.get('aggregations', []):
        if r['partID'] == 'naAggr':
            continue
        if r['minValue'] != 'seeUnitVal' or r['maxValue'] != 'seeUnitVal':
            V.add('DT.02', 'HARD', r['partID'], f"minValue={r['minValue']!r} maxValue={r['maxValue']!r}, expected both seeUnitVal")

    def is_numeric(v):
        try:
            float(v)
            return True
        except ValueError:
            return False

    for r in by_type.get('measurements', []):
        if r['dataType'] not in ('integer', 'float', 'seeUnitData'):
            continue
        for col in ('minValue', 'maxValue'):
            v = r[col]
            if not (v == 'seeUnitVal' or is_numeric(v)):
                V.add('DT.03', 'SOFT', r['partID'], f"{col}={v!r}, expected seeUnitVal or a real number")

    for r in active_parts:
        if r['dataType'] == 'categorical':
            if is_blank(r['minLength']) or is_blank(r['maxLength']):
                V.add('DT.04', 'HARD', r['partID'], "categorical row missing minLength/maxLength")

    for r in active_parts:
        if r['dataType'] in ('integer', 'float', 'seeUnitData'):
            if not is_blank(r['minLength']) or not is_blank(r['maxLength']):
                V.add('DT.05', 'HARD', r['partID'], f"numeric dataType={r['dataType']!r} but minLength={r['minLength']!r} maxLength={r['maxLength']!r}")


# ===========================================================================
# XC.* -- cross-cutting / global rules
# ===========================================================================

PARTID_RE = re.compile(r'^[a-zA-Z][a-zA-Z0-9]*$')


def check_crosscutting(data, active_parts, by_type):
    # XC.01 is a meta-rule instantiated by the per-partType sentinel checks above -- no separate check.

    # XC.02: table-triplet role by partType
    schema_types = {'attributes', 'partSupport'}
    content_types = {'measurements', 'categories', 'units', 'classes', 'groups', 'methods'}
    for r in active_parts:
        pt = r['partType']
        for table in TABLE_NAMES:
            v = r[table]
            if is_blank(v):
                continue
            if pt in content_types and v != 'input':
                V.add('XC.02', 'HARD', r['partID'], f"{table}={v!r} for partType={pt!r}, expected 'input' only")

    # XC.03: seeUnitData/seeUnitAggScale resolve to a real value on the referenced units row.
    # No separate check here -- DT.01 already enforces "seeUnitData only ever appears on
    # measurements", which is exactly what makes a units row's own dataType/aggregationScale
    # the real, non-deferred value XC.03 describes; a second check would just double-report
    # the same violation under a different rule ID.

    # XC.05: global partID uniqueness
    counts = Counter(r['partID'] for r in active_parts)
    for pid, n in counts.items():
        if n > 1:
            V.add('XC.05', 'HARD', pid, f"partID appears {n} times among active parts")

    # XC.06: partID format
    for r in active_parts:
        if r['partID'] == '16rgs':
            continue
        if not PARTID_RE.match(r['partID']):
            V.add('XC.06', 'HARD', r['partID'], f"partID {r['partID']!r} does not match ^[a-zA-Z][a-zA-Z0-9]*$")

    # XC.07
    semver_re = re.compile(r'^\d+\.\d+\.\d+$')
    for r in active_parts:
        fr, lu = r['firstReleased'], r['lastUpdated']
        if is_blank(fr) or is_blank(lu):
            V.add('XC.07', 'HARD', r['partID'], "firstReleased/lastUpdated blank")
            continue
        if not (semver_re.match(fr) and semver_re.match(lu)):
            V.add('XC.07', 'HARD', r['partID'], f"firstReleased={fr!r} lastUpdated={lu!r} not strict X.Y.Z")
            continue
        if tuple(map(int, fr.split('.'))) > tuple(map(int, lu.split('.'))):
            V.add('XC.07', 'HARD', r['partID'], f"firstReleased={fr!r} > lastUpdated={lu!r}")

    # XC.08
    for r in active_parts:
        if is_blank(r['changes']):
            fr = r['firstReleased']
            try:
                early = tuple(map(int, fr.split('.'))) <= (2, 0, 0)
            except ValueError:
                early = False
            if not early:
                V.add('XC.08', 'HARD', r['partID'], f"changes blank, firstReleased={fr!r} (> 2.0.0)")

    # XC.09 / XC.10: translation coverage
    trans_by_part = defaultdict(set)
    for t in data['trans_all']:
        trans_by_part[t['partID']].add(t['lang'])
    all_langs = {l['lang'] for l in data['lang_all']}
    current_version = data['version']
    for r in active_parts:
        langs = trans_by_part.get(r['partID'], set())
        if 'eng' not in langs:
            V.add('XC.09', 'HARD', r['partID'], "no 'eng' row in translations.csv")
        missing = all_langs - langs - {'eng'}
        if missing:
            is_new = r['firstReleased'] == current_version
            note = " (newly added this version, may be expected lag)" if is_new else ""
            V.add('XC.10', 'SOFT', r['partID'], f"missing translations for {sorted(missing)}{note}")

    # XC.11: fKAliasID resolves to a real partID
    active_ids = {r['partID'] for r in active_parts}
    for r in active_parts:
        if not is_blank(r['fKAliasID']) and r['fKAliasID'] not in active_ids:
            V.add('XC.11', 'HARD', r['partID'], f"fKAliasID={r['fKAliasID']!r} does not resolve to an active partID")

    # XC.12
    check_populated(active_parts, 'label', 'XC.12')
    check_populated(active_parts, 'partDesc', 'XC.12')

    # XC.13
    check_closed_set(data['parts_all'], 'status', {'active', 'depreciated'}, 'XC.13')

    # XC.14: no two active parts share a label
    label_counts = Counter(r['label'] for r in active_parts)
    for label, n in label_counts.items():
        if n > 1:
            dupes = [r['partID'] for r in active_parts if r['label'] == label]
            V.add('XC.14', 'HARD', None, f"label {label!r} shared by {dupes}")

    # XC.15: minValue < maxValue wherever both are real numbers
    def is_numeric(v):
        try:
            float(v)
            return True
        except ValueError:
            return False
    for r in active_parts:
        mv, mxv = r['minValue'], r['maxValue']
        if is_numeric(mv) and is_numeric(mxv):
            if not (float(mv) < float(mxv)):
                V.add('XC.15', 'HARD', r['partID'], f"minValue={mv!r} >= maxValue={mxv!r}")

    # XC.16: sets.csv internal key integrity
    sets_active = [s for s in data['sets_all'] if s['status'] == 'active']
    settype_by_setid = defaultdict(set)
    for s in sets_active:
        settype_by_setid[s['setID']].add(s['setType'])
    for setid, types in settype_by_setid.items():
        if len(types) > 1:
            V.add('XC.16', 'HARD', setid, f"setID maps to multiple setTypes: {sorted(types)}")
    setcompid_counts = Counter(s['setCompID'] for s in sets_active)
    for scid, n in setcompid_counts.items():
        if n > 1:
            V.add('XC.16', 'HARD', scid, f"setCompID appears {n} times")
    pair_counts = Counter((s['setID'], s['partID']) for s in sets_active)
    for pair, n in pair_counts.items():
        if n > 1:
            V.add('XC.16', 'HARD', pair[1], f"duplicate (setID, partID) membership pair: {pair}")

    # XC.17: every published CSV column has a matching partID
    schema_rows = [r for r in active_parts if r['partType'] in ('attributes', 'partSupport')]
    described_columns_by_table = defaultdict(set)
    for r in schema_rows:
        for table in TABLE_NAMES:
            if not is_blank(r[table]):
                described_columns_by_table[table].add(r['partID'])
    ref_tables = {
        'parts': (data['parts_h'], None), 'sets': (data['sets_h'], None),
        'translations': (data['trans_h'], None), 'wideNames': (data['wide_h'], None),
        'countries': (data['countries_h'], None), 'zones': (data['zones_h'], None),
        'languages': (data['lang_h'], None),
    }
    active_ids_all = {r['partID'] for r in data['parts_all'] if r['status'] == 'active'}
    for table, (header, _) in ref_tables.items():
        for col in header:
            if col not in active_ids_all:
                V.add('XC.17', 'HARD', col, f"column {table}.{col} has no matching active partID")

    # XC.18: wideNames *Name matches current label of *Input's target
    pairs = [
        ('reportTableName', 'reportTableInput'), ('partTypeName', 'partTypeInput'),
        ('compartmentName', 'compartmentInput'), ('specimenName', 'specimenInput'),
        ('fractionName', 'fractionInput'), ('measureName', 'measureInput'),
        ('methodName', 'methodInput'), ('unitName', 'unitInput'),
        ('aggregationName', 'aggregationInput'), ('attributeName', 'attributeInput'),
    ]
    label_by_partid = {r['partID']: r['label'] for r in data['parts_all']}
    label_by_setpartid = {(s['setID'], s['partID']): s['label'] for s in data['sets_all']}
    wide_h = data['wide_h']
    for row in data['wide_all']:
        for name_col, input_col in pairs:
            if name_col not in wide_h or input_col not in wide_h:
                continue
            input_val = row.get(input_col)
            name_val = row.get(name_col)
            if is_blank(input_val) or is_blank(name_val):
                continue
            if input_col == 'fractionInput':
                expected = None
                for (setid, pid), lbl in label_by_setpartid.items():
                    if pid == input_val:
                        expected = lbl
                        break
            else:
                expected = label_by_partid.get(input_val)
            if expected is not None and name_val != expected:
                V.add('XC.18', 'HARD', row.get('wideName'), f"{name_col}={name_val!r} != current label {expected!r} of {input_col}={input_val!r}")


# ===========================================================================
# Main
# ===========================================================================

def main():
    data = load()
    active_parts = [r for r in data['parts_all'] if r['status'] == 'active']
    by_type = defaultdict(list)
    for r in active_parts:
        by_type[r['partType']].append(r)
    sets_active = [s for s in data['sets_all'] if s['status'] == 'active']

    check_measurements(by_type)
    check_attributes(by_type)
    check_pk_per_table(by_type.get('attributes', []), by_type.get('partSupport', []))
    check_categories(by_type)
    check_units(by_type)
    check_classes(by_type, by_type.get('measurements', []))
    check_groups(by_type)
    check_methods(by_type)
    check_quality_indicators(by_type)
    check_vocab(dict(by_type), data['wide_all'], sets_active)
    check_datatype_rules(active_parts, by_type)
    check_crosscutting(data, active_parts, by_type)

    hard = V.hard()
    soft = V.soft()

    if soft:
        print(f"=== {len(soft)} SOFT (advisory) findings ===")
        for rule_id, _, pid, msg in soft:
            print(f"  [{rule_id}] {pid}: {msg}")
        print()

    if hard:
        print(f"=== {len(hard)} HARD (blocking) violations ===")
        for rule_id, _, pid, msg in hard:
            print(f"  [{rule_id}] {pid}: {msg}")
        print()
        print(f"FAILED: {len(hard)} hard violation(s), {len(soft)} advisory finding(s).")
        sys.exit(1)

    print(f"PASSED: 0 hard violations, {len(soft)} advisory finding(s).")


if __name__ == '__main__':
    main()

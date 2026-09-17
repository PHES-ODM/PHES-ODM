#!/usr/bin/env python3
"""
Keeps each dictionary-tables/ODM_<table>.csv in sync with its
ODM_<table>_v<version>.csv sibling.

Both files are hand-edited in practice -- a fix sometimes lands on one,
sometimes the other -- and that's exactly how they drifted apart during the
2026-09 SQL/Excel template audit (stale TRUE/FALSE partID casing, a blank
dataType, and stale wideNames labels all diverged independently between the
two, in three separate incidents). Triggered by
.github/workflows/sync-dictionary-versions.yml on every push to main that
touches dictionary-tables/ODM_*.csv.

Sync model: whichever file actually changed in the push propagates to its
sibling. The two are identical except the unversioned file carries a leading
"Version,X.Y.Z,,,..." stamp row that the versioned file doesn't -- that row
is stripped/reconstructed around the comparison and copy, never treated as
a real content difference.

If both files changed in the same push and disagree after that
normalization, this is a genuine conflict: never guess a winner. Every
OTHER table in the same push that synced cleanly is still written (reported
via the "synced" output); the conflicted table is left untouched and
reported via the "conflicts" output for the workflow to fail on and open an
issue about.
"""
import glob
import os
import subprocess
import sys

DICT_DIR = os.path.join(os.path.dirname(__file__), '..', '..', 'dictionary-tables')


def changed_files(before, after):
    out = subprocess.run(
        ['git', 'diff', '--name-only', before, after, '--', 'dictionary-tables/'],
        capture_output=True, text=True, check=True, cwd=os.path.join(os.path.dirname(__file__), '..', '..'),
    ).stdout
    return {os.path.basename(p) for p in out.splitlines() if p.strip()}


def read_lines(path):
    with open(path, encoding='utf-8', newline='') as f:
        return f.read().splitlines(keepends=True)


def strip_version_stamp(lines):
    if lines and lines[0].startswith('Version,'):
        return lines[1:]
    return lines


def find_versioned_sibling(table):
    matches = sorted(glob.glob(os.path.join(DICT_DIR, f'ODM_{table}_v*.csv')))
    if len(matches) != 1:
        return None, matches
    return matches[0], matches


def discover_tables():
    return sorted({
        fn[len('ODM_'):-len('.csv')]
        for fn in os.listdir(DICT_DIR)
        if fn.startswith('ODM_') and fn.endswith('.csv') and '_v' not in fn
    })


def sync_table(table, changed):
    """Returns one of: None (nothing to do), 'synced', 'conflict'."""
    unversioned_name = f'ODM_{table}.csv'
    unversioned_path = os.path.join(DICT_DIR, unversioned_name)
    versioned_path, all_matches = find_versioned_sibling(table)
    if versioned_path is None:
        if all_matches:
            print(f"SKIP {table}: {len(all_matches)} versioned siblings found, expected exactly 1: {all_matches}")
        return None
    versioned_name = os.path.basename(versioned_path)

    u_changed = unversioned_name in changed
    v_changed = versioned_name in changed
    if not u_changed and not v_changed:
        return None

    u_lines = read_lines(unversioned_path)
    v_lines = read_lines(versioned_path)
    u_body = strip_version_stamp(u_lines)

    if u_body == v_lines:
        if u_changed and v_changed:
            print(f"OK {table}: both changed but already match, nothing to do")
        return None

    if u_changed and v_changed:
        print(f"CONFLICT {table}: both {unversioned_name} and {versioned_name} changed in this push and disagree")
        return 'conflict'

    if u_changed:
        with open(versioned_path, 'w', encoding='utf-8', newline='') as f:
            f.writelines(u_body)
        print(f"SYNCED {table}: {unversioned_name} -> {versioned_name}")
    else:
        stamp = u_lines[0] if u_lines and u_lines[0].startswith('Version,') else None
        if stamp is None:
            # Unversioned file has no stamp row yet -- derive one from the
            # versioned filename itself (ODM_<table>_v<X.Y.Z>.csv), padded
            # to the same column count as the versioned file's header.
            version = versioned_name.rsplit('_v', 1)[1][:-len('.csv')]
            ncols = len(v_lines[0].split(',')) if v_lines else 2
            stamp = 'Version,' + version + ',' * max(0, ncols - 2) + '\n'
        with open(unversioned_path, 'w', encoding='utf-8', newline='') as f:
            f.write(stamp)
            f.writelines(v_lines)
        print(f"SYNCED {table}: {versioned_name} -> {unversioned_name}")

    return 'synced'


def main():
    if len(sys.argv) != 3:
        print("usage: sync_dictionary_versions.py <before-sha> <after-sha>", file=sys.stderr)
        sys.exit(2)
    before, after = sys.argv[1], sys.argv[2]
    changed = changed_files(before, after)

    synced, conflicts = [], []
    for table in discover_tables():
        result = sync_table(table, changed)
        if result == 'synced':
            synced.append(table)
        elif result == 'conflict':
            conflicts.append(table)

    gha_out = os.environ.get('GITHUB_OUTPUT')
    if gha_out:
        with open(gha_out, 'a') as f:
            f.write(f"synced={','.join(synced)}\n")
            f.write(f"conflicts={','.join(conflicts)}\n")

    if conflicts:
        print("\nConflicted tables (left untouched, need manual resolution):")
        for table in conflicts:
            print(f"  - {table}")
        sys.exit(1)


if __name__ == '__main__':
    main()

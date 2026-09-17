#!/usr/bin/env python3
"""
Sets PHES-ODM-Doc's own documentation version, in both DESCRIPTION and
qmd/_quarto.yml, to match the dictionary version it's being synced to.

The documentation version used to be tracked independently of the
dictionary version -- but the two had already drifted from each other in
practice (DESCRIPTION at 2.1.0 while _quarto.yml was still at 2.0.1,
observed 2026-09), and even reconciled, an independent doc version number
next to a dictionary at v3.0.1 was confusing rather than useful: every
other artifact (the Excel workbook, the SQL seed data, the changelog) is
named for the dictionary version, and the documentation's own reference
chapters are entirely derived from that same dictionary snapshot anyway.
So as of 2026-09, the documentation version is simply set to the
dictionary version on every sync -- there's no longer a separate bump to
compute.

Used by .github/workflows/sync-doc-repo.yml against a checked-out
PHES-ODM-Doc clone: `bump_doc_version.py <doc-repo-path> <dictionary-version>`.
"""
import os
import re
import sys


def parse_semver(s):
    return tuple(int(p) for p in s.split('.'))


def main():
    doc_repo, new_version = sys.argv[1], sys.argv[2]
    desc_path = os.path.join(doc_repo, 'DESCRIPTION')
    quarto_path = os.path.join(doc_repo, 'qmd', '_quarto.yml')

    with open(desc_path) as f:
        desc = f.read()
    old_desc_version = re.search(r'^Version:\s*(\S+)', desc, re.MULTILINE).group(1)

    with open(quarto_path) as f:
        quarto = f.read()
    old_quarto_version = re.search(r'^\s*version:\s*"([^"]+)"', quarto, re.MULTILINE).group(1)

    if old_desc_version != old_quarto_version:
        print(f"NOTE: DESCRIPTION ({old_desc_version}) and _quarto.yml ({old_quarto_version}) had "
              f"already drifted from each other; both are being set to {new_version} regardless.")

    desc = re.sub(r'^Version:\s*\S+', f'Version: {new_version}', desc, count=1, flags=re.MULTILINE)
    with open(desc_path, 'w') as f:
        f.write(desc)

    quarto = re.sub(r'(^\s*version:\s*)"[^"]+"', rf'\g<1>"{new_version}"', quarto, count=1, flags=re.MULTILINE)
    quarto = re.sub(r'(^\s*output-file:\s*)"ODM-documentation-v[^"]+"',
                     rf'\g<1>"ODM-documentation-v{new_version}"', quarto, count=1, flags=re.MULTILINE)
    with open(quarto_path, 'w') as f:
        f.write(quarto)

    old_baseline_tuple = max(parse_semver(old_desc_version), parse_semver(old_quarto_version))
    old_baseline = '.'.join(str(p) for p in old_baseline_tuple)
    print(f"Set documentation version {old_baseline} -> {new_version} in DESCRIPTION and _quarto.yml.")

    gha_out = os.environ.get('GITHUB_OUTPUT')
    if gha_out:
        with open(gha_out, 'a') as f:
            f.write(f"old_version={old_baseline}\n")
            f.write(f"new_version={new_version}\n")


if __name__ == '__main__':
    main()

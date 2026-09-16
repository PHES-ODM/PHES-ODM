#!/usr/bin/env python3
"""
Bumps PHES-ODM-Doc's own documentation version (a PATCH bump) in both
DESCRIPTION and qmd/_quarto.yml, reading whichever of the two is currently
higher as the baseline -- these are known to drift from each other in
practice (DESCRIPTION at 2.1.0 while _quarto.yml was still at 2.0.1,
observed 2026-09), so bumping from the max of both fixes that drift as a
side effect rather than perpetuating it.

A patch bump is deliberately the largest jump this makes on its own: a
human should still bump further (minor/major) by hand afterward if the
dictionary change actually warrants it -- see sync-odm-doc-release's own
"don't assume a bump size" guidance, which this automation can't ask about.

Used by .github/workflows/sync-doc-repo.yml against a checked-out
PHES-ODM-Doc clone, passed as the sole argument.
"""
import os
import re
import sys


def parse_semver(s):
    return tuple(int(p) for p in s.split('.'))


def bump_patch(version):
    major, minor, patch = parse_semver(version)
    return f"{major}.{minor}.{patch + 1}"


def main():
    doc_repo = sys.argv[1]
    desc_path = os.path.join(doc_repo, 'DESCRIPTION')
    quarto_path = os.path.join(doc_repo, 'qmd', '_quarto.yml')

    with open(desc_path) as f:
        desc = f.read()
    desc_version = re.search(r'^Version:\s*(\S+)', desc, re.MULTILINE).group(1)

    with open(quarto_path) as f:
        quarto = f.read()
    quarto_version = re.search(r'^\s*version:\s*"([^"]+)"', quarto, re.MULTILINE).group(1)

    baseline = max(parse_semver(desc_version), parse_semver(quarto_version))
    baseline_str = '.'.join(str(p) for p in baseline)
    new_version = bump_patch(baseline_str)

    if desc_version != quarto_version:
        print(f"NOTE: DESCRIPTION ({desc_version}) and _quarto.yml ({quarto_version}) had already "
              f"drifted from each other; bumping from the higher of the two ({baseline_str}).")

    desc = re.sub(r'^Version:\s*\S+', f'Version: {new_version}', desc, count=1, flags=re.MULTILINE)
    with open(desc_path, 'w') as f:
        f.write(desc)

    quarto = re.sub(r'(^\s*version:\s*)"[^"]+"', rf'\g<1>"{new_version}"', quarto, count=1, flags=re.MULTILINE)
    quarto = re.sub(r'(^\s*output-file:\s*)"ODM-documentation-v[^"]+"',
                     rf'\g<1>"ODM-documentation-v{new_version}"', quarto, count=1, flags=re.MULTILINE)
    with open(quarto_path, 'w') as f:
        f.write(quarto)

    print(f"Bumped documentation version {baseline_str} -> {new_version} in DESCRIPTION and _quarto.yml.")

    gha_out = os.environ.get('GITHUB_OUTPUT')
    if gha_out:
        with open(gha_out, 'a') as f:
            f.write(f"old_version={baseline_str}\n")
            f.write(f"new_version={new_version}\n")


if __name__ == '__main__':
    main()

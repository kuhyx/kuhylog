#!/usr/bin/env bash
# Runs the suite and fails on a single uncovered line.
#
# `flutter test --coverage` only reports on files a test imports, so an
# entirely untested file would silently vanish from the report. The
# second check below catches that by comparing the file list in
# lcov.info against the files actually in lib/.
set -euo pipefail

cd "$(dirname "$0")/.."

flutter test --coverage "$@"

python3 - <<'PY'
import pathlib
import sys

lcov = pathlib.Path('coverage/lcov.info')
if not lcov.exists():
    sys.exit('coverage/lcov.info was not produced')

reported, missed, current = set(), {}, None
total = covered = 0
for line in lcov.read_text().splitlines():
    if line.startswith('SF:'):
        current = line[3:]
        reported.add(current)
        missed[current] = []
    elif line.startswith('DA:'):
        number, count = line[3:].split(',')
        total += 1
        if count == '0':
            missed[current].append(int(number))
        else:
            covered += 1

on_disk = {str(p) for p in pathlib.Path('lib').rglob('*.dart')}
untested = sorted(on_disk - reported)
uncovered = {f: n for f, n in missed.items() if n}

percent = 100.0 if total == 0 else covered / total * 100
print(f'lines  : {covered}/{total} ({percent:.2f}%)')
print(f'files  : {len(reported)} reported, {len(on_disk)} on disk')

if untested:
    print('\nfiles with no coverage data at all:')
    for path in untested:
        print(f'  {path}')

if uncovered:
    print('\nuncovered lines:')
    for path, numbers in sorted(uncovered.items()):
        print(f'  {path}: {numbers}')

if untested or uncovered:
    sys.exit('FAIL: coverage is not 100%')
print('\nOK: 100% line coverage')
PY

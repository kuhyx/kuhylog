#!/usr/bin/env bash
# The single command CI and a human both run before shipping.
set -euo pipefail
cd "$(dirname "$0")/.."

echo '==> flutter pub get'
flutter pub get

echo '==> dart format --set-exit-if-changed'
dart format --set-exit-if-changed lib test

echo '==> flutter analyze --fatal-infos --fatal-warnings'
flutter analyze --fatal-infos --fatal-warnings

echo '==> tool/coverage.sh'
./tool/coverage.sh

echo
echo 'All checks passed.'

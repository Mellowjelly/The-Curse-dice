#!/usr/bin/env bash
# Runs the automated tests. Fails if any test fails OR any script error appears.
# Usage: tools/run_tests.sh   (from the project folder; needs `godot` on PATH)
set -o pipefail
out=$(godot --headless --path . -s tests/run_tests.gd 2>&1)
code=$?
echo "$out" | grep -vE "^Godot Engine|leaked at exit|resources still in use|^\s+at: "
if echo "$out" | grep -q "SCRIPT ERROR"; then
	echo "TESTS FAILED: script errors above"
	exit 1
fi
exit $code

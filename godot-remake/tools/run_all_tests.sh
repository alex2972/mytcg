#!/usr/bin/env bash
# Runs every test script (tests/test_*.gd and tests/online/test_*.gd) headless with a 90 s timeout each.
# Prints only failures and a summary. Usage: bash tools/run_all_tests.sh [filter]
cd "$(dirname "$0")/.." || exit 1
G="${GODOT:-/z/godot/Godot_v4.7.1-stable_win64_console.exe}"
filter="${1:-}"
failed=0; total=0
for f in tests/test_*.gd tests/online/test_*.gd; do
  [ -f "$f" ] || continue
  [ -n "$filter" ] && [[ "$f" != *"$filter"* ]] && continue
  total=$((total+1))
  out=$(timeout 90 "$G" --headless --path . -s "$f" 2>&1)
  code=$?
  bad=$(echo "$out" | grep -iE "FAIL|SCRIPT ERROR|Parse Error" | head -5)
  if [ $code -ne 0 ] || [ -n "$bad" ]; then
    failed=$((failed+1))
    echo "== $f (exit $code)"
    [ -n "$bad" ] && echo "$bad"
    [ $code -eq 124 ] && echo "   (timed out)"
  fi
done
echo "tests: $total, failed: $failed"
[ $failed -eq 0 ]

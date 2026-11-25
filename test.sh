#!/bin/zsh
# Builds clipclean, checks the cleaning rules, then runs a watcher against a private
# pasteboard. Your real clipboard is not touched.
#   ./test.sh --rules   rule cases only (fast)
set -euo pipefail
cd "${0:A:h}"
./build.sh
swiftc -O Tests/e2e.swift -o build/e2e
mkdir -p build/rules && cp Tests/rules.swift build/rules/main.swift
swiftc -O Sources/Cleaner.swift Sources/Rules.swift Sources/RuleTypes.swift build/rules/main.swift -o build/clean-url

fail=0
count=0
check() { # check <input> <expected>
  local got
  got=$(build/clean-url "$1")
  count=$((count + 1))
  if [[ "$got" != "$2" ]]; then
    print -r -- "FAIL  $1"
    print -r -- "  want  $2"
    print -r -- "  got   $got"
    fail=1
  fi
}
same() { check "$1" "$1" }

while IFS= read -r line; do
  [[ -z "$line" || "$line" == \#* ]] && continue
  parts=(${=line})
  case $parts[1] in
    strip) check "$parts[2]" "$parts[3]" ;;
    keep)  same "$parts[2]" ;;
    *)     print -r -- "bad line in Tests/cases.txt: $line"; fail=1 ;;
  esac
done < Tests/cases.txt

# Inputs with spaces, which the cases file cannot hold
same 'https://example.com/?utm_source=a b'
same 'see https://example.com/?utm_source=x for details'
same 'not a url'
same ''

if (( fail )); then
  print "rule tests FAILED"
  exit 1
fi
print "rule tests passed ($count cases)"
[[ "${1:-}" == "--rules" ]] && exit 0

name="clipclean-test-$$"
CLIPCLEAN_PASTEBOARD=$name build/clipclean &
watcher=$!
trap 'kill $watcher 2>/dev/null || true' EXIT
build/e2e $name

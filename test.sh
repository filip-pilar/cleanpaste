#!/bin/zsh
# Checks every case in Tests/cases.txt. Touches nothing outside build/.
set -euo pipefail
cd "${0:A:h}"
mkdir -p build
swiftc Sources/Cleaner.swift Sources/Rules.swift Sources/RuleTypes.swift Tests/run.swift -o build/rules-test
build/rules-test Tests/cases.txt

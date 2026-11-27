#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
lake env lean --version
lake build
for audit in Audit.lean AuditAffine.lean; do
  if ! report=$(lake env lean "$audit" 2>&1); then
    printf '%s\n' "$report" >&2
    exit 1
  fi
  printf '%s\n' "$report"
  awk '
    /depends on axioms: \[/ {
      reading = 1
      seen = 1
      sub(/.*depends on axioms: \[/, "")
    }
    reading {
      axioms = axioms $0
      if ($0 ~ /\]/) {
        gsub(/[[:space:]]/, "", axioms)
        if (axioms != "propext,Classical.choice,Quot.sound]") bad = 1
        reading = 0
        axioms = ""
      }
    }
    END { exit (bad || !seen || reading) }
  ' <<< "$report"
done

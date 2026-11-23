# Reproduce the finite coding calculations

The portable source package now contains the two original scanners, the original pair-graph and witness-replay checkers, all172 normalized inputs, and all429024 saved accepted representatives. Native sources are unchanged; the new Python driver handles portable paths and input/output checks. This package supports regenerating the pair graphs without the historical1.68GB witness streams.

Requires Python>=3.10 and a C++17 compiler (`clang++` or `g++`). Graph canonicalization additionally uses `pynauty`. Run commands from the extracted source root.

```sh
python3 scripts/check_data.py
python3 scripts/check_catalogue.py  # pynauty required
```

These verify literal lower matrices, mother parameters, all matrix/input bindings, the polynomial identity, saved-list parity/cardinality, and catalogue inequivalence. They do not repeat the full quotient enumerations.

Print a complete-case execution plan without running or creating output:

```sh
python3 scripts/reproduce_case.py --case 0 --output /tmp/ecc-case000
```

Actually regenerate both complete2^32 coset domains and every pair for one mother:

```sh
python3 scripts/reproduce_case.py --case 0 --output /tmp/ecc-case000 --run
```

Repeat for any index0..171; output directory must be new. `data/case-index.json` lists names and expected counts. `--cpu-seconds 180` is the default per-scanner limit. A timeout or partial traversal fails and retains the partial output, never produces PASS. The original pair-graph kernel also has a52 CPU-second limit; this sufficed for the reproduced cases, and slower platforms may require adapting that limit with the change recorded. This is not a global cost estimate.

Each successful case writes `verification.json`, both scan JSON reports, both regenerated accepted lists, compiler identity, and the pair graph. The driver validates actual-matrix→scan-coordinate bindings before executing, checks2^32 complete traversal in both implementations, exact set equality to the archived list, and every unordered pair with zero edges. The graph check recomputes weights directly; it does not read the large saved witness streams.

During the2026-11-04 revision, cases0 and171 were run end to end from this driver:

- Case0: both full scans return668 accepted cosets;222778 pairs checked;0 edges.
- Case171: both full scans return3785 accepted cosets;7161220 pairs checked;0 edges.
- All172 dry-run plans validated their matrix and coordinate bindings.

These runs validate the packaged reproducer on two cases. The other170 cases' complete scan claims refer to the original stored runs, whose accepted sets and complete flags were rechecked on2026-11-03. All619053789 historical pair witnesses were replayed on that date. No claim is made that all344 full scans were repeated for this revision.

## Lean

Both source snapshots and pinned manifests are in `formal/`. See `formal/README.md` for build and audit commands. The2026-11-03 build results apply to identical Lean sources: no formal source was changed in this editorial revision. The manuscript now explicitly distinguishes the Python-checked[42,16,12] lower witness from the Lean-checked upper reduction.

## Compact evidence and omitted archive

`data/COMPUTATIONAL_COVERAGE.json` and related historical files retain their original run status fields and metadata; they are provenance records, not updated revision status. In the portable archive, old machine prefixes are replaced by `ARCHIVE_ROOT/`. Current review/verification status is in `validation/verification-summary.json` and `REVIEW_STATUS.md`. Original historical witness-stream replay requires the separately retained large evidence tree. The package includes the original replay checker source for inspection but does not pretend that those omitted streams can be opened from the compact archive.

## Mathematical revision of 2026-11-06

The manuscript structure was revised without changing data/, native/, or formal/. Fresh finite-data and PDF checks are recorded in validation/. Full-domain scans and Lean builds were not rerun for this exposition-only revision.

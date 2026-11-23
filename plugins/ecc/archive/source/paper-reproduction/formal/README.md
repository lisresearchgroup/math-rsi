# Lean source snapshots

Sources and pinned manifests are copied without modification from the two verified local projects. No build cache is included. Resolve mathlib dependencies before building a clean copy.

```sh
cd ecc43
lake exe cache get
lake build ECC.Corollaries
lake env lean Audit.lean
lake env lean CorollariesAudit.lean
cd ../ecc42
lake exe cache get
lake build ECC42
lake env lean Audit.lean
```

The preparation session rebuilt the original projects successfully. This portable snapshot has identical source bytes but has not downloaded a second dependency cache. Final theorem arguments explicitly expose published and computed imports. See the paper's formal-interface appendix; a clean axiom list does not discharge those arguments.

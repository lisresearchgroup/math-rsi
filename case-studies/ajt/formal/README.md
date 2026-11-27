# Lean evidence for the Alon–Jaeger–Tarsi conjecture

For a prime *p*, let *A* be an *n* × *n* matrix over `ZMod p` with
`A.det ≠ 0`. The original conclusion asks for *x* with every coordinate
nonzero and every coordinate of *Ax* nonzero. The affine conclusion allows
independent vectors *a* and *b* of forbidden values and asks for
`xᵢ ≠ aᵢ` and `(Ax)ᵢ ≠ bᵢ` in every coordinate *i*.

| Field and dimension | All nonsingular matrices | All nonsingular symmetric matrices |
| --- | --- | --- |
| Every prime p ≥ 5, n ≤ 11 | Affine and homogeneous | Affine and homogeneous |
| p = 5, n = 12 | Open in this work | Affine and homogeneous |
| Every prime p ≥ 7, n = 12 | Affine and homogeneous | Affine and homogeneous |

For all primes p ≥ 5, the symmetric affine and homogeneous results hold
through dimension 23. The proof uses the fact that if all nonsingular
matrices satisfy the affine conclusion in every dimension through *k*, then
for each nonsingular *A* of dimension at most 2*k* + 1, one of *A* and its
transpose satisfies the affine conclusion.

The prime-dependent permanent bound for general matrices is n < 2<sup>p−2</sup>.
It covers n = 12 for every prime p ≥ 7, since 12 < 32 ≤ 2<sup>p−2</sup>.
For p = 5 it covers n < 8. The separate dimension-eleven proof over
the field of order five uses a marked MacWilliams inequality.

## Lean declarations

- [Task/DimensionEleven.lean](Task/DimensionEleven.lean) exports
  `AlonJaegerTarsi.hasAJTVector_dim_le_eleven` and
  `AlonJaegerTarsi.hasAJTVector_five_dim_eleven`.
- [Task/PermanentRank.lean](Task/PermanentRank.lean) exports
  `AlonJaegerTarsi.PermanentApproach.hasAJTVector_prime_dim_lt`.
- [Task/SameDimensionAffine.lean](Task/SameDimensionAffine.lean) exports
  `AlonJaegerTarsi.AffineReduction.affine_of_same_dimension`,
  `affine_prime_dim_le_eleven` and `symmetric_affine_dim_le_twenty_three`
  in the same namespace. The same-dimension implication assumes the
  homogeneous conclusion for every nonsingular matrix in the fixed dimension.
- [Task/SymmetricDimensions.lean](Task/SymmetricDimensions.lean) and
  [AuditAffine.lean](AuditAffine.lean) give the conditional least-dimension
  result. If *r* is the least dimension in which the homogeneous conclusion
  fails over a fixed field of order *p* with p ≥ 5, the corresponding least
  dimensions are *r* for general affine matrices and 2*r* for symmetric
  affine matrices. Existence of a failure remains the premise.

[Audit.lean](Audit.lean) checks the homogeneous results against the expanded
original coordinate statement, including the field of order five in dimension 11 and
primes p ≥ 7 in dimension 12. [AuditAffine.lean](AuditAffine.lean) checks
the affine results directly for independently specified forbidden coordinates.
Both audits print the actual Lean types and transitive axioms. The source tree
contains the definitions of the original problem and 44 local dependency
modules in the proof closure. The original task proof slots were removed.
See [attribution and licensing](NOTICE.md).

## Replay

With Git and [Elan](https://github.com/leanprover/elan) installed, run from
this directory:

```sh
lake exe cache get
bash check.sh
```

The cache is optional. If a prebuilt cache is unavailable, install a C/C++
build toolchain and Node.js with npm for the upstream dependencies, then run
`bash check.sh` to build them from source. The lockfile pins
[Mathlib](https://github.com/leanprover-community/mathlib4/commit/5b3f719bf129e3cf48daf6ff76a2ec5cb6e9b1e3)
and its transitive packages. The Lean toolchain is
`leanprover/lean4:v4.33.0-rc1`. The project requires no benchmark runner,
test suite, or verifier image.

## Verification record

All 44 local modules were rebuilt from the delivered source in a fresh
network-disabled Linux container with 2 CPUs and 8 GiB RAM. The run used
Lean 4.33.0-rc1, commit `62eed1db4d67327ec8120be05f1a1b0847d74561`,
and prebuilt Mathlib dependencies at the pinned commits. Its local Lean build
directory started empty. The build and both independent import audits exited
with status 0. All 19 printed declarations depend on exactly `propext`,
`Classical.choice` and `Quot.sound`, including both dimension-12 specializations.
[Source build](evidence/source-rebuild.log) · [Actual types and axioms](evidence/caller-and-axioms.log).

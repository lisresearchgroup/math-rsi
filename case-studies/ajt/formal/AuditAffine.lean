import Task.SymmetricDimensions

open Matrix
open AlonJaegerTarsi
open AlonJaegerTarsi.AffineReduction
open AlonJaegerTarsi.AffineBasisTools
open AlonJaegerTarsi.TransposeHalf
open AlonJaegerTarsi.PermanentApproach

namespace SolSameDimensionAudit

def RawHomogeneous {p n : ℕ} (A : Matrix (Fin n) (Fin n) (ZMod p)) : Prop :=
  ∃ x : Fin n → ZMod p, (∀ j, x j ≠ 0) ∧ ∀ i, (∑ j, A i j * x j) ≠ 0

def RawAffine {p n : ℕ} (A : Matrix (Fin n) (Fin n) (ZMod p)) : Prop :=
  ∀ a b : Fin n → ZMod p, ∃ x : Fin n → ZMod p,
    (∀ j, x j ≠ a j) ∧ ∀ i, (∑ j, A i j * x j) ≠ b i

theorem raw_same_dimension_iff {p n : ℕ} [Fact p.Prime] (hp : 5 ≤ p) :
    (∀ A : Matrix (Fin n) (Fin n) (ZMod p), A.det ≠ 0 → RawHomogeneous A) ↔
    (∀ A : Matrix (Fin n) (Fin n) (ZMod p), A.det ≠ 0 → RawAffine A) := by
  constructor
  · intro h A hA
    exact (affine_iff_avoid A).mp
      (affine_of_same_dimension (by rw [ZMod.card]; omega) h A hA)
  · intro h A hA
    exact h A hA 0 0

theorem raw_affine_eleven {p n : ℕ} [Fact p.Prime] (hp : 5 ≤ p) (hn : n ≤ 11)
    (A : Matrix (Fin n) (Fin n) (ZMod p)) (hA : A.det ≠ 0)
    (a b : Fin n → ZMod p) :
    ∃ x : Fin n → ZMod p, (∀ j, x j ≠ a j) ∧ ∀ i, (∑ j, A i j * x j) ≠ b i :=
  (affine_iff_avoid A).mp (affine_prime_dim_le_eleven hp hn A hA) a b

theorem raw_symmetric_affine_twenty_three {p n : ℕ} [Fact p.Prime] (hp : 5 ≤ p) (hn : n ≤ 23)
    (A : Matrix (Fin n) (Fin n) (ZMod p)) (hA : A.det ≠ 0)
    (hs : ∀ i j, A i j = A j i) (a b : Fin n → ZMod p) :
    ∃ x : Fin n → ZMod p, (∀ j, x j ≠ a j) ∧ ∀ i, (∑ j, A i j * x j) ≠ b i := by
  have symm : A.IsSymm := by
    ext i j
    exact hs j i
  exact (affine_iff_avoid A).mp (symmetric_affine_dim_le_twenty_three hp hn A hA symm) a b

theorem raw_least_symmetric_affine_failure {p r : ℕ} [Fact p.Prime] (hp : 5 ≤ p)
    (below : ∀ d < r, ∀ A : Matrix (Fin d) (Fin d) (ZMod p), A.det ≠ 0 → RawHomogeneous A)
    (bad : ∃ A : Matrix (Fin r) (Fin r) (ZMod p), A.det ≠ 0 ∧ ¬ RawHomogeneous A) :
    (∀ d < r+r, ∀ S : Matrix (Fin d) (Fin d) (ZMod p),
      S.det ≠ 0 → S.IsSymm → RawAffine S) ∧
    ∃ S : Matrix (Fin (r+r)) (Fin (r+r)) (ZMod p), S.det ≠ 0 ∧ S.IsSymm ∧ ¬ RawAffine S := by
  obtain ⟨A, hA, hbad⟩ := bad
  cases r with
  | zero => exact (hbad ⟨0, fun i => i.elim0, fun i => i.elim0⟩).elim
  | succ k =>
    constructor
    · intro d hd S hS hs
      have hsmall : ∀ m ≤ k, AtDim (ZMod p) m := by
        intro m hm
        exact affine_of_same_dimension (by rw [ZMod.card]; omega)
          (below m (by omega))
      exact (affine_iff_avoid S).mp
        (symmetric_affine_upto_double hp hsmall (by omega) S hS hs)
    · refine ⟨symmetricLift A, symmetricLift_det_ne_zero A hA, symmetricLift_isSymm A, ?_⟩
      intro ha
      have hlift : AffineAJT (symmetricLift A) := (affine_iff_avoid _).mpr ha
      have ha' := (affine_symmetricLift_iff A).mp hlift
      exact hbad (homogeneous_of_affine A ha'.1)

theorem raw_affine_twelve_prime_ge_seven {p : ℕ} [Fact p.Prime] (hp : 7 ≤ p)
    (A : Matrix (Fin 12) (Fin 12) (ZMod p)) (hA : A.det ≠ 0)
    (a b : Fin 12 → ZMod p) :
    ∃ x : Fin 12 → ZMod p, (∀ j, x j ≠ a j) ∧ ∀ i, (∑ j, A i j * x j) ≠ b i := by
  apply (affine_iff_avoid A).mp _ a b
  apply affine_of_same_dimension (by rw [ZMod.card]; omega) _ A hA
  intro B hB
  apply hasAJTVector_prime_dim_lt B hB
  calc 12 < 2 ^ 5 := by decide
       _ ≤ 2 ^ (p - 2) := Nat.pow_le_pow_right (by decide) (by omega)

end SolSameDimensionAudit

#print AtDim
#print AffineAJT
#print SolSameDimensionAudit.RawHomogeneous
#print SolSameDimensionAudit.RawAffine
#check affine_of_same_dimension
#check affine_prime_dim_le_eleven
#check symmetric_affine_dim_le_twenty_three
#check affine_or_transpose
#check affine_symmetricLift_iff
#check symmetric_dimensions_iff
#check SolSameDimensionAudit.raw_same_dimension_iff
#check SolSameDimensionAudit.raw_affine_eleven
#check SolSameDimensionAudit.raw_symmetric_affine_twenty_three
#check SolSameDimensionAudit.raw_least_symmetric_affine_failure
#print axioms affine_of_same_dimension
#print axioms affine_prime_dim_le_eleven
#print axioms symmetric_affine_dim_le_twenty_three
#print axioms affine_or_transpose
#print axioms affine_symmetricLift_iff
#print axioms symmetric_dimensions_iff
#print axioms SolSameDimensionAudit.raw_same_dimension_iff
#print axioms SolSameDimensionAudit.raw_affine_eleven
#print axioms SolSameDimensionAudit.raw_symmetric_affine_twenty_three
#print axioms SolSameDimensionAudit.raw_least_symmetric_affine_failure

#check SolSameDimensionAudit.raw_affine_twelve_prime_ge_seven
#print axioms SolSameDimensionAudit.raw_affine_twelve_prime_ge_seven

import Task.CoverMinimal
import Task.WeightTransform

open Finset Matrix

namespace AlonJaegerTarsi.WeightTransform

local instance : Fact (Nat.Prime 5) := ⟨by decide⟩

/-- A minimal counterexample has no enumerator entry in the indicated small
weights. The boundary with five moving forms includes weights (2,3) and (3,2). -/
theorem primal_counts_zero {n : ℕ} (hsmall : Cover.Below (ZMod 5) n)
    (A : Matrix (Fin n) (Fin n) (ZMod 5)) (hA : A.det ≠ 0) (hbad : ¬HasAJTVector A)
    (i j : ℕ) (hi : 0 < i) (hij : i+j < 5 ∨ (i+j ≤ 5 ∧ 1 < i ∧ 1 < j)) :
    counts A i j = 0 := by
  classical
  unfold counts
  rw [Finset.card_eq_zero]
  apply eq_empty_iff_forall_notMem.mpr
  intro x hx
  obtain ⟨hxi, hyj⟩ := (mem_filter.mp hx).2
  have hxn : x ≠ 0 := by
    intro e
    have hzero : wt (0 : Fin n → ZMod 5) = 0 := by simp [wt]
    rw [e, hzero] at hxi
    omega
  apply hbad
  apply Cover.hasAJTVector_of_small_weights hsmall A hA x hxn
  change wt x + wt (A *ᵥ x) < Fintype.card (ZMod 5) ∨
    (wt x + wt (A *ᵥ x) ≤ Fintype.card (ZMod 5) ∧ 1 < wt x ∧ 1 < wt (A *ᵥ x))
  rwa [hxi, hyj, ZMod.card]

end AlonJaegerTarsi.WeightTransform

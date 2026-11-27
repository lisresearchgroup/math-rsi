import Task.MarkedSemanticFourier
import Task.DimensionTen
import Task.PermanentPrimalBox
import Task.PolynomialCertificateEleven
import Task.PolynomialMarkedValues

namespace AlonJaegerTarsi.MarkedEleven

open Matrix Finset WeightTransform

local instance : Fact (Nat.Prime 5) := ⟨by decide⟩

private theorem counts_zero_mismatch (B : Matrix11) (hB : B.det ≠ 0) (i j : ℕ)
    (h : (i=0 ∧ j≠0) ∨ (j=0 ∧ i≠0)) : counts B i j = 0 := by
  classical
  have hinj := Matrix.mulVec_injective_of_isUnit
    ((isUnit_iff_isUnit_det B).mpr (isUnit_iff_ne_zero.mpr hB))
  apply card_filter_eq_zero_iff.mpr
  intro x _ hw
  have eq : wt x = 0 ↔ wt (B *ᵥ x) = 0 := by
    rw [wt_eq_zero, wt_eq_zero]
    exact ⟨fun e => e ▸ B.mulVec_zero, fun e => hinj (e.trans B.mulVec_zero.symm)⟩
  change wt x = i ∧ wt (B *ᵥ x) = j at hw
  omega

theorem actual_primal_forbid (B : Matrix11) (hB : B.det ≠ 0) (hbad : ¬HasAJTVector B)
    (lower : Cover.Below (ZMod 5) 11) (x : Word) :
    ¬primalForbidden (wt x) (wt (B *ᵥ x)) := by
  apply notForbiddenOfCounts B _ x
  intro i j h
  rcases h with h | h | ⟨rfl,rfl⟩ | h | h
  · exact counts_zero_mismatch B hB i j (.inl h)
  · exact counts_zero_mismatch B hB i j (.inr h)
  · exact Nat.eq_zero_of_not_pos fun hc => hbad ((counts_full_pos B).mp hc)
  all_goals
    apply primal_counts_zero_of_box lower B hB hbad i j (by omega)
    rw [ZMod.card]
    omega

attribute [local irreducible] counts wt

set_option maxHeartbeats 2000000 in
theorem actual_dual_forbid (B : Matrix11) (hB : B.det ≠ 0) (hbad : ¬HasAJTVector B)
    (lower : Cover.Below (ZMod 5) 11) (y : Word) :
    ¬dualForbidden (wt (-(Bᵀ *ᵥ y))) (wt y) := by
  apply dualNotForbiddenOfCounts B _ y
  intro i j h
  have ht : Bᵀ.det ≠ 0 := by simpa using hB
  rcases h with hz | hz | ⟨hm, hh⟩
  · exact counts_zero_mismatch Bᵀ ht i j (.inr hz)
  · exact counts_zero_mismatch Bᵀ ht i j (.inl hz)
  obtain ⟨h11,h12,h21⟩ := dual_small_counts_zero B hB hbad lower
  obtain ⟨h13,h31⟩ := dual_one_three_count_zero B hB hbad lower
  have h22 := dual_two_two_count_zero B hB hbad lower
  have hcases : (i=1 ∧ j=1) ∨ (i=1 ∧ j=2) ∨ (i=1 ∧ j=3) ∨ (i=2 ∧ j=1) ∨
      (i=2 ∧ j=2) ∨ (i=3 ∧ j=1) := by omega
  rcases hcases with ⟨rfl,rfl⟩|⟨rfl,rfl⟩|⟨rfl,rfl⟩|⟨rfl,rfl⟩|⟨rfl,rfl⟩|⟨rfl,rfl⟩ <;> assumption

/-- The ordinary weight certificate forces the presence of a word usable by the
five-coordinate transform, in one of the two inverse orientations. -/
theorem normalized_of_bad (A : Matrix11) (hA : A.det ≠ 0) (hbad : ¬HasAJTVector A)
    (lower : Cover.Below (ZMod 5) 11) :
    ∃ B : Matrix11, B.det ≠ 0 ∧ ¬HasAJTVector B ∧ Bᵀ *ᵥ markPrefix 2 = -markPrefix 3 := by
  apply exists_normalized_marked A hA hbad
  by_contra! hz
  have h23 : symCount Aᵀ 2 3 = 0 := by simp [symCount, Nat.eq_zero_of_le_zero hz.1,
    Nat.eq_zero_of_le_zero hz.2]
  have haf := spectrum_full_positive_of_v23_eq_zero (spectrum_of_counterexample A hA hbad lower)
    (by decide) h23
  have hfull : counts A 11 11 = 0 := Nat.eq_zero_of_not_pos fun h => hbad ((counts_full_pos A).mp h)
  simp [symCount, hfull] at haf

end AlonJaegerTarsi.MarkedEleven

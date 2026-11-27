import Task.BalancedAJT
import Task.AffineReduction

open Matrix Finset

namespace AlonJaegerTarsi.BalancedCover

open CharacterMethod

variable {K : Type*} [Field K] [Fintype K] [DecidableEq K] {n p : ℕ} [Fact p.Prime]

theorem balanced_nonzero (hq : 3 < Fintype.card K) : Balanced ((univ : Finset K).erase 0) := by
  refine ⟨⟨1, by simp⟩, fun a _ => ?_⟩
  have hc : ({0,a,-a} : Finset K).card < (univ : Finset K).card :=
    (Finset.card_le_three ..).trans_lt (by simpa using hq)
  obtain ⟨b,_,hb⟩ := exists_mem_notMem_of_card_lt_card hc
  simp only [mem_insert, mem_singleton, not_or] at hb
  exact ⟨b,hb.1,mem_erase.mpr ⟨fun h => hb.2.2 (by linear_combination h),mem_univ _⟩,
    mem_erase.mpr ⟨fun h => hb.2.1 (by linear_combination -h),mem_univ _⟩⟩

theorem combine_normals (A : Matrix (Fin n) (Fin n) (ZMod p))
    (c : Fin n ⊕ Fin n → ZMod p) :
    combine (normals A) c = (c ∘ Sum.inl) + Aᵀ *ᵥ (c ∘ Sum.inr) := by
  funext j
  simp [combine, normals, Fintype.sum_sum_type, Finset.sum_apply, Pi.single_apply, dotProduct,
    mulVec, mul_comm, transpose_apply]

/-- The transpose of any smallest homogeneous counterexample has witnesses for
every affine shift of its outputs. -/
theorem affine_transpose_of_minimum_bad (hp : 5 ≤ p) (hn : 2 ≤ n)
    (hsmall : Cover.Below (ZMod p) n) (A : Matrix (Fin n) (Fin n) (ZMod p)) (hA : A.det ≠ 0)
    (hbad : ¬HasAJTVector A) : AffineReduction.AffineAJT Aᵀ := by
  classical
  let S := (univ : Finset (ZMod p)).erase 0
  have hs : Balanced S := balanced_nonzero (by rw [ZMod.card]; omega)
  intro t
  obtain ⟨c,he⟩ := witnesses_repair (by omega) hn hsmall A hA hbad S hs (-t)
  rw [combine_normals] at he
  have hc (i) : (c i).val ≠ 0 := (mem_erase.mp (c i).property).1
  refine ⟨fun i => (c (.inr i)).val,fun i => hc _,fun i hh => hc (.inl i) ?_⟩
  have h := congrFun he i
  change (c (.inl i)).val + (Aᵀ *ᵥ (fun j => (c (.inr j)).val)) i = -t i at h
  change (Aᵀ *ᵥ (fun j => (c (.inr j)).val)) i + t i = 0 at hh
  linear_combination h - hh

/-- For the original problem it would suffice to show that homogeneous failure
also prevents some affine shift on the other side. -/
theorem conjecture_of_transpose_failure
    (hdual : ∀ (q : ℕ) [Fact q.Prime], 5 ≤ q → ∀ (d : ℕ) (B : Matrix (Fin d) (Fin d) (ZMod q)),
      B.det ≠ 0 → ¬HasAJTVector B → ¬AffineReduction.AffineAJT Bᵀ) : AJTConjecture := by
  intro q _ hq n
  induction n using Nat.strong_induction_on with
  | h n ih =>
    intro A hA
    by_cases hn : 2 ≤ n
    · by_contra hb
      exact hdual q hq n A hA hb (affine_transpose_of_minimum_bad hq hn ih A hA hb)
    · exact hasAJTVector_dim_le_ten hq (by omega) A hA

end AlonJaegerTarsi.BalancedCover

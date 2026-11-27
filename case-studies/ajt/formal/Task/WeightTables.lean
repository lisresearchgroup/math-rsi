import Task.WeightFourier

open Matrix Finset
open scoped BigOperators
namespace AlonJaegerTarsi.WeightTransform

variable {p n : ℕ}

@[simp] theorem wt_zero : wt (0 : Fin n → ZMod p) = 0 := by simp [wt]

@[simp] theorem wt_eq_zero (x : Fin n → ZMod p) : wt x = 0 ↔ x = 0 := by
  classical
  rw [wt, card_eq_zero, filter_eq_empty_iff]
  simp [funext_iff]

@[simp] theorem counts_zero_zero [NeZero p] (A : Matrix (Fin n) (Fin n) (ZMod p)) : counts A 0 0 = 1 := by
  have he (x : Fin n → ZMod p) : (wt x = 0 ∧ wt (A *ᵥ x) = 0) ↔ x = 0 :=
    ⟨fun h => (wt_eq_zero _).mp h.1, by rintro rfl; simp⟩
  have hs : (univ.filter fun x => wt x = 0 ∧ wt (A *ᵥ x) = 0) = {0} := by
    ext x
    simpa only [mem_filter, mem_univ, true_and, mem_singleton] using he x
  rw [counts, hs, card_singleton]

@[simp] theorem kraw_zero_weight (a : ℕ) : kraw p n a 0 = (n.choose a : ℤ) * (p-1 : ℕ)^a := by
  unfold kraw
  rw [sum_eq_single 0]
  · simp [mul_comm]
  · intro i _ hi
    cases i with
    | zero => exact (hi rfl).elim
    | succ i => simp
  · simp

theorem sphere_card [NeZero p] (a : ℕ) :
    (univ.filter fun x : Fin n → ZMod p => wt x = a).card = n.choose a * (p-1)^a := by
  have he := sphere_transform (0 : Fin n → ZMod p) a
  simp only [dotProduct_zero, AddChar.map_zero_eq_one, sum_const, nsmul_eq_mul, mul_one,
    wt_zero, kraw_zero_weight, Int.cast_mul, Int.cast_natCast, Int.cast_pow] at he
  exact_mod_cast he

private theorem eq_idx (x : Fin n → ZMod p) (i : Fin (n+1)) :
    (⟨wt x, Nat.lt_succ_of_le (wt_le x)⟩ : Fin (n+1)) = i ↔ wt x = i := Fin.ext_iff

variable [NeZero p]

theorem row_sum (A : Matrix (Fin n) (Fin n) (ZMod p)) (i : ℕ) :
    ∑ j : Fin (n+1), counts A i j = n.choose i * (p-1)^i := by
  rw [← sphere_card (p := p)]
  have h := Finset.card_eq_sum_card_fiberwise
    (s := univ.filter fun x : Fin n → ZMod p => wt x = i)
    (f := fun x => (⟨wt (A *ᵥ x), Nat.lt_succ_of_le (wt_le _)⟩ : Fin (n+1)))
    (t := univ) (fun _ _ => mem_univ _)
  simpa only [filter_filter, counts, eq_idx] using h.symm

theorem col_sum [Fact p.Prime] (A : Matrix (Fin n) (Fin n) (ZMod p)) (hA : A.det ≠ 0) (j : ℕ) :
    ∑ i : Fin (n+1), counts A i j = n.choose j * (p-1)^j := by
  classical
  rw [← sphere_card (p := p)]
  let s := univ.filter fun x : Fin n → ZMod p => wt (A *ᵥ x) = j
  have h := Finset.card_eq_sum_card_fiberwise
    (s := s) (f := fun x => (⟨wt x, Nat.lt_succ_of_le (wt_le x)⟩ : Fin (n+1)))
    (t := univ) (fun _ _ => mem_univ _)
  have h₁ : (∑ i : Fin (n+1), counts A i j) = s.card := by
    simpa only [s, counts, filter_filter, eq_idx, and_comm] using h.symm
  rw [h₁]
  have unit := (Matrix.isUnit_iff_isUnit_det A).mpr hA.isUnit
  exact Finset.card_bijective _ ⟨Matrix.mulVec_injective_iff_isUnit.mpr unit,
    Matrix.mulVec_surjective_iff_isUnit.mpr unit⟩ (by simp [s])

/-- The two tables used by the certificate are each averaged with their own
transpose and scaled by two to retain integral entries. -/
def symCount (A : Matrix (Fin n) (Fin n) (ZMod p)) (i j : Fin (n+1)) : ℤ :=
  (counts A i j : ℤ) + counts A j i

@[simp] theorem symCount_zero_zero (A : Matrix (Fin n) (Fin n) (ZMod p)) :
    symCount A 0 0 = 2 := by simp [symCount]

theorem symCount_row [Fact p.Prime] (A : Matrix (Fin n) (Fin n) (ZMod p))
    (hA : A.det ≠ 0) (i : Fin (n+1)) :
    ∑ j, symCount A i j = 2 * (n.choose i * (p-1)^(i : ℕ) : ℕ) := by
  simp only [symCount, sum_add_distrib, ← Nat.cast_sum, row_sum, col_sum A hA]
  ring

theorem symCount_macWilliams (A : Matrix (Fin n) (Fin n) (ZMod p)) (a b : Fin (n+1)) :
    (p : ℤ)^n * symCount Aᵀ a b =
      ∑ i : Fin (n+1), ∑ j : Fin (n+1), symCount A i j * kraw p n a i * kraw p n b j := by
  simp only [symCount, mul_add, add_mul, sum_add_distrib, macWilliams A]
  rw [add_comm]
  congr 1
  rw [Finset.sum_comm]
  apply sum_congr rfl
  intro i _
  apply sum_congr rfl
  intro j _
  ring

end AlonJaegerTarsi.WeightTransform

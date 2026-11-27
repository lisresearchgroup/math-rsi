import Task.Basic

namespace AlonJaegerTarsi.Cover

open Matrix Finset
open scoped BigOperators

section FiniteField

variable {F R C : Type*} [Field F] [Fintype F] [Fintype C] [DecidableEq C]

/-- Move along a coordinate line, retaining every row in a specified family.
Rows with zero slope must already have nonzero value. -/
theorem avoidOnLine [DecidableEq F] (A : Matrix R C F) (s : Finset R) (j : C) (x : C → F)
    (hx : ∀ k, k ≠ j → x k ≠ 0)
    (hfixed : ∀ i ∈ s, A i j = 0 → (A *ᵥ x) i ≠ 0)
    (hcount : (s.filter (fun i => A i j ≠ 0)).card + 1 < Fintype.card F) :
    ∃ c : F, NowhereZero (x + Pi.single j c) ∧ ∀ i ∈ s, (A *ᵥ (x + Pi.single j c)) i ≠ 0 := by
  classical
  let forbidden (i : R) := -(A *ᵥ x) i / A i j
  let bad := insert (-x j) ((s.filter (fun i => A i j ≠ 0)).image forbidden)
  have hb : bad.card < (univ : Finset F).card := by
    refine (Finset.card_insert_le _ _).trans_lt ?_
    exact (Nat.add_le_add_right Finset.card_image_le 1).trans_lt (by simpa using hcount)
  obtain ⟨c, _, hc⟩ := Finset.exists_mem_notMem_of_card_lt_card hb
  have hc' : c ≠ -x j ∧ c ∉ (s.filter (fun i => A i j ≠ 0)).image forbidden := by
    simpa [bad] using hc
  refine ⟨c, ?_, ?_⟩
  · intro k
    by_cases hk : k = j
    · subst k
      simpa [Pi.single_eq_same, add_eq_zero_iff_neg_eq] using hc'.1.symm
    · simpa [Pi.single_eq_of_ne hk] using hx k hk
  · intro i hi
    simp only [Matrix.mulVec_add, Matrix.mulVec_single, Pi.add_apply]
    change (A *ᵥ x) i + A i j * c ≠ 0
    by_cases hij : A i j = 0
    · simpa [hij] using hfixed i hi hij
    · intro heq
      have hcroot : c = forbidden i := by
        apply (eq_div_iff hij).2
        linear_combination heq
      exact hc'.2 (hcroot ▸ Finset.mem_image_of_mem forbidden (Finset.mem_filter.mpr ⟨hi, hij⟩))

/-- Any family of fewer than |F|-1 nonzero linear forms is simultaneously
nonzero at some point of the coordinate torus. -/
theorem avoidFewRows [DecidableEq F] (A : Matrix R C F) (s : Finset R)
    (hrows : ∀ i ∈ s, ∃ j, A i j ≠ 0)
    (hcount : s.card + 1 < Fintype.card F) :
    ∃ x : C → F, NowhereZero x ∧ ∀ i ∈ s, (A *ᵥ x) i ≠ 0 := by
  classical
  induction s using Finset.induction_on with
  | empty => exact ⟨fun _ => 1, fun _ => one_ne_zero, by simp⟩
  | @insert r s hr ih =>
    have hle : s.card ≤ (insert r s).card := Finset.card_le_card (Finset.subset_insert ..)
    obtain ⟨x, hx, hAx⟩ := ih (fun i hi => hrows i (Finset.mem_insert_of_mem hi))
      ((Nat.add_le_add_right hle 1).trans_lt hcount)
    obtain ⟨j, hj⟩ := hrows r (Finset.mem_insert_self ..)
    obtain ⟨c, hc, hAc⟩ := avoidOnLine A (insert r s) j x (fun k _ => hx k)
      (fun i hi hz => by
        rcases Finset.mem_insert.mp hi with rfl | h
        · exact (hj hz).elim
        · exact hAx i h) ((Nat.add_le_add_right (Finset.card_filter_le (insert r s) (fun i => A i j ≠ 0)) 1).trans_lt hcount)
    exact ⟨_, hc, hAc⟩

end FiniteField

section PrimeField

variable {p n : ℕ} [Fact p.Prime]

private theorem hasNonzeroRowEntry (A : Matrix (Fin n) (Fin n) (ZMod p)) (hA : A.det ≠ 0)
    (i : Fin n) : ∃ j, A i j ≠ 0 := by
  by_contra! h
  exact hA (Matrix.det_eq_zero_of_row_eq_zero i h)

/-- When the row count is |F|-1, a column containing both a zero entry and a
nonzero entry splits the constraints into two strictly smaller families. -/
private theorem boundaryOfMixedColumn
    (A : Matrix (Fin n) (Fin n) (ZMod p)) (hA : A.det ≠ 0) (hn : n + 1 = p)
    (j i₀ i₁ : Fin n) (h₀ : A i₀ j = 0) (h₁ : A i₁ j ≠ 0) : HasAJTVector A := by
  classical
  let fixed := univ.filter (fun i => A i j = 0)
  have hf : fixed.card < n := by
    simpa using (Finset.card_lt_univ_of_notMem (s := fixed) (x := i₁) (by simp [fixed, h₁]))
  have hm : (univ.filter (fun i => A i j ≠ 0)).card < n := by
    simpa using (Finset.card_lt_univ_of_notMem
      (s := univ.filter (fun i => A i j ≠ 0)) (x := i₀) (by simp [h₀]))
  obtain ⟨x, hx, hAx⟩ := avoidFewRows A fixed (fun i _ => hasNonzeroRowEntry A hA i)
    (by rw [ZMod.card]; omega)
  obtain ⟨c, hc, hAc⟩ := avoidOnLine A univ j x (fun k _ => hx k)
    (fun i _ hz => hAx i (by simp [fixed, hz])) (by rw [ZMod.card]; omega)
  exact ⟨_, hc, fun i => hAc i (mem_univ _)⟩

/-- At the same boundary, a dense matrix allows one row to be made proportional
to the pivot coordinate along the whole line. Its one forbidden value is
already forbidden by that coordinate. -/
private theorem boundaryOfDense (A : Matrix (Fin n) (Fin n) (ZMod p))
    (hp : 5 ≤ p) (hn : n + 1 = p) (hA : ∀ i j, A i j ≠ 0) : HasAJTVector A := by
  classical
  let j : Fin n := ⟨0, by omega⟩
  let k : Fin n := ⟨1, by omega⟩
  have hkj : k ≠ j := by intro e; have := congrArg Fin.val e; simp [k, j] at this
  have hthree : (3 : ZMod p) ≠ 0 := by
    change ((3 : ℕ) : ZMod p) ≠ 0
    rw [ne_eq, ZMod.natCast_eq_zero_iff]
    intro hd
    have := Nat.le_of_dvd (by decide : 0 < 3) hd
    omega
  let w (i : Fin n) : ZMod p := 1 + (if i = k then 2 else 0) - (if i = j then 1 else 0)
  let x (i : Fin n) := w i / A j i
  have hxj : x j = 0 := by simp [x, w, hkj.symm]
  have hx : ∀ l, l ≠ j → x l ≠ 0 := by
    intro l hlj
    apply div_ne_zero _ (hA j l)
    by_cases hlk : l = k
    · convert hthree using 1
      norm_num [w, hlk, hkj]
    · simp [w, hlj, hlk]
  have hrow : (A *ᵥ x) j = 0 := by
    change (∑ i, A j i * (w i / A j i)) = 0
    have hcancel (i) : A j i * (w i / A j i) = w i := by field_simp [hA j i]
    simp only [hcancel, w, sum_sub_distrib, sum_add_distrib]
    simp only [Finset.sum_ite_eq', Finset.mem_univ, if_true, Finset.sum_const, Finset.card_univ,
      Fintype.card_fin, nsmul_eq_mul, mul_one]
    have hcast : (n : ZMod p) + 1 = 0 := by rw [← Nat.cast_add_one, hn, ZMod.natCast_self]
    linear_combination hcast
  have hcards : (univ.erase j).card < n := by
    simpa using (Finset.card_lt_univ_of_notMem (s := univ.erase j) (x := j) (by simp))
  obtain ⟨c, hc, hAc⟩ := avoidOnLine A (univ.erase j) j x hx
    (fun i _ h => (hA i j h).elim) (by
      rw [ZMod.card]
      have hle := Finset.card_filter_le (univ.erase j) (fun i => A i j ≠ 0)
      omega)
  refine ⟨_, hc, fun i => ?_⟩
  by_cases e : i = j
  · subst i
    have hcn : c ≠ 0 := by simpa [Pi.add_apply, hxj] using hc j
    rw [Matrix.mulVec_add, Matrix.mulVec_single, Pi.add_apply, hrow, zero_add]
    exact mul_ne_zero (hA j j) hcn
  · exact hAc i (by simp [e])

/-- The prime-field AJT conclusion holds in every dimension strictly below p. -/
theorem hasAJTVector_of_dimension_lt (hp : 5 ≤ p) (hn : n < p)
    (A : Matrix (Fin n) (Fin n) (ZMod p)) (hA : A.det ≠ 0) : HasAJTVector A := by
  classical
  by_cases hstrict : n + 1 < p
  · obtain ⟨x, hx, hAx⟩ := avoidFewRows A univ (fun i _ => hasNonzeroRowEntry A hA i)
      (by simpa [ZMod.card] using hstrict)
    exact ⟨x, hx, fun i => hAx i (mem_univ _)⟩
  have heq : n + 1 = p := by omega
  by_cases hd : ∀ i j, A i j ≠ 0
  · exact boundaryOfDense A hp heq hd
  · push Not at hd
    obtain ⟨i, j, hij⟩ := hd
    have hex : ∃ k, A k j ≠ 0 := by
      by_contra! h
      exact hA (Matrix.det_eq_zero_of_column_eq_zero j h)
    obtain ⟨k, hk⟩ := hex
    exact boundaryOfMixedColumn A hA heq j i k hij hk

end PrimeField
end AlonJaegerTarsi.Cover

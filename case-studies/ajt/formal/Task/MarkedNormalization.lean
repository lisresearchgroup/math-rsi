import Task.WeightTransform

namespace AlonJaegerTarsi.WeightTransform

open Matrix Finset

noncomputable section

private abbrev F := ZMod 5

/-- The weight-k word with ones in the first k indices. -/
def markPrefix {n : ℕ} (k : ℕ) (i : Fin n) : ZMod 5 := if i.val < k then 1 else 0

/-- Independent permutations and nonzero scalings of the rows and columns. -/
def RowColumnEquivalent {n : ℕ} (A B : Matrix (Fin n) (Fin n) F) : Prop :=
  ∃ (r c : Fin n → F) (ρ κ : Equiv.Perm (Fin n)), NowhereZero r ∧ NowhereZero c ∧
    B = diagonal r * A.submatrix ρ κ * diagonal c

private theorem orderSupport {n k : ℕ} (x : Fin n → F) (hk : wt x = k) :
    ∃ e : Equiv.Perm (Fin n), ∀ i, x (e i) ≠ 0 ↔ i.val < k := by
  classical
  have hkn : k ≤ n := hk ▸ wt_le x
  let ep : {i : Fin n // i.val < k} ≃ Fin k :=
    { toFun := fun i => ⟨i.1, i.2⟩
      invFun := fun i => ⟨i.castLE hkn, i.2⟩
      left_inv := fun _ => rfl
      right_inv := fun _ => rfl }
  have hsrc : Fintype.card {i : Fin n // i.val < k} = k := by simpa using Fintype.card_congr ep
  have hdst : Fintype.card {i : Fin n // x i ≠ 0} = k := by
    simpa [Fintype.card_subtype, wt] using hk
  let e : {i : Fin n // i.val < k} ≃ {i : Fin n // x i ≠ 0} :=
    Fintype.equivOfCardEq (hsrc.trans hdst.symm)
  exact ⟨e.extendSubtype, fun i => ⟨fun h => by_contra (fun hi => e.extendSubtype_not_mem i hi h),
    e.extendSubtype_mem i⟩⟩

private theorem preserveBad {n : ℕ} (A : Matrix (Fin n) (Fin n) F)
    (r c : Fin n → F) (ρ κ : Equiv.Perm (Fin n)) (hc : NowhereZero c)
    (hbad : ¬HasAJTVector A) : ¬HasAJTVector (diagonal r * A.submatrix ρ κ * diagonal c) := by
  classical
  letI : Fact (Nat.Prime 5) := ⟨by decide⟩
  rintro ⟨x, hx, hy⟩
  let u (j : Fin n) := c (κ.symm j) * x (κ.symm j)
  have hcol : (diagonal c *ᵥ x) ∘ κ.symm = u := funext (fun j => mulVec_diagonal c x (κ.symm j))
  have h (i : Fin n) :
      ((diagonal r * A.submatrix ρ κ * diagonal c) *ᵥ x) i = r i * (A *ᵥ u) (ρ i) := by
    rw [← mulVec_mulVec, ← mulVec_mulVec, mulVec_diagonal, submatrix_mulVec_equiv, hcol]
    rfl
  refine hbad ⟨u, fun j => mul_ne_zero (hc _) (hx _), fun j hj => hy (ρ.symm j) ?_⟩
  rw [h, ρ.apply_symm_apply, hj, mul_zero]

/-- Normalize a given dual word, retaining explicit row and column monomial
equivalence, nonsingularity, and failure of the AJT property. -/
theorem normalizeMarkedWord {n k l : ℕ} (A : Matrix (Fin n) (Fin n) (ZMod 5))
    (hA : A.det ≠ 0) (hbad : ¬HasAJTVector A) (y : Fin n → ZMod 5)
    (hy : wt y = k) (hz : wt (Aᵀ *ᵥ y) = l) :
    ∃ B : Matrix (Fin n) (Fin n) (ZMod 5), B.det ≠ 0 ∧ ¬HasAJTVector B ∧
      RowColumnEquivalent A B ∧ Bᵀ *ᵥ markPrefix k = -markPrefix l := by
  classical
  letI : Fact (Nat.Prime 5) := ⟨by decide⟩
  let z := Aᵀ *ᵥ y
  obtain ⟨ρ, hρ⟩ := orderSupport y hy
  obtain ⟨κ, hκ⟩ := orderSupport z hz
  let r (i : Fin n) : F := if i.val < k then y (ρ i) else 1
  let c (i : Fin n) : F := if i.val < l then -(z (κ i))⁻¹ else 1
  have hr : NowhereZero r := fun i => by
    by_cases hi : i.val < k <;> simp [r, hi, (hρ i).2]
  have hc : NowhereZero c := fun i => by
    by_cases hi : i.val < l <;> simp [c, hi, (hκ i).2]
  let M := A.submatrix ρ κ
  have hM : M.det ≠ 0 := ((Matrix.isUnit_iff_isUnit_det M).mp
    ((Matrix.isUnit_submatrix_equiv ρ κ).mpr ((Matrix.isUnit_iff_isUnit_det A).mpr
      (isUnit_iff_ne_zero.mpr hA)))).ne_zero
  let B := diagonal r * M * diagonal c
  have hB : B.det ≠ 0 := by
    simp only [B, det_mul, det_diagonal]
    exact mul_ne_zero (mul_ne_zero (Finset.prod_ne_zero_iff.mpr fun i _ => hr i) hM)
      (Finset.prod_ne_zero_iff.mpr fun i _ => hc i)
  have hrval : diagonal r *ᵥ markPrefix k = y ∘ ρ := by
    funext i
    rw [mulVec_diagonal]
    by_cases hi : i.val < k
    · simp [markPrefix, r, hi]
    · simp [markPrefix, r, hi, not_ne_iff.mp (mt (hρ i).1 hi)]
  have hcval : diagonal c *ᵥ (z ∘ κ) = -markPrefix l := by
    funext i
    rw [mulVec_diagonal]
    by_cases hi : i.val < l
    · simp [markPrefix, c, hi, (hκ i).2 hi]
    · simp [markPrefix, c, hi, not_ne_iff.mp (mt (hκ i).1 hi)]
  refine ⟨B, hB, preserveBad A r c ρ κ hc hbad, ⟨r,c,ρ,κ,hr,hc,rfl⟩, ?_⟩
  rw [show Bᵀ = diagonal c * (Mᵀ * diagonal r) from by simp [B],
    ← mulVec_mulVec, ← mulVec_mulVec, hrval]
  have hMy : Mᵀ *ᵥ (y ∘ ρ) = z ∘ κ := by
    rw [show Mᵀ = Aᵀ.submatrix κ ρ from rfl, submatrix_mulVec_equiv]
    simp [Function.comp_assoc, z]
  rw [hMy, hcval]

private theorem wordOfCounts {n k l : ℕ} (A : Matrix (Fin n) (Fin n) F)
    (h : 0 < counts A k l) : ∃ y, wt y = k ∧ wt (A *ᵥ y) = l := by
  obtain ⟨y, hy⟩ := Finset.card_pos.mp h
  exact ⟨y, (Finset.mem_filter.mp hy).2⟩

/-- Orient the marked word by using the original matrix or its inverse, then
normalize both supports to their initial positions. -/
theorem exists_normalized_marked_with_equiv (A : Matrix (Fin 11) (Fin 11) (ZMod 5))
    (hA : A.det ≠ 0) (hbad : ¬HasAJTVector A)
    (hword : 0 < counts Aᵀ 2 3 ∨ 0 < counts Aᵀ 3 2) :
    ∃ B : Matrix (Fin 11) (Fin 11) (ZMod 5), B.det ≠ 0 ∧ ¬HasAJTVector B ∧
      (RowColumnEquivalent A B ∨ RowColumnEquivalent A⁻¹ B) ∧
      Bᵀ *ᵥ markPrefix 2 = -markPrefix 3 := by
  classical
  letI : Fact (Nat.Prime 5) := ⟨by decide⟩
  rcases hword with h | h
  · obtain ⟨y, hy, hz⟩ := wordOfCounts Aᵀ h
    obtain ⟨B, hB, hb, he, hp⟩ := normalizeMarkedWord A hA hbad y hy hz
    exact ⟨B, hB, hb, .inl he, hp⟩
  · obtain ⟨y, hy, hz⟩ := wordOfCounts Aᵀ h
    have unit : IsUnit A.det := isUnit_iff_ne_zero.mpr hA
    have hinv : A⁻¹.det ≠ 0 := by simpa using inv_ne_zero hA
    have badInv : ¬HasAJTVector A⁻¹ := by
      rintro ⟨x, hx, hx'⟩
      exact hbad ⟨A⁻¹ *ᵥ x, hx', by simpa [mulVec_mulVec, A.mul_nonsing_inv unit] using hx⟩
    have hback : wt ((A⁻¹)ᵀ *ᵥ (Aᵀ *ᵥ y)) = 3 := by
      simpa [mulVec_mulVec, ← Matrix.transpose_mul, A.mul_nonsing_inv unit] using hy
    obtain ⟨B, hB, hb, he, hp⟩ := normalizeMarkedWord A⁻¹ hinv badInv (Aᵀ *ᵥ y) hz hback
    exact ⟨B, hB, hb, .inr he, hp⟩

/-- Consumable matrix form for the marked spectrum calculation. -/
theorem exists_normalized_marked (A : Matrix (Fin 11) (Fin 11) (ZMod 5))
    (hA : A.det ≠ 0) (hbad : ¬HasAJTVector A)
    (hword : 0 < counts Aᵀ 2 3 ∨ 0 < counts Aᵀ 3 2) :
    ∃ B : Matrix (Fin 11) (Fin 11) (ZMod 5), B.det ≠ 0 ∧ ¬HasAJTVector B ∧
      Bᵀ *ᵥ markPrefix 2 = -markPrefix 3 := by
  obtain ⟨B, hb, hbad', _, hm⟩ := exists_normalized_marked_with_equiv A hA hbad hword
  exact ⟨B, hb, hbad', hm⟩

end
end AlonJaegerTarsi.WeightTransform

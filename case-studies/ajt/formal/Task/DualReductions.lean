import Task.WeightTransform
import Task.PermanentRank

/-! Eliminating a row with at most two nonzero entries in a minimal AJT counterexample. -/

noncomputable section

namespace AlonJaegerTarsi.WeightTransform

open Finset Matrix
open scoped BigOperators

variable {F : Type*} [Field F] [Fintype F] [DecidableEq F] {n : ℕ}

/-- Tie one input coordinate to a scalar multiple of a second coordinate. -/
def identify (j : Fin (n+1)) (k : Fin n) (c : F) :
    (Fin n → F) →ₗ[F] (Fin (n+1) → F) where
  toFun x := j.insertNth (c * x k) x
  map_add' x y := by
    ext z
    induction z using j.succAboveCases <;> simp [mul_add]
  map_smul' a x := by
    ext z
    induction z using j.succAboveCases <;> simp [mul_left_comm]

omit [Fintype F] [DecidableEq F] in
private theorem row_two_sum (A : Matrix (Fin (n+1)) (Fin (n+1)) F) (i j : Fin (n+1))
    (k : Fin n) (hk : ∀ l : Fin n, l ≠ k → A i (j.succAbove l) = 0) (x : Fin (n+1) → F) :
    (A *ᵥ x) i = A i j * x j + A i (j.succAbove k) * x (j.succAbove k) := by
  rw [Matrix.mulVec, dotProduct, Fin.sum_univ_succAbove _ j]
  congr 1
  exact Finset.sum_eq_single k (fun l _ hl => by simp [hk l hl]) (by simp)

private theorem exists_identification (hF : 3 < Fintype.card F)
    (a b u v : F) (ha : a ≠ 0) (huv : a * u + b * v ≠ 0) :
    ∃ c : F, c ≠ 0 ∧ a * c + b ≠ 0 ∧ u ≠ c * v := by
  classical
  let bad : Finset F := {0, -b / a, u / v}
  have hcard : bad.card < Fintype.card F :=
    (Finset.card_le_three (a := (0 : F)) (b := -b/a) (c := u/v)).trans_lt hF
  obtain ⟨c, _, hc⟩ := exists_mem_notMem_of_card_lt_card (s := bad) (t := univ) hcard
  obtain ⟨hc0, hc1, hc2⟩ : c ≠ 0 ∧ c ≠ -b/a ∧ c ≠ u/v := by simpa [bad, not_or] using hc
  refine ⟨c, hc0, fun h => hc1 ((eq_div_iff ha).mpr (by linear_combination h)), ?_⟩
  intro h
  by_cases hv : v = 0
  · exact huv (by simp [h, hv])
  · exact hc2 ((eq_div_iff hv).mpr h.symm)

omit [Fintype F] [DecidableEq F] in
theorem hasAJTVector_of_foldWitness (A : Matrix (Fin (n+1)) (Fin (n+1)) F) (hA : A.det ≠ 0)
    (i j : Fin (n+1)) (k : Fin n) (c : F) (hc : c ≠ 0)
    (w : Fin (n+1) → F) (hAw' : A *ᵥ w = Pi.single i 1)
    (hcKer : w j ≠ c * w (j.succAbove k))
    (lower : ∀ B : Matrix (Fin n) (Fin n) F, B.det ≠ 0 → ∃ z, NowhereZero z ∧
      NowhereZero (B *ᵥ z) ∧ (A *ᵥ identify j k c z) i ≠ 0) :
    HasAJTVector A := by
  classical
  let u : Fin (n+1) → F := Pi.single i 1
  have hAw : A *ᵥ w = u := hAw'
  let f := identify j k c
  let g : (Fin n → F) →ₗ[F] (Fin n → F) :=
    LinearMap.pi fun l => (LinearMap.proj (i.succAbove l)).comp (A.mulVecLin.comp f)
  let B : Matrix (Fin n) (Fin n) F := LinearMap.toMatrix' g
  have hB (z : Fin n → F) (l : Fin n) : (B *ᵥ z) l = (A *ᵥ f z) (i.succAbove l) := by
    rw [show B = LinearMap.toMatrix' g from rfl, LinearMap.toMatrix'_mulVec]
    rfl
  have hBinj : Function.Injective B.mulVec := by
    change Function.Injective B.mulVecLin
    apply LinearMap.ker_eq_bot.mp
    apply LinearMap.ker_eq_bot'.mpr
    intro z hz
    let t := (A *ᵥ f z) i
    have hout : A *ᵥ f z = t • u := by
      ext r
      induction r using i.succAboveCases with
      | x => simp [t, u]
      | p l =>
        have hzero : (B *ᵥ z) l = 0 := congrFun hz l
        simpa [← hB, u, Pi.single_apply] using hzero
    have hf : f z = t • w := by
      apply mulVec_injective_of_isUnit ((isUnit_iff_isUnit_det A).mpr (isUnit_iff_ne_zero.mpr hA))
      rwa [mulVec_smul, hAw]
    have hleft := congrFun hf j
    have hright := congrFun hf (j.succAbove k)
    simp [f, identify] at hleft hright
    have ht : t = 0 := by
      by_contra h
      apply hcKer
      apply mul_left_cancel₀ h
      linear_combination c * hright - hleft
    ext l
    simpa [f, identify, ht] using congrFun hf (j.succAbove l)
  have hdet : B.det ≠ 0 :=
    isUnit_iff_ne_zero.mp ((isUnit_iff_isUnit_det B).mp (mulVec_injective_iff_isUnit.mp hBinj))
  obtain ⟨z, hz, hAz, hactive⟩ := lower B hdet
  refine ⟨f z, ?_, ?_⟩
  · intro r
    induction r using j.succAboveCases with
    | x => simpa [f, identify] using mul_ne_zero hc (hz k)
    | p l => simpa [f, identify] using hz l
  · intro r
    induction r using i.succAboveCases with
    | x => exact hactive
    | p l => exact hB z l ▸ hAz l

omit [Fintype F] [DecidableEq F] in
private theorem hasAJTVector_of_fold (A : Matrix (Fin (n+1)) (Fin (n+1)) F) (hA : A.det ≠ 0)
    (i j : Fin (n+1)) (k : Fin n) (c : F) (hc : c ≠ 0)
    (w : Fin (n+1) → F) (hAw' : A *ᵥ w = Pi.single i 1)
    (hcKer : w j ≠ c * w (j.succAbove k))
    (hactive : ∀ z, NowhereZero z → (A *ᵥ identify j k c z) i ≠ 0)
    (lower : ∀ B : Matrix (Fin n) (Fin n) F, B.det ≠ 0 → HasAJTVector B) :
    HasAJTVector A := by
  apply hasAJTVector_of_foldWitness A hA i j k c hc w hAw' hcKer
  intro B hB
  obtain ⟨z, hz, hBz⟩ := lower B hB
  exact ⟨z, hz, hBz, hactive z hz⟩

/-- Fold two input coordinates together to satisfy a row supported on them. The kernel
of the deleted output row determines one of the forbidden folding coefficients. -/
theorem hasAJTVector_of_row_on_two (A : Matrix (Fin (n+1)) (Fin (n+1)) F)
    (hA : A.det ≠ 0) (hF : 3 < Fintype.card F) (i j : Fin (n+1)) (k : Fin n)
    (hj : A i j ≠ 0) (hk : ∀ l : Fin n, l ≠ k → A i (j.succAbove l) = 0)
    (lower : ∀ B : Matrix (Fin n) (Fin n) F, B.det ≠ 0 → HasAJTVector B) :
    HasAJTVector A := by
  classical
  let u : Fin (n+1) → F := Pi.single i 1
  let w := A⁻¹ *ᵥ u
  have hAw : A *ᵥ w = u := by
    dsimp only [w]
    rw [mulVec_mulVec, A.mul_nonsing_inv (isUnit_iff_ne_zero.mpr hA), one_mulVec]
  have hwi : (A *ᵥ w) i ≠ 0 := by simp [hAw, u]
  rw [row_two_sum A i j k hk] at hwi
  obtain ⟨c, hc, hcRow, hcKer⟩ := exists_identification hF _ _ _ _ hj hwi
  apply hasAJTVector_of_fold A hA i j k c hc w hAw hcKer _ lower
  intro z hz
  rw [row_two_sum A i j k hk]
  simpa [identify, add_mul, mul_assoc] using mul_ne_zero hcRow (hz k)

/-- Every matrix with a row of weight one or two reduces to the immediately smaller dimension. -/
theorem hasAJTVector_of_row_weight_le_two {m : ℕ}
    (A : Matrix (Fin (m+2)) (Fin (m+2)) F) (hA : A.det ≠ 0) (hF : 3 < Fintype.card F)
    (i : Fin (m+2)) (hi : wt (A i) ≤ 2)
    (lower : ∀ B : Matrix (Fin (m+1)) (Fin (m+1)) F, B.det ≠ 0 → HasAJTVector B) :
    HasAJTVector A := by
  classical
  obtain ⟨j, hj⟩ : ∃ j, A i j ≠ 0 := by
    by_contra! h
    exact hA (det_eq_zero_of_row_eq_zero i h)
  let s := univ.filter fun a => A i a ≠ 0
  let t := univ.filter fun l : Fin (m+1) => A i (j.succAbove l) ≠ 0
  have hs : j ∈ s := mem_filter.mpr ⟨mem_univ _, hj⟩
  have hsmall : t.card ≤ 1 := by
    calc
      t.card ≤ (s.erase j).card := card_le_card_of_injOn (fun l => j.succAbove l)
        (fun l hl => mem_erase.mpr ⟨j.succAbove_ne l,
          mem_filter.mpr ⟨mem_univ _, (mem_filter.mp hl).2⟩⟩)
        j.succAbove_right_injective.injOn
      _ ≤ 1 := by
        rw [card_erase_of_mem hs]
        change s.card ≤ 2 at hi
        omega
  obtain ⟨k, hk⟩ := card_le_one_iff_subset_singleton.mp hsmall
  apply hasAJTVector_of_row_on_two A hA hF i j k hj _ lower
  intro l hl
  by_contra hn
  exact hl (mem_singleton.mp (hk (mem_filter.mpr ⟨mem_univ _, hn⟩)))

omit [Fintype F] in
private theorem row_from_dual_weight_one {m : ℕ} (A : Matrix (Fin m) (Fin m) F)
    (x : Fin m → F) (hx : wt x = 1) :
    ∃ i, wt (A i) = wt (Aᵀ *ᵥ x) := by
  classical
  obtain ⟨i, hi⟩ := Finset.card_eq_one.mp (show (univ.filter fun j => x j ≠ 0).card = 1 from hx)
  have hiMem : i ∈ univ.filter (fun j => x j ≠ 0) := by rw [hi]; simp
  have hxi : x i ≠ 0 := (mem_filter.mp hiMem).2
  have hx' : x = Pi.single i (x i) := by
    ext j
    by_cases hji : j = i
    · subst j
      simp
    · have hz : x j = 0 := by
        by_contra hj
        exact hji (mem_singleton.mp (hi ▸ mem_filter.mpr ⟨mem_univ _, hj⟩))
      simp [hji, hz]
  refine ⟨i, ?_⟩
  rw [hx', Matrix.mulVec_single]
  simp [wt, Matrix.col, hxi]

private theorem zero_of_no_vector {m : ℕ} (A : Matrix (Fin m) (Fin m) F) (r s : ℕ)
    (h : ∀ x, wt x = r → wt (A *ᵥ x) ≠ s) : counts A r s = 0 := by
  apply Finset.card_eq_zero.mpr
  apply Finset.filter_eq_empty_iff.mpr
  intro x _ hx
  exact h x hx.1 hx.2

/-- In a minimal counterexample over the five-element field, the transpose has no
weight transitions (1,1), (1,2), or (2,1). -/
theorem dual_small_counts_zero {m : ℕ} (A : Matrix (Fin m) (Fin m) (ZMod 5))
    (hA : A.det ≠ 0) (hbad : ¬ HasAJTVector A)
    (lower : ∀ k < m, ∀ B : Matrix (Fin k) (Fin k) (ZMod 5), B.det ≠ 0 → HasAJTVector B) :
    counts Aᵀ 1 1 = 0 ∧ counts Aᵀ 1 2 = 0 ∧ counts Aᵀ 2 1 = 0 := by
  classical
  letI : Fact (Nat.Prime 5) := ⟨by decide⟩
  have h5 : 3 < Fintype.card (ZMod 5) := by rw [ZMod.card]; decide
  cases m with
  | zero => exact (hbad (PermanentApproach.hasAJTVector_prime_dim_lt A hA (by decide))).elim
  | succ m =>
    cases m with
    | zero => exact (hbad (PermanentApproach.hasAJTVector_prime_dim_lt A hA (by decide))).elim
    | succ m =>
      have short (B : Matrix (Fin (m+2)) (Fin (m+2)) (ZMod 5)) (hB : B.det ≠ 0)
          (hbadB : ¬HasAJTVector B) (x : Fin (m+2) → ZMod 5) (hw : wt x = 1) :
          2 < wt (Bᵀ *ᵥ x) := by
        by_contra! hv
        obtain ⟨i, hi⟩ := row_from_dual_weight_one B x hw
        exact hbadB (hasAJTVector_of_row_weight_le_two B hB h5 i (hi.le.trans hv)
          (lower _ (by omega)))
      have hunit : IsUnit A.det := isUnit_iff_ne_zero.mpr hA
      have hinv : A⁻¹.det ≠ 0 := by simpa using inv_ne_zero hA
      have hbadinv : ¬ HasAJTVector A⁻¹ := by
        rintro ⟨z, hz, hy⟩
        exact hbad ⟨A⁻¹ *ᵥ z, hy, by simpa [mulVec_mulVec, A.mul_nonsing_inv hunit] using hz⟩
      refine ⟨zero_of_no_vector _ _ _ (fun x hx => ?_),
        zero_of_no_vector _ _ _ (fun x hx => ?_), zero_of_no_vector _ _ _ (fun x hx => ?_)⟩
      · have h := short A hA hbad x hx
        omega
      · have h := short A hA hbad x hx
        omega
      · intro hy
        have h := short A⁻¹ hinv hbadinv (Aᵀ *ᵥ x) hy
        rw [mulVec_mulVec, ← Matrix.transpose_mul, A.mul_nonsing_inv hunit, transpose_one,
          one_mulVec, hx] at h
        omega

omit [Fintype F] in
private theorem relation_of_weight_two (v : Fin (n+1) → F) (hv : wt v = 2) :
    ∃ (j : Fin (n+1)) (k : Fin n) (c : F), c ≠ 0 ∧
      ∀ z, v ⬝ᵥ z = 0 ↔ z j = c * z (j.succAbove k) := by
  classical
  obtain ⟨j, j', hjj, hsupport⟩ := Finset.card_eq_two.mp hv
  obtain ⟨k, hk⟩ := Fin.exists_succAbove_eq hjj.symm
  subst j'
  have hmem (r : Fin (n+1)) : v r ≠ 0 ↔ r = j ∨ r = j.succAbove k := by
    have := Finset.ext_iff.mp hsupport r
    simpa using this
  have ha := (hmem j).2 (Or.inl rfl)
  have hb := (hmem (j.succAbove k)).2 (Or.inr rfl)
  refine ⟨j, k, -v (j.succAbove k)/v j, div_ne_zero (neg_ne_zero.mpr hb) ha, ?_⟩
  intro z
  rw [dotProduct, Fin.sum_univ_succAbove _ j, Finset.sum_eq_single k]
  · rw [div_mul_eq_mul_div, eq_div_iff ha]
    constructor <;> intro he <;> linear_combination he
  · intro l _ hl
    have hzero : v (j.succAbove l) = 0 := by
      by_contra hn
      rcases (hmem _).1 hn with h | h
      · exact j.succAbove_ne l h
      · exact hl (j.succAbove_right_injective h)
    simp [hzero]
  · simp

omit [Fintype F] in
/-- A relation supported on exactly two input and two output coordinates defines two
coordinate hyperplanes on which deletion preserves the nowhere-zero constraints. -/
theorem hasAJTVector_of_dual_two_two (A : Matrix (Fin (n+1)) (Fin (n+1)) F) (hA : A.det ≠ 0)
    (v : Fin (n+1) → F) (hv : wt v = 2) (ht : wt (Aᵀ *ᵥ v) = 2)
    (lower : ∀ B : Matrix (Fin n) (Fin n) F, B.det ≠ 0 → HasAJTVector B) :
    HasAJTVector A := by
  classical
  obtain ⟨i, l, b, hb, hOut⟩ := relation_of_weight_two v hv
  obtain ⟨j, k, c, hc, hIn⟩ := relation_of_weight_two (Aᵀ *ᵥ v) ht
  let f := identify j k c
  let g : (Fin n → F) →ₗ[F] (Fin n → F) :=
    LinearMap.pi fun r => (LinearMap.proj (i.succAbove r)).comp (A.mulVecLin.comp f)
  let B : Matrix (Fin n) (Fin n) F := LinearMap.toMatrix' g
  have hB (z : Fin n → F) (r : Fin n) : (B *ᵥ z) r = (A *ᵥ f z) (i.succAbove r) := by
    rw [show B = LinearMap.toMatrix' g from rfl, LinearMap.toMatrix'_mulVec]
    rfl
  have hpair (z : Fin n → F) : (A *ᵥ f z) i = b * (A *ᵥ f z) (i.succAbove l) := by
    apply (hOut _).mp
    rw [dotProduct_mulVec, ← mulVec_transpose]
    apply (hIn _).mpr
    simp [f, identify]
  have hBinj : Function.Injective B.mulVec := by
    change Function.Injective B.mulVecLin
    apply LinearMap.ker_eq_bot.mp
    apply LinearMap.ker_eq_bot'.mpr
    intro z hz
    have hrest (r : Fin n) : (A *ᵥ f z) (i.succAbove r) = 0 := hB z r ▸ congrFun hz r
    have hzA : A *ᵥ f z = 0 := by
      ext a
      induction a using i.succAboveCases with
      | x => simp [hpair, hrest]
      | p r => exact hrest r
    have hfz : f z = 0 :=
      mulVec_injective_of_isUnit ((isUnit_iff_isUnit_det A).mpr (isUnit_iff_ne_zero.mpr hA))
        (hzA.trans (A.mulVec_zero).symm)
    ext r
    simpa [f, identify] using congrFun hfz (j.succAbove r)
  have hdet : B.det ≠ 0 :=
    isUnit_iff_ne_zero.mp ((isUnit_iff_isUnit_det B).mp (mulVec_injective_iff_isUnit.mp hBinj))
  obtain ⟨z, hz, hAz⟩ := lower B hdet
  refine ⟨f z, ?_, ?_⟩
  · intro r
    induction r using j.succAboveCases with
    | x => simpa [f, identify] using mul_ne_zero hc (hz k)
    | p a => simpa [f, identify] using hz a
  · intro r
    induction r using i.succAboveCases with
    | x => rw [hpair, ← hB]; exact mul_ne_zero hb (hAz l)
    | p a => exact hB z a ▸ hAz a

theorem dual_two_two_count_zero {m : ℕ} (A : Matrix (Fin m) (Fin m) (ZMod 5))
    (hA : A.det ≠ 0) (hbad : ¬ HasAJTVector A)
    (lower : ∀ k < m, ∀ B : Matrix (Fin k) (Fin k) (ZMod 5), B.det ≠ 0 → HasAJTVector B) :
    counts Aᵀ 2 2 = 0 := by
  letI : Fact (Nat.Prime 5) := ⟨by decide⟩
  apply zero_of_no_vector
  intro x hx hy
  cases m with
  | zero => simp [wt] at hx
  | succ m => exact hbad (hasAJTVector_of_dual_two_two A hA x hx hy (lower _ (by omega)))

omit [Fintype F] in
private theorem three_sum (A : Matrix (Fin (n+1)) (Fin (n+1)) F)
    {i a b c : Fin (n+1)} (hab : a ≠ b) (hac : a ≠ c) (hbc : b ≠ c)
    (hs : (univ.filter fun j => A i j ≠ 0) = {a,b,c}) (v : Fin (n+1) → F) :
    (A *ᵥ v) i = A i a * v a + A i b * v b + A i c * v c := by
  classical
  change ∑ j, A i j * v j = _
  calc
    _ = ∑ j ∈ (univ.filter fun j => A i j ≠ 0), A i j * v j := by
      refine (sum_subset (filter_subset _ _) ?_).symm
      intro j _ hj
      have : A i j = 0 := by simpa using hj
      simp [this]
    _ = _ := by rw [hs]; simp [hab, hac, hbc, add_assoc]

omit [Fintype F] in
/-- For a three-term row in odd characteristic a pair of its terms can be cancelled
without losing invertibility after deleting the row. -/
theorem hasAJTVector_of_row_weight_three (A : Matrix (Fin (n+1)) (Fin (n+1)) F)
    (hA : A.det ≠ 0) (h2 : (2 : F) ≠ 0) (i : Fin (n+1)) (hi : wt (A i) = 3)
    (lower : ∀ B : Matrix (Fin n) (Fin n) F, B.det ≠ 0 → HasAJTVector B) : HasAJTVector A := by
  classical
  let w := A⁻¹ *ᵥ Pi.single i 1
  have hAw : A *ᵥ w = Pi.single i 1 := by
    dsimp only [w]
    rw [mulVec_mulVec, A.mul_nonsing_inv (isUnit_iff_ne_zero.mpr hA), one_mulVec]
  have fold (a b c : Fin (n+1)) (hab : a ≠ b) (hac : a ≠ c) (hbc : b ≠ c)
      (hs : (univ.filter fun j => A i j ≠ 0) = {a,b,c})
      (hne : A i a * w a + A i b * w b ≠ 0) : HasAJTVector A := by
    obtain ⟨k, rfl⟩ := Fin.exists_succAbove_eq hab.symm
    obtain ⟨l, rfl⟩ := Fin.exists_succAbove_eq hac.symm
    have hmem (r : Fin (n+1)) : A i r ≠ 0 ↔ r = a ∨ r = a.succAbove k ∨ r = a.succAbove l := by
      simpa using Finset.ext_iff.mp hs r
    have ha := (hmem a).2 (Or.inl rfl)
    have hb := (hmem _).2 (Or.inr (Or.inl rfl))
    have hd := (hmem _).2 (Or.inr (Or.inr rfl))
    let v := -A i (a.succAbove k) / A i a
    have hv : v ≠ 0 := div_ne_zero (neg_ne_zero.mpr hb) ha
    have hcancel : A i a * v + A i (a.succAbove k) = 0 := by
      dsimp [v]
      field_simp
      ring
    apply hasAJTVector_of_fold A hA i a k v hv w hAw _ _ lower
    · intro h
      apply hne
      rw [h]
      linear_combination w (a.succAbove k) * hcancel
    · intro z hz
      rw [three_sum A hab hac hbc hs]
      simp only [identify, LinearMap.coe_mk, AddHom.coe_mk, Fin.insertNth_apply_same, Fin.insertNth_apply_succAbove]
      have hpart : A i a * (v * z k) + A i (a.succAbove k) * z k = 0 := by
        linear_combination z k * hcancel
      rw [hpart, zero_add]
      exact mul_ne_zero hd (hz l)
  obtain ⟨a,b,c,hab,hac,hbc,hs⟩ := Finset.card_eq_three.mp hi
  by_cases h1 : A i a * w a + A i b * w b = 0
  · by_cases h2pair : A i a * w a + A i c * w c = 0
    · apply fold b c a hbc hab.symm hac.symm (by rw [hs]; ext r; simp; tauto)
      intro h3
      have hsum : (A *ᵥ w) i ≠ 0 := by simp [hAw]
      rw [three_sum A hab hac hbc hs] at hsum
      exact (mul_ne_zero h2 hsum) (by linear_combination h1 + h2pair + h3)
    · exact fold a c b hac hab hbc.symm (by rw [hs]; ext r; simp; tauto) h2pair
  · exact fold a b c hab hac hbc hs h1

/-- The two transpose entries corresponding to a three-term row of the matrix or its inverse. -/
theorem dual_one_three_count_zero {m : ℕ} (A : Matrix (Fin m) (Fin m) (ZMod 5))
    (hA : A.det ≠ 0) (hbad : ¬ HasAJTVector A)
    (lower : ∀ k < m, ∀ B : Matrix (Fin k) (Fin k) (ZMod 5), B.det ≠ 0 → HasAJTVector B) :
    counts Aᵀ 1 3 = 0 ∧ counts Aᵀ 3 1 = 0 := by
  classical
  letI : Fact (Nat.Prime 5) := ⟨by decide⟩
  cases m with
  | zero => simp [counts, wt]
  | succ m =>
    have short (B : Matrix (Fin (m+1)) (Fin (m+1)) (ZMod 5)) (hB : B.det ≠ 0)
        (hbadB : ¬ HasAJTVector B) (x : Fin (m+1) → ZMod 5)
        (hw : wt x = 1) (hv : wt (Bᵀ *ᵥ x) = 3) : False := by
      obtain ⟨i, hi⟩ := row_from_dual_weight_one B x hw
      exact hbadB (hasAJTVector_of_row_weight_three B hB (by decide) i (hi.trans hv)
        (lower _ (by omega)))
    have hunit : IsUnit A.det := isUnit_iff_ne_zero.mpr hA
    have hinv : A⁻¹.det ≠ 0 := by simpa using inv_ne_zero hA
    have hbadinv : ¬ HasAJTVector A⁻¹ := by
      rintro ⟨z, hz, hy⟩
      exact hbad ⟨A⁻¹ *ᵥ z, hy, by simpa [mulVec_mulVec, A.mul_nonsing_inv hunit] using hz⟩
    refine ⟨zero_of_no_vector _ _ _ (short A hA hbad), zero_of_no_vector _ _ _ ?_⟩
    intro x hx hy
    apply short A⁻¹ hinv hbadinv (Aᵀ *ᵥ x) hy
    simpa [mulVec_mulVec, ← Matrix.transpose_mul, A.mul_nonsing_inv hunit] using hx

end AlonJaegerTarsi.WeightTransform

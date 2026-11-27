import Task.CoverApproach

namespace AlonJaegerTarsi.Cover

open Finset Matrix
open scoped BigOperators

section LinearForms

variable {K V I : Type*} [Field K] [Fintype K] [AddCommGroup V] [Module K V]

/-- Fewer than |K| proper affine hyperplanes cannot cover an affine space.
The parameter on a line through two points excludes at most one value per form. -/
theorem avoidAffineForms (f : I → V →ₗ[K] K) (b : I → K) (s : Finset I)
    (hproper : ∀ i ∈ s, ∃ x, b i + f i x ≠ 0) (hs : s.card < Fintype.card K) :
    ∃ x, ∀ i ∈ s, b i + f i x ≠ 0 := by
  classical
  induction s using Finset.induction_on with
  | empty => exact ⟨0, by simp⟩
  | @insert i s hi ih =>
    obtain ⟨x, hx⟩ := ih (fun k hk => hproper k (mem_insert_of_mem hk))
      ((card_le_card (subset_insert ..)).trans_lt hs)
    by_cases he : b i + f i x = 0
    · obtain ⟨y, hy⟩ := hproper i (mem_insert_self ..)
      let d := y - x
      have hd : f i d ≠ 0 := by
        intro hz
        apply hy
        dsimp [d] at hz
        rw [map_sub] at hz
        linear_combination he + hz
      let root (k : I) := -(b k + f k x) / f k d
      let bad := (insert i s).image root
      have hlt : bad.card < (univ : Finset K).card := card_image_le.trans_lt hs
      obtain ⟨t, _, ht⟩ := exists_mem_notMem_of_card_lt_card hlt
      refine ⟨x + t • d, fun k hk hz => ?_⟩
      simp only [map_add, map_smul, smul_eq_mul] at hz
      by_cases hkz : f k d = 0
      · rw [hkz, mul_zero, add_zero] at hz
        rcases mem_insert.mp hk with rfl | hks
        · exact hd hkz
        · exact hx k hks hz
      · apply ht
        have heq : t = root k := (eq_div_iff hkz).2 (by linear_combination hz)
        exact heq ▸ mem_image_of_mem root hk
    · exact ⟨x, fun k hk => (mem_insert.mp hk).elim (fun e => e ▸ he) (hx k)⟩

/-- Up to and including |K| proper homogeneous hyperplanes have a common
complement. Normalize one of the forms and avoid the rest on that slice. -/
theorem avoidLinearForms (f : I → V →ₗ[K] K) (s : Finset I)
    (hproper : ∀ i ∈ s, ∃ x, f i x ≠ 0) (hs : s.card ≤ Fintype.card K) :
    ∃ x, ∀ i ∈ s, f i x ≠ 0 := by
  classical
  obtain h | ⟨j, hj⟩ := s.eq_empty_or_nonempty
  · subst s
    exact ⟨0, by simp⟩
  obtain ⟨v, hv⟩ := hproper j hj
  let U := LinearMap.ker (f j)
  let g (i : I) := (f i).domRestrict U
  have proper (i) (hi : i ∈ s.erase j) : ∃ u : U, f i v + g i u ≠ 0 := by
    by_cases h : f i v = 0
    · obtain ⟨w, hw⟩ := hproper i (mem_of_mem_erase hi)
      let u := w - (f j w / f j v) • v
      have hu : u ∈ U := by
        change f j (w - (f j w / f j v) • v) = 0
        simp [hv]
      refine ⟨⟨u, hu⟩, ?_⟩
      change f i v + f i (w - (f j w / f j v) • v) ≠ 0
      simpa [h] using hw
    · exact ⟨0, by simpa using h⟩
  obtain ⟨u, hu⟩ := avoidAffineForms g (fun i => f i v) (s.erase j) proper
    ((card_lt_card (erase_ssubset hj)).trans_le hs)
  refine ⟨v + u.1, fun i hi => ?_⟩
  by_cases e : i = j
  · subst i
    have hzero : f j u.1 = 0 := u.property
    simpa [hzero] using hv
  · exact (map_add (f i) v u.1).symm ▸ hu i (mem_erase.mpr ⟨e, hi⟩)

end LinearForms

section Pivot

variable {F : Type*} [Field F] [Fintype F] [DecidableEq F] {m : ℕ}

/-- Extend a solution for a nonsingular cofactor through a sparse column. -/
theorem extendLightColumn (A : Matrix (Fin (m+1)) (Fin (m+1)) F) (hA : A.det ≠ 0)
    (j : Fin (m+1))
    (hsize : (univ.filter (fun i => A i j ≠ 0)).card + 1 < Fintype.card F)
    (hsmall : ∀ B : Matrix (Fin m) (Fin m) F, B.det ≠ 0 → HasAJTVector B) :
    HasAJTVector A := by
  classical
  have hco : ∃ i, A i j ≠ 0 ∧ (A.submatrix i.succAbove j.succAbove).det ≠ 0 := by
    by_contra! h
    apply hA
    rw [det_succ_column A j]
    apply sum_eq_zero
    intro i _
    by_cases hi : A i j = 0
    · simp [hi]
    · simp [h i hi]
  obtain ⟨i, hij, hd⟩ := hco
  obtain ⟨y, hy, hBy⟩ := hsmall _ hd
  let x : Fin (m+1) → F := j.insertNth (α := fun _ => F) 0 y
  have hx : ∀ k, k ≠ j → x k ≠ 0 := by
    intro k hk
    obtain ⟨l, rfl⟩ := Fin.exists_succAbove_eq hk
    simpa [x] using hy l
  have hfixed (k) (_ : k ∈ (univ : Finset (Fin (m+1)))) (hk : A k j = 0) :
      (A *ᵥ x) k ≠ 0 := by
    obtain ⟨l, rfl⟩ := Fin.exists_succAbove_eq (show k ≠ i by rintro rfl; exact hij hk)
    change (∑ h, A _ h * x h) ≠ 0
    rw [Fin.sum_univ_succAbove _ j]
    simpa [x, Matrix.mulVec, dotProduct] using hBy l
  obtain ⟨c, hc, hAc⟩ := avoidOnLine A univ j x hx hfixed hsize
  exact ⟨_, hc, fun i => hAc i (mem_univ _)⟩

end Pivot
end AlonJaegerTarsi.Cover

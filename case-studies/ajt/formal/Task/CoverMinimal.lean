import Task.CoverProjective

namespace AlonJaegerTarsi.Cover

open Module Matrix Finset Submodule
open scoped BigOperators

noncomputable section

/-- The lower-dimensional induction hypothesis, in the coordinates of the
original problem. -/
def Below (K : Type*) [Field K] (n : ℕ) : Prop :=
  ∀ d < n, ∀ A : Matrix (Fin d) (Fin d) K, A.det ≠ 0 → HasAJTVector A

variable {K E I J : Type*} [Field K] [AddCommGroup E] [Module K E]

private theorem basisContaining [Finite E] [FiniteDimensional K E] {u : I → E}
    (hu : LinearIndependent K u) :
    ∃ b : Basis (Fin (Module.finrank K E)) K E, ∀ i, ∃ j, b j = u i := by
  classical
  let s := hu.linearIndepOn_id.extend (Set.subset_univ (Set.range u))
  let b : Basis s K E := Basis.extend hu.linearIndepOn_id
  letI : Fintype s := Fintype.ofFinite s
  let e := Fintype.equivFinOfCardEq (Module.finrank_eq_card_basis b).symm
  refine ⟨b.reindex e, fun i => ?_⟩
  have hi : u i ∈ s := hu.linearIndepOn_id.subset_extend _ (Set.mem_range_self i)
  let v : s := ⟨u i, hi⟩
  refine ⟨e v, ?_⟩
  rw [Basis.reindex_apply, Equiv.symm_apply_apply]
  exact Basis.extend_apply_self _ _

/-- Applying AJT to the transition matrix of two extended bases of coefficient
vectors avoids any two independent families of vectors in the smaller space. -/
theorem avoidIndependent [Finite E] [FiniteDimensional K E] {n : ℕ} (hsmall : Below K n)
    (hd : Module.finrank K E < n) {u : I → E} {v : J → E}
    (hu : LinearIndependent K u) (hv : LinearIndependent K v) :
    ∃ L : E →ₗ[K] K, (∀ i, L (u i) ≠ 0) ∧ (∀ j, L (v j) ≠ 0) := by
  classical
  obtain ⟨B, hB⟩ := basisContaining hu
  obtain ⟨C, hC⟩ := basisContaining hv
  let M := B.toMatrix C
  have huM : IsUnit M := @isUnit_of_invertible _ _ M (B.invertibleToMatrix C)
  have hdet : Mᵀ.det ≠ 0 := by
    rw [det_transpose]
    exact ((Matrix.isUnit_iff_isUnit_det M).mp huM).ne_zero
  obtain ⟨x, hx, hy⟩ := hsmall _ hd Mᵀ hdet
  let L := B.constr K x
  refine ⟨L, fun i => ?_, fun j => ?_⟩
  · obtain ⟨k, hk⟩ := hB i
    rw [← hk]
    simpa [L] using hx k
  · obtain ⟨k, hk⟩ := hC j
    rw [← hk]
    simpa [L, M, Basis.constr_apply_fintype, Basis.equivFun_apply, Matrix.mulVec, dotProduct,
      Basis.toMatrix_apply] using hy k

/-- If each of two maps takes at least two distinct values, some pair is
separated by both maps. -/
private theorem commonSeparatedPair {T U V : Type*} (f : T → U) (g : T → V)
    (hf : ∃ a b, f a ≠ f b) (hg : ∃ a b, g a ≠ g b) :
    ∃ a b, f a ≠ f b ∧ g a ≠ g b := by
  classical
  by_contra! he
  obtain ⟨a,b,hab⟩ := hf
  have hgab := he a b hab
  obtain ⟨c,d,hcd⟩ := hg
  have hconst (t : T) : g t = g a := by
    by_cases hta : f t = f a
    · exact (he t b (hta ▸ hab)).trans hgab.symm
    · exact he t a hta
  exact hcd ((hconst c).trans (hconst d).symm)

private theorem functionalThroughQuotient [Finite E] [FiniteDimensional K E]
    {n : ℕ} (hsmall : Below K n) (H : Submodule K E) (dH : Module.finrank K H < n)
    {u : I → H} {v : J → H} (hu : LinearIndependent K u) (hv : LinearIndependent K v)
    (z : H) (huz : Disjoint (span K (Set.range u)) (K ∙ z))
    (hvz : Disjoint (span K (Set.range v)) (K ∙ z)) :
    ∃ L : E →ₗ[K] K, (∀ i, L (u i).1 ≠ 0) ∧ (∀ j, L (v j).1 ≠ 0) ∧ L z.1 = 0 := by
  classical
  let S := K ∙ z
  letI : Finite (H ⧸ S) := Finite.of_surjective S.mkQ S.mkQ_surjective
  have hu' : LinearIndependent K (S.mkQ ∘ u) := hu.map (by simpa using huz)
  have hv' : LinearIndependent K (S.mkQ ∘ v) := hv.map (by simpa using hvz)
  obtain ⟨f, hf, hg⟩ := avoidIndependent hsmall (S.finrank_quotient_le.trans_lt dH) hu' hv'
  obtain ⟨L, hL⟩ := (f.comp S.mkQ).exists_extend
  have heval (x : H) : L x = f (S.mkQ x) := DFunLike.congr_fun hL x
  refine ⟨L, fun i => (heval _).symm ▸ hf i, fun j => (heval _).symm ▸ hg j, ?_⟩
  rw [heval, show S.mkQ z = 0 from by
    change z ∈ S.mkQ.ker
    rw [Submodule.ker_mkQ]
    exact subset_span (by simp), map_zero]

/-- Move a functional in a direction d while preserving its values on ker d.
On coordinates outside the kernel there is only one forbidden parameter value. -/
private theorem avoidAlong {T : Type*} [Fintype K] [DecidableEq K] (g : T → E)
    (L d : E →ₗ[K] K) (s : Finset T)
    (hfixed : ∀ t ∉ s, L (g t) ≠ 0 ∧ d (g t) = 0)
    (hmove : ∀ t ∈ s, d (g t) ≠ 0)
    (hcount : (s.image (fun t => -L (g t) / d (g t))).card < Fintype.card K) :
    ∃ f : E →ₗ[K] K, ∀ t, f (g t) ≠ 0 := by
  classical
  obtain ⟨c, _, hc⟩ := exists_mem_notMem_of_card_lt_card (t := univ) hcount
  refine ⟨L + c • d, fun t hz => ?_⟩
  change L (g t) + c * d (g t) = 0 at hz
  by_cases ht : t ∈ s
  · have hr : c = -L (g t) / d (g t) :=
      (eq_div_iff (hmove t ht)).2 (by linear_combination hz)
    exact hc (hr ▸ mem_image_of_mem _ ht)
  · obtain ⟨ha, hb⟩ := hfixed t ht
    exact ha (by simpa [hb] using hz)

/-- A direction moving at most |K|-1 basis vectors is usable in a minimal
counterexample. At exactly |K| it suffices to have two moving vectors in each
basis, since one pair of forbidden parameters can be forced to coincide. -/
theorem avoidBasesOfSmallDirection [Fintype K] [DecidableEq K] [Finite E] [FiniteDimensional K E]
    {n : ℕ} (hsmall : Below K n) (hdim : Module.finrank K E = n)
    (B C : Basis (Fin n) K E) (d : E →ₗ[K] K) (hd : d ≠ 0)
    (hk : let s := univ.filter (fun i => d (B i) ≠ 0)
          let t := univ.filter (fun i => d (C i) ≠ 0)
          s.card + t.card < Fintype.card K ∨
            (s.card + t.card ≤ Fintype.card K ∧ 1 < s.card ∧ 1 < t.card)) :
    ∃ L : E →ₗ[K] K, (∀ i, L (B i) ≠ 0) ∧ (∀ j, L (C j) ≠ 0) := by
  classical
  let s := univ.filter (fun i => d (B i) ≠ 0)
  let t := univ.filter (fun i => d (C i) ≠ 0)
  let M := s.disjSum t
  let g : Fin n ⊕ Fin n → E := Sum.elim B C
  have hmem (a) : a ∈ M ↔ d (g a) ≠ 0 := by cases a <;> simp [M, s, t, g]
  let H := d.ker
  have dH : Module.finrank K H < n := by
    rw [← hdim]
    exact Submodule.finrank_lt (by simpa [H, LinearMap.ker_eq_top] using hd)
  let u : {i : Fin n // i ∉ s} → H := fun i => ⟨B i.1, by
    have hh := i.2
    simpa [s, H] using hh⟩
  let v : {i : Fin n // i ∉ t} → H := fun i => ⟨C i.1, by
    have hh := i.2
    simpa [t, H] using hh⟩
  have hu : LinearIndependent K u :=
    LinearIndependent.of_comp H.subtype (B.linearIndependent.comp _ Subtype.val_injective)
  have hv : LinearIndependent K v :=
    LinearIndependent.of_comp H.subtype (C.linearIndependent.comp _ Subtype.val_injective)
  have finish (L : E →ₗ[K] K) (h₁ : ∀ i, L (u i).1 ≠ 0) (h₂ : ∀ i, L (v i).1 ≠ 0)
      (hb : (M.image (fun r => -L (g r) / d (g r))).card < Fintype.card K) :
      ∃ L : E →ₗ[K] K, (∀ i, L (B i) ≠ 0) ∧ (∀ j, L (C j) ≠ 0) := by
    obtain ⟨L', hL'⟩ := avoidAlong g L d M (fun r hr => by
      have hz : d (g r) = 0 := not_ne_iff.mp (fun h => hr ((hmem r).mpr h))
      refine ⟨?_, hz⟩
      cases r with
      | inl i => exact h₁ ⟨i, by simpa [M] using hr⟩
      | inr i => exact h₂ ⟨i, by simpa [M] using hr⟩)
      (fun r hr => (hmem r).mp hr) hb
    exact ⟨L', fun i => hL' (.inl i), fun j => hL' (.inr j)⟩
  change s.card + t.card < Fintype.card K ∨ _ at hk
  rcases hk with h | ⟨h, hs, ht⟩
  · obtain ⟨L, h₁, h₂, _⟩ := functionalThroughQuotient hsmall H dH hu hv 0 (by simp) (by simp)
    exact finish L h₁ h₂ (card_image_le.trans_lt (by simpa [M] using h))
  · obtain ⟨i, hi, i', hi', hii'⟩ := one_lt_card.mp hs
    obtain ⟨j, hj, j', hj', hjj'⟩ := one_lt_card.mp ht
    let norm (r : M) : E := (d (g r.1))⁻¹ • g r.1
    let f₁ (r : M) := B.coord i (norm r)
    let f₂ (r : M) := C.coord j (norm r)
    have hn (r : M) : d (norm r) = 1 := by simp [norm, (hmem _).mp r.2]
    have h₁sep : ∃ a b, f₁ a ≠ f₁ b := by
      refine ⟨⟨.inl i, inl_mem_disjSum.mpr hi⟩, ⟨.inl i', inl_mem_disjSum.mpr hi'⟩, ?_⟩
      have hi0 : d (B i) ≠ 0 := (mem_filter.mp hi).2
      simp [f₁, norm, g, Basis.coord_apply, hii', hi0]
    have h₂sep : ∃ a b, f₂ a ≠ f₂ b := by
      refine ⟨⟨.inr j, inr_mem_disjSum.mpr hj⟩, ⟨.inr j', inr_mem_disjSum.mpr hj'⟩, ?_⟩
      have hj0 : d (C j) ≠ 0 := (mem_filter.mp hj).2
      simp [f₂, norm, g, Basis.coord_apply, hjj', hj0]
    obtain ⟨a, b, hab₁, hab₂⟩ := commonSeparatedPair f₁ f₂ h₁sep h₂sep
    let z : H := ⟨norm a - norm b, by simp [H, hn]⟩
    have hzu : z ∉ span K (Set.range u) := by
      have hle : span K (Set.range u) ≤ ((B.coord i).domRestrict H).ker := by
        apply Submodule.span_le.mpr
        rintro _ ⟨k, rfl⟩
        have hki : k.1 ≠ i := fun h => k.2 (h ▸ hi)
        simp [u, Basis.coord_apply, hki.symm]
      intro hzin
      have eqz := hle hzin
      change B.coord i (norm a - norm b) = 0 at eqz
      exact hab₁ (sub_eq_zero.mp (by simpa [f₁] using eqz))
    have hzv : z ∉ span K (Set.range v) := by
      have hle : span K (Set.range v) ≤ ((C.coord j).domRestrict H).ker := by
        apply Submodule.span_le.mpr
        rintro _ ⟨k, rfl⟩
        have hkj : k.1 ≠ j := fun h => k.2 (h ▸ hj)
        simp [v, Basis.coord_apply, hkj.symm]
      intro hzin
      have eqz := hle hzin
      change C.coord j (norm a - norm b) = 0 at eqz
      exact hab₂ (sub_eq_zero.mp (by simpa [f₂] using eqz))
    obtain ⟨L, h₁, h₂, hz⟩ := functionalThroughQuotient hsmall H dH hu hv z
      (disjoint_span_singleton_of_notMem hzu) (disjoint_span_singleton_of_notMem hzv)
    apply finish L h₁ h₂
    let root (r) := -L (g r) / d (g r)
    have hz' : L (norm a) = L (norm b) := sub_eq_zero.mp (by simpa [z] using hz)
    have hr : root a.1 = root b.1 := by
      have ha (r : M) : root r.1 = -L (norm r) := by simp [root, norm, div_eq_inv_mul]
      rw [ha, ha, hz']
    have hinj : ¬Set.InjOn root (M : Set (Fin n ⊕ Fin n)) := by
      intro hI
      have heq : a = b := Subtype.ext (hI a.2 b.2 hr)
      exact hab₁ (congrArg f₁ heq)
    have hlt : (M.image root).card < M.card :=
      lt_of_le_of_ne card_image_le (fun heq => hinj (card_image_iff.mp heq))
    exact hlt.trans_le (by simpa [M, s, t] using h)

/-- A graph-code word with small input and output weights gives an AJT vector
assuming the result in strictly smaller dimensions. -/
theorem hasAJTVector_of_small_weights [Fintype K] [DecidableEq K] {n : ℕ}
    (hsmall : Below K n) (A : Matrix (Fin n) (Fin n) K) (hA : A.det ≠ 0)
    (v : Fin n → K) (hv : v ≠ 0)
    (hwt : let s := (univ.filter fun i => v i ≠ 0).card
           let t := (univ.filter fun i => (A *ᵥ v) i ≠ 0).card
           s+t < Fintype.card K ∨ (s+t ≤ Fintype.card K ∧ 1 < s ∧ 1 < t)) :
    HasAJTVector A := by
  classical
  let B := Pi.basisFun K (Fin n)
  let C := basisOfPiSpaceOfLinearIndependent (Matrix.linearIndependent_rows_of_det_ne_zero hA)
  have hc (i) : C i = A i := congrFun (coe_basisOfPiSpaceOfLinearIndependent _) i
  have hrow (w : Fin n → K) (i : Fin n) : B.constr K w (C i) = (A *ᵥ w) i := by
    rw [hc, Basis.constr_apply_fintype]
    rfl
  let d := B.constr K v
  have hd (i) : d (B i) = v i := B.constr_basis _ _ _
  have hdne : d ≠ 0 := by
    intro h
    exact hv (funext fun i => by simpa [h] using (hd i).symm)
  obtain ⟨L, hB, hC⟩ := avoidBasesOfSmallDirection hsmall (by simp : Module.finrank K (Fin n → K) = n)
    B C d hdne (by simpa only [hd, d, hrow] using hwt)
  let w (i : Fin n) := L (B i)
  have hL : B.constr K w = L := B.ext (fun i => B.constr_basis _ _ _)
  refine ⟨w, hB, fun i => ?_⟩
  rw [← hrow w i, hL]
  exact hC i

end
end AlonJaegerTarsi.Cover

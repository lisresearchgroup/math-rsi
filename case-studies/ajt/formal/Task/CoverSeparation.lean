import Task.CoverMinimal

namespace AlonJaegerTarsi.Cover

open Module Matrix Submodule
open scoped BigOperators

noncomputable section

variable {K E I J : Type*} [Field K] [AddCommGroup E] [Module K E]

/-- A linear functional is nonzero on both indicated coefficient families. -/
def AvoidsPair (f : E →ₗ[K] K) (u : I → E) (v : J → E) : Prop :=
  (∀ i, f (u i) ≠ 0) ∧ ∀ j, f (v j) ≠ 0

/-- Two local linear functionals that agree at every point of their domain intersection
extend to a single linear functional on the ambient space. -/
theorem glueFunctionals (U W : Submodule K E) (f : U →ₗ[K] K) (g : W →ₗ[K] K)
    (h : ∀ (x : U) (y : W), (x : E) = y → f x = g y) :
    ∃ L : E →ₗ[K] K, (∀ x : U, L x = f x) ∧ ∀ y : W, L y = g y := by
  let p : E →ₗ.[K] K := ⟨U, f⟩
  let q : E →ₗ.[K] K := ⟨W, g⟩
  let t := p.sup q h
  obtain ⟨L, hL⟩ := t.toFun.exists_extend
  have hval (z : t.domain) : L z = t z := DFunLike.congr_fun hL z
  refine ⟨L, fun x => ?_, fun y => ?_⟩
  · obtain ⟨z, he, hf⟩ := LinearPMap.exists_of_le (p.left_le_sup q h) x
    exact (congrArg L he).trans ((hval z).trans hf.symm)
  · obtain ⟨z, he, hg⟩ := LinearPMap.exists_of_le (p.right_le_sup q h) y
    exact (congrArg L he).trans ((hval z).trans hg.symm)

private theorem avoidWithNonzero [Finite E] [FiniteDimensional K E] {n : ℕ}
    (hsmall : Below K n) (hd : finrank K E < n) {u : I → E} {v : J → E}
    (hu : LinearIndependent K u) (hv : LinearIndependent K v) (e : E)
    (hspan : e ∉ span K (Set.range u) ∨ e ∉ span K (Set.range v))
    {a : K} (ha : a ≠ 0) :
    ∃ f : E →ₗ[K] K, AvoidsPair f u v ∧ f e = a := by
  have hsol : ∃ f : E →ₗ[K] K, AvoidsPair f u v ∧ f e ≠ 0 := by
    rcases hspan with he | he
    · obtain ⟨f, hfu, hfv⟩ := avoidIndependent hsmall hd (hu.option he) hv
      exact ⟨f, ⟨fun i => hfu (some i), hfv⟩, hfu none⟩
    · obtain ⟨f, hfu, hfv⟩ := avoidIndependent hsmall hd hu (hv.option he)
      exact ⟨f, ⟨hfu, fun j => hfv (some j)⟩, hfv none⟩
  obtain ⟨f, ⟨hfu, hfv⟩, hfe⟩ := hsol
  refine ⟨(a / f e) • f, ⟨fun i => mul_ne_zero (div_ne_zero ha hfe) (hfu i),
    fun j => mul_ne_zero (div_ne_zero ha hfe) (hfv j)⟩, ?_⟩
  exact div_mul_cancel₀ a hfe

/-- If both families remain independent modulo a subspace, a smaller AJT solution
gives an avoiding functional that vanishes on the entire subspace. -/
theorem avoidThroughQuotient [Finite E] [FiniteDimensional K E] {n : ℕ}
    (hsmall : Below K n) {u : I → E} {v : J → E}
    (hu : LinearIndependent K u) (hv : LinearIndependent K v) (S : Submodule K E)
    (hd : finrank K (E ⧸ S) < n)
    (hsu : Disjoint (span K (Set.range u)) S) (hsv : Disjoint (span K (Set.range v)) S) :
    ∃ f : E →ₗ[K] K, AvoidsPair f u v ∧ S ≤ f.ker := by
  letI : Finite (E ⧸ S) := Finite.of_surjective S.mkQ S.mkQ_surjective
  have hu' : LinearIndependent K (S.mkQ ∘ u) := hu.map (by simpa using hsu)
  have hv' : LinearIndependent K (S.mkQ ∘ v) := hv.map (by simpa using hsv)
  obtain ⟨f, hfu, hfv⟩ := avoidIndependent hsmall hd hu' hv'
  refine ⟨f.comp S.mkQ, ⟨hfu, hfv⟩, fun x hx => ?_⟩
  change f (S.mkQ x) = 0
  rw [show S.mkQ x = 0 from (Submodule.Quotient.mk_eq_zero S).mpr hx, map_zero]

/-- The quotient dimension bound holds automatically inside a proper local space. -/
theorem avoidVanishingOn [Finite E] [FiniteDimensional K E] {n : ℕ}
    (hsmall : Below K n) (hd : finrank K E < n) {u : I → E} {v : J → E}
    (hu : LinearIndependent K u) (hv : LinearIndependent K v) (S : Submodule K E)
    (hsu : Disjoint (span K (Set.range u)) S) (hsv : Disjoint (span K (Set.range v)) S) :
    ∃ f : E →ₗ[K] K, AvoidsPair f u v ∧ S ≤ f.ker :=
  avoidThroughQuotient hsmall hu hv S (S.finrank_quotient_le.trans_lt hd) hsu hsv

private theorem avoidWithValue [Finite E] [FiniteDimensional K E] {n : ℕ}
    (hsmall : Below K n) (hd : finrank K E < n) {u : I → E} {v : J → E}
    (hu : LinearIndependent K u) (hv : LinearIndependent K v) (e : E)
    (hsu : e ∉ span K (Set.range u)) (hsv : e ∉ span K (Set.range v)) (a : K) :
    ∃ f : E →ₗ[K] K, AvoidsPair f u v ∧ f e = a := by
  by_cases ha : a = 0
  · obtain ⟨f, hf, hker⟩ := avoidVanishingOn hsmall hd hu hv (K ∙ e)
      (disjoint_span_singleton_of_notMem hsu) (disjoint_span_singleton_of_notMem hsv)
    exact ⟨f, hf, (hker (mem_span_singleton_self e)).trans ha.symm⟩
  · exact avoidWithNonzero hsmall hd hu hv e (.inl hsu) ha


/-- Restrict a coefficient family to an indexed subset living in a subspace. -/
def restriction (u : I → E) (s : Set I) (U : Submodule K E)
    (h : ∀ i ∈ s, u i ∈ U) : s → U := fun i => ⟨u i, h i i.2⟩

theorem independentRestriction {u : I → E} (hu : LinearIndependent K u)
    (s : Set I) (U : Submodule K E) (h : ∀ i ∈ s, u i ∈ U) :
    LinearIndependent K (restriction u s U h) :=
  LinearIndependent.of_comp U.subtype (hu.comp _ Subtype.val_injective)

private theorem spanRestriction {u : I → E} {s : Set I} {U : Submodule K E}
    {h : ∀ i ∈ s, u i ∈ U} {x : U}
    (hx : x ∈ span K (Set.range (restriction u s U h))) :
    (x : E) ∈ span K (u '' s) := by
  have hle : span K (Set.range (restriction u s U h)) ≤ (span K (u '' s)).comap U.subtype := by
    apply span_le.mpr
    rintro _ ⟨i, rfl⟩
    exact subset_span ⟨i, i.2, rfl⟩
  exact hle hx

private theorem outsideOneSide {u : I → E} (hu : LinearIndependent K u)
    (s : Set I) (U W : Submodule K E)
    (h₁ : ∀ i ∈ s, u i ∈ U) (h₂ : ∀ i ∈ sᶜ, u i ∈ W)
    (eU : U) (eW : W) (he : (eU : E) = eW) (hne : (eU : E) ≠ 0) :
    eU ∉ span K (Set.range (restriction u s U h₁)) ∨
      eW ∉ span K (Set.range (restriction u sᶜ W h₂)) := by
  by_contra! h
  have hd := hu.disjoint_span_image (s := s) (t := sᶜ) disjoint_compl_right
  exact hne ((Submodule.disjoint_def.mp hd) _ (spanRestriction h.1)
    (he.symm ▸ spanRestriction h.2))

/-- A one-dimensional intersection of two smaller subspaces allows their avoidance
solutions to be glued, whenever each of the two independent families is partitioned
between those subspaces. This applies, in particular, to two bases. -/
theorem avoidOfRankOneSeparation [Finite E] [FiniteDimensional K E] {n : ℕ}
    (hsmall : Below K n) (U W : Submodule K E) (dU : finrank K U < n)
    (dW : finrank K W < n) (dInt : finrank K (U ⊓ W : Submodule K E) = 1)
    {u : I → E} {v : J → E} (hu : LinearIndependent K u) (hv : LinearIndependent K v)
    (s : Set I) (t : Set J) (uU : ∀ i ∈ s, u i ∈ U) (uW : ∀ i ∈ sᶜ, u i ∈ W)
    (vU : ∀ j ∈ t, v j ∈ U) (vW : ∀ j ∈ tᶜ, v j ∈ W) :
    ∃ L : E →ₗ[K] K, AvoidsPair L u v := by
  classical
  obtain ⟨e, he⟩ := (finrank_pos_iff_exists_ne_zero (R := K)
    (M := ↥(U ⊓ W : Submodule K E))).mp (by omega)
  let eU : U := ⟨e.1, e.2.1⟩
  let eW : W := ⟨e.1, e.2.2⟩
  have hne : (eU : E) ≠ 0 := fun h => he (Subtype.ext h)
  let u₁ := restriction u s U uU
  let u₂ := restriction u sᶜ W uW
  let v₁ := restriction v t U vU
  let v₂ := restriction v tᶜ W vW
  have hu₁ : LinearIndependent K u₁ := independentRestriction hu _ _ _
  have hu₂ : LinearIndependent K u₂ := independentRestriction hu _ _ _
  have hv₁ : LinearIndependent K v₁ := independentRestriction hv _ _ _
  have hv₂ : LinearIndependent K v₂ := independentRestriction hv _ _ _
  have hus : eU ∉ span K (Set.range u₁) ∨ eW ∉ span K (Set.range u₂) :=
    outsideOneSide hu s U W uU uW eU eW rfl hne
  have hvs : eU ∉ span K (Set.range v₁) ∨ eW ∉ span K (Set.range v₂) :=
    outsideOneSide hv t U W vU vW eU eW rfl hne
  have hlocal : ∃ (f : U →ₗ[K] K) (g : W →ₗ[K] K),
      AvoidsPair f u₁ v₁ ∧ AvoidsPair g u₂ v₂ ∧ f eU = g eW := by
    by_cases hU : eU ∉ span K (Set.range u₁) ∨ eU ∉ span K (Set.range v₁)
    · by_cases hW : eW ∉ span K (Set.range u₂) ∨ eW ∉ span K (Set.range v₂)
      · obtain ⟨f, hf, hfe⟩ := avoidWithNonzero hsmall dU hu₁ hv₁ eU hU one_ne_zero
        obtain ⟨g, hg, hge⟩ := avoidWithNonzero hsmall dW hu₂ hv₂ eW hW one_ne_zero
        exact ⟨f, g, hf, hg, hfe.trans hge.symm⟩
      · obtain ⟨g, hgu, hgv⟩ := avoidIndependent hsmall dW hu₂ hv₂
        obtain ⟨f, hf, hfe⟩ := avoidWithValue hsmall dU hu₁ hv₁ eU
          (hus.resolve_right (fun h => hW (.inl h))) (hvs.resolve_right (fun h => hW (.inr h))) (g eW)
        exact ⟨f, g, hf, ⟨hgu, hgv⟩, hfe⟩
    · obtain ⟨f, hfu, hfv⟩ := avoidIndependent hsmall dU hu₁ hv₁
      obtain ⟨g, hg, hge⟩ := avoidWithValue hsmall dW hu₂ hv₂ eW
        (hus.resolve_left (fun h => hU (.inl h))) (hvs.resolve_left (fun h => hU (.inr h))) (f eU)
      exact ⟨f, g, ⟨hfu, hfv⟩, hg, hge.symm⟩
  obtain ⟨f, g, hf, hg, hfg⟩ := hlocal
  obtain ⟨L, hU, hW⟩ := glueFunctionals U W f g (fun x y hxy => by
    let z : ↥(U ⊓ W : Submodule K E) := ⟨x.1, x.2, hxy.symm ▸ y.2⟩
    obtain ⟨a, ha⟩ := exists_smul_eq_of_finrank_eq_one dInt he z
    have ha' : a • (e : E) = x := congrArg (fun z : ↥(U ⊓ W : Submodule K E) => (z : E)) ha
    have hx : a • eU = x := Subtype.ext ha'
    have hy : a • eW = y := Subtype.ext (ha'.trans hxy)
    rw [← hx, ← hy, map_smul, map_smul, hfg])
  refine ⟨L, ⟨fun i => ?_, fun j => ?_⟩⟩
  · by_cases hi : i ∈ s
    · exact (hU (u₁ ⟨i, hi⟩)).symm ▸ hf.1 ⟨i, hi⟩
    · exact (hW (u₂ ⟨i, hi⟩)).symm ▸ hg.1 ⟨i, hi⟩
  · by_cases hj : j ∈ t
    · exact (hU (v₁ ⟨j, hj⟩)).symm ▸ hf.2 ⟨j, hj⟩
    · exact (hW (v₂ ⟨j, hj⟩)).symm ▸ hg.2 ⟨j, hj⟩

/-- Matrix form of rank-one separation. The standard coordinate vectors and
the row vectors are the two coefficient bases. -/
theorem hasAJTVector_of_rankOneSeparation [Fintype K] [DecidableEq K] {n : ℕ}
    (hsmall : Below K n) (A : Matrix (Fin n) (Fin n) K) (hA : A.det ≠ 0)
    (U W : Submodule K (Fin n → K)) (dU : finrank K U < n) (dW : finrank K W < n)
    (dInt : finrank K (U ⊓ W : Submodule K (Fin n → K)) = 1)
    (s t : Set (Fin n))
    (uU : ∀ i ∈ s, Pi.single i 1 ∈ U) (uW : ∀ i ∈ sᶜ, Pi.single i 1 ∈ W)
    (vU : ∀ i ∈ t, A i ∈ U) (vW : ∀ i ∈ tᶜ, A i ∈ W) : HasAJTVector A := by
  classical
  let B := Pi.basisFun K (Fin n)
  have hB (i) : B i = Pi.single i 1 := Pi.basisFun_apply K (Fin n) i
  obtain ⟨L, hu, hv⟩ := avoidOfRankOneSeparation hsmall U W dU dW dInt
    B.linearIndependent (Matrix.linearIndependent_rows_of_det_ne_zero hA) s t
    (fun i hi => hB i ▸ uU i hi) (fun i hi => hB i ▸ uW i hi) vU vW
  let x (i : Fin n) := L (B i)
  have hL : B.constr K x = L := B.ext (fun i => B.constr_basis _ _ _)
  refine ⟨x, hu, fun i => ?_⟩
  have hi : B.constr K x (A i) = (A *ᵥ x) i := by
    rw [Basis.constr_apply_fintype]
    rfl
  rw [← hi, hL]
  exact hv i

end
end AlonJaegerTarsi.Cover

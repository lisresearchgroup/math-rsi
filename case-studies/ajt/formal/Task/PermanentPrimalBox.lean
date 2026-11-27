import Task.CoverSeparation
import Task.WeightTransform

/-! Successive identifications of moving forbidden parameters give a box of
zero entries for a minimal counterexample's split weight enumerator. -/

noncomputable section

namespace AlonJaegerTarsi.PermanentApproach

open Finset Module Submodule Matrix

variable {K E : Type*} [Field K] [AddCommGroup E] [Module K E] [FiniteDimensional K E]

private theorem separated_pair {T U V : Type*} (f : T → U) (g : T → V)
    (hf : ∃ a b, f a ≠ f b) (hg : ∃ a b, g a ≠ g b) :
    ∃ a b, f a ≠ f b ∧ g a ≠ g b := by
  classical
  by_contra! h
  obtain ⟨a,b,hab⟩ := hf
  have he (t : T) : g t = g a := by
    by_cases e : f t = f a
    · exact (h t b (e ▸ hab)).trans (h a b hab).symm
    · exact h t a e
  obtain ⟨c,d,hcd⟩ := hg
  exact hcd ((he c).trans (he d).symm)

private theorem projected_nonconstant (P : Finset E) (hP : P.Nonempty)
    (U S : Submodule K E) (hsp : U ⊔ span K (P : Set E) = ⊤)
    (hgap : finrank K U + finrank K S + 1 < finrank K E) :
    ∃ a b : ↥P, (U ⊔ S).mkQ a.1 ≠ (U ⊔ S).mkQ b.1 := by
  classical
  by_contra! h
  obtain ⟨a,ha⟩ := hP
  let W := U ⊔ S
  have hall (x : E) (hx : x ∈ P) : x-a ∈ W :=
    (Submodule.Quotient.eq W).mp (h ⟨x,hx⟩ ⟨a,ha⟩)
  have htop : W ⊔ K ∙ a = ⊤ := by
    apply top_unique
    rw [← hsp]
    refine sup_le (le_sup_left.trans le_sup_left) (span_le.mpr fun x hx => ?_)
    simpa using Submodule.add_mem_sup (hall x hx) (mem_span_singleton_self a)
  have hspan : finrank K (K ∙ a) ≤ 1 := by
    change Set.finrank K ({a} : Set E) ≤ 1
    simpa using (finrank_span_finset_le_card (R:=K) ({a} : Finset E))
  have hW := finrank_sup_add_finrank_inf_eq U S
  have hWa := finrank_sup_add_finrank_inf_eq W (K ∙ a)
  rw [htop,finrank_top] at hWa
  change finrank K W + _ = _ at hW
  omega

open scoped Classical in
/-- The rank available modulo each of two fixed subspaces bounds how many
pairs in a spanning point configuration can be identified simultaneously. -/
theorem exists_projected_ties [DecidableEq E] [Fintype K] (P : Finset E) (hP : P.Nonempty)
    (U V : Submodule K E) (hU : U ⊔ span K (P : Set E) = ⊤)
    (hV : V ⊔ span K (P : Set E) = ⊤) (k : ℕ)
    (hu : finrank K U + k < finrank K E) (hv : finrank K V + k < finrank K E) :
    ∃ S : Submodule K E, Disjoint U S ∧ Disjoint V S ∧ finrank K S = k ∧
      (P.image S.mkQ).card + k ≤ P.card := by
  classical
  induction k with
  | zero => exact ⟨⊥,disjoint_bot_right,disjoint_bot_right,by simp,by simpa using
      (card_image_le (s:=P) (f:=(⊥ : Submodule K E).mkQ))⟩
  | succ k ih =>
    obtain ⟨S,hUS,hVS,hS,hcnt⟩ := ih (by omega) (by omega)
    obtain ⟨a,b,huv,hvv⟩ := separated_pair (fun c : ↥P => (U⊔S).mkQ c.1)
      (fun c : ↥P => (V⊔S).mkQ c.1) (projected_nonconstant P hP U S hU (by omega))
      (projected_nonconstant P hP V S hV (by omega))
    let z := a.1-b.1
    have hu' : z ∉ U⊔S := fun h => huv ((Submodule.Quotient.eq _).mpr h)
    have hv' : z ∉ V⊔S := fun h => hvv ((Submodule.Quotient.eq _).mpr h)
    have hz : z ∉ S := fun h => hu' ((show S ≤ U⊔S from le_sup_right) h)
    let T := S ⊔ K ∙ z
    let q := S.mapQ T LinearMap.id (by simp [T])
    have hq (x : E) : q (S.mkQ x) = T.mkQ x := rfl
    let points := P.image S.mkQ
    have him : P.image T.mkQ = points.image q := by
      dsimp only [points]
      rw [Finset.image_image]
      exact Finset.image_congr (fun x _ => (hq x).symm)
    have ht : (P.image T.mkQ).card < points.card := by
      rw [him]
      apply lt_of_le_of_ne card_image_le
      intro h
      have hinj := Finset.card_image_iff.mp h
      have heq : q (S.mkQ a.1) = q (S.mkQ b.1) :=
        (Submodule.Quotient.eq T).mpr (show z ∈ T from
          (le_sup_right : K ∙ z ≤ T) (mem_span_singleton_self z))
      have e := hinj (show S.mkQ a.1 ∈ points from mem_image_of_mem _ a.2)
        (show S.mkQ b.1 ∈ points from mem_image_of_mem _ b.2) heq
      exact hz ((Submodule.Quotient.eq S).mp e)
    refine ⟨T,hUS.disjoint_sup_right_of_disjoint_sup_left (disjoint_span_singleton_of_notMem hu'),
      hVS.disjoint_sup_right_of_disjoint_sup_left (disjoint_span_singleton_of_notMem hv'),?_,?_⟩
    · simpa [T,hS] using finrank_sup_span_singleton hz
    · dsimp [points] at ht
      omega

private def fixedSpan {n : ℕ} (B : Basis (Fin n) K E) (s : Finset (Fin n)) : Submodule K E :=
  span K (Set.range (fun i : {i : Fin n // i ∉ s} => B i.1))

omit [FiniteDimensional K E] in
private theorem fixed_span_rank {n : ℕ} (B : Basis (Fin n) K E) (s : Finset (Fin n)) :
    finrank K (fixedSpan B s) + s.card = n := by
  classical
  have hi : LinearIndependent K (fun i : {i : Fin n // i ∉ s} => B i.1) :=
    B.linearIndependent.comp _ Subtype.val_injective
  rw [fixedSpan,finrank_span_eq_card hi,Fintype.card_subtype_compl]
  have hsn : s.card ≤ n := by simpa using s.card_le_univ
  simp
  omega

omit [FiniteDimensional K E] in
private theorem normalized_spans {n : ℕ} (B : Basis (Fin n) K E) (d : E →ₗ[K] K)
    (s : Finset (Fin n)) (P : Finset E) (hs : ∀ i ∈ s, d (B i) ≠ 0)
    (hp : ∀ i ∈ s, (d (B i))⁻¹ • B i ∈ P) :
    fixedSpan B s ⊔ span K (P : Set E) = ⊤ := by
  classical
  apply top_unique
  rw [← B.span_eq]
  refine span_le.mpr ?_
  rintro _ ⟨i,rfl⟩
  by_cases h : i∈s
  · have he : B i = d (B i) • ((d (B i))⁻¹ • B i) := by simp [smul_smul,hs i h]
    exact (le_sup_right : span K (P : Set E) ≤ _) (he ▸
      Submodule.smul_mem _ _ (subset_span (hp i h)))
  · exact (le_sup_left : fixedSpan B s ≤ _) (subset_span ⟨⟨i,h⟩,rfl⟩)

/-- If at least two basis vectors of each colour move and fewer than |K|−1 move
in either colour, a lower-dimensional solution avoids both full bases. -/
theorem avoidBasesOfWeightBox [Fintype K] [DecidableEq K] [Finite E] {n : ℕ}
    (hsmall : Cover.Below K n) (hdim : finrank K E = n)
    (B C : Basis (Fin n) K E) (d : E →ₗ[K] K)
    (hweights : let s := (univ.filter fun i => d (B i) ≠ 0).card
                let t := (univ.filter fun i => d (C i) ≠ 0).card
                2 ≤ min s t ∧ max s t + 1 < Fintype.card K) :
    ∃ L : E →ₗ[K] K, (∀ i, L (B i) ≠ 0) ∧ (∀ i, L (C i) ≠ 0) := by
  classical
  let s := univ.filter fun i => d (B i) ≠ 0
  let t := univ.filter fun i => d (C i) ≠ 0
  change 2 ≤ min s.card t.card ∧ _ at hweights
  have hsz (i) : i ∈ s ↔ d (B i) ≠ 0 := by simp [s]
  have htz (i) : i ∈ t ↔ d (C i) ≠ 0 := by simp [t]
  let norm (x : E) := (d x)⁻¹ • x
  let P := s.image (fun i => norm (B i)) ∪ t.image (fun i => norm (C i))
  have hPB (i) (hi : i ∈ s) : norm (B i) ∈ P :=
    mem_union_left _ (mem_image_of_mem _ hi)
  have hPC (i) (hi : i ∈ t) : norm (C i) ∈ P :=
    mem_union_right _ (mem_image_of_mem _ hi)
  have hP : P.Nonempty := by
    obtain ⟨i,hi⟩ := card_pos.mp (show 0 < s.card by omega)
    exact ⟨_,hPB i hi⟩
  let U := fixedSpan B s
  let V := fixedSpan C t
  have hU : U ⊔ span K (P : Set E) = ⊤ :=
    normalized_spans B d s P (fun i hi => (hsz i).mp hi) hPB
  have hV : V ⊔ span K (P : Set E) = ⊤ :=
    normalized_spans C d t P (fun i hi => (htz i).mp hi) hPC
  have hu : finrank K U + s.card = n := fixed_span_rank B s
  have hv : finrank K V + t.card = n := fixed_span_rank C t
  let k := min s.card t.card - 1
  obtain ⟨S,hUS,hVS,hS,hcount⟩ := exists_projected_ties P hP U V hU hV k
    (by dsimp [k]; omega) (by dsimp [k]; omega)
  have hquot : finrank K (E ⧸ S) < n := by
    have h := S.finrank_quotient_add_finrank
    dsimp [k] at hS
    omega
  let u := fun i : {i : Fin n // i ∉ s} => B i.1
  let v := fun i : {i : Fin n // i ∉ t} => C i.1
  have hui : LinearIndependent K u := B.linearIndependent.comp _ Subtype.val_injective
  have hvi : LinearIndependent K v := C.linearIndependent.comp _ Subtype.val_injective
  obtain ⟨L,havoid,hker⟩ := Cover.avoidThroughQuotient hsmall hui hvi S hquot hUS hVS
  let q := S.liftQ L hker
  let bad := (P.image S.mkQ).image fun z => -(q z)
  have hbad : bad.card < Fintype.card K := by
    have hb : bad.card ≤ (P.image S.mkQ).card := card_image_le
    have hcard : P.card ≤ s.card+t.card :=
      (card_union_le _ _).trans (Nat.add_le_add card_image_le card_image_le)
    dsimp [k] at hcount
    change _ ∧ max s.card t.card + 1 < Fintype.card K at hweights
    omega
  obtain ⟨c,_,hc⟩ := exists_mem_notMem_of_card_lt_card (t:=univ) hbad
  let f := L+c • d
  have good (x : E) (hz : d x ≠ 0) (hx : norm x ∈ P) : f x ≠ 0 := by
    intro hf
    change L x+c*d x=0 at hf
    have hr : -(q (S.mkQ (norm x))) = c := by
      change -(L ((d x)⁻¹ • x)) = c
      rw [map_smul,smul_eq_mul]
      field_simp
      linear_combination -hf
    exact hc (hr ▸ mem_image_of_mem _ (mem_image_of_mem _ hx))
  refine ⟨f, fun i => ?_, fun j => ?_⟩
  · by_cases hi : i ∈ s
    · exact good _ ((hsz i).mp hi) (hPB i hi)
    · have hz : d (B i) = 0 := not_ne_iff.mp (fun hh => hi ((hsz i).mpr hh))
      simpa [f,hz,u] using havoid.1 ⟨i,hi⟩
  · by_cases hj : j ∈ t
    · exact good _ ((htz j).mp hj) (hPC j hj)
    · have hz : d (C j) = 0 := not_ne_iff.mp (fun hh => hj ((htz j).mpr hh))
      simpa [f,hz,v] using havoid.2 ⟨j,hj⟩

open WeightTransform in
/-- A nonzero graph-code word whose two block weights are both at most |K|−2
yields an AJT vector, assuming smaller dimensions. -/
theorem hasAJTVector_of_weight_box [Fintype K] [DecidableEq K] {n : ℕ}
    (hsmall : Cover.Below K n) (A : Matrix (Fin n) (Fin n) K) (hA : A.det ≠ 0)
    (v : Fin n → K) (hv : v ≠ 0) (hw : max (wt v) (wt (A *ᵥ v)) + 1 < Fintype.card K) :
    HasAJTVector A := by
  classical
  by_cases hmin : 2 ≤ min (wt v) (wt (A *ᵥ v))
  · let B := Pi.basisFun K (Fin n)
    let C := basisOfPiSpaceOfLinearIndependent (Matrix.linearIndependent_rows_of_det_ne_zero hA)
    have hC (i) : C i = A i := congrFun (coe_basisOfPiSpaceOfLinearIndependent _) i
    have hrow (w : Fin n → K) (i : Fin n) : B.constr K w (C i) = (A *ᵥ w) i := by
      rw [hC,Basis.constr_apply_fintype]
      rfl
    let d := B.constr K v
    have hd (i) : d (B i) = v i := B.constr_basis _ _ _
    obtain ⟨L,hB,hC'⟩ := avoidBasesOfWeightBox hsmall (by simp : finrank K (Fin n → K) = n)
      B C d (by simpa only [hd, d, hrow, wt] using And.intro hmin hw)
    let x (i : Fin n) := L (B i)
    have hL : B.constr K x = L := B.ext (fun i => B.constr_basis _ _ _)
    refine ⟨x, hB, fun i => ?_⟩
    rw [← hrow x i,hL]
    exact hC' i
  · apply Cover.hasAJTVector_of_small_weights hsmall A hA v hv
    left
    change wt v + wt (A *ᵥ v) < Fintype.card K
    omega

end AlonJaegerTarsi.PermanentApproach

namespace AlonJaegerTarsi.WeightTransform

open Finset Matrix

/-- In a counterexample of least dimension, the entire positive square of
weights up to |K|−2 is absent from the primal split enumerator. -/
theorem primal_counts_zero_of_box {K : Type*} [Field K] [Fintype K] [DecidableEq K] {n : ℕ}
    (hsmall : Cover.Below K n) (A : Matrix (Fin n) (Fin n) K) (hA : A.det ≠ 0)
    (hbad : ¬HasAJTVector A) (i j : ℕ) (hi : 0 < i)
    (hij : max i j + 1 < Fintype.card K) : counts A i j = 0 := by
  classical
  unfold counts
  rw [Finset.card_eq_zero]
  apply eq_empty_iff_forall_notMem.mpr
  intro x hx
  obtain ⟨hxi,hyj⟩ := (mem_filter.mp hx).2
  have hxn : x ≠ 0 := by
    intro he
    have hzero : wt (0 : Fin n → K) = 0 := by simp [wt]
    rw [he,hzero] at hxi
    omega
  exact hbad (PermanentApproach.hasAJTVector_of_weight_box hsmall A hA x hxn
    (by simpa only [hxi,hyj] using hij))

end AlonJaegerTarsi.WeightTransform

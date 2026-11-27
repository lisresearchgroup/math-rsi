import Task.CoverSeparation

namespace AlonJaegerTarsi.Cover

open Module Submodule

noncomputable section

variable {K E I J : Type*} [Field K] [Fintype K] [AddCommGroup E] [Module K E]
  [Finite E] [FiniteDimensional K E]

/-- After omitting any one vector from the second basis, the remaining two
families admit an avoiding functional assuming AJT in smaller dimensions. -/
theorem avoidAllExceptOne {n : ℕ} (hq : 2 < Fintype.card K) (hsmall : Below K n)
    (hd : finrank K E ≤ n) (B : Basis I K E) (C : Basis J K E) (a b : J) (hab : a ≠ b) :
    ∃ f : E →ₗ[K] K, (∀ i, f (B i) ≠ 0) ∧ ∀ j, j ≠ a → f (C j) ≠ 0 := by
  classical
  have hcoord : (C.coord a) ≠ 0 := by
    intro h
    have hzero : C.coord a (C a) = 0 := by rw [h]; rfl
    simp [Basis.coord_apply] at hzero
  obtain ⟨i, hi⟩ : ∃ i, C.coord a (B i) ≠ 0 := by
    by_contra! h
    exact hcoord (B.ext h)
  let k : K := B.coord i (C b)
  obtain ⟨c, _, hc⟩ := Finset.exists_mem_notMem_of_card_lt_card
    (s := ({0,k⁻¹} : Finset K)) (t := Finset.univ) (by
      exact (Finset.card_insert_le _ _).trans_lt (by simpa using hq))
  have hc0 : c ≠ 0 := fun h => hc (h ▸ Finset.mem_insert_self ..)
  have hck : 1 - c * k ≠ 0 := by
    intro h
    have hmul : c * k = 1 := (sub_eq_zero.mp h).symm
    have hk : k ≠ 0 := by intro h; simp [h] at hmul
    apply hc
    have heq : c = k⁻¹ := ((eq_div_iff hk).2 hmul).trans (one_div k)
    simp [heq]
  let z := B i - c • C b
  let r : {j : I // j ≠ i} → E := fun j => B j
  let s : {j : J // j ≠ a} → E := fun j => C j
  have hr : LinearIndependent K r := B.linearIndependent.comp _ Subtype.val_injective
  have hs : LinearIndependent K s := C.linearIndependent.comp _ Subtype.val_injective
  have hzr : B.coord i z ≠ 0 := by
    simpa [z,k,Basis.coord_apply] using hck
  have hzs : C.coord a z ≠ 0 := by
    simpa [z,Basis.coord_apply,hab] using hi
  have hleB : span K (Set.range r) ≤ (B.coord i).ker := by
    refine span_le.mpr ?_
    rintro _ ⟨j,rfl⟩
    simp [r,Basis.coord_apply,j.2.symm]
  have hleC : span K (Set.range s) ≤ (C.coord a).ker := by
    refine span_le.mpr ?_
    rintro _ ⟨j,rfl⟩
    simp [s,Basis.coord_apply,j.2.symm]
  have hzne : z ≠ 0 := fun h => hzr (by simp [h])
  have hdim := (K ∙ z).finrank_quotient_add_finrank
  rw [finrank_span_singleton hzne] at hdim
  obtain ⟨f, hf, hzk⟩ := avoidThroughQuotient hsmall hr hs (K ∙ z) (by omega)
    (disjoint_span_singleton_of_notMem (fun h => hzr (hleB h)))
    (disjoint_span_singleton_of_notMem (fun h => hzs (hleC h)))
  have hrel : f (B i) = c * f (C b) := sub_eq_zero.mp (by
    simpa [z] using (show f z = 0 from hzk (mem_span_singleton_self z)))
  refine ⟨f, fun j => ?_, fun j hj => hf.2 ⟨j,hj⟩⟩
  by_cases hj : j = i
  · exact hj ▸ hrel ▸ mul_ne_zero hc0 (hf.2 ⟨b,hab.symm⟩)
  · exact hf.1 ⟨j,hj⟩

/-- A minimum blocked pair of bases has a private hyperplane point at every
individual constituent. In this orientation the selected zero lies in C. -/
theorem exactOneZeroOfBlockedBases {n : ℕ} (hq : 2 < Fintype.card K) (hsmall : Below K n)
    (hd : finrank K E ≤ n) (B : Basis I K E) (C : Basis J K E) (a b : J) (hab : a ≠ b)
    (hbad : ¬∃ L : E →ₗ[K] K, AvoidsPair L B C) :
    ∃ f : E →ₗ[K] K, (∀ i, f (B i) ≠ 0) ∧ ∀ j, f (C j) = 0 ↔ j = a := by
  obtain ⟨f, hf, hg⟩ := avoidAllExceptOne hq hsmall hd B C a b hab
  have hfa : f (C a) = 0 := by
    by_contra h
    exact hbad ⟨f, ⟨hf, fun j => by by_cases hj : j = a; exact hj ▸ h; exact hg j hj⟩⟩
  exact ⟨f,hf,fun j => ⟨fun h => by by_contra hj; exact hg j hj h,fun h => h ▸ hfa⟩⟩

end
end AlonJaegerTarsi.Cover

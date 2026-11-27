import Task.AffineBasisTools
import Task.DimensionEleven

namespace AlonJaegerTarsi.TransposeHalf

open Module Matrix Finset Submodule AffineReduction BalancedCover AffineBasisTools CharacterMethod

noncomputable section

variable {p n k : ℕ} [Fact p.Prime]
private abbrev Sites (n : ℕ) := Fin n ⊕ Fin n
private abbrev V (p n : ℕ) := Fin n → ZMod p

private def Covered (v : Sites n → V p n) (a : Sites n → ZMod p) (s : Finset (Sites n)) : Prop :=
  ∀ x, ∃ j ∈ s, v j ⬝ᵥ x = a j

private theorem core (v : Sites n → V p n) (a : Sites n → ZMod p) (h : Covered v a univ) :
    ∃ s : Finset (Sites n), (∀ x,∃ j : s,v j ⬝ᵥ x = a j) ∧
      ∀ w : s,∃ x, ∀ j : s,j ≠ w → v j ⬝ᵥ x ≠ a j := by
  classical
  let F := univ.filter (Covered v a)
  obtain ⟨s,hs,hmin⟩ := exists_min_image F card ⟨univ,by simpa [F] using h⟩
  refine ⟨s,fun x => ?_,fun w => ?_⟩
  · obtain ⟨j,hj,he⟩ := (mem_filter.mp hs).2 x
    exact ⟨⟨j,hj⟩,he⟩
  · have hnc : ¬Covered v a (s.erase w) := fun hw =>
      (Nat.not_le_of_lt (card_erase_lt_of_mem w.property))
        (hmin _ (by simp [F,hw]))
    unfold Covered at hnc
    push Not at hnc
    obtain ⟨x,hx⟩ := hnc
    exact ⟨x, fun j hj => hx j (mem_erase.mpr ⟨fun e => hj (Subtype.ext e),j.2⟩)⟩

private def coreSpan (v : Sites n → V p n) (s : Finset (Sites n)) : Submodule (ZMod p) (V p n) :=
  span (ZMod p) (Set.range fun j : s => v j)

private theorem mem_coreSpan (v : Sites n → V p n) (s : Finset (Sites n)) (j : s) :
    v j ∈ coreSpan v s := subset_span (Set.mem_range_self j)

private theorem core_rank_bad (A : Matrix (Fin n) (Fin n) (ZMod p)) (hA : A.det ≠ 0)
    (s : Finset (Sites n)) (a : Sites n → ZMod p)
    (hc : ∀ x, ∃ j : s, normals A j ⬝ᵥ x = a j) :
    ¬AtDim (ZMod p) (finrank (ZMod p) (coreSpan (normals A) s)) := by
  classical
  let H := coreSpan (normals A) s
  let B := Pi.basisFun (ZMod p) (Fin n)
  let I := {i : Fin n // Sum.inl i ∈ s}
  let J := {j : Fin n // Sum.inr j ∈ s}
  let u (i : I) : H := ⟨normals A (.inl i.val),mem_coreSpan _ s ⟨.inl i,i.2⟩⟩
  let v (j : J) : H := ⟨normals A (.inr j.val),mem_coreSpan _ s ⟨.inr j,j.2⟩⟩
  have hu : LinearIndependent (ZMod p) u := by
    apply LinearIndependent.of_comp H.subtype
    simpa [Function.comp_def,u,normals,B,Pi.basisFun_apply] using
      (B.linearIndependent.comp (Subtype.val : I → Fin n) Subtype.val_injective)
  have hv : LinearIndependent (ZMod p) v := LinearIndependent.of_comp H.subtype
    ((Matrix.linearIndependent_rows_of_det_ne_zero hA).comp (Subtype.val : J → Fin n) Subtype.val_injective)
  intro ha
  obtain ⟨f,hu',hv'⟩ := avoidIndependent ha u v hu hv (fun i => a (.inl i)) (fun j => a (.inr j))
  obtain ⟨L,hL⟩ := f.exists_extend
  let x (i : Fin n) := L (B i)
  have hcL : B.constr (ZMod p) x = L := B.ext (fun i => B.constr_basis _ _ _)
  have hdot (w : V p n) : w ⬝ᵥ x = L w := by
    rw [← hcL, Basis.constr_apply_fintype]
    rfl
  obtain ⟨⟨j,hj⟩,he⟩ := hc x
  rw [hdot] at he
  cases j with
  | inl i => exact hu' ⟨i,hj⟩ ((DFunLike.congr_fun hL (u ⟨i,hj⟩)).symm.trans he)
  | inr j => exact hv' ⟨j,hj⟩ ((DFunLike.congr_fun hL (v ⟨j,hj⟩)).symm.trans he)

private theorem quotient_span (H : Submodule (ZMod p) (V p n))
    (B : Basis (Fin n) (ZMod p) (V p n)) :
    span (ZMod p) (Set.range (H.mkQ ∘ B)) = ⊤ := by
  rw [Set.range_comp,← map_span,B.span_eq,Submodule.map_top,LinearMap.range_eq_top]
  exact H.mkQ_surjective

private theorem completeCoefficients (hp : 5 ≤ p) (v : Sites n → V p n) (a : Sites n → ZMod p)
    (s : Finset (Sites n)) (blocked : ∀ x,∃ j : s,v j ⬝ᵥ x = a j)
    (privatePoint : ∀ w : s,∃ x,∀ j : s,j ≠ w → v j ⬝ᵥ x ≠ a j)
    (d : Sites n → ZMod p) (hd : ∀ i,d i ≠ 0) (y : V p n)
    (hQ : (coreSpan v s).mkQ (combine v d) = (coreSpan v s).mkQ y) :
    ∃ c : Sites n → ZMod p, (∀ i,c i ≠ 0) ∧ combine v c = y := by
  classical
  let H := coreSpan v s
  let vs (i : s) := v i
  let ds (i : s) := d i
  let y₀ := y - combine v d + combine vs ds
  have hdiff : y - combine v d ∈ H := by
    rw [← H.ker_mkQ,LinearMap.mem_ker,map_sub,sub_eq_zero]
    exact hQ.symm
  have hy : y₀ ∈ H := H.add_mem hdiff (H.sum_mem (fun i _ => H.smul_mem _ (mem_coreSpan v s i)))
  obtain ⟨q,hq⟩ := (mem_span_range_iff_exists_fun (ZMod p)).mp hy
  let S := (univ : Finset (ZMod p)).erase 0
  have hbal : Balanced S := balanced_nonzero (by rw [ZMod.card]; omega)
  obtain ⟨c,hc,hm⟩ := represent_by_balanced vs S hbal
    (repair_of_affine_cover vs (fun i : s => a i) blocked privatePoint) q
  have hcs : combine vs c = y₀ := hc.trans hq
  let c' (j : Sites n) := if h : j ∈ s then c ⟨j,h⟩ else d j
  refine ⟨c',fun i => ?_,?_⟩
  · by_cases hi : i ∈ s
    · simpa [c',hi] using (mem_erase.mp (hm ⟨i,hi⟩)).1
    · simpa [c',hi] using hd i
  · have hsplit (e : Sites n → ZMod p) :
        combine v e = combine vs (fun j : s => e j) + ∑ j ∈ sᶜ,e j • v j := by
      unfold combine
      rw [sum_coe_sort s (fun j => e j • v j)]
      exact (sum_add_sum_compl s _).symm
    have hcin : (fun j : s => c' j) = c := by ext j; simp [c',j.2]
    have hcout : ∑ j ∈ sᶜ,c' j • v j = ∑ j ∈ sᶜ,d j • v j :=
      sum_congr rfl (fun j hj => by simp [c',mem_compl.mp hj])
    have htotal := hsplit d
    change combine v d = combine vs ds + _ at htotal
    rw [hsplit,hcin,hcout,hcs]
    dsimp only [y₀]
    rw [htotal]
    abel

private theorem affine_transpose_of_quotient (hp : 5 ≤ p)
    (A : Matrix (Fin n) (Fin n) (ZMod p)) (hA : A.det ≠ 0) (s : Finset (Sites n))
    (a : Sites n → ZMod p) (blocked : ∀ x,∃ j : s,normals A j ⬝ᵥ x = a j)
    (privatePoint : ∀ w : s,∃ x,∀ j : s,j ≠ w → normals A j ⬝ᵥ x ≠ a j)
    (hgood : AtDim (ZMod p) (finrank (ZMod p) ((V p n) ⧸ coreSpan (normals A) s))) :
    AffineAJT Aᵀ := by
  classical
  let H := coreSpan (normals A) s
  let B := Pi.basisFun (ZMod p) (Fin n)
  let C := basisOfPiSpaceOfLinearIndependent (Matrix.linearIndependent_rows_of_det_ne_zero hA)
  have hB (i : Fin n) : B i = normals A (.inl i) := Pi.basisFun_apply _ _ _
  have hC (i : Fin n) : C i = normals A (.inr i) := congrFun (coe_basisOfPiSpaceOfLinearIndependent _) i
  letI : Finite ((V p n) ⧸ H) := Finite.of_surjective H.mkQ H.mkQ_surjective
  intro t
  obtain ⟨l,r,hl,hr,he⟩ := representSpanning hgood (H.mkQ ∘ B) (H.mkQ ∘ C)
    (quotient_span H B) (quotient_span H C) (H.mkQ (-t))
  let d := Sum.elim l r
  have hd (i) : d i ≠ 0 := by cases i with | inl i => exact hl i | inr j => exact hr j
  have hrep : H.mkQ (combine (normals A) d) = H.mkQ (-t) := by
    unfold combine
    rw [Fintype.sum_sum_type,map_add,map_sum,map_sum]
    simpa only [Function.comp_apply,hB,hC,map_smul,d,Sum.elim_inl,Sum.elim_inr] using he
  obtain ⟨c,hc,hy⟩ := completeCoefficients hp (normals A) a s blocked privatePoint d hd (-t) hrep
  rw [combine_normals] at hy
  refine ⟨c ∘ Sum.inr,fun i => hc (.inr i),fun j hj => hc (.inl j) ?_⟩
  have hz := congrFun hy j
  change c (.inl j) + (Aᵀ *ᵥ (c ∘ Sum.inr)) j = -t j at hz
  change (Aᵀ *ᵥ (c ∘ Sum.inr)) j + t j = 0 at hj
  linear_combination hz - hj

/-- If affine AJT holds through dimension k, failures for both orientations
of the same matrix are impossible through dimension 2k+1. -/
theorem affine_or_transpose (hp : 5 ≤ p) (hsmall : ∀ d ≤ k, AtDim (ZMod p) d)
    (hn : n ≤ 2*k+1) (A : Matrix (Fin n) (Fin n) (ZMod p)) (hA : A.det ≠ 0) :
    AffineAJT A ∨ AffineAJT Aᵀ := by
  classical
  by_cases ha : AffineAJT A
  · exact Or.inl ha
  right
  rw [affine_iff_avoid] at ha
  push Not at ha
  obtain ⟨a,b,hab⟩ := ha
  let f := Sum.elim a b
  have hc : Covered (normals A) f univ := by
    intro x
    by_contra! hz
    obtain ⟨j,hj⟩ := hab x (fun i => by simpa [normals,f] using hz (.inl i) (mem_univ _))
    exact hz (.inr j) (mem_univ _) hj
  obtain ⟨s,hs,hs'⟩ := core _ _ hc
  have bad := core_rank_bad A hA s f hs
  have hbig : k < finrank (ZMod p) (coreSpan (normals A) s) :=
    lt_of_not_ge fun h => bad (hsmall _ h)
  have dim := (coreSpan (normals A) s).finrank_quotient_add_finrank
  rw [show finrank (ZMod p) (V p n) = n from by simp [V]] at dim
  exact affine_transpose_of_quotient hp A hA s f hs hs' (hsmall _ (by omega))

theorem symmetric_affine_upto_double (hp : 5 ≤ p) (hsmall : ∀ d ≤ k, AtDim (ZMod p) d)
    (hn : n ≤ 2*k+1) (A : Matrix (Fin n) (Fin n) (ZMod p)) (hA : A.det ≠ 0) (hs : A.IsSymm) :
    AffineAJT A := by
  simpa only [hs.eq,or_self] using affine_or_transpose hp hsmall hn A hA

theorem symmetric_affine_dim_le_twenty_one (hp : 5 ≤ p) (hn : n ≤ 21)
    (A : Matrix (Fin n) (Fin n) (ZMod p)) (hA : A.det ≠ 0) (hs : A.IsSymm) : AffineAJT A :=
  symmetric_affine_upto_double (k := 10) hp (fun d hd => affine_prime_dim_le_ten hp hd) hn A hA hs

end
end AlonJaegerTarsi.TransposeHalf

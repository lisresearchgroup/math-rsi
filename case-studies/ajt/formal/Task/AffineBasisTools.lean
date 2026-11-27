import Task.AffineIrredundance

namespace AlonJaegerTarsi.AffineBasisTools

open Module Matrix Finset Submodule AffineReduction

noncomputable section

variable {K E I J : Type*} [Field K] [AddCommGroup E] [Module K E]
  [FiniteDimensional K E] [Finite E] [Fintype I] [Fintype J]

def AtDim (K : Type*) [Field K] (d : ℕ) : Prop :=
  ∀ M : Matrix (Fin d) (Fin d) K, M.det ≠ 0 → AffineAJT M

private theorem containsBasis (u : I → E) (hu : span K (Set.range u) = ⊤) :
    ∃ (B : Basis (Fin (finrank K E)) K E) (f : Fin (finrank K E) ↪ I), ∀ i, B i = u (f i) := by
  classical
  obtain ⟨κ,a,ha,he,hi⟩ := exists_linearIndependent' K u
  letI : Fintype κ := Fintype.ofInjective a ha
  let b := Basis.mk hi (by rw [he,hu])
  let e := Fintype.equivFinOfCardEq (finrank_eq_card_basis b).symm
  exact ⟨b.reindex e, e.symm.toEmbedding.trans ⟨a,ha⟩,fun i => by simp [Basis.reindex_apply,b]⟩

private theorem extendsToBasis (u : I → E) (hu : LinearIndependent K u) :
    ∃ (B : Basis (Fin (finrank K E)) K E) (f : I ↪ Fin (finrank K E)), ∀ i, B (f i) = u i := by
  classical
  let s := hu.linearIndepOn_id.extend (Set.subset_univ (Set.range u))
  let b : Basis s K E := Basis.extend hu.linearIndepOn_id
  letI : Fintype s := Fintype.ofFinite s
  let e := Fintype.equivFinOfCardEq (finrank_eq_card_basis b).symm
  let g (i : I) : s := ⟨u i,hu.linearIndepOn_id.subset_extend _ (Set.mem_range_self i)⟩
  refine ⟨b.reindex e,(⟨g,fun i j h => hu.injective (congrArg Subtype.val h)⟩ : I ↪ s).trans
    e.toEmbedding,fun i => ?_⟩
  rw [Basis.reindex_apply]
  change b (e.symm (e (g i))) = _
  rw [Equiv.symm_apply_apply]
  exact Basis.extend_apply_self _ _

/-- On two independent families in E, prescribed scalar values can be avoided
assuming affine AJT only in the dimension of E. -/
theorem avoidIndependent (hgood : AtDim K (finrank K E)) (u : I → E) (v : J → E)
    (hu : LinearIndependent K u) (hv : LinearIndependent K v) (a : I → K) (b : J → K) :
    ∃ L : E →ₗ[K] K, (∀ i,L (u i) ≠ a i) ∧ (∀ j,L (v j) ≠ b j) := by
  classical
  obtain ⟨B,f,hf⟩ := extendsToBasis u hu
  obtain ⟨C,g,hg⟩ := extendsToBasis v hv
  let M := B.toMatrix C
  have hdet : Mᵀ.det ≠ 0 := by
    rw [det_transpose]
    exact ((isUnit_iff_isUnit_det M).mp (@isUnit_of_invertible _ _ M (B.invertibleToMatrix C))).ne_zero
  obtain ⟨x,hx,hy⟩ := (affine_iff_avoid Mᵀ).mp (hgood _ hdet)
    (Function.extend f a (fun _ => 0)) (Function.extend g b (fun _ => 0))
  refine ⟨B.constr K x,fun i => ?_,fun j => ?_⟩
  · rw [← hf i,Basis.constr_basis]
    simpa [f.injective.extend_apply] using hx (f i)
  · rw [← hg j]
    simpa [M,Basis.constr_apply_fintype,Matrix.mulVec,dotProduct,Basis.toMatrix_apply,g.injective.extend_apply]
      using hy (g j)

private def addAt {d : ℕ} [DecidableEq I] (f : Fin d ↪ I) (t : Fin d → K) (j : I) : K :=
  1 + ∑ i, if f i = j then t i else 0

private theorem addAt_ne {d : ℕ} [DecidableEq I] (f : Fin d ↪ I) (t : Fin d → K)
    (ht : ∀ i,t i ≠ -1) (j : I) : addAt f t j ≠ 0 := by
  by_cases hj : ∃ i,f i = j
  · obtain ⟨k,rfl⟩ := hj
    simp [addAt, f.injective.eq_iff, add_eq_zero_iff_neg_eq]
    intro h
    exact ht k h.symm
  · push_neg at hj
    simp [addAt,hj]

private theorem addAt_sum {d : ℕ} [DecidableEq I] (u : I → E) (f : Fin d ↪ I) (t : Fin d → K) :
    ∑ j, addAt f t j • u j = (∑ j, u j) + ∑ i, t i • u (f i) := by
  simp only [addAt,add_smul,one_smul,sum_add_distrib,Finset.sum_smul,ite_smul,zero_smul]
  congr 1
  rw [Finset.sum_comm]
  simp

/-- Two spanning families in E represent any target with every coefficient
nonzero, assuming affine AJT in the dimension of E. -/
theorem representSpanning (hgood : AtDim K (finrank K E)) (u : I → E) (v : J → E)
    (hu : span K (Set.range u) = ⊤) (hv : span K (Set.range v) = ⊤) (y : E) :
    ∃ (a : I → K) (b : J → K), (∀ i,a i ≠ 0) ∧ (∀ j,b j ≠ 0) ∧
      (∑ i,a i • u i) + (∑ j,b j • v j) = y := by
  classical
  obtain ⟨B,f,hf⟩ := containsBasis u hu
  obtain ⟨C,g,hg⟩ := containsBasis v hv
  let M := B.toMatrix C
  have hdet := ((isUnit_iff_isUnit_det M).mp (@isUnit_of_invertible _ _ M (B.invertibleToMatrix C))).ne_zero
  let y₀ := y - (∑ i,u i) - ∑ j,v j
  obtain ⟨x,hx,hy⟩ := (affine_iff_avoid M).mp (hgood _ hdet)
    (fun _ => -1) (fun i => B.repr y₀ i + 1)
  let z (i) := B.repr y₀ i - (M *ᵥ x) i
  have hz (i) : z i ≠ -1 := fun h => hy i (by dsimp [z] at h; linear_combination -h)
  refine ⟨addAt f z,addAt g x, addAt_ne f z hz,addAt_ne g x hx,?_⟩
  rw [addAt_sum,addAt_sum]
  have he : (∑ i,z i • u (f i)) + (∑ j,x j • v (g j)) = y₀ := by
    simp_rw [← hf,← hg]
    apply B.repr.injective
    ext i
    simp [z, M, Matrix.mulVec, dotProduct, Basis.toMatrix_apply,mul_comm, Finsupp.single_apply]
  calc
    _ = ((∑ i,u i) + ∑ j,v j) + ((∑ i,z i • u (f i)) + ∑ j,x j • v (g j)) := by abel
    _ = y := by rw [he]; dsimp [y₀]; abel

end
end AlonJaegerTarsi.AffineBasisTools

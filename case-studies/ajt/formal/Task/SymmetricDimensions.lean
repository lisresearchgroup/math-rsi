import Task.SameDimensionAffine
import Task.PermanentSymmetric

namespace AlonJaegerTarsi.TransposeHalf

open Matrix AffineReduction AffineBasisTools PermanentApproach

variable {K : Type*} [Field K] {d p k : ℕ}

theorem affine_symmetricLift_iff (A : Matrix (Fin d) (Fin d) K) :
    AffineAJT (symmetricLift A) ↔ AffineAJT A ∧ AffineAJT Aᵀ := by
  constructor
  · intro h
    have both (t s : Fin d → K) :
        (∃ x, NowhereZero x ∧ NowhereZero (A *ᵥ x + t)) ∧
        (∃ y, NowhereZero y ∧ NowhereZero (Aᵀ *ᵥ y + s)) := by
      let b := Sum.elim t s
      obtain ⟨w,hw,hy⟩ := h (b ∘ finSumFinEquiv.symm)
      let z := w ∘ finSumFinEquiv
      have hv (j : Fin d ⊕ Fin d) :
          ((fromBlocks 0 A Aᵀ 0) *ᵥ z) j + b j ≠ 0 := by
        simpa [symmetricLift,submatrix_mulVec_equiv,z,Function.comp_def] using hy (finSumFinEquiv j)
      exact ⟨⟨z ∘ Sum.inr,fun j => hw _,fun i => by simpa [fromBlocks_mulVec,b] using hv (.inl i)⟩,
        ⟨z ∘ Sum.inl,fun j => hw _,fun i => by simpa [fromBlocks_mulVec,b] using hv (.inr i)⟩⟩
    exact ⟨fun t => (both t 0).1,fun s => (both 0 s).2⟩
  · rintro ⟨ha,hat⟩ t
    let b := t ∘ finSumFinEquiv
    obtain ⟨x,hx,hy⟩ := ha (b ∘ Sum.inl)
    obtain ⟨y,hx',hy'⟩ := hat (b ∘ Sum.inr)
    let z := Sum.elim y x
    refine ⟨z ∘ finSumFinEquiv.symm,fun i => ?_,fun i => ?_⟩
    · obtain ⟨i,rfl⟩ := finSumFinEquiv.surjective i
      simp only [Function.comp_apply,Equiv.symm_apply_apply]
      cases i with | inl j => exact hx' j | inr j => exact hx j
    · obtain ⟨j,rfl⟩ := finSumFinEquiv.surjective i
      change ((symmetricLift A) *ᵥ (z ∘ finSumFinEquiv.symm)) (finSumFinEquiv j) + b j ≠ 0
      simp only [symmetricLift,submatrix_mulVec_equiv,Function.comp_apply,Equiv.symm_apply_apply]
      cases j with
      | inl j => simpa [fromBlocks_mulVec,z,Function.comp_def] using hy j
      | inr j => simpa [fromBlocks_mulVec,z,Function.comp_def] using hy' j

/-- The exact relation between the dimensions of the two universal statements.
In particular, their least possible failures have dimensions r and 2r. -/
theorem symmetric_dimensions_iff [Fact p.Prime] (hp : 5 ≤ p) :
    (∀ d ≤ 2*k+1, ∀ A : Matrix (Fin d) (Fin d) (ZMod p), A.det ≠ 0 → A.IsSymm → AffineAJT A) ↔
    (∀ d ≤ k, AtDim (ZMod p) d) := by
  constructor
  · intro h d hd A hA
    exact ((affine_symmetricLift_iff A).mp (h (d+d) (by omega) _
      (symmetricLift_det_ne_zero A hA) (symmetricLift_isSymm A))).1
  · intro h d hd A hA hs
    exact symmetric_affine_upto_double hp h hd A hA hs

end AlonJaegerTarsi.TransposeHalf

import Task.DimensionEleven
import Task.TransposeHalf

namespace AlonJaegerTarsi.AffineReduction

open Matrix Finset TransposeHalf AffineBasisTools

/-- A shift can be absorbed into one input column. Scaling a homogeneous witness
recovers the prescribed shift without passing to a higher dimension. -/
theorem affine_of_same_dimension {K : Type*} [Field K] [Fintype K] (hq : 2 < Fintype.card K)
    {n : ℕ} (hom : ∀ M : Matrix (Fin n) (Fin n) K, M.det ≠ 0 → HasAJTVector M) :
    AtDim K n := by
  classical
  intro A hA b
  cases n with
  | zero => exact ⟨0, fun i => i.elim0, fun i => i.elim0⟩
  | succ m =>
    let i : Fin (m+1) := 0
    let D := (A.updateCol i b).det
    have hcard : ({0,-A.det / D} : Finset K).card < (univ : Finset K).card :=
      (card_le_two ..).trans_lt (by simpa using hq)
    obtain ⟨c,_,hc⟩ := exists_mem_notMem_of_card_lt_card hcard
    simp only [mem_insert, mem_singleton, not_or] at hc
    let C := A.updateCol i ((fun j => A j i) + c • b)
    have hdet : C.det ≠ 0 := by
      change (A.updateCol i ((fun j => A j i) + c • b)).det ≠ 0
      rw [det_updateCol_add,det_updateCol_smul,updateCol_eq_self]
      change A.det + c * D ≠ 0
      intro h
      by_cases hd : D=0
      · exact hA (by simpa [hd] using h)
      · exact hc.2 ((eq_div_iff hd).mpr (by linear_combination h))
    obtain ⟨z,hz,hy⟩ := hom C hdet
    have hmat : C = A + vecMulVec (c • b) (Pi.single i 1) := by
      ext j k
      by_cases hk : k=i
      · subst k
        simp [C,vecMulVec_apply]
      · simp [C,updateCol_ne hk,vecMulVec_apply,Pi.single_apply,hk]
    let t := c * z i
    have ht : t ≠ 0 := mul_ne_zero hc.1 (hz i)
    have hact : C *ᵥ z = A *ᵥ z + t • b := by
      rw [hmat,add_mulVec,vecMulVec_mulVec]
      congr 1
      ext j
      simp [t,mul_comm,mul_left_comm,mul_assoc]
    refine ⟨t⁻¹ • z,fun j => mul_ne_zero (inv_ne_zero ht) (hz j),fun j h => hy j ?_⟩
    rw [hact]
    rw [mulVec_smul] at h
    change t⁻¹ * (A *ᵥ z) j + b j = 0 at h
    change (A *ᵥ z) j + t * b j = 0
    field_simp [ht] at h
    linear_combination h

theorem affine_prime_dim_le_eleven {p n : ℕ} [Fact p.Prime] (hp : 5 ≤ p) (hn : n ≤ 11) :
    AtDim (ZMod p) n :=
  affine_of_same_dimension (by rw [ZMod.card]; omega) (fun A hA => hasAJTVector_dim_le_eleven hp hn A hA)

theorem symmetric_affine_dim_le_twenty_three {p n : ℕ} [Fact p.Prime] (hp : 5 ≤ p) (hn : n ≤ 23)
    (A : Matrix (Fin n) (Fin n) (ZMod p)) (hA : A.det ≠ 0) (hs : A.IsSymm) : AffineAJT A :=
  symmetric_affine_upto_double (k := 11) hp (fun _ hd => affine_prime_dim_le_eleven hp hd) hn A hA hs

end AlonJaegerTarsi.AffineReduction

import Task.BalancedRepair
import Task.CoverEssential
import Task.PermanentRank

open Matrix Finset Module
open scoped BigOperators

namespace AlonJaegerTarsi.BalancedCover

noncomputable section

open CharacterMethod

variable {p n : ℕ} [Fact p.Prime]

theorem eval_differences {I : Type*} [DecidableEq I] (v : I → (Fin n → ZMod p))
    (s : Finset I) (b : I → ZMod p) (hb : ∀ i, b i ≠ 0) (x : Fin n → ZMod p) :
    charEval (dotChar x) (differences (fun i => b i • v i) s) ≠ 0 ↔
      ∀ j ∈ s, v j ⬝ᵥ x ≠ 0 := by
  have h (t : ZMod p) : 1 - ZMod.stdAddChar t ≠ 0 ↔ t ≠ 0 := by
    rw [sub_ne_zero, ← (ZMod.stdAddChar (N := p)).map_zero_eq_one, ZMod.injective_stdAddChar.ne_iff]
    exact ne_comm
  simp [differences, prod_ne_zero_iff, dotChar, smul_dotProduct, smul_eq_mul, h, hb]

private theorem normals_good (A : Matrix (Fin n) (Fin n) (ZMod p)) (x : Fin n → ZMod p) :
    (∀ j, normals A j ⬝ᵥ x ≠ 0) ↔ NowhereZero x ∧ NowhereZero (A *ᵥ x) := by
  constructor
  · intro h
    exact ⟨fun i => by simpa [normals] using h (.inl i), fun i => h (.inr i)⟩
  · rintro ⟨hx,hy⟩ (j|j)
    · simpa [normals] using hx j
    · exact hy j

/-- Under dimension induction, deleting any one normal produces a proper subsystem
with an avoiding functional. This uses invertibility of the actual input matrix. -/
theorem avoid_erased_normals (hp : 3 ≤ p) (hn : 2 ≤ n) (hsmall : Cover.Below (ZMod p) n)
    (A : Matrix (Fin n) (Fin n) (ZMod p)) (hA : A.det ≠ 0) (w : Fin n ⊕ Fin n) :
    ∃ x : Fin n → ZMod p, ∀ j ∈ univ.erase w, normals A j ⬝ᵥ x ≠ 0 := by
  classical
  let B := Pi.basisFun (ZMod p) (Fin n)
  let C := basisOfPiSpaceOfLinearIndependent (Matrix.linearIndependent_rows_of_det_ne_zero hA)
  have hc (i) : C i = A i := congrFun (coe_basisOfPiSpaceOfLinearIndependent _) i
  have hrow (f : (Fin n → ZMod p) →ₗ[ZMod p] ZMod p) (i) :
      normals A (Sum.inr i) ⬝ᵥ (fun j => f (B j)) = f (C i) := by
    have he : B.constr (ZMod p) (fun j => f (B j)) = f := B.ext (fun j => B.constr_basis _ _ _)
    rw [← he, hc, Basis.constr_apply_fintype]
    simp only [Basis.constr_basis]
    rfl
  have hq : 2 < Fintype.card (ZMod p) := by rw [ZMod.card]; omega
  haveI : Nontrivial (Fin n) := Fin.nontrivial_iff_two_le.mpr hn
  cases w with
  | inl i =>
    obtain ⟨k,hk⟩ := exists_ne i
    obtain ⟨f,hC,hB⟩ := Cover.avoidAllExceptOne hq hsmall (by simp) C B i k hk.symm
    refine ⟨fun j => f (B j),?_⟩
    rintro (j|j) hj
    · exact (by simpa [normals] using hB j (fun e => (mem_erase.mp hj).1 (congrArg Sum.inl e)))
    · rw [hrow]; exact hC j
  | inr i =>
    obtain ⟨k,hk⟩ := exists_ne i
    obtain ⟨f,hB,hC⟩ := Cover.avoidAllExceptOne hq hsmall (by simp) B C i k hk.symm
    refine ⟨fun j => f (B j),?_⟩
    rintro (j|j) hj
    · simpa [normals] using hB j
    · rw [hrow]
      exact hC j (fun e => (mem_erase.mp hj).1 (congrArg Sum.inr e))

/-- A smallest bad matrix would represent every target by coefficients from
any prescribed balanced set. -/
theorem witnesses_repair (hp : 3 ≤ p) (hn : 2 ≤ n) (hsmall : Cover.Below (ZMod p) n)
    (A : Matrix (Fin n) (Fin n) (ZMod p)) (hA : A.det ≠ 0) (hbad : ¬HasAJTVector A)
    (S : Finset (ZMod p)) (hS : Balanced S) (y : Fin n → ZMod p) :
    ∃ c : (Fin n ⊕ Fin n) → S, combine (normals A) (fun j => (c j).val) = y := by
  classical
  let v := normals A
  have repair (b : (Fin n ⊕ Fin n) → ZMod p) (hb : ∀ i, b i ≠ 0) (w : Fin n ⊕ Fin n) :
      ∃ U ⊆ univ.erase w, ∃ T ⊆ univ.erase w, b w • v w =
        (∑ j ∈ U, b j • v j) - ∑ j ∈ T, b j • v j := by
    let g := fun j => b j • v j
    apply relation_of_essential g univ w (mem_univ _)
    · apply eq_zero_of_charEval_eq_zero
      intro χ
      obtain ⟨x,rfl⟩ := dotChar_bijective.surjective χ
      by_contra h
      have all := (eval_differences v univ b hb x).mp h
      exact hbad ⟨x, (normals_good A x).mp (fun j => all j (mem_univ _))⟩
    · obtain ⟨x,hx⟩ := avoid_erased_normals hp hn hsmall A hA w
      have h := (eval_differences v _ b hb x).mpr hx
      intro e
      apply h
      change charEval (dotChar x) (differences g (univ.erase w)) = 0
      rw [e,map_zero]
  let a : Fin n ⊕ Fin n → ZMod p := Sum.elim y (fun _ => 0)
  obtain ⟨c,he,hc⟩ := represent_by_balanced v S hS repair a
  refine ⟨fun i => ⟨c i,hc i⟩, he.trans ?_⟩
  ext i
  simp [combine,v,normals,a,Fintype.sum_sum_type,Finset.sum_apply,Pi.single_apply,
    smul_eq_mul]

/-- The balanced-set cardinality criterion of Nagy–Pach–Tomon for two bases.
The dimension is arbitrary. -/
theorem hasAJTVector_of_balanced (hp : 5 ≤ p) (S : Finset (ZMod p))
    (hS : Balanced S) (hsize : S.card^2 < p)
    (A : Matrix (Fin n) (Fin n) (ZMod p)) (hA : A.det ≠ 0) : HasAJTVector A := by
  induction n using Nat.strong_induction_on with
  | h n ih =>
    by_cases hn : 2 ≤ n
    · have lower : Cover.Below (ZMod p) n := fun d hd B hB => ih d hd B hB
      by_contra hbad
      have h := Fintype.card_le_of_surjective (fun c : (Fin n ⊕ Fin n) → S =>
        combine (normals A) (fun j => (c j).val))
        (witnesses_repair (by omega) hn lower A hA hbad S hS)
      have hpow : p^n ≤ (S.card^2)^n := by
        simpa [Fintype.card_fun,Fintype.card_sum,← pow_mul,two_mul,Nat.mul_comm] using h
      exact (Nat.not_lt_of_ge hpow) (Nat.pow_lt_pow_left hsize (by omega))
    · apply PermanentApproach.hasAJTVector_prime_dim_lt A hA
      calc n ≤ 1 := by omega
           _ < 2^1 := by decide
           _ ≤ 2^(p-2) := Nat.pow_le_pow_right (by decide) (by omega)

end
end AlonJaegerTarsi.BalancedCover

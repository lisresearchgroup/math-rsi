import Task.Basic

/-! The integral group ring criterion for the prime-field AJT property. -/

open scoped BigOperators
open Matrix

namespace AlonJaegerTarsi.CharacterMethod

noncomputable section
variable {G : Type*} [AddCommGroup G]

/-- The algebra homomorphism that evaluates group elements at an additive character. -/
def charEval (ψ : AddChar G ℂ) : AddMonoidAlgebra ℤ G →+* ℂ :=
  AddMonoidAlgebra.liftNCRingHom (Int.castRingHom ℂ) ψ.toMonoidHom (fun _ _ => Commute.all ..)

@[simp] theorem charEval_single (ψ : AddChar G ℂ) (v : G) (a : ℤ) :
    charEval ψ (AddMonoidAlgebra.single v a) = a * ψ v := by
  simp [charEval]

theorem charEval_eq_sum [Fintype G] (ψ : AddChar G ℂ) (f : AddMonoidAlgebra ℤ G) :
    charEval ψ f = ∑ v, (f.coeff v : ℂ) * ψ v := by
  classical
  conv_lhs => rw [← AddMonoidAlgebra.sum_coeff_single f, Finsupp.sum, map_sum]
  simp only [charEval_single]
  apply Finset.sum_subset (Finset.subset_univ _)
  intro v _ hv
  simp [Finsupp.notMem_support_iff.mp hv]

/-- Orthogonality of finite complex characters recovers every coefficient of the integral
group ring element. -/
theorem eq_zero_of_charEval_eq_zero [Fintype G] (f : AddMonoidAlgebra ℤ G)
    (hf : ∀ ψ, charEval ψ f = 0) : f = 0 := by
  classical
  ext v
  have h : (∑ ψ : AddChar G ℂ, charEval ψ f * ψ (-v)) = 0 := by simp [hf]
  simp_rw [charEval_eq_sum, Finset.sum_mul, mul_assoc, ← AddChar.map_add_eq_mul] at h
  rw [Finset.sum_comm] at h
  simp_rw [← Finset.mul_sum, AddChar.sum_apply_eq_ite, ← sub_eq_add_neg, sub_eq_zero] at h
  simpa using h

variable {n p : ℕ} [NeZero p]

/-- Additive character indexed by a vector in the dual coordinate space. -/
def dotChar (x : Fin n → ZMod p) : AddChar (Fin n → ZMod p) ℂ where
  toFun v := ZMod.stdAddChar (v ⬝ᵥ x)
  map_zero_eq_one' := by simp
  map_add_eq_mul' _ _ := by rw [add_dotProduct, AddChar.map_add_eq_mul]

theorem dotChar_bijective : Function.Bijective (dotChar (n := n) (p := p)) := by
  refine (Fintype.bijective_iff_injective_and_card _).mpr ⟨?_, AddChar.card_eq.symm⟩
  intro x y h
  funext j
  apply ZMod.injective_stdAddChar
  simpa [dotChar, single_dotProduct] using
    (DFunLike.congr_fun h (Pi.single j (1 : ZMod p)))

/-- One difference operator for each standard basis vector and each row vector. -/
def differenceProduct (A : Matrix (Fin n) (Fin n) (ZMod p)) :
    AddMonoidAlgebra ℤ (Fin n → ZMod p) :=
  (∏ i, (1 - AddMonoidAlgebra.single (Pi.single i (1 : ZMod p)) 1)) *
    ∏ i, (1 - AddMonoidAlgebra.single (A i) 1)

theorem eval_differenceProduct (A : Matrix (Fin n) (Fin n) (ZMod p)) (x : Fin n → ZMod p) :
    charEval (dotChar x) (differenceProduct A) ≠ 0 ↔ NowhereZero x ∧ NowhereZero (A *ᵥ x) := by
  classical
  have h (a : ZMod p) : 1 - ZMod.stdAddChar a ≠ 0 ↔ a ≠ 0 := by
    rw [sub_ne_zero, ← (ZMod.stdAddChar (N := p)).map_zero_eq_one, ZMod.injective_stdAddChar.ne_iff]
    exact ne_comm
  simp only [differenceProduct, map_prod, map_sub, map_one, map_mul, charEval_single,
    Int.cast_one, one_mul, mul_ne_zero_iff, Finset.prod_ne_zero_iff, Finset.mem_univ,
    forall_const, dotChar, AddChar.coe_mk, single_dotProduct, h, NowhereZero, Matrix.mulVec]

/-- A Fourier formulation of the exact AJT property. -/
theorem hasAJTVector_iff_differenceProduct_ne_zero (A : Matrix (Fin n) (Fin n) (ZMod p)) :
    HasAJTVector A ↔ differenceProduct A ≠ 0 := by
  constructor
  · rintro ⟨x, hx, hAx⟩ hzero
    exact (eval_differenceProduct A x).mpr ⟨hx, hAx⟩ (hzero ▸ map_zero _)
  · contrapose!
    intro h
    apply eq_zero_of_charEval_eq_zero
    intro χ
    obtain ⟨x, rfl⟩ := dotChar_bijective.surjective χ
    by_contra hχ
    exact h ⟨x, (eval_differenceProduct A x).mp hχ⟩

/-- The two lists of normal vectors, indexed disjointly so equal vectors retain their
multiplicity. -/
def normals (A : Matrix (Fin n) (Fin n) (ZMod p)) :
    Fin n ⊕ Fin n → (Fin n → ZMod p) :=
  Sum.elim (fun i => Pi.single i 1) (fun i => A i)

omit [NeZero p] in
/-- Subset-sum expansion of the difference operators. -/
theorem differenceProduct_expansion (A : Matrix (Fin n) (Fin n) (ZMod p)) :
    differenceProduct A =
      ∑ S : Finset (Fin n ⊕ Fin n),
        AddMonoidAlgebra.single (∑ i ∈ S, normals A i) ((-1 : ℤ) ^ S.card) := by
  classical
  have he : differenceProduct A =
      ∏ i, (1 - AddMonoidAlgebra.single (normals A i) (1 : ℤ)) := by
    rw [Fintype.prod_sum_type]
    rfl
  rw [he]
  simp_rw [sub_eq_add_neg, ← AddMonoidAlgebra.single_neg]
  rw [Finset.prod_one_add]
  simp only [Finset.powerset_univ, AddMonoidAlgebra.prod_single, Finset.prod_const]

/-- A unique subset sum gives a coefficient of absolute value one and supplies an AJT
vector. -/
theorem hasAJTVector_of_unique_subset_sum (A : Matrix (Fin n) (Fin n) (ZMod p))
    (S : Finset (Fin n ⊕ Fin n))
    (h : ∀ T : Finset (Fin n ⊕ Fin n),
      (∑ i ∈ T, normals A i) = (∑ i ∈ S, normals A i) → T = S) : HasAJTVector A := by
  classical
  apply (hasAJTVector_iff_differenceProduct_ne_zero A).mpr
  intro he
  let v := ∑ i ∈ S, normals A i
  have hzero := congrArg (fun f : AddMonoidAlgebra ℤ (Fin n → ZMod p) => f.coeff v) he
  rw [differenceProduct_expansion] at hzero
  simp only [AddMonoidAlgebra.coeff_sum, Finsupp.finsetSum_apply,
    AddMonoidAlgebra.coeff_single, Finsupp.single_apply, AddMonoidAlgebra.coeff_zero, Finsupp.zero_apply] at hzero
  rw [Finset.sum_eq_single S] at hzero
  · simp [v] at hzero
  · intro T _ hne
    exact if_neg (fun hz => hne (h T hz))
  · simp

end
end AlonJaegerTarsi.CharacterMethod

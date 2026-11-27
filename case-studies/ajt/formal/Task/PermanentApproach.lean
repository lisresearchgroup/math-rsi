import Task.Basic

/-! Polynomial certificates for a nowhere-zero vector. -/

namespace AlonJaegerTarsi.PermanentApproach

open Matrix MvPolynomial
open scoped BigOperators

noncomputable section

variable {n : ℕ}

/-- The product of the row forms evaluates to the product of the output coordinates. -/
def rowProduct {R : Type*} [CommSemiring R] (A : Matrix (Fin n) (Fin n) R) :
    MvPolynomial (Fin n) R :=
  ∏ i, ∑ j, C (A i j) * X j

theorem eval_rowProduct {R : Type*} [CommSemiring R] (A : Matrix (Fin n) (Fin n) R)
    (x : Fin n → R) : eval x (rowProduct A) = ∏ i, (A *ᵥ x) i := by
  simp [rowProduct, Matrix.mulVec, dotProduct]

/-- For a map selecting one entry in each row, count the selections in every column. -/
def columnCounts (f : Fin n → Fin n) : Fin n →₀ ℕ := ∑ i, Finsupp.single (f i) 1

theorem coeff_rowProduct {R : Type*} [CommSemiring R] (A : Matrix (Fin n) (Fin n) R)
    (t : Fin n →₀ ℕ) :
    (rowProduct A).coeff t = ∑ f : Fin n → Fin n,
      if columnCounts f = t then ∏ i, A i (f i) else 0 := by
  classical
  rw [rowProduct, Fintype.prod_sum, coeff_sum]
  apply Finset.sum_congr rfl
  intro f _
  simp_rw [X, C_mul_monomial, mul_one]
  rw [← monomial_sum_prod, coeff_monomial]
  rfl

/-- A degree-`n` nonzero coefficient whose exponents fit into the nonzero grid yields AJT. -/
theorem hasAJTVector_of_coeff {F : Type*} [Field F] [Fintype F] (A : Matrix (Fin n) (Fin n) F)
    (t : Fin n →₀ ℕ) (ht : (rowProduct A).coeff t ≠ 0) (hd : t.degree = n)
    (hsmall : ∀ i, t i < Fintype.card F - 1) : HasAJTVector A := by
  classical
  have hupper : (rowProduct A).totalDegree ≤ n := by
    refine (totalDegree_finsetProd _ _).trans ?_
    calc
      _ ≤ ∑ _i : Fin n, 1 := Finset.sum_le_sum fun i _ =>
        totalDegree_finsetSum_le fun j _ => (totalDegree_mul _ _).trans <| by simp
      _ = n := by simp
  have hdegree : (rowProduct A).totalDegree = t.degree := by
    apply Nat.le_antisymm (hupper.trans (Nat.le_of_eq hd.symm))
    exact le_totalDegree (mem_support_iff.mpr ht)
  obtain ⟨x, hx, hAx⟩ := combinatorial_nullstellensatz_exists_eval_nonzero (rowProduct A) t ht
    hdegree (fun _ => (Finset.univ : Finset F).erase 0) (by simpa using hsmall)
  refine ⟨x, fun i => (Finset.mem_erase.mp (hx i)).1, ?_⟩
  rw [eval_rowProduct] at hAx
  exact fun i hi => hAx (Finset.prod_eq_zero (Finset.mem_univ i) hi)

/-- Choosing each column once is equivalent to choosing a permutation. -/
theorem columnCounts_eq_id_iff (f : Fin n → Fin n) :
    columnCounts f = columnCounts id ↔ Function.Bijective f := by
  classical
  constructor
  · intro h
    have hs : Function.Surjective f := by
      intro j
      by_contra! hj
      have h0 : columnCounts f j = 0 := by
        simp [columnCounts, Finsupp.finsetSum_apply, hj]
      rw [h] at h0
      simp [columnCounts, Finsupp.finsetSum_apply] at h0
    exact ⟨Finite.injective_iff_surjective.mpr hs, hs⟩
  · intro h
    exact Fintype.sum_equiv (Equiv.ofBijective f h) (fun i => Finsupp.single (f i) 1)
      (fun i => Finsupp.single i 1) (fun _ => rfl)

theorem coeff_squarefree_eq_permanent {R : Type*} [CommSemiring R]
    (A : Matrix (Fin n) (Fin n) R) :
    (rowProduct A).coeff (columnCounts id) = A.permanent := by
  classical
  rw [coeff_rowProduct]
  simp_rw [columnCounts_eq_id_iff]
  rw [← Finset.sum_filter, Finset.sum_subtype _ (by simp : ∀ f : Fin n → Fin n,
    f ∈ Finset.univ.filter (Function.Bijective ·) ↔ Function.Bijective f)]
  calc
    _ = Aᵀ.permanent := Fintype.sum_equiv Equiv.bijectiveEquiv _ _ fun _ => rfl
    _ = A.permanent := A.permanent_transpose

/-- A nonzero permanent suffices over any finite field with at least three elements. -/
theorem hasAJTVector_of_permanent {F : Type*} [Field F] [Fintype F] (hF : 2 < Fintype.card F)
    (A : Matrix (Fin n) (Fin n) F) (hp : A.permanent ≠ 0) : HasAJTVector A := by
  apply hasAJTVector_of_coeff A (columnCounts id) (by rwa [coeff_squarefree_eq_permanent])
  · simp [columnCounts]
  · intro i
    simpa [columnCounts, Finsupp.finsetSum_apply] using (show 1 < Fintype.card F - 1 by omega)

theorem columnCounts_apply (f : Fin n → Fin n) (j : Fin n) :
    columnCounts f j = Fintype.card {i // f i = j} := by
  classical
  simp only [columnCounts, Finsupp.finsetSum_apply, Finsupp.single_apply, Fintype.card_subtype,
    Finset.card_filter]

private theorem columnCounts_comp_perm (g : Fin n → Fin n) (σ : Equiv.Perm (Fin n)) :
    columnCounts (g ∘ σ) = columnCounts g :=
  Fintype.sum_equiv σ _ _ fun _ => rfl

private theorem exists_rearrangement {f g : Fin n → Fin n} (h : columnCounts f = columnCounts g) :
    ∃ σ : Equiv.Perm (Fin n), g ∘ σ = f := by
  classical
  let e (j : Fin n) : {i // f i = j} ≃ {i // g i = j} :=
    Fintype.equivOfCardEq (by rw [← columnCounts_apply, ← columnCounts_apply, h])
  exact ⟨Equiv.ofFiberEquiv e, funext (Equiv.ofFiberEquiv_map e)⟩

/-- Permute the labels of equal columns in a repeated-column minor. -/
private def reassignmentEquiv (g : Fin n → Fin n) (ρ : Equiv.Perm (Fin n)) :
    {σ : Equiv.Perm (Fin n) // g ∘ σ = g} ≃
    {σ : Equiv.Perm (Fin n) // g ∘ σ = g ∘ ρ} where
  toFun σ := ⟨ρ.trans σ.val, congrArg (fun f => f ∘ ρ) σ.property⟩
  invFun σ := ⟨ρ.symm.trans σ.val, by
    funext i
    exact (congrFun σ.property (ρ.symm i)).trans (congrArg g (ρ.apply_symm_apply i))⟩
  left_inv σ := by ext i; simp
  right_inv σ := by ext i; simp

/-- Repeating a column turns the coefficient for its multiplicity vector into a permanent.
The multiplicative factor counts permutations preserving the list of repeated columns. -/
theorem permanent_repeat_eq {R : Type*} [CommSemiring R]
    (A : Matrix (Fin n) (Fin n) R) (g : Fin n → Fin n) :
    (A.submatrix id g).permanent =
      Fintype.card {σ : Equiv.Perm (Fin n) // g ∘ σ = g} •
        (rowProduct A).coeff (columnCounts g) := by
  classical
  let orbit (σ : Equiv.Perm (Fin n)) : Fin n → Fin n := g ∘ σ
  let w (f : Fin n → Fin n) := ∏ i, A i (f i)
  rw [← (A.submatrix id g).permanent_transpose, coeff_rowProduct, Finset.smul_sum]
  change ∑ σ : Equiv.Perm (Fin n), w (orbit σ) = _
  rw [← Finset.sum_fiberwise' Finset.univ orbit w]
  apply Finset.sum_congr rfl
  intro f _
  by_cases h : columnCounts f = columnCounts g
  · rw [if_pos h, Finset.sum_const]
    congr 1
    rw [← Fintype.card_subtype (fun σ => orbit σ = f)]
    obtain ⟨ρ, rfl⟩ := exists_rearrangement h
    exact Fintype.card_congr (reassignmentEquiv g ρ).symm
  · rw [if_neg h, smul_zero, Finset.sum_const, Finset.filter_eq_empty_iff.mpr]
    · simp
    · intro σ _ heq
      apply h
      rw [← heq]
      exact columnCounts_comp_perm g σ

/-- A full-size nonzero permanent after repeating any column at most `|F| - 2` times
certifies the original matrix in all dimensions. -/
theorem hasAJTVector_of_repeated_permanent {F : Type*} [Field F] [Fintype F]
    (A : Matrix (Fin n) (Fin n) F) (g : Fin n → Fin n)
    (hcap : ∀ j, columnCounts g j < Fintype.card F - 1)
    (hper : (A.submatrix id g).permanent ≠ 0) : HasAJTVector A := by
  refine hasAJTVector_of_coeff A (columnCounts g) ?_ (by simp [columnCounts]) hcap
  intro hz
  apply hper
  rw [permanent_repeat_eq, hz, smul_zero]

end
end AlonJaegerTarsi.PermanentApproach

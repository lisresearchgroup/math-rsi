import Task.PermanentApproach

/-! The permanent-rank dimension bound for the AJT property. -/

noncomputable section

namespace AlonJaegerTarsi.PermanentApproach

open Matrix MvPolynomial
open scoped BigOperators

variable {n : ℕ} {F : Type*} [Field F]

/-- A linear form in the row variables, as a linear function of its coefficients. -/
def columnForm : (Fin n → F) →ₗ[F] MvPolynomial (Fin n) F :=
  ∑ j, (LinearMap.proj j).smulRight (X j)

theorem columnForm_apply (v : Fin n → F) :
    columnForm v = ∑ j, C (v j) * X j := by
  simp [columnForm, MvPolynomial.smul_eq_C_mul]

/-- The exponent vector with one on `s` and zero elsewhere. -/
def subsetExponent (s : Finset (Fin n)) : Fin n →₀ ℕ :=
  ∑ i ∈ s, Finsupp.single i 1

theorem subsetExponent_apply (s : Finset (Fin n)) (j : Fin n) :
    subsetExponent s j = if j ∈ s then 1 else 0 := by
  simp [subsetExponent, Finsupp.finsetSum_apply, Finsupp.single_apply]

theorem subsetExponent_insert {s : Finset (Fin n)} {i : Fin n} (hi : i ∉ s) :
    subsetExponent (insert i s) = subsetExponent s + Finsupp.single i 1 := by
  simp [subsetExponent, hi, add_comm]

/-- If the coefficients of a linear form vanish on an already used row set, one new row
can contribute to the indicated squarefree coefficient only through the matching term. -/
theorem coeff_extend_subset (Q : MvPolynomial (Fin n) F) (s : Finset (Fin n))
    (v : Fin n → F) (hz : ∀ j ∈ s, v j = 0) (i : Fin n) (hi : i ∉ s) :
    (Q * columnForm v).coeff (subsetExponent (insert i s)) =
      v i * Q.coeff (subsetExponent s) := by
  classical
  rw [columnForm_apply, Finset.mul_sum, coeff_sum, Finset.sum_eq_single i]
  · rw [mul_left_comm Q, coeff_C_mul, subsetExponent_insert hi, coeff_mul_X]
  · intro j _ hji
    by_cases hjs : j ∈ s
    · simp [hz j hjs]
    · have hzero : subsetExponent (insert i s) j = 0 := by simp [subsetExponent_apply, hjs, hji]
      rw [mul_left_comm Q, coeff_C_mul, coeff_mul_X', if_neg (by simpa using hzero), mul_zero]
  · simp

/-- The unused independent columns that kill every one-row extension inject under restriction
to the occupied row set. -/
theorem card_unused_le_card_rows (A : Matrix (Fin n) (Fin n) F) (hA : A.det ≠ 0)
    (Q : MvPolynomial (Fin n) F) (s rows : Finset (Fin n))
    (hq : Q.coeff (subsetExponent rows) ≠ 0)
    (hkill : ∀ j ∉ s, ∀ i ∉ rows,
      (Q * columnForm (A.col j)).coeff (subsetExponent (insert i rows)) = 0) :
    n - s.card ≤ rows.card := by
  classical
  let I := {j : Fin n // j ∉ s}
  have hind : LinearIndependent F (fun j : I => fun i : rows => A i j) := by
    apply Fintype.linearIndependent_iff.mpr
    intro l hlin j
    have hcolumns : LinearIndependent F (fun a : I => A.col a.val) :=
      (Matrix.linearIndependent_cols_of_det_ne_zero hA).comp Subtype.val Subtype.val_injective
    apply Fintype.linearIndependent_iff.mp hcolumns l _ j
    let v := ∑ a : I, l a • A.col a.val
    change v = 0
    have hrows (i : Fin n) (hi : i ∈ rows) : v i = 0 := by
      simpa [v, Matrix.col, Finset.sum_apply] using congrFun hlin ⟨i, hi⟩
    ext i
    by_cases hi : i ∈ rows
    · exact hrows i hi
    · have h : (Q * columnForm v).coeff (subsetExponent (insert i rows)) = 0 := by
        simp only [v, map_sum, map_smul, Finset.mul_sum, mul_smul_comm, coeff_sum, coeff_smul]
        exact Finset.sum_eq_zero fun a _ => by rw [hkill a a.property i hi, smul_zero]
      rw [coeff_extend_subset Q rows v hrows i hi] at h
      exact (mul_eq_zero.mp h).resolve_right hq
  have hcard := hind.fintype_card_le_finrank
  simpa [I, Fintype.card_subtype_compl, Module.finrank_fintype_fun_eq_card] using hcard

/-- A product has a nonzero squarefree coefficient using exactly `r` rows. -/
def HasMinor (P : MvPolynomial (Fin n) F) (r : ℕ) : Prop :=
  ∃ rows : Finset (Fin n), rows.card = r ∧ P.coeff (subsetExponent rows) ≠ 0

/-- One copy of an independent column basis cuts the remaining deficit at least in half. -/
theorem extend_in_one_copy (A : Matrix (Fin n) (Fin n) F) (hA : A.det ≠ 0)
    (P : MvPolynomial (Fin n) F) (r : ℕ) (hP : HasMinor P r) :
    ∃ s : Finset (Fin n), HasMinor (P * ∏ j ∈ s, columnForm (A.col j)) (r + s.card) ∧
      2 * (n - (r + s.card)) ≤ n - r := by
  classical
  let Q (s : Finset (Fin n)) := P * ∏ j ∈ s, columnForm (A.col j)
  let ok (s : Finset (Fin n)) := HasMinor (Q s) (r + s.card)
  let choices := Finset.univ.filter ok
  have hempty : ∅ ∈ choices := by simpa [choices, Q, ok] using hP
  obtain ⟨s, hs, hmax⟩ := choices.exists_max_image Finset.card ⟨∅, hempty⟩
  have hgood : ok s := (Finset.mem_filter.mp hs).2
  refine ⟨s, hgood, ?_⟩
  obtain ⟨rows, hrows, hc⟩ := hgood
  have hbound := card_unused_le_card_rows A hA (Q s) s rows hc (by
    intro j hjs i hir
    by_contra hnon
    have hmore : insert j s ∈ choices := by
      apply Finset.mem_filter.mpr
      refine ⟨Finset.mem_univ _, insert i rows, ?_, ?_⟩
      · simp [hjs, hir, hrows, Nat.add_assoc]
      · simpa [Q, hjs, mul_comm, mul_left_comm, mul_assoc] using hnon
    have hle := hmax _ hmore
    simp [hjs] at hle)
  omega

/-- A multiset of chosen columns, recorded by its coordinatewise multiplicities. -/
def chosenColumns (A : Matrix (Fin n) (Fin n) F) (d : Fin n → ℕ) :
    MvPolynomial (Fin n) F := ∏ j, columnForm (A.col j) ^ d j

private def addCopy (d : Fin n → ℕ) (s : Finset (Fin n)) (j : Fin n) : ℕ :=
  d j + if j ∈ s then 1 else 0

private theorem chosenColumns_addCopy (A : Matrix (Fin n) (Fin n) F)
    (d : Fin n → ℕ) (s : Finset (Fin n)) :
    chosenColumns A (addCopy d s) = chosenColumns A d * ∏ j ∈ s, columnForm (A.col j) := by
  classical
  simp only [chosenColumns, addCopy, pow_add, Finset.prod_mul_distrib]
  congr 1
  calc
    _ = ∏ j, if j ∈ s then columnForm (A.col j) else 1 := by
      apply Finset.prod_congr rfl
      intro j _
      split_ifs <;> simp
    _ = _ := by rw [← Finset.prod_filter]; simp

private theorem sum_addCopy (d : Fin n → ℕ) (s : Finset (Fin n)) :
    ∑ j, addCopy d s j = (∑ j, d j) + s.card := by
  classical
  simp [addCopy, Finset.sum_add_distrib]

/-- After `k` more copies one can extend the previous multiplicities to reach a deficit at most the old deficit divided by `2^k`. -/
theorem extend_in_copies (A : Matrix (Fin n) (Fin n) F) (hA : A.det ≠ 0)
    (d : Fin n → ℕ) (hd : HasMinor (chosenColumns A d) (∑ j, d j)) (k : ℕ) :
    ∃ e : Fin n → ℕ, (∀ j, e j ≤ d j + k) ∧ HasMinor (chosenColumns A e) (∑ j, e j) ∧
      2 ^ k * (n - ∑ j, e j) ≤ n - ∑ j, d j := by
  induction k with
  | zero => exact ⟨d, by simp, hd, by simp⟩
  | succ k ih =>
    obtain ⟨b, hb, hm, hr⟩ := ih
    obtain ⟨s, hs, hhalf⟩ := extend_in_one_copy A hA (chosenColumns A b) _ hm
    refine ⟨addCopy b s, ?_, ?_, ?_⟩
    · intro j
      have hj := hb j
      simp only [addCopy]
      split <;> omega
    · simpa [sum_addCopy, chosenColumns_addCopy] using hs
    · rw [sum_addCopy, pow_succ, Nat.mul_assoc]
      exact (Nat.mul_le_mul_left (2^k) hhalf).trans hr

private theorem hasAJTVector_of_full_selection [Fintype F] (A : Matrix (Fin n) (Fin n) F)
    (e : Fin n → ℕ) (he : ∑ j, e j = n) (hcap : ∀ j, e j < Fintype.card F - 1)
    (hper : (chosenColumns A e).coeff (subsetExponent Finset.univ) ≠ 0) :
    HasAJTVector A := by
  classical
  let E : Fin n ≃ Σ j : Fin n, Fin (e j) := Fintype.equivOfCardEq (by simp [he])
  let g (j : Fin n) := (E j).1
  have hg (j : Fin n) : columnCounts g j = e j := by
    rw [columnCounts, Finsupp.finsetSum_apply]
    calc
      _ = ∑ u : Σ j : Fin n, Fin (e j), Finsupp.single u.1 1 j :=
        Fintype.sum_equiv E _ _ fun _ => rfl
      _ = e j := by
        rw [Fintype.sum_sigma]
        simp [Finsupp.single_apply]
  have hpoly : rowProduct (A.submatrix id g)ᵀ = chosenColumns A e := by
    calc
      _ = ∏ j, columnForm (A.col (g j)) := by
        simp [rowProduct, columnForm_apply, Matrix.col]
      _ = ∏ u : Σ j : Fin n, Fin (e j), columnForm (A.col u.1) :=
        Fintype.prod_equiv E _ _ fun _ => rfl
      _ = _ := by simp [Fintype.prod_sigma, chosenColumns]
  apply hasAJTVector_of_repeated_permanent A g (by simpa only [hg] using hcap)
  rw [← (A.submatrix id g).permanent_transpose, ← coeff_squarefree_eq_permanent, hpoly]
  exact hper

/-- From any initial nonzero squarefree column minor, `k` more copies suffice as soon as
its deficit is less than `2^k` and the resulting column multiplicities fit in the grid. -/
theorem hasAJTVector_of_permanent_deficit [Fintype F] (A : Matrix (Fin n) (Fin n) F)
    (hA : A.det ≠ 0) (d : Fin n → ℕ) (k : ℕ) (hd : HasMinor (chosenColumns A d) (∑ j, d j))
    (hgap : n - ∑ j, d j < 2 ^ k) (hcap : ∀ j, d j + k < Fintype.card F - 1) :
    HasAJTVector A := by
  obtain ⟨e, hle, ⟨rows, he, hc⟩, hdef⟩ := extend_in_copies A hA d hd k
  have hcard : ∑ j, e j ≤ n := by simpa only [← he, Fintype.card_fin] using rows.card_le_univ
  have hfull : ∑ j, e j = n := by
    by_contra h
    have hb : 2 ^ k ≤ 2 ^ k * (n - ∑ j, e j) := Nat.le_mul_of_pos_right _ (by omega)
    omega
  have huniv : rows = Finset.univ := rows.eq_univ_of_card (by simp [he, hfull])
  exact hasAJTVector_of_full_selection A e hfull (fun j => (hle j).trans_lt (hcap j))
    (huniv ▸ hc)

/-- Yu's dimension guarantee for an arbitrary finite field. -/
theorem hasAJTVector_of_dimension_lt_two_pow [Fintype F] (A : Matrix (Fin n) (Fin n) F)
    (hA : A.det ≠ 0) (hdim : n < 2 ^ (Fintype.card F - 2)) : HasAJTVector A := by
  have hcard : 1 < Fintype.card F := Fintype.one_lt_card
  apply hasAJTVector_of_permanent_deficit A hA (fun _ => 0) (Fintype.card F - 2)
  · exact ⟨∅, by simp, by simp [chosenColumns, subsetExponent]⟩
  · simpa using hdim
  · intro j
    omega

/-- Prime-field specialization with the same matrix and determinant hypotheses as the fixed task. -/
theorem hasAJTVector_prime_dim_lt {p : ℕ} [Fact p.Prime] (A : Matrix (Fin n) (Fin n) (ZMod p))
    (hA : A.det ≠ 0) (h : n < 2 ^ (p - 2)) : HasAJTVector A :=
  hasAJTVector_of_dimension_lt_two_pow A hA (by simpa using h)

end AlonJaegerTarsi.PermanentApproach

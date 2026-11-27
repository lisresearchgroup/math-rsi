import Task.DimensionTen

namespace AlonJaegerTarsi.AffineReduction

open Matrix

variable {K : Type*} [Field K] {n m : ℕ}

/-- Each row may prescribe its own additive shift. -/
def AffineAJT (A : Matrix (Fin n) (Fin n) K) : Prop :=
  ∀ b : Fin n → K, ∃ x, NowhereZero x ∧ NowhereZero (A *ᵥ x + b)

/-- Translating the input also allows an arbitrary forbidden value in each input coordinate. -/
theorem affine_iff_avoid (A : Matrix (Fin n) (Fin n) K) :
    AffineAJT A ↔ ∀ u v : Fin n → K, ∃ x, (∀ i, x i ≠ u i) ∧ (∀ i, (A *ᵥ x) i ≠ v i) := by
  constructor
  · intro h u v
    obtain ⟨z, hz, hAz⟩ := h (A *ᵥ u - v)
    refine ⟨z + u, fun i he => hz i (by simpa using he), fun i he => hAz i ?_⟩
    rw [mulVec_add] at he
    change (A *ᵥ z) i + ((A *ᵥ u) i - v i) = 0
    change (A *ᵥ z) i + (A *ᵥ u) i = v i at he
    rw [← he]
    ring
  · intro h b
    obtain ⟨z, hz, hAz⟩ := h 0 (-b)
    exact ⟨z, hz, fun i he => hAz i (eq_neg_of_add_eq_zero_left he)⟩

/-- The last coordinate homogenizes all the shifts simultaneously. -/
def homogenize (A : Matrix (Fin n) (Fin n) K) (b : Fin n → K) :
    Matrix (Fin (n+1)) (Fin (n+1)) K :=
  (fromBlocks A (replicateCol (Fin 1) b) 0 (1 : Matrix (Fin 1) (Fin 1) K)).submatrix
    finSumFinEquiv.symm finSumFinEquiv.symm

@[simp] theorem det_homogenize (A : Matrix (Fin n) (Fin n) K) (b : Fin n → K) :
    (homogenize A b).det = A.det := by
  simp [homogenize]

private theorem column_action (b : Fin n → K) (y : Fin 1 → K) (i : Fin n) :
    (replicateCol (Fin 1) b *ᵥ y) i = b i * y 0 := by
  simp [replicateCol, mulVec, dotProduct]

theorem homogenize_iff (A : Matrix (Fin n) (Fin n) K) (b : Fin n → K) :
    HasAJTVector (homogenize A b) ↔ ∃ x, NowhereZero x ∧ NowhereZero (A *ᵥ x + b) := by
  constructor
  · rintro ⟨z, hz, hAz⟩
    let w : Fin n ⊕ Fin 1 → K := z ∘ finSumFinEquiv
    let t := w (.inr 0)
    let x := w ∘ Sum.inl
    have ht : t ≠ 0 := hz _
    have hrow (i : Fin n) : (A *ᵥ x) i + b i * t ≠ 0 := by
      have h := hAz (finSumFinEquiv (.inl i))
      simpa [homogenize, submatrix_mulVec_equiv, fromBlocks_mulVec, column_action, w, t, x] using h
    refine ⟨t⁻¹ • x, fun i => mul_ne_zero (inv_ne_zero ht) (hz _), fun i he => hrow i ?_⟩
    rw [mulVec_smul] at he
    change t⁻¹ * (A *ᵥ x) i + b i = 0 at he
    field_simp [ht] at he
    linear_combination he
  · rintro ⟨x, hx, hAx⟩
    let z : Fin n ⊕ Fin 1 → K := Sum.elim x (fun _ => 1)
    refine ⟨z ∘ finSumFinEquiv.symm, fun i => ?_, fun i => ?_⟩
    · obtain ⟨j, rfl⟩ := finSumFinEquiv.surjective i
      cases j with
      | inl j => simpa [z] using hx j
      | inr j => simp [z]
    · obtain ⟨j, rfl⟩ := finSumFinEquiv.surjective i
      cases j with
      | inl j =>
        simpa [homogenize, submatrix_mulVec_equiv, fromBlocks_mulVec, column_action, z, Function.comp_def] using hAx j
      | inr j =>
        simp [homogenize, submatrix_mulVec_equiv, fromBlocks_mulVec, z, Function.comp_def]

theorem affine_of_succ (A : Matrix (Fin n) (Fin n) K) (hA : A.det ≠ 0)
    (h : ∀ B : Matrix (Fin (n+1)) (Fin (n+1)) K, B.det ≠ 0 → HasAJTVector B) :
    AffineAJT A :=
  fun b => (homogenize_iff A b).mp (h _ (by simpa using hA))

theorem homogeneous_of_affine (A : Matrix (Fin n) (Fin n) K) (h : AffineAJT A) :
    HasAJTVector A := by
  obtain ⟨x, hx, hAx⟩ := h 0
  exact ⟨x, hx, by simpa using hAx⟩

theorem universal_iff :
    (∀ (d : ℕ) (A : Matrix (Fin d) (Fin d) K), A.det ≠ 0 → HasAJTVector A) ↔
    ∀ (d : ℕ) (A : Matrix (Fin d) (Fin d) K), A.det ≠ 0 → AffineAJT A :=
  ⟨fun h _ A hA => affine_of_succ A hA (h _),
   fun h d A hA => homogeneous_of_affine A (h d A hA)⟩

/-- An arbitrary off-diagonal block is allowed when the two diagonal blocks solve
the affine problem. -/
theorem affine_fromBlocks (B : Matrix (Fin m) (Fin m) K) (C : Matrix (Fin n) (Fin m) K)
    (D : Matrix (Fin n) (Fin n) K) (hB : AffineAJT B) (hD : AffineAJT D) :
    AffineAJT ((fromBlocks B 0 C D).submatrix finSumFinEquiv.symm finSumFinEquiv.symm) := by
  intro b
  let b' : Fin m ⊕ Fin n → K := b ∘ finSumFinEquiv
  obtain ⟨x, hx, hBx⟩ := hB (b' ∘ Sum.inl)
  obtain ⟨y, hy, hDy⟩ := hD (C *ᵥ x + b' ∘ Sum.inr)
  let z := Sum.elim x y
  refine ⟨z ∘ finSumFinEquiv.symm, fun j => ?_, fun j => ?_⟩
  · obtain ⟨i, rfl⟩ := finSumFinEquiv.surjective j
    cases i with
    | inl i => simpa [z] using hx i
    | inr i => simpa [z] using hy i
  · obtain ⟨i, rfl⟩ := finSumFinEquiv.surjective j
    cases i with
    | inl i => simpa [submatrix_mulVec_equiv, fromBlocks_mulVec, z, b', Function.comp_def] using hBx i
    | inr i => simpa [submatrix_mulVec_equiv, fromBlocks_mulVec, z, b', Function.comp_def,
        add_left_comm, add_comm, add_assoc] using hDy i

theorem affine_prime_dim_le_nine {p : ℕ} [Fact p.Prime] (hp : 5 ≤ p) (hn : n ≤ 9)
    (A : Matrix (Fin n) (Fin n) (ZMod p)) (hA : A.det ≠ 0) : AffineAJT A :=
  affine_of_succ A hA fun B hB => hasAJTVector_dim_le_ten hp (by omega) B hB

end AlonJaegerTarsi.AffineReduction

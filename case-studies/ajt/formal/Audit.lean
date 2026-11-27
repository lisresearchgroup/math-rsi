import Task.DimensionEleven

open Matrix
open scoped BigOperators

namespace IndependentN11Audit

theorem original_shape_all_n_le_11 (p n : ℕ) [Fact p.Prime]
    (hp : 5 ≤ p) (hn : n ≤ 11)
    (A : Matrix (Fin n) (Fin n) (ZMod p)) (hA : A.det ≠ 0) :
    ∃ x : Fin n → ZMod p,
      (∀ i, x i ≠ 0) ∧ (∀ i, (∑ j : Fin n, A i j * x j) ≠ 0) := by
  obtain ⟨x, hx, hAx⟩ := AlonJaegerTarsi.hasAJTVector_dim_le_eleven hp hn A hA
  exact ⟨x, hx, hAx⟩

theorem original_shape_n11 (p : ℕ) [Fact p.Prime] (hp : 5 ≤ p)
    (A : Matrix (Fin 11) (Fin 11) (ZMod p)) (hA : A.det ≠ 0) :
    ∃ x : Fin 11 → ZMod p,
      (∀ i, x i ≠ 0) ∧ (∀ i, (∑ j : Fin 11, A i j * x j) ≠ 0) := by
  exact original_shape_all_n_le_11 p 11 hp (by decide) A hA

theorem original_shape_F5_n11
    (A : Matrix (Fin 11) (Fin 11) (ZMod 5)) (hA : A.det ≠ 0) :
    ∃ x : Fin 11 → ZMod 5,
      (∀ i, x i ≠ 0) ∧ (∀ i, (∑ j : Fin 11, A i j * x j) ≠ 0) := by
  letI : Fact (Nat.Prime 5) := ⟨by decide⟩
  obtain ⟨x, hx, hAx⟩ := AlonJaegerTarsi.hasAJTVector_five_dim_eleven A hA
  exact ⟨x, hx, hAx⟩

/-- The prime-dependent bound of the existing permanent argument. -/
theorem original_shape_below_power (p n : ℕ) [Fact p.Prime]
    (hn : n < 2 ^ (p - 2))
    (A : Matrix (Fin n) (Fin n) (ZMod p)) (hA : A.det ≠ 0) :
    ∃ x : Fin n → ZMod p,
      (∀ i, x i ≠ 0) ∧ (∀ i, (∑ j : Fin n, A i j * x j) ≠ 0) := by
  obtain ⟨x, hx, hAx⟩ :=
    AlonJaegerTarsi.PermanentApproach.hasAJTVector_prime_dim_lt A hA hn
  exact ⟨x, hx, hAx⟩

theorem original_shape_n12_prime_ge_7 (p : ℕ) [Fact p.Prime] (hp : 7 ≤ p)
    (A : Matrix (Fin 12) (Fin 12) (ZMod p)) (hA : A.det ≠ 0) :
    ∃ x : Fin 12 → ZMod p,
      (∀ i, x i ≠ 0) ∧ (∀ i, (∑ j : Fin 12, A i j * x j) ≠ 0) := by
  apply original_shape_below_power p 12 _ A hA
  calc 12 < 2 ^ 5 := by decide
       _ ≤ 2 ^ (p - 2) := Nat.pow_le_pow_right (by decide) (by omega)

end IndependentN11Audit

#print AlonJaegerTarsi.NowhereZero
#print AlonJaegerTarsi.HasAJTVector
#print AlonJaegerTarsi.AJTConjecture
#check AlonJaegerTarsi.hasAJTVector_five_dim_eleven
#check AlonJaegerTarsi.hasAJTVector_dim_le_eleven
#check IndependentN11Audit.original_shape_all_n_le_11
#check IndependentN11Audit.original_shape_n11
#check IndependentN11Audit.original_shape_F5_n11
#print axioms AlonJaegerTarsi.hasAJTVector_five_dim_eleven
#print axioms AlonJaegerTarsi.hasAJTVector_dim_le_eleven
#print axioms IndependentN11Audit.original_shape_all_n_le_11
#print axioms IndependentN11Audit.original_shape_n11
#print axioms IndependentN11Audit.original_shape_F5_n11
#check AlonJaegerTarsi.PermanentApproach.hasAJTVector_prime_dim_lt
#check IndependentN11Audit.original_shape_below_power
#check IndependentN11Audit.original_shape_n12_prime_ge_7
#print axioms AlonJaegerTarsi.PermanentApproach.hasAJTVector_prime_dim_lt
#print axioms IndependentN11Audit.original_shape_below_power
#print axioms IndependentN11Audit.original_shape_n12_prime_ge_7

import Task.WeightTables
import Task.PolynomialCertificateValues
import Task.CoverWeightZeros
import Task.DualReductions

namespace AlonJaegerTarsi

open Matrix WeightTransform

local instance : Fact (Nat.Prime 5) := ⟨by decide⟩

theorem spectrum_of_counterexample {n : ℕ} (A : Matrix (Fin n) (Fin n) (ZMod 5))
    (hA : A.det ≠ 0) (hbad : ¬ HasAJTVector A) (lower : Cover.Below (ZMod 5) n) :
    SpectrumConstraints n (symCount A) (symCount Aᵀ) 2 := by
  classical
  have ht : Aᵀ.det ≠ 0 := by simpa using hA
  obtain ⟨d11, d12, d21⟩ := dual_small_counts_zero A hA hbad lower
  refine ⟨?_, ?_, ?_, ?_, symCount_zero_zero _, symCount_zero_zero _, ?_, ?_,
    symCount_macWilliams A, ?_, ?_⟩
  · intro i j
    unfold symCount
    positivity
  · intro i j
    unfold symCount
    positivity
  · intro i j
    exact add_comm ..
  · intro i j
    exact add_comm ..
  · intro i
    simpa [sphere, Nat.cast_mul, Nat.cast_pow] using symCount_row A hA i
  · intro i
    simpa [sphere, Nat.cast_mul, Nat.cast_pow] using symCount_row Aᵀ ht i
  · intro i j h₁ h₂ h₃ h₄
    have e₁ := primal_counts_zero lower A hA hbad i j (by omega) (by omega)
    have e₂ := primal_counts_zero lower A hA hbad j i (by omega) (by omega)
    simp [symCount, e₁, e₂]
  · intro i j hi hle hj
    rcases (show j.val = 1 ∨ j.val = 2 by omega) with hj | hj <;>
      simp [symCount, hi, hj, d11, d12, d21]

/-- In the field of order five, every invertible matrix of dimension at most
ten has a nowhere-zero vector with nowhere-zero image. -/
theorem hasAJTVector_five_dim_le_ten {n : ℕ} (hn : n ≤ 10)
    (A : Matrix (Fin n) (Fin n) (ZMod 5)) (hA : A.det ≠ 0) : HasAJTVector A := by
  induction n using Nat.strong_induction_on with
  | h n ih =>
    by_cases hsmall : n ≤ 5
    · exact PermanentApproach.hasAJTVector_prime_dim_lt A hA (by norm_num; omega)
    have lower : Cover.Below (ZMod 5) n := fun d hd B hB => ih d hd (by omega) B hB
    by_contra hbad
    have hc := spectrum_of_counterexample A hA hbad lower
    have hp := spectrum_full_positive (by omega) hn hc (by decide)
    have hw : counts A n n = 0 := Nat.eq_zero_of_not_pos fun h => hbad ((counts_full_pos A).mp h)
    simp [symCount, hw] at hp

/-- All primes in the task satisfy the conjecture in dimensions at most ten. -/
theorem hasAJTVector_dim_le_ten {p n : ℕ} [Fact p.Prime] (hp : 5 ≤ p) (hn : n ≤ 10)
    (A : Matrix (Fin n) (Fin n) (ZMod p)) (hA : A.det ≠ 0) : HasAJTVector A := by
  by_cases hfive : p = 5
  · subst p
    exact hasAJTVector_five_dim_le_ten hn A hA
  · apply PermanentApproach.hasAJTVector_prime_dim_lt A hA
    calc n ≤ 10 := hn
         _ < 2^4 := by decide
         _ ≤ 2^(p-2) := Nat.pow_le_pow_right (by decide) (by omega)

end AlonJaegerTarsi

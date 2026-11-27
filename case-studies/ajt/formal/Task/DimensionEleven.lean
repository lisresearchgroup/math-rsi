import Task.MarkedCounterexample
import Task.PolynomialMarkedTags
import Task.PolynomialMarkedDot
import Task.AffineReduction

namespace AlonJaegerTarsi

open Matrix MarkedEleven

local instance : Fact (Nat.Prime 5) := ⟨by decide⟩

/-- In dimension eleven over the field of order five, the actual tables of a
hypothetical counterexample violate a marked MacWilliams inequality. -/
theorem hasAJTVector_five_dim_eleven (A : Matrix11) (hA : A.det ≠ 0) : HasAJTVector A := by
  classical
  let lower : Cover.Below (ZMod 5) 11 :=
    fun d hd B hB => hasAJTVector_five_dim_le_ten (by omega) B hB
  by_contra hbad
  obtain ⟨B, hB, hbadB, hm⟩ := normalized_of_bad A hA hbad lower
  apply marked_infeasible (W := primalTable B) (V := dualTable B)
  exact ⟨fiberTable_nonneg (primalKey B), fiberTable_nonneg (dualKey B),
    primalCorner pTag_zero_iff B hm, dualCorner vTag_zero_iff B hm,
    primalForbid pTag_left pTag_right B hm (actual_primal_forbid B hB hbadB lower),
    dualForbid vTag_realize B hm (actual_dual_forbid B hB hbadB lower),
    primalLeft pTag_left B hm, primalRight pTag_right B hB hm,
    dualLeft vwL_actual B hB, dualRight vwR_actual B,
    actual_marked_transform B (mark_sum_zero B hm) vTag_scale local_dot_counts⟩

/-- Every nonsingular matrix in the prime fields of the task satisfies AJT
in dimensions at most eleven. -/
theorem hasAJTVector_dim_le_eleven {p n : ℕ} [Fact p.Prime] (hp : 5 ≤ p) (hn : n ≤ 11)
    (A : Matrix (Fin n) (Fin n) (ZMod p)) (hA : A.det ≠ 0) : HasAJTVector A := by
  by_cases hten : n ≤ 10
  · exact hasAJTVector_dim_le_ten hp hten A hA
  obtain rfl : n = 11 := by omega
  by_cases hfive : p = 5
  · subst p
    exact hasAJTVector_five_dim_eleven A hA
  · apply PermanentApproach.hasAJTVector_prime_dim_lt A hA
    calc 11 < 2^4 := by decide
         _ ≤ 2^(p-2) := Nat.pow_le_pow_right (by decide) (by omega)

theorem AffineReduction.affine_prime_dim_le_ten {p n : ℕ} [Fact p.Prime] (hp : 5 ≤ p)
    (hn : n ≤ 10) (A : Matrix (Fin n) (Fin n) (ZMod p)) (hA : A.det ≠ 0) :
    AffineReduction.AffineAJT A :=
  AffineReduction.affine_of_succ A hA (fun B hB => hasAJTVector_dim_le_eleven hp (by omega) B hB)

end AlonJaegerTarsi

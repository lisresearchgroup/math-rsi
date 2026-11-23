import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Data.Fintype.Fin
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.NormNum.Parity
import Mathlib.Tactic.Ring
import Mathlib.Tactic.LinearCombination
import Lean.Elab.Tactic.Omega

/-!
Exact arithmetic for Step 3 of `global_closure/PROOF_PACKAGE.md`.

The last theorem is conditional on the two MacWilliams moment equations.
It does not assert that an arbitrary code satisfies those equations: that
code-to-weight-enumerator bridge is a separate proof obligation.
-/

namespace ECC

open scoped BigOperators

/-- The binary length-44 Krawtchouk value, with the binomial convention of the
proof package.  `Fin 45` keeps the natural subtraction `44 - w` in its domain. -/
def krawtchouk44 (j : ℕ) (w : Fin 45) : ℤ :=
  ∑ i ∈ Finset.range (j + 1),
    (-1 : ℤ) ^ i * (Nat.choose w.val i : ℤ) *
      (Nat.choose (44 - w.val) (j - i) : ℤ)

/-- The auxiliary polynomial used to force a dual word of weight four. -/
def weightPolynomial (w : ℤ) : ℤ :=
  (w - 18) * (w - 20) * (w - 24) * (w - 26)

theorem weightPolynomial_zero : weightPolynomial 0 = 224640 := by
  norm_num [weightPolynomial]

/-- Each of the 45 permitted weight values is checked against the actual
binomial definition, without native evaluation or externally supplied data. -/
theorem krawtchouk44_two (w : Fin 45) :
    krawtchouk44 2 w = 2 * ((w.val : ℤ) - 22) ^ 2 - 22 := by
  fin_cases w <;>
    norm_num [krawtchouk44, Finset.sum_range_succ,
      Nat.choose_eq_descFactorial_div_factorial, Nat.descFactorial, Nat.factorial]

theorem krawtchouk44_four (w : Fin 45) :
    3 * krawtchouk44 4 w =
      2 * ((w.val : ℤ) - 22) ^ 4 -
        128 * ((w.val : ℤ) - 22) ^ 2 + 693 := by
  fin_cases w <;>
    norm_num [krawtchouk44, Finset.sum_range_succ,
      Nat.choose_eq_descFactorial_div_factorial, Nat.descFactorial, Nat.factorial]

/-- Twice the rational identity from the proof package, so no rounding or
division convention enters the statement. -/
theorem weightPolynomial_krawtchouk (w : Fin 45) :
    2 * weightPolynomial (w.val : ℤ) =
      3 * krawtchouk44 4 w + 44 * krawtchouk44 2 w + 403 := by
  rw [krawtchouk44_two, krawtchouk44_four]
  dsimp [weightPolynomial]
  ring

/-- The excluded small and odd weights are explicit hypotheses. -/
theorem weightPolynomial_nonneg (w : Fin 45)
    (heven : Even w.val) (hmin : 18 ≤ w.val) :
    0 ≤ weightPolynomial (w.val : ℤ) := by
  fin_cases w <;> norm_num [weightPolynomial] at *

/-- A finite weight enumerator supplies the polynomial lower bound. -/
theorem weightPolynomial_sum_lower_bound (A : Fin 45 → ℕ)
    (hzero : A 0 = 1)
    (hsupport : ∀ w, A w ≠ 0 → w = 0 ∨ (Even w.val ∧ 18 ≤ w.val)) :
    (224640 : ℤ) ≤ ∑ w, (A w : ℤ) * weightPolynomial (w.val : ℤ) := by
  have hnonneg : ∀ w : Fin 45,
      0 ≤ (A w : ℤ) * weightPolynomial (w.val : ℤ) := by
    intro w
    by_cases hz : A w = 0
    · simp [hz]
    · rcases hsupport w hz with hw | ⟨heven, hmin⟩
      · subst w
        norm_num [hzero, weightPolynomial]
      · exact mul_nonneg (Int.natCast_nonneg _) (weightPolynomial_nonneg w heven hmin)
  have hsingle := Finset.single_le_sum
    (s := Finset.univ) (f := fun w : Fin 45 =>
      (A w : ℤ) * weightPolynomial (w.val : ℤ))
    (fun w _ => hnonneg w) (Finset.mem_univ (0 : Fin 45))
  simpa only [hzero, Nat.cast_one, Fin.val_zero, Nat.cast_zero, one_mul,
    weightPolynomial_zero] using hsingle

/-- The exact numerical bridge from the explicitly supplied length-44,
dimension-10 MacWilliams moments to at least twelve dual weight-four words.

Remaining application obligation: construct `A`, `B2`, and `B4` from the
actual code and its orthogonal code and prove every hypothesis below. -/
theorem dualFour_lower_bound (A : Fin 45 → ℕ) (B2 B4 : ℕ)
    (hzero : A 0 = 1)
    (htotal : (∑ w, (A w : ℤ)) = 1024)
    (hsupport : ∀ w, A w ≠ 0 → w = 0 ∨ (Even w.val ∧ 18 ≤ w.val))
    (hsecond : (∑ w, (A w : ℤ) * krawtchouk44 2 w) = 1024 * (B2 : ℤ))
    (hfourth : (∑ w, (A w : ℤ) * krawtchouk44 4 w) = 1024 * (B4 : ℤ))
    (hB2 : B2 = 0) :
    12 ≤ B4 := by
  have hsum :
      2 * (∑ w, (A w : ℤ) * weightPolynomial (w.val : ℤ)) =
        3 * (∑ w, (A w : ℤ) * krawtchouk44 4 w) +
        44 * (∑ w, (A w : ℤ) * krawtchouk44 2 w) +
        403 * (∑ w, (A w : ℤ)) := by
    simp only [Finset.mul_sum, ← Finset.sum_add_distrib]
    apply Finset.sum_congr rfl
    intro w _
    have h := weightPolynomial_krawtchouk w
    linear_combination (A w : ℤ) * h
  have hlow := weightPolynomial_sum_lower_bound A hzero hsupport
  rw [hfourth, hsecond, htotal, hB2] at hsum
  norm_num at hsum
  omega

#print axioms weightPolynomial_krawtchouk
#print axioms weightPolynomial_nonneg
#print axioms dualFour_lower_bound

end ECC

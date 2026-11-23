import ECC.Dual
import ECC.Parity
import ECC.Polynomial
import Mathlib.Algebra.Group.AddChar
import Mathlib.Algebra.Field.ZMod
import Mathlib.FieldTheory.Finiteness
import Mathlib.Tactic.IntervalCases
import Mathlib.Tactic.Linarith

noncomputable section

namespace ECC

open scoped BigOperators Classical

local instance codeFintype {n : ℕ} (C : Submodule F2 (Word n)) : Fintype C :=
  Fintype.ofFinite C

/-- The rational-valued additive character of the binary field. -/
def binaryChar : AddChar F2 ℚ where
  toFun a := if a = 0 then 1 else -1
  map_zero_eq_one' := by simp
  map_add_eq_mul' a b := by
    have h : ∀ a : F2, a = 0 ∨ a = 1 := by decide
    rcases h a with rfl | rfl <;> rcases h b with rfl | rfl <;>
      simp [show (1 : F2) + 1 = 0 by decide]

@[simp] theorem binaryChar_zero : binaryChar 0 = 1 := by rfl
@[simp] theorem binaryChar_one : binaryChar 1 = -1 := by rfl
@[simp] theorem binaryChar_eq_one (a : F2) : binaryChar a = 1 ↔ a = 0 := by
  have ha : a = 0 ∨ a = 1 := (by decide : ∀ a : F2, a = 0 ∨ a = 1) a
  rcases ha with rfl | rfl <;> norm_num

/-- Restrict the pairing character of an actual word to an actual linear code. -/
def codeCharacter {n : ℕ} (C : Submodule F2 (Word n)) (y : Word n) : AddChar C ℚ where
  toFun x := binaryChar (dotWord x.val y)
  map_zero_eq_one' := by simp
  map_add_eq_mul' x z := by
    change binaryChar (dotWord (x.val + z.val) y) = _
    rw [dotWord_add_left, AddChar.map_add_eq_mul]

@[simp] theorem codeCharacter_apply {n : ℕ} (C : Submodule F2 (Word n))
    (y : Word n) (x : C) : codeCharacter C y x = binaryChar (dotWord x.val y) := rfl

theorem codeCharacter_eq_zero_iff {n : ℕ} (C : Submodule F2 (Word n)) (y : Word n) :
    codeCharacter C y = 0 ↔ y ∈ dualCode C := by
  constructor
  · intro h x hx
    have he := DFunLike.congr_fun h (⟨x, hx⟩ : C)
    simpa only [codeCharacter_apply, AddChar.zero_apply, binaryChar_eq_one] using he
  · intro h
    ext x
    simp [h x.val x.property]

/-- Character orthogonality, proved for the actual submodule, with no supplied moments. -/
theorem code_character_sum {n : ℕ} (C : Submodule F2 (Word n)) (y : Word n) :
    (∑ x : C, binaryChar (dotWord x.val y)) =
      if y ∈ dualCode C then (Fintype.card C : ℚ) else 0 := by
  classical
  simpa only [codeCharacter_apply, codeCharacter_eq_zero_iff] using
    (AddChar.sum_eq_ite (codeCharacter C y))

theorem weight_eq_zero_iff {n : ℕ} (x : Word n) : weight x = 0 ↔ x = 0 := by
  classical
  simp only [weight, Finset.card_eq_zero, Finset.filter_eq_empty_iff]
  constructor
  · intro h
    funext i
    simpa only [Finset.mem_univ, true_implies, not_not, Pi.zero_apply] using h (Finset.mem_univ i)
  · intro h
    subst x
    simp

theorem macWilliams_weight_le_length {n : ℕ} (x : Word n) : weight x ≤ n := by
  classical
  exact (Finset.card_filter_le _ _).trans_eq (Fintype.card_fin n)

/-- The actual sum over all binary words of the specified weight. -/
def characterShell {n : ℕ} (x : Word n) (j : ℕ) : ℚ :=
  ∑ y : Word n, if weight y = j then binaryChar (dotWord x y) else 0

theorem characterShell_zero {n : ℕ} (x : Word n) : characterShell x 0 = 1 := by
  classical
  simp [characterShell, weight_eq_zero_iff]

theorem sum_binary (f : F2 → ℚ) : (∑ a, f a) = f 0 + f 1 := by
  change (∑ a : Fin 2, f a) = _
  exact Fin.sum_univ_two _

theorem sum_word_cons {n : ℕ} (f : Word (n + 1) → ℚ) :
    (∑ x, f x) = (∑ x : Word n, f (Fin.cons 0 x)) +
      ∑ x : Word n, f (Fin.cons 1 x) := by
  rw [← (Fin.consEquiv (fun _ : Fin (n + 1) => F2)).sum_comp]
  rw [Fintype.sum_prod_type, sum_binary]
  rfl

theorem dotWord_cons {n : ℕ} (a b : F2) (x y : Word n) :
    dotWord (Fin.cons a x) (Fin.cons b y) = a * b + dotWord x y := by
  simp [dotWord, Fin.sum_univ_succ]

theorem characterShell_cons_succ {n : ℕ} (a : F2) (x : Word n) (j : ℕ) :
    characterShell (Fin.cons a x) (j + 1) =
      characterShell x (j + 1) + binaryChar a * characterShell x j := by
  classical
  unfold characterShell
  rw [sum_word_cons]
  simp only [weight_cons, ne_eq, not_true_eq_false, ite_false, zero_add,
    one_ne_zero, not_false_eq_true, ite_true, dotWord_cons, mul_zero,
    mul_one, AddChar.map_add_eq_mul]
  congr 1
  rw [Finset.mul_sum]
  apply Finset.sum_congr rfl
  intro y _
  have hw : 1 + weight y = j + 1 ↔ weight y = j := by omega
  simp only [hw]
  split_ifs <;> simp

/-- Closed forms of the first five binary Krawtchouk polynomials over the rationals. -/
def shellPolynomial (n j w : ℕ) : ℚ :=
  let s : ℚ := (n : ℚ) - 2 * (w : ℚ)
  match j with
  | 0 => 1
  | 1 => s
  | 2 => (s ^ 2 - n) / 2
  | 3 => (s ^ 3 - (3 * n - 2) * s) / 6
  | 4 => (s ^ 4 - (6 * n - 8) * s ^ 2 + 3 * n * (n - 2)) / 24
  | _ => 0

theorem shellPolynomial_zero_head (n j w : ℕ) (hj : j ≤ 3) :
    shellPolynomial (n + 1) (j + 1) w =
      shellPolynomial n (j + 1) w + shellPolynomial n j w := by
  interval_cases j <;> simp only [shellPolynomial, Nat.cast_add, Nat.cast_one] <;> ring

theorem shellPolynomial_one_head (n j w : ℕ) (hj : j ≤ 3) :
    shellPolynomial (n + 1) (j + 1) (w + 1) =
      shellPolynomial n (j + 1) w - shellPolynomial n j w := by
  interval_cases j <;> simp only [shellPolynomial, Nat.cast_add, Nat.cast_one] <;> ring

/-- The shell sum is calculated from the actual weight of the paired word. -/
theorem characterShell_eq_polynomial {n : ℕ} (x : Word n) (j : ℕ) (hj : j ≤ 4) :
    characterShell x j = shellPolynomial n j (weight x) := by
  induction n generalizing j with
  | zero =>
    have hx : x = 0 := Subsingleton.elim _ _
    subst x
    interval_cases j <;> simp [characterShell, shellPolynomial, weight, dotWord]
  | succ n ih =>
    cases j with
    | zero => simp [characterShell_zero, shellPolynomial]
    | succ j =>
      have hx : x = Fin.cons (x 0) (Fin.tail x) := (Fin.cons_self_tail x).symm
      rw [hx, characterShell_cons_succ]
      rw [ih _ (j + 1) hj, ih _ j (by omega), weight_cons]
      have ha : x 0 = 0 ∨ x 0 = 1 :=
        (by decide : ∀ a : F2, a = 0 ∨ a = 1) (x 0)
      rcases ha with ha | ha
      · simp only [ha, ne_eq, not_true_eq_false, ite_false, zero_add, binaryChar_zero, one_mul]
        exact (shellPolynomial_zero_head n j _ (by omega)).symm
      · simp only [ha, ne_eq, one_ne_zero, not_false_eq_true, ite_true, binaryChar_one,
          neg_one_mul]
        simpa only [Nat.add_comm, sub_eq_add_neg] using
          (shellPolynomial_one_head n j (weight (Fin.tail x)) (by omega)).symm

/-- Summing over the actual code converts shell sums into the actual dual shells. -/
theorem sum_characterShell {n : ℕ} (C : Submodule F2 (Word n)) (j : ℕ) :
    (∑ x : C, characterShell x.val j) =
      ∑ y : Word n, if weight y = j then
        (if y ∈ dualCode C then (Fintype.card C : ℚ) else 0) else 0 := by
  classical
  unfold characterShell
  rw [Finset.sum_comm]
  apply Finset.sum_congr rfl
  intro y _
  by_cases hy : weight y = j
  · simp only [hy, ite_true, code_character_sum]
  · simp [hy]

/-- Vanishing of a dual shell forces its Krawtchouk moment to vanish. -/
theorem sum_shellPolynomial_eq_zero {n : ℕ} (C : Submodule F2 (Word n))
    (j : ℕ) (hj : j ≤ 4)
    (hdual : ∀ y ∈ dualCode C, weight y ≠ j) :
    (∑ x : C, shellPolynomial n j (weight x.val)) = 0 := by
  classical
  simp_rw [← characterShell_eq_polynomial _ j hj]
  rw [sum_characterShell]
  apply Finset.sum_eq_zero
  intro y _
  by_cases hmem : y ∈ dualCode C
  · simp [hdual y hmem]
  · simp [hmem]

theorem shellPolynomial_two_eq (w : ℕ) :
    shellPolynomial 44 2 w = 2 * ((w : ℚ) - 22) ^ 2 - 22 := by
  simp only [shellPolynomial]
  ring

theorem shellPolynomial_four_eq (w : ℕ) :
    3 * shellPolynomial 44 4 w =
      2 * ((w : ℚ) - 22) ^ 4 - 128 * ((w : ℚ) - 22) ^ 2 + 693 := by
  simp only [shellPolynomial]
  ring

/-- Rational copy of the integer polynomial, used only to sum actual codewords. -/
def weightPolynomialQ (w : ℕ) : ℚ :=
  ((w : ℚ) - 18) * ((w : ℚ) - 20) * ((w : ℚ) - 24) * ((w : ℚ) - 26)

theorem weightPolynomialQ_cast (w : ℕ) :
    weightPolynomialQ w = ((weightPolynomial (w : ℤ)) : ℚ) := by
  simp [weightPolynomialQ, weightPolynomial]

theorem weightPolynomialQ_shell (w : ℕ) :
    2 * weightPolynomialQ w =
      3 * shellPolynomial 44 4 w + 44 * shellPolynomial 44 2 w + 403 := by
  rw [shellPolynomial_two_eq, shellPolynomial_four_eq]
  unfold weightPolynomialQ
  ring

theorem code_polynomial_sum_lower (C : Submodule F2 (Word 44))
    (hmin : MinWeight C 18) (heven : EvenCode C) :
    (224640 : ℚ) ≤ ∑ x : C, weightPolynomialQ (weight x.val) := by
  classical
  have hnonneg : ∀ x : C, 0 ≤ weightPolynomialQ (weight x.val) := by
    intro x
    by_cases hx : x.val = 0
    · norm_num [hx, weightPolynomialQ]
    · have hp := weightPolynomial_nonneg
        (⟨weight x.val, Nat.lt_succ_of_le (macWilliams_weight_le_length x.val)⟩ : Fin 45)
        (heven x.val x.property) (hmin x.val x.property hx)
      rw [weightPolynomialQ_cast]
      exact_mod_cast hp
  have hsingle := Finset.single_le_sum (s := Finset.univ)
    (f := fun x : C => weightPolynomialQ (weight x.val))
    (fun x _ => hnonneg x) (Finset.mem_univ (0 : C))
  norm_num [weightPolynomialQ] at hsingle ⊢
  exact hsingle

/-- Every actual even binary [44,10,≥18] code with dual distance at least four
has an actual dual word of weight four. The MacWilliams moments in this theorem
are derived from character orthogonality, rather than supplied as hypotheses. -/
theorem exists_dual_weight_four (C : Submodule F2 (Word 44))
    (hdim : Module.finrank F2 C = 10) (hmin : MinWeight C 18)
    (heven : EvenCode C) (hdualmin : MinWeight (dualCode C) 4) :
    ∃ y ∈ dualCode C, weight y = 4 := by
  classical
  by_contra hnone
  have hfour : ∀ y ∈ dualCode C, weight y ≠ 4 := by
    intro y hy hw
    exact hnone ⟨y, hy, hw⟩
  have htwo : ∀ y ∈ dualCode C, weight y ≠ 2 := by
    intro y hy hw
    have hne : y ≠ 0 := by
      intro hz
      simp [hz] at hw
    have hbound := hdualmin y hy hne
    omega
  have hs2 := sum_shellPolynomial_eq_zero C 2 (by omega) htwo
  have hs4 := sum_shellPolynomial_eq_zero C 4 (by omega) hfour
  have hcard : Fintype.card C = 1024 := by
    rw [Module.card_eq_pow_finrank (K := F2), hdim]
    decide
  have hid :
      2 * (∑ x : C, weightPolynomialQ (weight x.val)) =
        3 * (∑ x : C, shellPolynomial 44 4 (weight x.val)) +
        44 * (∑ x : C, shellPolynomial 44 2 (weight x.val)) +
        403 * (Fintype.card C : ℚ) := by
    simp only [Finset.mul_sum]
    rw [← Finset.sum_add_distrib]
    have hc : (403 : ℚ) * Fintype.card C = ∑ _x : C, (403 : ℚ) := by simp [mul_comm]
    rw [hc, ← Finset.sum_add_distrib]
    exact Finset.sum_congr rfl (fun x _ => weightPolynomialQ_shell (weight x.val))
  rw [hs2, hs4, hcard] at hid
  have hlow := code_polynomial_sum_lower C hmin heven
  norm_num at hid
  linarith

#print axioms exists_dual_weight_four

end ECC

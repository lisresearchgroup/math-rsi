import Mathlib.Data.ZMod.Basic
import Mathlib.LinearAlgebra.Dimension.Finrank
import Mathlib.LinearAlgebra.Dimension.Constructions
import Mathlib.Algebra.CharP.Two
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic.Abel
import Mathlib.Tactic.NormNum

namespace ECC

abbrev F2 := ZMod 2
abbrev Word (n : ℕ) := Fin n → F2

def weight {n : ℕ} (x : Word n) : ℕ :=
  (Finset.univ.filter (fun i => x i ≠ 0)).card

def MinWeight {n : ℕ} (C : Submodule F2 (Word n)) (d : ℕ) : Prop :=
  ∀ x ∈ C, x ≠ 0 → d ≤ weight x

def CodeExists (n k d : ℕ) : Prop :=
  ∃ C : Submodule F2 (Word n),
    Module.finrank F2 C = k ∧ MinWeight C d

def EvenCode {n : ℕ} (C : Submodule F2 (Word n)) : Prop :=
  ∀ x ∈ C, Even (weight x)

def MainClaim : Prop := ¬ CodeExists 43 10 17

def OptimalDistance (n k d : ℕ) : Prop :=
  CodeExists n k d ∧ ¬ CodeExists n k (d + 1)

def ThreeClosedEntries : Prop :=
  OptimalDistance 43 10 16 ∧
  OptimalDistance 44 10 17 ∧
  OptimalDistance 44 11 16

@[simp] theorem weight_zero (n : ℕ) : weight (0 : Word n) = 0 := by
  simp [weight]

end ECC

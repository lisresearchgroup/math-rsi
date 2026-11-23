import Mathlib.Data.ZMod.Basic
import Mathlib.LinearAlgebra.Dimension.Finrank
import Mathlib.LinearAlgebra.Dimension.Constructions
import Mathlib.Algebra.CharP.Two
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic.Abel
import Mathlib.Tactic.NormNum

namespace ECC42

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

/-- Exact minimum distance, including a nonzero word attaining the bound. -/
def ExactCodeExists (n k d : ℕ) : Prop :=
  ∃ C : Submodule F2 (Word n),
    Module.finrank F2 C = k ∧ MinWeight C d ∧
    ∃ x ∈ C, x ≠ 0 ∧ weight x = d

/-- Proposition 2 of Bouyuklieva–Bouyukliev (ICMS 2020), used as a hypothesis. -/
def Proposition2 : Prop := ¬ ExactCodeExists 41 14 14

@[simp] theorem weight_zero (n : ℕ) : weight (0 : Word n) = 0 := by
  simp [weight]

end ECC42

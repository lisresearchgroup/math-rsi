import ECC.Basic

namespace ECC

def dotWord {n : ℕ} (x y : Word n) : F2 := ∑ i, x i * y i

theorem dotWord_comm {n : ℕ} (x y : Word n) : dotWord x y = dotWord y x := by
  simp [dotWord, mul_comm]

@[simp] theorem dotWord_zero_left {n : ℕ} (y : Word n) : dotWord 0 y = 0 := by
  simp [dotWord]

@[simp] theorem dotWord_zero_right {n : ℕ} (x : Word n) : dotWord x 0 = 0 := by
  simp [dotWord]

theorem dotWord_add_left {n : ℕ} (x y z : Word n) :
    dotWord (x + y) z = dotWord x z + dotWord y z := by
  simp [dotWord, add_mul, Finset.sum_add_distrib]

theorem dotWord_add_right {n : ℕ} (x y z : Word n) :
    dotWord x (y + z) = dotWord x y + dotWord x z := by
  simp [dotWord, mul_add, Finset.sum_add_distrib]

def dualCode {n : ℕ} (C : Submodule F2 (Word n)) : Submodule F2 (Word n) where
  carrier := {y | ∀ x ∈ C, dotWord x y = 0}
  zero_mem' := by simp
  add_mem' := by
    intro y z hy hz x hx
    rw [dotWord_add_right, hy x hx, hz x hx, add_zero]
  smul_mem' := by
    intro a y hy x hx
    simp only [dotWord, Pi.smul_apply, smul_eq_mul]
    simp_rw [mul_left_comm (x _) a]
    rw [← Finset.mul_sum]
    change a * dotWord x y = 0
    rw [hy x hx, mul_zero]

@[simp] theorem mem_dualCode {n : ℕ} (C : Submodule F2 (Word n)) (y : Word n) :
    y ∈ dualCode C ↔ ∀ x ∈ C, dotWord x y = 0 := Iff.rfl

end ECC

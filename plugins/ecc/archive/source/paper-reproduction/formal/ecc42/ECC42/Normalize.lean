import ECC42.Basic
import Mathlib.Algebra.Field.ZMod
import Mathlib.LinearAlgebra.Dimension.Free
import Mathlib.LinearAlgebra.FiniteDimensional.Lemmas

namespace ECC42

/-- Replace one coordinate by zero, keeping the length unchanged. -/
def eraseCoordinate {n : ℕ} (i : Fin n) : Word n →ₗ[F2] Word n where
  toFun x j := if j = i then 0 else x j
  map_add' x y := by ext j; by_cases h : j = i <;> simp [h]
  map_smul' a x := by ext j; by_cases h : j = i <;> simp [h]

theorem weight_eraseCoordinate {n : ℕ} (i : Fin n) (x : Word n) :
    weight (eraseCoordinate i x) = weight x - (if x i ≠ 0 then 1 else 0) := by
  classical
  have hs : (Finset.univ.filter (fun j => eraseCoordinate i x j ≠ 0)) =
      (Finset.univ.filter (fun j => x j ≠ 0)).erase i := by
    ext j
    by_cases h : j = i <;> simp [eraseCoordinate, h]
  unfold weight
  rw [hs, Finset.card_erase_eq_ite]
  simp only [Finset.mem_filter, Finset.mem_univ, true_and]
  split_ifs <;> omega

/-- A code with positive dimension has a nonzero word. -/
theorem exists_nonzero_word {n k : ℕ} (C : Submodule F2 (Word n))
    (hk : Module.finrank F2 C = k) (hpos : 0 < k) :
    ∃ x ∈ C, x ≠ 0 := by
  have hp : 0 < Module.finrank F2 C := by omega
  obtain ⟨x, hx⟩ := Module.finrank_pos_iff_exists_ne_zero.mp hp
  exact ⟨x, x.property, fun h => hx (Subtype.ext h)⟩

/-- Normalize distance using induction on the weight of an actual codeword.
Each step erases one coordinate only when all nonzero words have weight > d. -/
theorem normalize_with_witness {n k d w : ℕ} (hd : 0 < d)
    (C : Submodule F2 (Word n)) (hk : Module.finrank F2 C = k)
    (hmin : MinWeight C d) (x : Word n) (hx : x ∈ C)
    (hx0 : x ≠ 0) (hw : weight x = w) : ExactCodeExists n k d := by
  classical
  induction w using Nat.strong_induction_on generalizing C x with
  | h w ih =>
    by_cases hex : ∃ y ∈ C, y ≠ 0 ∧ weight y = d
    · exact ⟨C, hk, hmin, hex⟩
    have hstrong : MinWeight C (d + 1) := by
      intro y hy hy0
      have hge := hmin y hy hy0
      have hne : weight y ≠ d := fun heq => hex ⟨y, hy, hy0, heq⟩
      omega
    obtain ⟨i, hi⟩ : ∃ i, x i ≠ 0 := by
      by_contra h
      apply hx0
      ext i
      simpa using not_exists.mp h i
    let f : C →ₗ[F2] Word n := (eraseCoordinate i).comp C.subtype
    have hf : Function.Injective f := by
      intro a b hab
      apply sub_eq_zero.mp
      by_contra hne
      have hne' : ((a - b : C) : Word n) ≠ 0 := fun hz => hne (Subtype.ext hz)
      have hz : f (a - b) = 0 := by rw [map_sub, hab, sub_self]
      have hb := hstrong _ (a - b).property hne'
      have he := weight_eraseCoordinate i ((a - b : C) : Word n)
      change eraseCoordinate i ((a - b : C) : Word n) = 0 at hz
      rw [hz, weight_zero] at he
      split_ifs at he <;> omega
    let D := LinearMap.range f
    have hDdim : Module.finrank F2 D = k := by
      rw [LinearMap.finrank_range_of_inj hf]
      exact hk
    have hDmin : MinWeight D d := by
      rintro y ⟨a, rfl⟩ hy
      have ha0 : (a : Word n) ≠ 0 := by
        intro ha
        apply hy
        change eraseCoordinate i (a : Word n) = 0
        rw [ha, map_zero]
      have hb := hstrong _ a.property ha0
      have he := weight_eraseCoordinate i (a : Word n)
      change d ≤ weight (eraseCoordinate i (a : Word n))
      split_ifs at he <;> omega
    have hx' : eraseCoordinate i x ∈ D := ⟨⟨x, hx⟩, rfl⟩
    have hw' : weight (eraseCoordinate i x) = w - 1 := by
      rw [weight_eraseCoordinate, ite_eq_left hi, hw]
    have hx0' : eraseCoordinate i x ≠ 0 := by
      intro hz
      have hb := hstrong x hx hx0
      rw [hz, weight_zero] at hw'
      omega
    have hlt : w - 1 < w := by
      have hb := hstrong x hx hx0
      omega
    exact ih (w - 1) hlt D hDdim hDmin (eraseCoordinate i x) hx' hx0' hw'

theorem normalize_distance {n k d : ℕ} (hk : 0 < k) (hd : 0 < d)
    (h : CodeExists n k d) : ExactCodeExists n k d := by
  obtain ⟨C, hdim, hmin⟩ := h
  obtain ⟨x, hx, hx0⟩ := exists_nonzero_word C hdim hk
  exact normalize_with_witness hd C hdim hmin x hx hx0 rfl

end ECC42

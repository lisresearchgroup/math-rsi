import ECC.Parity
import Mathlib.Algebra.Field.ZMod
import Mathlib.LinearAlgebra.FiniteDimensional.Lemmas
import Mathlib.Algebra.BigOperators.Group.Finset.Pi

namespace ECC
namespace Griesmer

set_option maxHeartbeats 2000000

open scoped BigOperators

variable {ι : Type*} [Fintype ι]

/-- Hamming weight on any finite coordinate type. -/
def hamming (x : ι → F2) : ℕ := ∑ i, if x i ≠ 0 then 1 else 0

@[simp] theorem hamming_zero : hamming (0 : ι → F2) = 0 := by
  simp [hamming]

theorem hamming_pos {x : ι → F2} (hx : x ≠ 0) : 0 < hamming x := by
  classical
  obtain ⟨i, hi⟩ := Function.ne_iff.mp hx
  have h := Finset.single_le_sum (f := fun j => if x j ≠ 0 then 1 else 0)
    (s := Finset.univ) (fun _ _ => Nat.zero_le _) (Finset.mem_univ i)
  simp only [Pi.zero_apply] at hi
  have hh : 1 ≤ hamming x := by simpa only [hi, ne_eq, not_false_eq_true, ite_true, hamming] using h
  omega

theorem hamming_fin {n : ℕ} (x : Word n) : hamming x = weight x := by
  simp [hamming, weight, Finset.card_filter]

/-- Delete the support of `c`. -/
def residualMap (C : Submodule F2 (ι → F2)) (c : ι → F2) :
    C →ₗ[F2] ({i // c i = 0} → F2) where
  toFun x i := (x : ι → F2) i
  map_add' _ _ := rfl
  map_smul' _ _ := rfl

theorem hamming_restrict (x c : ι → F2) :
    hamming (fun i : {i // c i = 0} => x i) =
      ∑ i, if c i = 0 then (if x i ≠ 0 then 1 else 0) else 0 := by
  classical
  rw [← Finset.sum_filter]
  simpa [hamming] using
    (Finset.sum_subtype_eq_sum_filter (s := Finset.univ)
      (p := fun i => c i = 0) (fun i => if x i ≠ 0 then 1 else 0))

/-- The two words in a residual-code fibre have this exact weight sum. -/
theorem hamming_add_identity (x c : ι → F2) :
    hamming x + hamming (x + c) = hamming c +
      2 * hamming (fun i : {i // c i = 0} => x i) := by
  rw [hamming_restrict]
  simp only [hamming, Finset.mul_sum, ← Finset.sum_add_distrib, Pi.add_apply]
  apply Finset.sum_congr rfl
  intro i _
  have h : ∀ a b : F2,
      (if a ≠ 0 then 1 else 0) + (if a + b ≠ 0 then 1 else 0) =
        (if b ≠ 0 then 1 else 0) +
          2 * (if b = 0 then (if a ≠ 0 then 1 else 0) else 0) := by decide
  exact h (x i) (c i)

theorem hamming_add_zero_card (c : ι → F2) :
    hamming c + Fintype.card {i // c i = 0} = Fintype.card ι := by
  classical
  rw [Fintype.card_subtype, Finset.card_filter]
  simp only [hamming, ← Finset.sum_add_distrib]
  have h : ∀ i : ι, (if c i ≠ 0 then 1 else 0) + (if c i = 0 then 1 else 0) = 1 := by
    intro i
    by_cases hi : c i = 0 <;> simp [hi]
  simp_rw [h]
  simp

omit [Fintype ι] in
theorem residualMap_self (C : Submodule F2 (ι → F2)) (c : C) :
    residualMap C c c = 0 := by
  funext i
  exact i.property

/-- A minimum-weight word spans the entire kernel of its residual map. -/
theorem residualMap_ker (C : Submodule F2 (ι → F2)) (c : C)
    (hc : c ≠ 0)
    (hmin : ∀ x : C, x ≠ 0 → hamming (c : ι → F2) ≤ hamming (x : ι → F2)) :
    (residualMap C c).ker = Submodule.span F2 {c} := by
  classical
  apply le_antisymm
  · intro x hx
    by_cases hx0 : x = 0
    · simp [hx0]
    by_cases hxc : x = c
    · rw [hxc]
      exact Submodule.subset_span (Set.mem_singleton c)
    have hsum : x + c ≠ 0 := by
      intro h
      apply hxc
      have hh := congrArg (fun z : C => z + c) h
      have hcc : c + c = 0 := by
        apply Subtype.ext
        funext i
        exact CharTwo.add_self_eq_zero ((c : ι → F2) i)
      simpa [add_assoc, hcc] using hh
    have h1 := hmin x hx0
    have h2 := hmin (x + c) hsum
    have hid := hamming_add_identity (x : ι → F2) (c : ι → F2)
    have hz : (fun i : {i // (c : ι → F2) i = 0} => (x : ι → F2) i) = 0 := hx
    rw [hz, hamming_zero, mul_zero, add_zero] at hid
    have hp : 0 < hamming (c : ι → F2) :=
      hamming_pos (fun h => hc (Subtype.ext h))
    change hamming (c : ι → F2) ≤ hamming ((x : ι → F2) + (c : ι → F2)) at h2
    omega
  · apply Submodule.span_le.mpr
    intro x hx
    have hx' : x = c := Set.mem_singleton_iff.mp hx
    subst x
    exact residualMap_self C c

/-- Residual distance bound; no enumeration or imported coding bound is used. -/
theorem residualMap_min (C : Submodule F2 (ι → F2)) (c : C)
    (hmin : ∀ x : C, x ≠ 0 → hamming (c : ι → F2) ≤ hamming (x : ι → F2)) :
    ∀ y ∈ (residualMap C c).range, y ≠ 0 →
      (hamming (c : ι → F2) + 1) / 2 ≤ hamming y := by
  rintro y ⟨x, rfl⟩ hy
  have hx : x ≠ 0 := fun h => hy (by rw [h, map_zero])
  have hxc : x + c ≠ 0 := by
    intro h
    apply hy
    have hh := congrArg (residualMap C c) h
    simpa only [map_add, residualMap_self, add_zero, map_zero] using hh
  have h1 := hmin x hx
  have h2 := hmin (x + c) hxc
  have hid := hamming_add_identity (x : ι → F2) (c : ι → F2)
  change hamming (c : ι → F2) ≤ hamming ((x : ι → F2) + (c : ι → F2)) at h2
  change (hamming (c : ι → F2) + 1) / 2 ≤
    hamming (fun i : {i // (c : ι → F2) i = 0} => (x : ι → F2) i)
  omega

/-- Binary Griesmer sum, in the equivalent residual recursion. -/
def bound : ℕ → ℕ → ℕ
  | 0, _ => 0
  | k + 1, d => d + bound k ((d + 1) / 2)

theorem bound_mono (k : ℕ) {d e : ℕ} (h : d ≤ e) : bound k d ≤ bound k e := by
  induction k generalizing d e with
  | zero => simp [bound]
  | succ k ih =>
    simp only [bound]
    exact Nat.add_le_add h (ih (Nat.div_le_div_right (Nat.add_le_add_right h 1)))

/-- The binary Griesmer inequality, proved by minimum-word residual induction. -/
theorem bound_le_length (k : ℕ) {ι : Type*} [Fintype ι]
    (C : Submodule F2 (ι → F2)) {d : ℕ}
    (hdim : Module.finrank F2 C = k)
    (hmin : ∀ x : C, x ≠ 0 → d ≤ hamming (x : ι → F2)) :
    bound k d ≤ Fintype.card ι := by
  classical
  induction k generalizing ι d with
  | zero => simp [bound]
  | succ k ih =>
    have hex : ∃ x : C, x ≠ 0 :=
      Module.finrank_pos_iff_exists_ne_zero.mp (by rw [hdim]; omega)
    have hexWeight : ∃ s : ℕ, ∃ x : C, x ≠ 0 ∧ hamming (x : ι → F2) = s := by
      obtain ⟨x, hx⟩ := hex
      exact ⟨hamming (x : ι → F2), x, hx, rfl⟩
    obtain ⟨c, hc, hcWeight⟩ := Nat.find_spec hexWeight
    have hcmin : ∀ x : C, x ≠ 0 → hamming (c : ι → F2) ≤ hamming (x : ι → F2) := by
      intro x hx
      rw [hcWeight]
      exact Nat.find_min' hexWeight ⟨x, hx, rfl⟩
    have hker : Module.finrank F2 (residualMap C c).ker = 1 := by
      rw [residualMap_ker C c hc hcmin]
      exact finrank_span_singleton hc
    have hrank : Module.finrank F2 (residualMap C c).range = k := by
      have h := (residualMap C c).finrank_range_add_finrank_ker
      rw [hker, hdim] at h
      omega
    have hrmin : ∀ y : (residualMap C c).range, y ≠ 0 →
        (hamming (c : ι → F2) + 1) / 2 ≤ hamming (y : {i // (c : ι → F2) i = 0} → F2) := by
      intro y hy
      exact residualMap_min C c hcmin y y.property (fun h => hy (Subtype.ext h))
    have hi := ih (residualMap C c).range hrank hrmin
    have hd := hmin c hc
    have hm := bound_mono k (Nat.div_le_div_right (c := 2) (Nat.add_le_add_right hd 1))
    have hl := hamming_add_zero_card (c : ι → F2)
    simp only [bound]
    omega

end Griesmer

theorem codeExists_griesmer {n k d : ℕ} (h : CodeExists n k d) :
    Griesmer.bound k d ≤ n := by
  obtain ⟨C, hdim, hmin⟩ := h
  have hg := Griesmer.bound_le_length k C hdim (d := d) (by
    intro x hx
    rw [Griesmer.hamming_fin]
    exact hmin x x.property (fun h => hx (Subtype.ext h)))
  simpa using hg

theorem no_code_41_8_19 : ¬ CodeExists 41 8 19 := by
  intro h
  have hg := codeExists_griesmer h
  norm_num [Griesmer.bound] at hg

theorem no_code_40_7_20 : ¬ CodeExists 40 7 20 := by
  intro h
  have hg := codeExists_griesmer h
  norm_num [Griesmer.bound] at hg

/-- This is the exact-distance bridge needed for the published `[41,8,18]`
nonexistence input, whose statement concerns actual minimum distance. -/
theorem exists_weight18_of_41_8_min18 (C : Submodule F2 (Word 41))
    (hdim : Module.finrank F2 C = 8) (hmin : MinWeight C 18) :
    ∃ x ∈ C, weight x = 18 := by
  by_contra h
  apply no_code_41_8_19
  refine ⟨C, hdim, ?_⟩
  intro x hx hx0
  have hb := hmin x hx hx0
  have hn : weight x ≠ 18 := fun he => h ⟨x, hx, he⟩
  omega

/-- An even shortened `[40,7,≥18]` mother has actual distance exactly 18. -/
theorem exists_weight18_of_even_40_7_min18 (C : Submodule F2 (Word 40))
    (hdim : Module.finrank F2 C = 7) (hmin : MinWeight C 18)
    (heven : EvenCode C) : ∃ x ∈ C, weight x = 18 := by
  by_contra h
  apply no_code_40_7_20
  refine ⟨C, hdim, ?_⟩
  intro x hx hx0
  have hb := hmin x hx hx0
  have hn : weight x ≠ 18 := fun he => h ⟨x, hx, he⟩
  obtain ⟨a, ha⟩ := heven x hx
  omega

#print axioms codeExists_griesmer
#print axioms no_code_41_8_19
#print axioms no_code_40_7_20
#print axioms exists_weight18_of_41_8_min18
#print axioms exists_weight18_of_even_40_7_min18
end ECC

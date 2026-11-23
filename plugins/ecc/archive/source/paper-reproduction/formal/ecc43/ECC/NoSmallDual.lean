import ECC.Griesmer
import ECC.ShorteningCore
import Mathlib.LinearAlgebra.Dimension.Free

set_option maxHeartbeats 2000000

namespace ECC

/-- Exact published input E1: actual distance 18, not an assumed bound for all
codes of distance at least 18. Griesmer supplies the latter implication below. -/
def PublishedNonexistence41 : Prop :=
  ∀ C : Submodule F2 (Word 41), Module.finrank F2 C = 8 → ¬ ExactMinWeight C 18

theorem no_code_41_8_18_of_published (hE1 : PublishedNonexistence41) :
    ¬ CodeExists 41 8 18 := by
  rintro ⟨C, hdim, hmin⟩
  apply hE1 C hdim
  obtain ⟨x, hx, hw⟩ := exists_weight18_of_41_8_min18 C hdim hmin
  refine ⟨hmin, x, hx, ?_, hw⟩
  intro hz
  rw [hz, weight_zero] at hw
  contradiction

/-- Choosing a `k`-dimensional linear subcode does not lower its minimum
distance. The inclusion and dimension are constructed from a linear injection. -/
theorem codeExists_of_finrank_ge {n k d : ℕ} (C : Submodule F2 (Word n))
    (hdim : k ≤ Module.finrank F2 C) (hmin : MinWeight C d) :
    CodeExists n k d := by
  classical
  have hle : Module.finrank F2 (Word k) ≤ Module.finrank F2 C := by
    simpa [Word, F2] using hdim
  obtain ⟨f, hf⟩ := finrank_le_iff_exists_linearMap.mp hle
  let g : Word k →ₗ[F2] Word n := C.subtype.comp f
  have hg : Function.Injective g := Subtype.val_injective.comp hf
  refine ⟨g.range, ?_, ?_⟩
  · rw [LinearMap.finrank_range_of_inj hg]
    simp [Word, F2]
  · rintro y ⟨x, rfl⟩ hy
    exact hmin (g x) (f x).property hy

theorem dotWord_parts {n m : ℕ} (x y : Word (n+m)) :
    dotWord x y = dotWord (firstPart n m x) (firstPart n m y) +
      dotWord (lastPart n m x) (lastPart n m y) := by
  rw [dotWord, Fin.sum_univ_add]
  rfl

/-- A nonzero relation supported in the last three positions would reduce the
projection rank to at most two, producing a forbidden `[41,8,≥18]` subcode. -/
theorem no_nonzero_dual_supported_last3 (hE1 : PublishedNonexistence41)
    (C : Submodule F2 (Word 44)) (hdim : Module.finrank F2 C = 10)
    (hmin : MinWeight C 18) (y : Word 44) (hy : y ∈ dualCode C)
    (hfirst : firstPart 41 3 y = 0) : y = 0 := by
  classical
  by_contra hy0
  have hlast : lastPart 41 3 y ≠ 0 := by
    intro hz
    apply hy0
    rw [← join_parts (n := 41) (m := 3) y, hfirst, hz, joinWord_zero]
  obtain ⟨i, hi⟩ := Function.ne_iff.mp hlast
  simp only [Pi.zero_apply] at hi
  have hnot : LinearMap.range (tailProjection (n := 41) (m := 3) C) ≠ ⊤ := by
    intro htop
    obtain ⟨x, hx⟩ := LinearMap.range_eq_top.mp htop (Pi.single i 1)
    have hdot := hy x x.property
    rw [dotWord_parts (n := 41) (m := 3), hfirst, dotWord_zero_right, zero_add] at hdot
    change dotWord ((tailProjection C) x) (lastPart 41 3 y) = 0 at hdot
    rw [hx] at hdot
    have hd : dotWord (Pi.single i 1) (lastPart 41 3 y) = lastPart 41 3 y i := by
      simp [dotWord, Pi.single_apply]
    rw [hd] at hdot
    exact hi hdot
  have hlt : Module.finrank F2 (LinearMap.range (tailProjection (n := 41) (m := 3) C)) < 3 := by
    have h := Submodule.finrank_lt_finrank_of_lt (lt_top_iff_ne_top.mpr hnot)
    simpa [Word, F2] using h
  have hr := shortenedCode_finrank (n := 41) (m := 3) C
  rw [hdim] at hr
  have hshort : 8 ≤ Module.finrank F2 (shortenedCode (n := 41) (m := 3) C) := by omega
  exact no_code_41_8_18_of_published hE1
    (codeExists_of_finrank_ge _ hshort (shortenedCode_minWeight (n := 41) (m := 3) C hmin))

#print axioms no_code_41_8_18_of_published
#print axioms no_nonzero_dual_supported_last3

end ECC

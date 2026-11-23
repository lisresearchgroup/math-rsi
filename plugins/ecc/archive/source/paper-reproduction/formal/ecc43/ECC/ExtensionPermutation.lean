import ECC.Permutation
import ECC.ShorteningCore

namespace ECC

/-- Extend a permutation of the forty mother coordinates by fixing all four
extension coordinates. -/
def extendHeadPermutation (e : Fin 40 ≃ Fin 40) : Fin 44 ≃ Fin 44 where
  toFun i := Fin.addCases (m := 40) (n := 4) (motive := fun _ => Fin 44)
    (fun j => Fin.castAdd 4 (e j)) (Fin.natAdd 40) i
  invFun i := Fin.addCases (m := 40) (n := 4) (motive := fun _ => Fin 44)
    (fun j => Fin.castAdd 4 (e.symm j)) (Fin.natAdd 40) i
  left_inv := by
    intro i
    refine Fin.addCases (m := 40) (n := 4) ?_ ?_ i <;> intro j <;> simp
  right_inv := by
    intro i
    refine Fin.addCases (m := 40) (n := 4) ?_ ?_ i <;> intro j <;> simp

@[simp] theorem permuteWord_extend_append (e : Fin 40 ≃ Fin 40)
    (a : Word 40) (t : Word 4) :
    permuteWord (extendHeadPermutation e) (appendTail a t) = appendTail (permuteWord e a) t := by
  funext i
  refine Fin.addCases (m := 40) (n := 4) ?_ ?_ i <;> intro j <;>
    simp [extendHeadPermutation, appendTail]

theorem standardExtension_permute_le (e : Fin 40 ≃ Fin 40)
    (K : Submodule F2 (Word 40)) (a b c : Word 40) :
    StandardExtension (permuteCode e K) (permuteWord e a) (permuteWord e b) (permuteWord e c) ≤
      permuteCode (extendHeadPermutation e) (StandardExtension K a b c) := by
  apply Submodule.span_le.mpr
  intro x hx
  rcases hx with ⟨k, rfl⟩ | hx
  · obtain ⟨z,hz,hzk⟩ := k.property
    refine ⟨appendTail z 0, kernel_mem_standardExtension K a b c z hz, ?_⟩
    change permuteWord (extendHeadPermutation e) (appendTail z 0) = appendTail k.val 0
    rw [permuteWord_extend_append]
    exact congrArg (fun q => appendTail q 0) hzk
  · rcases hx with hx | hx | hx
    · subst x
      exact ⟨appendTail a tail1, row1_mem_standardExtension K a b c,
        permuteWord_extend_append e a tail1⟩
    · subst x
      exact ⟨appendTail b tail2, row2_mem_standardExtension K a b c,
        permuteWord_extend_append e b tail2⟩
    · rw [Set.mem_singleton_iff] at hx
      subst x
      exact ⟨appendTail c tail3, row3_mem_standardExtension K a b c,
        permuteWord_extend_append e c tail3⟩

theorem permute_standardExtension_le (e : Fin 40 ≃ Fin 40)
    (K : Submodule F2 (Word 40)) (a b c : Word 40) :
    permuteCode (extendHeadPermutation e) (StandardExtension K a b c) ≤
      StandardExtension (permuteCode e K) (permuteWord e a) (permuteWord e b) (permuteWord e c) := by
  apply Submodule.map_le_iff_le_comap.mpr
  apply Submodule.span_le.mpr
  intro x hx
  change permuteWord (extendHeadPermutation e) x ∈
    StandardExtension (permuteCode e K) (permuteWord e a) (permuteWord e b) (permuteWord e c)
  rcases hx with ⟨k, rfl⟩ | hx
  · rw [permuteWord_extend_append]
    apply kernel_mem_standardExtension
    exact ⟨k.val,k.property,rfl⟩
  · rcases hx with hx | hx | hx
    · subst x
      rw [permuteWord_extend_append]
      exact row1_mem_standardExtension _ _ _ _
    · subst x
      rw [permuteWord_extend_append]
      exact row2_mem_standardExtension _ _ _ _
    · rw [Set.mem_singleton_iff] at hx
      subst x
      rw [permuteWord_extend_append]
      exact row3_mem_standardExtension _ _ _ _

/-- The entire generated extension is transported by a genuine coordinate
permutation, with all tail coordinates fixed. -/
theorem standardExtension_permute_eq (e : Fin 40 ≃ Fin 40)
    (K : Submodule F2 (Word 40)) (a b c : Word 40) :
    StandardExtension (permuteCode e K) (permuteWord e a) (permuteWord e b) (permuteWord e c) =
      permuteCode (extendHeadPermutation e) (StandardExtension K a b c) :=
  le_antisymm (standardExtension_permute_le e K a b c) (permute_standardExtension_le e K a b c)

theorem standardExtension_permute_even (e : Fin 40 ≃ Fin 40)
    (K : Submodule F2 (Word 40)) (a b c : Word 40)
    (h : EvenCode (StandardExtension K a b c)) :
    EvenCode (StandardExtension (permuteCode e K) (permuteWord e a) (permuteWord e b) (permuteWord e c)) := by
  rw [standardExtension_permute_eq]
  exact permuteCode_even _ _ h

theorem standardExtension_permute_minWeight {d : ℕ} (e : Fin 40 ≃ Fin 40)
    (K : Submodule F2 (Word 40)) (a b c : Word 40)
    (h : MinWeight (StandardExtension K a b c) d) :
    MinWeight (StandardExtension (permuteCode e K) (permuteWord e a) (permuteWord e b) (permuteWord e c)) d := by
  rw [standardExtension_permute_eq]
  exact permuteCode_minWeight _ _ h

end ECC

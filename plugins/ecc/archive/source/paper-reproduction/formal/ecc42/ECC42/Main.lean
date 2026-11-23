import ECC42.Parity
import ECC42.Shorten
import ECC42.Normalize

namespace ECC42

/-- The entire reduction, with exact minimum distance in its output. -/
theorem reduction_42_16_to_41_14 (h : CodeExists 42 16 13) :
    ExactCodeExists 41 14 14 := by
  have h43 : CodeExists 43 16 14 := extend_42_16 h
  have h42 : CodeExists 42 15 14 := codeExists_shorten h43
  have h41 : CodeExists 41 14 14 := codeExists_shorten h42
  exact normalize_distance (by decide) (by decide) h41

/-- If published Proposition 2 holds, no binary linear [42,16,≥13] code exists.
The published proposition is an explicit assumption, not a declared axiom. -/
theorem nonexistence_of_proposition2 (hProp2 : Proposition2) :
    ¬ CodeExists 42 16 13 := by
  intro h
  exact hProp2 (reduction_42_16_to_41_14 h)

/-- Expanded statement on actual subspaces, without code-existence abbreviations. -/
theorem nonexistence_explicit
    (hProp2 : ¬ ∃ D : Submodule F2 (Fin 41 → F2),
      Module.finrank F2 D = 14 ∧
      (∀ y ∈ D, y ≠ 0 → 14 ≤ weight y) ∧
      ∃ y ∈ D, y ≠ 0 ∧ weight y = 14)
    (C : Submodule F2 (Fin 42 → F2))
    (hDim : Module.finrank F2 C = 16)
    (hWeight : ∀ x ∈ C, x ≠ 0 → 13 ≤ weight x) : False := by
  exact nonexistence_of_proposition2 hProp2 ⟨C, hDim, hWeight⟩

end ECC42

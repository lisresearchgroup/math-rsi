import ECC.MatrixSupport
import ECC.Catalogue
import ECC.LowerBoundData

namespace ECC

def matrixCode (n : ℕ) (rows : List ℕ) : Submodule F2 (Word n) :=
  LinearMap.range (linearEncode n rows)

/-- The frozen actual 43-bit matrix, not an assumed code, gives this lower bound. -/
theorem code431016 : CodeExists 43 10 16 := by
  have hd : Packed.distanceCheck 43 Packed.seed43.length 16 Packed.seed43 = true := by
    simpa only [Packed.seed43_verified.1] using Packed.seed43_verified.2.2.1
  have h := codeExists_of_distanceCheck (by decide : 0 < 16) hd
  simpa only [Packed.seed43_verified.1] using h

/-- All the literal catalogue entries pass the checks, with membership binding
the statements to the actual 172 matrices. This does not assert classification. -/
theorem catalogue_member_checks {rows : List ℕ} (hr : rows ∈ Packed.catalogueRows) :
    rows.length = 7 ∧ Packed.distanceCheck 40 7 18 rows = true ∧
    Packed.evenCheck 40 7 rows = true ∧ Packed.fullSupportCheck 40 rows = true := by
  have hd := List.all_eq_true.mp Packed.catalogue_all_distance rows hr
  have hs := List.all_eq_true.mp Packed.catalogue_all_shape_even_support rows hr
  simp only [Bool.and_eq_true, beq_iff_eq] at hs
  exact ⟨hs.1.1.1, hd, hs.1.2, hs.2⟩

/-- A mathematical submodule, its dimension, distance, and evenness are derived
from each concrete matrix's kernel-checked finite computations. -/
theorem catalogue_member_is_even_code {rows : List ℕ}
    (hr : rows ∈ Packed.catalogueRows) :
    Module.finrank F2 (matrixCode 40 rows) = 7 ∧
    MinWeight (matrixCode 40 rows) 18 ∧ EvenCode (matrixCode 40 rows) := by
  obtain ⟨hlen, hd, he, _⟩ := catalogue_member_checks hr
  have hd' : Packed.distanceCheck 40 rows.length 18 rows = true := by
    simpa only [hlen] using hd
  have he' : Packed.evenCheck 40 rows.length rows = true := by
    simpa only [hlen] using he
  refine ⟨?_, ?_, evenCode_of_evenCheck he'⟩
  · unfold matrixCode
    rw [LinearMap.finrank_range_of_inj
      (linearEncode_injective_of_distanceCheck (by decide : 0 < 18) hd')]
    simpa [Word, F2] using hlen
  · rintro y ⟨x, rfl⟩ hne
    apply distanceCheck_implies_message_bound hd' x
    intro hx
    apply hne
    rw [hx, map_zero]

/-- Every frozen mother has dimension 7, exact minimum distance 18, even weight,
and full support, all referring to the same decoded range submodule. -/
theorem catalogue_member_parameters {rows : List ℕ}
    (hr : rows ∈ Packed.catalogueRows) :
    Module.finrank F2 (matrixCode 40 rows) = 7 ∧
    ExactMinWeight (matrixCode 40 rows) 18 ∧
    EvenCode (matrixCode 40 rows) ∧ FullSupport (matrixCode 40 rows) := by
  obtain ⟨hlen, hd, _, hs⟩ := catalogue_member_checks hr
  obtain ⟨hdim, _, heven⟩ := catalogue_member_is_even_code hr
  obtain ⟨u, hu⟩ := Packed.catalogue_all_attains_distance rows hr
  have hd' : Packed.distanceCheck 40 rows.length 18 rows = true := by
    simpa only [hlen] using hd
  exact ⟨hdim, exactMinWeight_of_distanceCheck (by decide) hd' hu,
    heven, fullSupport_of_fullSupportCheck hs⟩

theorem seed43_exact_distance : ExactMinWeight (matrixCode 43 Packed.seed43) 16 := by
  have hd : Packed.distanceCheck 43 Packed.seed43.length 16 Packed.seed43 = true := by
    simpa only [Packed.seed43_verified.1] using Packed.seed43_verified.2.2.1
  exact exactMinWeight_of_distanceCheck (by decide) hd Packed.seed43_verified.2.2.2

end ECC

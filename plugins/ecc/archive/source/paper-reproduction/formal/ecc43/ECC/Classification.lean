import ECC.Permutation
import ECC.CatalogueFacts
import ECC.Coset

namespace ECC

def MotherParameters (K : Submodule F2 (Word 40)) : Prop :=
  Module.finrank F2 K = 7 ∧ ExactMinWeight K 18 ∧ EvenCode K ∧ FullSupport K

def catalogueAt (i : Fin 172) : List ℕ :=
  Packed.catalogueRows.get (Fin.cast Packed.catalogue_size.symm i)

def catalogueCode (i : Fin 172) : Submodule F2 (Word 40) := matrixCode 40 (catalogueAt i)

theorem catalogueAt_mem (i : Fin 172) : catalogueAt i ∈ Packed.catalogueRows :=
  List.get_mem _ _

theorem catalogueCode_parameters (i : Fin 172) : MotherParameters (catalogueCode i) :=
  catalogue_member_parameters (catalogueAt_mem i)

/-- The published upper bound of 172 coordinate-equivalence classes, expressed
as its finite pigeonhole statement. This is the external classification input;
it does not name or assume completeness of our reconstructed catalogue. -/
def PublishedClassBound : Prop :=
  ∀ f : Fin 173 → Submodule F2 (Word 40),
    (∀ i, MotherParameters (f i)) →
    ∃ i j, i ≠ j ∧ CoordinateEquivalent (f i) (f j)

/-- The external finite graph-canonicalization result for the actual catalogue.
The mathematical consequence, coverage, is proved below rather than assumed. -/
def CatalogueInequivalent : Prop :=
  ∀ i j : Fin 172, i ≠ j → ¬ CoordinateEquivalent (catalogueCode i) (catalogueCode j)

theorem catalogue_covers_of_class_bound (hBound : PublishedClassBound)
    (hDistinct : CatalogueInequivalent) (K : Submodule F2 (Word 40))
    (hK : MotherParameters K) : ∃ i : Fin 172, CoordinateEquivalent K (catalogueCode i) := by
  let f : Fin 173 → Submodule F2 (Word 40) := Fin.lastCases K catalogueCode
  have hf : ∀ i, MotherParameters (f i) := by
    intro i
    refine Fin.lastCases ?_ (fun j => ?_) i
    · exact hK
    · simpa only [f, Fin.lastCases_castSucc] using catalogueCode_parameters j
  obtain ⟨i, j, hij, he⟩ := hBound f hf
  revert hij he
  refine Fin.lastCases ?_ (fun i => ?_) i
  · refine Fin.lastCases ?_ (fun j => ?_) j
    · intro h
      exact False.elim (h rfl)
    · intro _ h
      simp only [f, Fin.lastCases_last, Fin.lastCases_castSucc] at h
      exact ⟨j, h⟩
  · refine Fin.lastCases ?_ (fun j => ?_) j
    · intro _ h
      simp only [f, Fin.lastCases_last, Fin.lastCases_castSucc] at h
      exact ⟨i, coordinateEquivalent_symm h⟩
    · intro hij h
      simp only [f, Fin.lastCases_castSucc] at h
      have hne : i ≠ j := fun h => hij (congrArg Fin.castSucc h)
      exact False.elim (hDistinct i j hne h)

theorem far_permuteCode (e : Fin 40 ≃ Fin 40) (K : Submodule F2 (Word 40))
    (d : ℕ) (a : Word 40) :
    Far (permuteCode e K) d (permuteWord e a) ↔ Far K d a := by
  constructor
  · intro h k hk
    have hb := h (permuteWord e k) (⟨k, hk, rfl⟩)
    have hw : weight (permuteWord e a + permuteWord e k) = weight (a + k) := by
      rw [← map_add, weight_permuteWord]
    rwa [hw] at hb
  · intro h k hk
    obtain ⟨z, hz, rfl⟩ := hk
    change d ≤ weight (permuteWord e a + permuteWord e z)
    rw [← map_add, weight_permuteWord]
    exact h z hz

theorem pairIncompatible_of_coordinateEquivalent {K L : Submodule F2 (Word 40)}
    (he : CoordinateEquivalent K L) (hL : PairIncompatible L) : PairIncompatible K := by
  obtain ⟨e, rfl⟩ := he
  intro a b hea heb hfa hfb hfab
  have ha := (far_permuteCode e K 16 a).mpr hfa
  have hb := (far_permuteCode e K 16 b).mpr hfb
  have hab := (far_permuteCode e K 16 (a + b)).mpr hfab
  rw [map_add] at hab
  exact hL (permuteWord e a) (permuteWord e b)
    (by simpa using hea) (by simpa using heb) ha hb hab

/-- Classification and coordinate normalization transfer the computed result
for actual representatives to every mother with the required parameters. -/
theorem all_mothers_incompatible (hBound : PublishedClassBound)
    (hDistinct : CatalogueInequivalent)
    (hComputed : ∀ i : Fin 172, PairIncompatible (catalogueCode i)) :
    ∀ K : Submodule F2 (Word 40), MotherParameters K → PairIncompatible K := by
  intro K hK
  obtain ⟨i, he⟩ := catalogue_covers_of_class_bound hBound hDistinct K hK
  exact pairIncompatible_of_coordinateEquivalent he (hComputed i)

end ECC
